//
//  CCDBLock.h
//  CCDB
//
//  Created by cmw on 2022/1/2.
//

#include <pthread.h>

void ccdb_readLock(void);
void ccdb_writeLock(void);
void ccdb_unlock(void);
