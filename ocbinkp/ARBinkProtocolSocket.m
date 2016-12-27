//
//  ARBinkProtocolSocket.m
//  ocbinkp
//
//  Created by Akasaka Ryuunosuke on 26/12/16.
//  Copyright (c) 2016 Akasaka Ryuunosuke. All rights reserved.
//

#import "ARBinkProtocolSocket.h"

static const ARBinkFrame EmptyFrame;

void BinkLogFrame(ARBinkFrame frame) {
    if (frame.type == ARBinkFrameTypeCommand) {
        NSString *dataStringRepresentation = GetBinkFrameDataAsString(frame);
        NSLog(@"%@ ARBinkFrame/Command: %@, %u, %@",frame.isOut ? @"SENT":@"RECV",@[@"NUL",@"ADR",@"PWD",@"FILE",@"OK",@"EOB",@"GOT",@"ERR",@"BSY",@"GET",@"SKIP"][frame.command],frame.datalen,dataStringRepresentation);
    } else {
        NSLog(@"%@ ARBinkFrame/Data: %u bytes",frame.isOut ? @"SENT":@"RECV",frame.datalen);
    }
}

NSString* GetBinkFrameDataAsString(ARBinkFrame frame) {
    NSString *result = [[NSString alloc]initWithBytesNoCopy:&frame.data length:frame.datalen encoding:NSUTF8StringEncoding freeWhenDone:NO];
    return result;
}

@interface NSData (Endian)
-(NSData *)swapEndian;
@end

@implementation NSData (Endian)

-(NSData *)swapEndian
{
    NSMutableData *data = [NSMutableData data];
    int i = (int)[self length] - 1;
    while (i >= 0)
    {
        [data appendData:[self subdataWithRange:NSMakeRange(i, 1)]];
        i--;
    }
    return [NSData dataWithData:data];
}


@end

@implementation ARBinkProtocolSocket
@synthesize innerSocket=innerSocket;

+ (ARBinkProtocolSocket*) socketToHost: (NSString*)host port:(uint16_t)port delegate:(id<ARBinkProtocolDelegate>)delegate {
    return [[ARBinkProtocolSocket alloc]initWithHost:host port:port delegate:delegate];
}

- (ARBinkProtocolSocket*) initWithHost: (NSString*)host port:(uint16_t)port delegate:(id<ARBinkProtocolDelegate>)delegate {
    self = [super init];
    self.delegate = delegate;
    
    innerSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    [self connectToHost:host port:port];
    return self;
}

- (ARBinkProtocolSocket*) initWithDelegate:(id<ARBinkProtocolDelegate>)delegate {
    self = [super init];
    self.delegate = delegate;
    
    innerSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    return self;
}

- (void) _awaitPacket {
   // NSLog(@"waiting binkp packet...");
    [innerSocket readDataToLength:2 withTimeout:-1 tag:TAG_WAIT_PACKET];
}

- (void) sendErrorToDelegate:(NSError*)error {
    if(error && self.delegate && [self.delegate respondsToSelector:@selector(didGetBinkpError:)])
        [self.delegate didGetBinkpError:error];
}

- (void) writeFrame:(ARBinkFrame)frame {
    NSData *headerData = [NSData dataWithBytes:&frame.header length:2].swapEndian;
    NSMutableData *formedData = [[NSMutableData alloc]init];
    
    [formedData appendBytes:headerData.bytes  length:headerData.length];
    if (frame.type == ARBinkFrameTypeCommand) {
        [formedData appendBytes:&frame.command length:sizeof(frame.command)];
    }
    [formedData appendBytes:frame.data length:frame.datalen];
    
    [innerSocket writeData:formedData withTimeout:10.0 tag:TAG_SEND];
    frame.isOut = true;
    //NSLog(@"write frame... %@",formedData);
    BinkLogFrame(frame);
    
}

- (ARBinkFrame) frameOfType: (ARBinkFrameType)type withData: (NSData*)data {
    uint16_t newHeader = 0;
    
    newHeader = data.length;
    
    ARBinkFrame frame;
    
    frame.type = type;
    if (type == ARBinkFrameTypeCommand) {
        newHeader = newHeader + 1;
        newHeader = newHeader | 32768;
    }
    frame.header = newHeader;
    frame.datalen = data.length;
    memcpy(frame.data, data.bytes, data.length);
    
    
    return frame;
}

- (void) writeFrameOfType: (ARBinkFrameType)type withData: (NSData*)data {
    [self writeFrame:[self frameOfType:type withData:data]];
}

- (ARBinkFrame) dataFrameWithData:(NSData*)data {
    return [self frameOfType:ARBinkFrameTypeData withData:data];
}

- (ARBinkFrame) dataFrameWithString:(NSString*)string {
    NSData *strData = [string dataUsingEncoding:NSUTF8StringEncoding];
    return [self dataFrameWithData:strData];
}

- (ARBinkFrame) commandFrame:(ARBinkCommand)command withArgs:(NSData*)data {
    NSMutableData *frameData = [NSMutableData new];
    if(data)[frameData appendData:data  ];
    ARBinkFrame frame = [self frameOfType:ARBinkFrameTypeCommand withData:frameData];
    frame.command = command;
    return frame;
}

- (ARBinkFrame) commandFrame:(ARBinkCommand)command withString:(NSString*)string {
    NSData *strData = [string dataUsingEncoding:NSUTF8StringEncoding];
    return [self commandFrame:command withArgs:strData];
}

- (ARBinkFrame) commandFrame:(ARBinkCommand)command {
    return [self commandFrame:command withArgs:nil];
}

- (void) writeCommandFrame:(ARBinkCommand)command withArgs:(NSData*)args {
    [self writeFrame:[self commandFrame:command withArgs:args]];
}

- (void) writeCommandFrame:(ARBinkCommand)command withString:(NSString*)string {
    [self writeFrame:[self commandFrame:command withString:string]];
}

- (void) writeCommandFrame:(ARBinkCommand)command  {
    [self writeFrame:[self commandFrame:command]];
}

- (void) writeDataFrameWithData:(NSData*)data {
    [self writeFrame:[self dataFrameWithData:data]];
}

- (void) writeDataFrameWithString:(NSString*)string {
    [self writeFrame:[self dataFrameWithString:string]];
}

#pragma mark - Socket delegate

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"binkp connect...");
    [self _awaitPacket];
    if (self.delegate && [self.delegate respondsToSelector:@selector(didConnectBinkpHost:port:)]) {
        [self.delegate didConnectBinkpHost:host port:port];
    }
    
}
- (void) socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag    {
    //[self _awaitPacket];
}
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSData *mdata = [data swapEndian];
    //NSLog(@"RECV-RAW: %@",data);
    if (TAG_WAIT_PACKET == tag) {
        currentRecvFrame = EmptyFrame;
        memcpy(&currentRecvFrame.header, mdata.bytes, 2);
        currentRecvFrame.datalen = (currentRecvFrame.header & ~32768);
        
        if ((currentRecvFrame.header & 32768) > 0) {
            [innerSocket readDataToLength:currentRecvFrame.datalen withTimeout:-1 tag:TAG_RECVING_CMD];
            currentRecvFrame.type = ARBinkFrameTypeCommand;
            currentRecvFrame.datalen -= 1;
        } else {
            
            [innerSocket readDataToLength:currentRecvFrame.datalen withTimeout:-1 tag:TAG_RECVING_DTA];
            currentRecvFrame.type = ARBinkFrameTypeData;
        }
       // BinkLogFrame(currentRecvFrame);
    }
    else if (TAG_RECVING_CMD == tag) {
        memcpy(&currentRecvFrame.command, data.bytes, 1);
        memcpy(&currentRecvFrame.data, data.bytes+1, currentRecvFrame.datalen);
        if (self.delegate && [self.delegate respondsToSelector:@selector(didGetBinkpFrame:)]) {
            [self.delegate didGetBinkpFrame:currentRecvFrame];
        }
        [self _awaitPacket];
    }
    else if(TAG_RECVING_DTA == tag) {
        memcpy(&currentRecvFrame.data, data.bytes, currentRecvFrame.datalen);
        if (self.delegate && [self.delegate respondsToSelector:@selector(didGetBinkpFrame:)]) {
            [self.delegate didGetBinkpFrame:currentRecvFrame];
        }
        [self _awaitPacket];

    }
}
- (void)socket:(GCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag    {
    NSLog(@"part data %lu...",partialLength);
}
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:( NSError *)err {
    NSLog(@"disconnect");
}

- (void) connectToHost: (NSString*)host port:(uint16_t)port {
    NSError *e = nil;
    [innerSocket setDelegate:self];
    [innerSocket connectToHost:host onPort:port error:&e];
    [NSThread sleepForTimeInterval:1];
    [self sendErrorToDelegate:e];
}

- (void) disconnect {
    [innerSocket disconnectAfterReadingAndWriting];
}
@end
