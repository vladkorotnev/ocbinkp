//
//  ARBinkTransactionManager.h
//  ocbinkp
//
//  Created by Akasaka Ryuunosuke on 26/12/16.
//  Copyright (c) 2016 Akasaka Ryuunosuke. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARBinkProtocolSocket.h"
#import "ARBinkFile.h"
#import "ARBinkStructs.h"
#import "ARBinkPoint.h"
#define SYS_ID @"AkRObjCBinkDTransactionManager"
#define LOC_ID @"Mobile Access Point"
#define SYSOP @"Unidentified User"
#define LIB_VER @"VER 1.0"
typedef enum : NSUInteger {
    TransactionStateBegin,
    TransactionStateSentPass,
    TransactionStateAuthed,
    TransactionStateReceivingFile,
    TransactionStateSendingFiles,
    TransactionStateSendingAFile
} BinkTransactionState;

typedef enum : NSUInteger {
    PollErrorUnknown,
    PollErrorBusy,
    PollErrorAuthFailure,
    PollErrorProtocolError
} ARBinkPollError;

@class ARBinkTransactionManager;
@protocol ARBinkTransactionDelegate <NSObject>

- (void) pollDidComplete:(ARBinkTransactionManager*)poller;
- (void) pollDidFail:(ARBinkTransactionManager*)poller withReason:(ARBinkPollError)reason;
- (void) pollDidFail:(ARBinkTransactionManager*)poller dueToTransactionError:(NSError*)error;
- (void) pollDidGetFile:(ARBinkFile*)file atPoller:(ARBinkTransactionManager*)poller;
- (void) pollDidSendFile:(ARBinkFile*)file atPoller:(ARBinkTransactionManager*)poller;

@end

@interface ARBinkTransactionManager : NSObject<ARBinkProtocolDelegate> {
    ARBinkProtocolSocket * socket;
    BinkTransactionState state;
    ARBinkFile *currentRecvFile;
    ARBinkFile *currentSendFile;
    unsigned long long currentSendPos;
}
@property (nonatomic,retain) ARBinkPoint *point;
@property (nonatomic,retain) NSMutableArray *outgoing;
@property (nonatomic,retain) NSMutableArray *incoming;
@property id<ARBinkTransactionDelegate> delegate;

- (ARBinkTransactionManager *)initWithPoint:(ARBinkPoint*)point delegate:(id<ARBinkTransactionDelegate>)delegate;
- (void) poll;
@end



