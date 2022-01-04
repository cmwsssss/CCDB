//
//  CCDBMMAPCache.c
//  CCDB
//
//  Created by cmw on 2021/12/18.
//

#import "CCDBMMAPCache.h"
#import <sys/mman.h>

#define DEFAULT_SIZE 1024 * 1024 * 1

typedef enum : NSUInteger {
    MMAPPropertyTypeString = 1,
    MMAPPropertyTypeInt = 2,
    MMAPPropertyTypeDouble = 3,
    MMAPPropertyTypeBool = 4,
    MMAPPropertyTypeNull = 5
} MMAPPropertyType;

static NSString *s_mmap_direcotyPath;
static int s_mmap_currentPtrIndex = 0;

static size_t *s_mmap_fileSize;

static void **s_mmap_headerPtrs;
static void **s_mmap_tailPtrs;

static int *s_mmap_fileInstance;

static char **s_mmap_model_name;

static NSMutableArray *s_mmap_writeSemaphore;
static NSMutableArray *s_mmap_replaceSemaphore;

static dispatch_semaphore_t s_semaphoreInit;


NSString *getMMAPDirectoryPath(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        s_mmap_direcotyPath = [[paths objectAtIndex:0]stringByAppendingPathComponent:@"CCDB_data"];
        
        BOOL isExisited = [[NSFileManager defaultManager]fileExistsAtPath:s_mmap_direcotyPath];
        if(isExisited == false) {
            [[NSFileManager defaultManager]createDirectoryAtPath:s_mmap_direcotyPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
    });
    return s_mmap_direcotyPath;
}

size_t getFileSize(NSString *filePath) {
    FILE *file = fopen(filePath.UTF8String, "r");
    if (file == NULL) {
        return 0;
    }
    fseek(file, 0, SEEK_END);
    size_t fileLength = ftell(file);
    fclose(file);
    return fileLength;
}

void *cc_realloc(void *src, size_t newSize, size_t oldSize) {
    if (oldSize == 0) {
        return malloc(newSize);
    }
    void *newPtr = malloc(newSize);
    memcpy(newPtr, src, oldSize);
    free(src);
    return newPtr;
}

void ccdb_syncAllLocalCache(void) {
    NSArray <NSString *> *paths = [[NSFileManager defaultManager] subpathsAtPath:getMMAPDirectoryPath()];
    [paths enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj containsString:@".mmap"]) {
            NSString *modelIndex = [obj componentsSeparatedByString:@"."].firstObject;
            ccdb_initilizeMMAPCache(modelIndex);
        }
    }];
}

int ccdb_initilizeMMAPCache(NSString *modelIndex) {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_semaphoreInit = dispatch_semaphore_create(1);
    });
    dispatch_semaphore_wait(s_semaphoreInit, DISPATCH_TIME_FOREVER);
    for (int i = 0; i < s_mmap_currentPtrIndex; i++) {
        if ([[NSString stringWithUTF8String:s_mmap_model_name[i]] isEqualToString:modelIndex]) {
            dispatch_semaphore_signal(s_semaphoreInit);
            return i;
        }
    }
    NSString *filePath = [getMMAPDirectoryPath() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mmap", modelIndex]];
    
    size_t size = getFileSize(filePath);
    int fileInstance = open(filePath.UTF8String, O_RDWR|O_CREAT, 0666);
    bool emptyFile = false;
    if (size == 0) {
        ftruncate(fileInstance, DEFAULT_SIZE);
        size = DEFAULT_SIZE;
        emptyFile = true;
    }
    
    void *headerPtr = mmap(NULL, size, (PROT_READ|PROT_WRITE), (MAP_FILE|MAP_SHARED), fileInstance, 0);
    
    s_mmap_currentPtrIndex++;
    s_mmap_headerPtrs = cc_realloc(s_mmap_headerPtrs, s_mmap_currentPtrIndex * sizeof(void *), (s_mmap_currentPtrIndex - 1) * sizeof(void *));
    s_mmap_tailPtrs = cc_realloc(s_mmap_tailPtrs, s_mmap_currentPtrIndex * sizeof(void *), (s_mmap_currentPtrIndex - 1)  * sizeof(void *));
    s_mmap_model_name = cc_realloc(s_mmap_model_name, s_mmap_currentPtrIndex * sizeof(char *), (s_mmap_currentPtrIndex - 1) * sizeof(char *));
    s_mmap_fileSize = cc_realloc(s_mmap_fileSize, s_mmap_currentPtrIndex * sizeof(size_t), (s_mmap_currentPtrIndex - 1) * sizeof(size_t));
    if (!s_mmap_writeSemaphore) {
        s_mmap_writeSemaphore = [[NSMutableArray alloc] init];
    }
    if (!s_mmap_replaceSemaphore) {
        s_mmap_replaceSemaphore = [[NSMutableArray alloc] init];
    }
    s_mmap_fileInstance = cc_realloc(s_mmap_fileInstance, sizeof(int) * s_mmap_currentPtrIndex, sizeof(int) * (s_mmap_currentPtrIndex - 1));
    
    s_mmap_headerPtrs[s_mmap_currentPtrIndex - 1] = headerPtr;
    if (emptyFile) {
        long length = sizeof(long);
        memcpy(headerPtr, &length, sizeof(long));
    }
    long length = *(long *)headerPtr;
    
    void *tail = headerPtr + length;
    s_mmap_tailPtrs[s_mmap_currentPtrIndex - 1] = tail;
    
    memcpy(tail, &length, sizeof(long));
    
    length = strlen(modelIndex.UTF8String) + 1;
    
    s_mmap_model_name[s_mmap_currentPtrIndex - 1] = malloc(length);
    strcpy(s_mmap_model_name[s_mmap_currentPtrIndex - 1], modelIndex.UTF8String);

    s_mmap_fileSize[s_mmap_currentPtrIndex - 1] = size;

    [s_mmap_writeSemaphore addObject:dispatch_semaphore_create(1)];
    [s_mmap_replaceSemaphore addObject:dispatch_semaphore_create(1)];

    s_mmap_fileInstance[s_mmap_currentPtrIndex - 1] = fileInstance;
    
    dispatch_semaphore_signal(s_semaphoreInit);
    return s_mmap_currentPtrIndex - 1;
}

void *insertMMAPCache(void* seek, const char *propertyNameBytes, int propertyLength, void *bytes, int bytesLength, MMAPPropertyType type) {
    //sizeof(int)
    memcpy(seek, &propertyLength, 4);
    seek += 4;

    memcpy(seek, propertyNameBytes, propertyLength);
    seek += propertyLength;
    
    //sizeof(nsinteger)
    memcpy(seek, &type, 8);
    seek += 8;
    
    //sizeof(int)
    memcpy(seek, &bytesLength, 4);
    seek += 4;
    
    memcpy(seek, bytes, bytesLength);
    seek += bytesLength;
    
    return seek;
}

void truncateFile(NSInteger mmapPtrIndex, long length) {
    munmap(s_mmap_headerPtrs[mmapPtrIndex], length);
    long newSize = s_mmap_fileSize[mmapPtrIndex] * 2;
    int fileInstance = s_mmap_fileInstance[mmapPtrIndex];
    ftruncate(fileInstance, newSize);
    s_mmap_fileSize[mmapPtrIndex] = newSize;
    void *headerPtr = mmap(NULL, newSize, (PROT_READ|PROT_WRITE), (MAP_FILE|MAP_SHARED), fileInstance, 0);
    s_mmap_headerPtrs[mmapPtrIndex] = headerPtr;
    s_mmap_tailPtrs[mmapPtrIndex] = headerPtr + length;
}

void resetMMAPLength(NSInteger mmapPtrIndex) {
    void *head = s_mmap_headerPtrs[mmapPtrIndex];
    void *tail = s_mmap_tailPtrs[mmapPtrIndex];
    long length = tail - head;
    memcpy(head, &length, sizeof(long));
    
    dispatch_semaphore_wait(s_mmap_writeSemaphore[mmapPtrIndex], DISPATCH_TIME_FOREVER);
    if (length >= s_mmap_fileSize[mmapPtrIndex] / 4 * 3) {
        truncateFile(mmapPtrIndex, length);
    }
    dispatch_semaphore_signal(s_mmap_writeSemaphore[mmapPtrIndex]);
}

void ccdb_beginMMAPCacheTransaction(NSInteger mmapPtrIndex, CCDBMMAPTransactionType type) {
    dispatch_semaphore_wait(s_mmap_writeSemaphore[mmapPtrIndex], DISPATCH_TIME_FOREVER);
    memcpy(s_mmap_tailPtrs[mmapPtrIndex], &type, sizeof(CCDBMMAPTransactionType));
    s_mmap_tailPtrs[mmapPtrIndex] += sizeof(CCDBMMAPTransactionType);
}

void ccdb_commitMMAPCacheTransaction(NSInteger mmapPtrIndex) {
    void *tail = s_mmap_tailPtrs[mmapPtrIndex];
    const char stop = '\0';
    //sizeof(char)
    memcpy(tail, &stop, 1);
    s_mmap_tailPtrs[mmapPtrIndex]++;
    dispatch_semaphore_signal(s_mmap_writeSemaphore[mmapPtrIndex]);
    resetMMAPLength(mmapPtrIndex);
}

void ccdb_insertMMAPCacheWithDouble(double value, NSString *propertyName, NSInteger mmapPtrIndex) {
    void *seek = s_mmap_tailPtrs[mmapPtrIndex];
    const char *propertyBytes = propertyName.UTF8String;
    int propertyLength = (int)strlen(propertyBytes) + 1;
    void *bytes = &value;
    //sizeof(double)
    int bytesLength = 8;
    
    s_mmap_tailPtrs[mmapPtrIndex] = insertMMAPCache(seek, propertyBytes, propertyLength, bytes, bytesLength, MMAPPropertyTypeDouble);
}

void ccdb_insertMMAPCacheWithNull(NSString *propertyName, NSInteger mmapPtrIndex) {
    void *seek = s_mmap_tailPtrs[mmapPtrIndex];
    const char *propertyBytes = propertyName.UTF8String;
    int propertyLength = (int)strlen(propertyBytes) + 1;
    bool value = true;
    void *bytes = &value;
    //sizeof(bool)
    int bytesLength = 1;
    
    s_mmap_tailPtrs[mmapPtrIndex] = insertMMAPCache(seek, propertyBytes, propertyLength, bytes, bytesLength, MMAPPropertyTypeNull);
}

void ccdb_insertMMAPCacheWithBool(bool value, NSString *propertyName, NSInteger mmapPtrIndex) {
    void *seek = s_mmap_tailPtrs[mmapPtrIndex];
    const char *propertyBytes = propertyName.UTF8String;
    int propertyLength = (int)strlen(propertyBytes) + 1;
    void *bytes = &value;
    //sizeof(bool)
    int bytesLength = 1;
    
    s_mmap_tailPtrs[mmapPtrIndex] = insertMMAPCache(seek, propertyBytes, propertyLength, bytes, bytesLength, MMAPPropertyTypeBool);
}

void ccdb_insertMMAPCacheWithInt(NSInteger number, NSString *propertyName, NSInteger mmapPtrIndex) {
    void *seek = s_mmap_tailPtrs[mmapPtrIndex];
    
    const char *propertyBytes = propertyName.UTF8String;
    int propertyLength = (int)strlen(propertyBytes) + 1;
    void *bytes = &number;
    //sizeof(nsinteger)
    int bytesLength = 8;
    
    s_mmap_tailPtrs[mmapPtrIndex] = insertMMAPCache(seek, propertyBytes, propertyLength, bytes, bytesLength, MMAPPropertyTypeInt);
}

void ccdb_insertMMAPCacheWithString(NSString *string, NSString *propertyName, NSInteger mmapPtrIndex) {
    void *seek = s_mmap_tailPtrs[mmapPtrIndex];
    const char *propertyBytes = propertyName.UTF8String;
    int propertyLength = (int)strlen(propertyBytes) + 1;
    const char *bytes = string.UTF8String;
    int bytesLength = (int)strlen(bytes) + 1;
    
    s_mmap_tailPtrs[mmapPtrIndex] = insertMMAPCache(seek, propertyBytes, propertyLength, bytes, bytesLength, MMAPPropertyTypeString);
}

const char *getDeleteAllObjectFromContainerSql(int mmapPtrIndex) {
    const char *tableName = s_mmap_model_name[mmapPtrIndex];
    NSMutableString *deleteSql = [[NSMutableString alloc] initWithFormat:@"DELETE FROM %s_index", tableName];
    return deleteSql.UTF8String;
}

const char *getDeleteObjectFromContainerSql(int mmapPtrIndex) {
    const char *tableName = s_mmap_model_name[mmapPtrIndex];
    NSMutableString *deleteSql = [[NSMutableString alloc] initWithFormat:@"DELETE FROM %s_index where primary_key = ?", tableName];
    return deleteSql.UTF8String;
}

const char *getDeleteAllSql(int mmapPtrIndex) {
    const char *tableName = s_mmap_model_name[mmapPtrIndex];
    NSMutableString *deleteSql = [[NSMutableString alloc] initWithFormat:@"DELETE FROM %s", tableName];
    return deleteSql.UTF8String;
}

const char *getContainerDeleteAllSql(int mmapPtrIndex) {
    const char *tableName = s_mmap_model_name[mmapPtrIndex];
    NSMutableString *deleteSql = [[NSMutableString alloc] initWithFormat:@"DELETE FROM %s_index where hash_id = ?", tableName];
    return deleteSql.UTF8String;
}

const char *getContainerDeleteSql(int mmapPtrIndex) {
    const char *tableName = s_mmap_model_name[mmapPtrIndex];
    NSMutableString *deleteSql = [[NSMutableString alloc] initWithFormat:@"DELETE FROM %s_index where hash_id = ? and primary_key = ?", tableName];
    return deleteSql.UTF8String;
}

const char *getContainerReplaceIntoDBSql(int mmapPtrIndex) {
    const char *tableName = s_mmap_model_name[mmapPtrIndex];
    NSMutableString *replaceSql = [[NSMutableString alloc] initWithFormat:@"REPLACE INTO %s_index (id,hash_id,primary_key,update_time) VALUES(?,?,?,?)", tableName];
    return replaceSql.UTF8String;
}

const char *getDeleteDBSql(int mmapPtrIndex, void *seek) {
    int propertyNameLength = *(int *)seek;
    seek += sizeof(int);
    
    const char *propertyName = malloc(propertyNameLength);
    memcpy(propertyName, seek, propertyNameLength);
    
    NSMutableString *sql = [[NSMutableString alloc] initWithFormat:@"DELETE FROM %s WHERE %s = ?", s_mmap_model_name[mmapPtrIndex], propertyName];

    return sql.UTF8String;
}

const char *getReplaceIntoDBSql(int mmapPtrIndex, void *seek) {
    NSMutableString *replaceSql = [[NSMutableString alloc] initWithFormat:@"REPLACE INTO %s (", s_mmap_model_name[mmapPtrIndex]];
    int bindCount = 0;
    while (*(char *)seek != '\0') {
        int length = *(int *)seek;
        seek += sizeof(int);
        const char *propertyName = malloc(length);
        memcpy(propertyName, seek, length);
        seek += length + sizeof(MMAPPropertyType);
        
        length = *(int *)seek;
        seek += length + sizeof(int);
        if (bindCount == 0) {
            [replaceSql appendFormat:@"%s",propertyName];
        } else {
            [replaceSql appendFormat:@",%s",propertyName];
        }
        free(propertyName);
        bindCount++;
    }
    [replaceSql appendString:@") VALUES ("];
    for(int i = 0; i < bindCount; i++) {
        if (i == 0) {
            [replaceSql appendString:@"?"];
        } else {
            [replaceSql appendString:@",?"];
        }
    }
    [replaceSql appendString:@")"];
    return replaceSql.UTF8String;
}

void *bindPropertyWithMMAPSeek(void *seek, sqlite3_stmt* stmt, int index, int mmapPtrIndex) {
    int propertyLength = *(int *)seek;
    seek += sizeof(int);
    
    const char *propertyName = malloc(propertyLength);
    memcpy((void *)propertyName, seek, propertyLength);
    seek += propertyLength;
    
    MMAPPropertyType type = *(MMAPPropertyType *)seek;
    seek += sizeof(MMAPPropertyType);
    switch (type) {
        case MMAPPropertyTypeInt: {
            seek += sizeof(int);
            NSInteger value = *(NSInteger *)seek;
            seek += sizeof(NSInteger);
            sqlite3_bind_int64(stmt, index, value);
        }
            break;
        case MMAPPropertyTypeBool: {
            seek += sizeof(int);
            bool value = *(bool *)seek;
            seek += sizeof(bool);
            sqlite3_bind_int(stmt, index, value);
        }
            break;
        case MMAPPropertyTypeDouble: {
            seek += sizeof(int);
            double value = *(double *)seek;
            seek += sizeof(double);
            sqlite3_bind_double(stmt, index, value);
        }
            break;
        case MMAPPropertyTypeString: {
            int bytesLength = *(int *)seek;
            seek += sizeof(int);
            const char *value = malloc(bytesLength);
            memcpy((void *)value, seek, bytesLength);
            seek += bytesLength;
            sqlite3_bind_text(stmt, index, value, -1, SQLITE_TRANSIENT);
            free(value);
        }
            break;
        case MMAPPropertyTypeNull: {
            seek += sizeof(int);
            seek += sizeof(bool);
            sqlite3_bind_null(stmt, index);
        }
            break;
        default:
            break;
    }
    free(propertyName);
    return seek;
}

void dealTransaction(sqlite3 *dbInstance, NSInteger dbInstanceIndex, int i) {
    sqlite3_stmt **stmts = malloc(sizeof(sqlite3 *) * (CCDBMMAPTransactionTypeDeleteAllObjectFromContainer + 1));
    for (int i = 0; i <= CCDBMMAPTransactionTypeDeleteAllObjectFromContainer; i++) {
        stmts[i] = NULL;
    }
    dispatch_semaphore_wait(s_mmap_replaceSemaphore[i], DISPATCH_TIME_FOREVER);
    
    dispatch_semaphore_wait(s_mmap_writeSemaphore[i], DISPATCH_TIME_FOREVER);
    void *originalTail = s_mmap_tailPtrs[i];
    long length = originalTail - s_mmap_headerPtrs[i] - sizeof(long);
    void *temp = malloc(length);
    memcpy(temp, s_mmap_headerPtrs[i] + sizeof(long), length);
    void *seek = temp;
    void *tail = temp + length;
    dispatch_semaphore_signal(s_mmap_writeSemaphore[i]);
    
    while (seek != tail) {
        CCDBMMAPTransactionType type = *(CCDBMMAPTransactionType *)seek;
        seek += sizeof(CCDBMMAPTransactionType);
        char *sql = NULL;
        if (!stmts[type]) {
            switch (type) {
                case CCDBMMAPTransactionTypeUpdate:
                    sql = (char *)getReplaceIntoDBSql(i, seek);
                    break;
                case CCDBMMAPTransactionTypeDelete:
                    sql = (char *)getDeleteDBSql(i, seek);
                    break;
                case CCDBMMAPTransactionTypeContainerUpdate:
                    sql = (char *)getContainerReplaceIntoDBSql(i);
                    break;
                case CCDBMMAPTransactionTypeContainerDelete:
                    sql = (char *)getContainerDeleteSql(i);
                    break;
                case CCDBMMAPTransactionTypeDeleteAll:
                    sql = (char *)getDeleteAllSql(i);
                    break;
                case CCDBMMAPTransactionTypeContainerDeleteAll:
                    sql = (char *)getContainerDeleteAllSql(i);
                    break;
                case CCDBMMAPTransactionTypeDeleteObjectFromContainer:
                    sql = (char *)getDeleteObjectFromContainerSql(i);
                    break;
                case CCDBMMAPTransactionTypeDeleteAllObjectFromContainer:
                    sql = (char *)getDeleteAllObjectFromContainerSql(i);
                    break;
                default:
                    break;
            }
            if (sql == NULL) {
                assert("sql == null");
            }
            if (sqlite3_prepare_v2(dbInstance, sql, -1, &(stmts[type]), NULL) != SQLITE_OK) {
                assert("sqlite3_prepare_v2 error update");
            }
        }
        int index = 1;
        while (*(char *)(seek) != '\0') {
            seek = bindPropertyWithMMAPSeek(seek, stmts[type], index, i);
            index++;
        }
        sqlite3_step(stmts[type]);
        sqlite3_reset(stmts[type]);
        seek++;
    }
    
    dispatch_semaphore_wait(s_mmap_writeSemaphore[i], DISPATCH_TIME_FOREVER);
    length = s_mmap_tailPtrs[i] - originalTail + sizeof(long);
    memcpy(s_mmap_headerPtrs[i], &length, sizeof(long));
    memcpy(s_mmap_headerPtrs[i] + sizeof(long), originalTail, length - sizeof(long));
    s_mmap_tailPtrs[i] = s_mmap_headerPtrs[i] + length;
    dispatch_semaphore_signal(s_mmap_writeSemaphore[i]);
    
    dispatch_semaphore_signal(s_mmap_replaceSemaphore[i]);
    free(temp);
    free(stmts);
}

void ccdb_replaceMMAPCacheDataIntoDB(sqlite3 *dbInstance, NSInteger dbInstanceIndex) {
    for (int i = 0; i < s_mmap_currentPtrIndex; i++) {
        if (s_mmap_tailPtrs[i] != s_mmap_headerPtrs[i] + sizeof(long)) {
            dealTransaction(dbInstance, dbInstanceIndex, i);
        }
    }
}

