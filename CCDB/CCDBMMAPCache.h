//
//  CCDBMMAPCache.h
//  CCDB
//
//  Created by cmw on 2021/12/18.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

#ifndef CCDBMMAPCache_h
#define CCDBMMAPCache_h

typedef enum : NSUInteger {
    CCDBMMAPTransactionTypeUpdate = 1,
    CCDBMMAPTransactionTypeDelete = 2,
    CCDBMMAPTransactionTypeContainerUpdate = 3,
    CCDBMMAPTransactionTypeContainerDelete = 4,
    CCDBMMAPTransactionTypeDeleteAll = 5,
    CCDBMMAPTransactionTypeContainerDeleteAll = 6,
    CCDBMMAPTransactionTypeDeleteObjectFromContainer = 7,
    CCDBMMAPTransactionTypeDeleteAllObjectFromContainer = 8
} CCDBMMAPTransactionType;

int ccdb_initilizeMMAPCache(NSString *modelIndex);
void ccdb_syncAllLocalCache(void);

void ccdb_insertMMAPCacheWithNull(NSString *propertyName, NSInteger mmapPtrIndex);
void ccdb_insertMMAPCacheWithInt(NSInteger value, NSString *propertyName, NSInteger mmapPtrIndex);
void ccdb_insertMMAPCacheWithBool(bool value, NSString *propertyName, NSInteger mmapPtrIndex);
void ccdb_insertMMAPCacheWithDouble(double value, NSString *propertyName, NSInteger mmapPtrIndex);
void ccdb_insertMMAPCacheWithString(NSString *value, NSString *propertyName, NSInteger mmapPtrIndex);

void ccdb_beginMMAPCacheTransaction(NSInteger mmapPtrIndex, CCDBMMAPTransactionType type);
void ccdb_commitMMAPCacheTransaction(NSInteger mmapPtrIndex);

void ccdb_replaceMMAPCacheDataIntoDB(sqlite3 *dbInstance, NSInteger dbIndex);

#endif /* CCDBMMAPCache_h */
