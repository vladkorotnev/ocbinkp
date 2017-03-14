//
//  ARBinkProtocolSocket.h
//  ocbinkp
//
//  Created by Akasaka Ryuunosuke on 26/12/16.
//  Copyright (c) 2016 Akasaka Ryuunosuke. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
#import "ARBinkStructs.h"

#define TAG_SEND 1
#define TAG_WAIT_PACKET 2
#define TAG_RECVING_CMD 3
#define TAG_RECVING_DTA 4



extern void BinkLogFrame(ARBinkFrame frame);
extern NSString* GetBinkFrameDataAsString(ARBinkFrame frame);

@protocol ARBinkProtocolDelegate <NSObject>

- (void) didGetBinkpFrame: (ARBinkFrame)frame;
- (void) didConnectBinkpHost: (NSString*)host port:(uint16_t)port;
- (void) didGetBinkpError:(NSError*)error;

@end

@interface ARBinkProtocolSocket : NSObject<GCDAsyncSocketDelegate>
{
    ARBinkFrame currentRecvFrame;
}

@property id<ARBinkProtocolDelegate> delegate;
@property (nonatomic,strong) GCDAsyncSocket *innerSocket;
+ (ARBinkProtocolSocket*) socketToHost: (NSString*)host port:(uint16_t)port delegate:(id<ARBinkProtocolDelegate>)delegate;
- (ARBinkProtocolSocket*) initWithHost: (NSString*)host port:(uint16_t)port delegate:(id<ARBinkProtocolDelegate>)delegate;
- (ARBinkProtocolSocket*) initWithDelegate:(id<ARBinkProtocolDelegate>)delegate;

- (void) connectToHost: (NSString*)host port:(uint16_t)port;

- (void) writeFrame:(ARBinkFrame)frame;
- (ARBinkFrame) frameOfType: (ARBinkFrameType)type withData: (NSData*)data;
- (void) writeFrameOfType: (ARBinkFrameType)type withData: (NSData*)data;

- (ARBinkFrame) commandFrame:(ARBinkCommand)command withArgs:(NSData*)data;
- (ARBinkFrame) commandFrame:(ARBinkCommand)command withString:(NSString*)string;
- (ARBinkFrame) commandFrame:(ARBinkCommand)command;
- (ARBinkFrame) dataFrameWithData:(NSData*)data;
- (ARBinkFrame) dataFrameWithString:(NSString*)string;

- (void) writeCommandFrame:(ARBinkCommand)command withArgs:(NSData*)args;
- (void) writeCommandFrame:(ARBinkCommand)command withString:(NSString*)string;
- (void) writeCommandFrame:(ARBinkCommand)command;
- (void) writeDataFrameWithData:(NSData*)data;
- (void) writeDataFrameWithString:(NSString*)string;

- (void) disconnect;

@end
