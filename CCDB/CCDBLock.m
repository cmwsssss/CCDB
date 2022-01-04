//
//  CCDBLock.m
//  CCDB
//
//  Created by cmw on 2022/1/2.
//

#import "CCDBLock.h"

static pthread_rwlock_t s_lock = PTHREAD_RWLOCK_INITIALIZER;

void ccdb_readLock(void) {
    pthread_rwlock_rdlock(&s_lock);
}
void ccdb_writeLock(void) {
    pthread_rwlock_wrlock(&s_lock);
}
void ccdb_unlock(void) {
    pthread_rwlock_unlock(&s_lock);
}
