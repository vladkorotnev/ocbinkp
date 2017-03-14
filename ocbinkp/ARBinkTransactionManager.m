//
//  ARBinkTransactionManager.m
//  ocbinkp
//
//  Created by Akasaka Ryuunosuke on 26/12/16.
//  Copyright (c) 2016 Akasaka Ryuunosuke. All rights reserved.
//

#import "ARBinkTransactionManager.h"

@implementation ARBinkTransactionManager

- (ARBinkTransactionManager *)initWithPoint:(ARBinkPoint*)point delegate:(id<ARBinkTransactionDelegate>)delegate {
    self = [self init];
    self.point = point;
    self.outgoing = [NSMutableArray new];
    self.incoming = [NSMutableArray new];
    self.delegate = delegate;
    socket = [[ARBinkProtocolSocket alloc]initWithDelegate:self];
    return self;
}

- (void) didGetBinkpFrame: (ARBinkFrame)frame {
    BinkLogFrame(frame);
    if (state == TransactionStateBegin) {
        if (frame.command == M_ADR) {
            [socket writeCommandFrame:M_NUL withString:SYS_ID];
            [socket writeCommandFrame:M_NUL withString:[NSString stringWithFormat:@"ZYZ %@",(self.point.sysop?:SYSOP)]];
            [socket writeCommandFrame:M_NUL withString:[NSString stringWithFormat:@"LOC %@",self.point.location?:LOC_ID]];
            [socket writeCommandFrame:M_NUL withString:LIB_VER];
            [socket writeCommandFrame:M_ADR withString:self.point.address?:@""];
            [socket writeCommandFrame:M_PWD withString:self.point.password?:@"-"];
            state = TransactionStateSentPass;
        } else if (frame.command == M_BSY) {
            // terminate poll with error
            [socket disconnect];
            if (self.delegate && [self.delegate respondsToSelector:@selector(pollDidFail:withReason:)]) {
                [self.delegate pollDidFail:self withReason:PollErrorBusy];
            }
        }
    }
    else if (TransactionStateSentPass == state) {
        switch (frame.command) {
            case M_ERR:
                //o shit
                NSLog(@"Authetication failure");
                [socket disconnect];
                if (self.delegate && [self.delegate respondsToSelector:@selector(pollDidFail:withReason:)]) {
                    [self.delegate pollDidFail:self withReason:PollErrorAuthFailure];
                }
                break;
            case M_OK:
                NSLog(@"Authetication success");
                state = TransactionStateAuthed;
                break;
                
            default:
                break;
        }
    }
    else if (TransactionStateAuthed == state) {
        switch (frame.command) {
            case M_ERR:
                //o shit
                if (self.delegate && [self.delegate respondsToSelector:@selector(pollDidFail:withReason:)]) {
                    [self.delegate pollDidFail:self withReason:PollErrorUnknown];
                }
                break;
            case M_FILE:
                // files
                {
                    NSArray*param = [GetBinkFrameDataAsString(frame) componentsSeparatedByString:@" "];
                    currentRecvFile = [[ARBinkFile alloc]initWithName:param[0] targetSize:[param[1] longLongValue] unixTime:[param[2] longLongValue]];
                    state = TransactionStateReceivingFile;
                }
                break;
            case M_OK:
                
                break;
            case M_EOB:
                if (self.outgoing.count == 0) {
                    
                    NSLog(@"Out queue is empty, suppose we are done");
                    [self _exitPoll];
                } else {
                    // continue with sending
                    state = TransactionStateSendingFiles;
                    [self _sendNextFileIfNeeded];
                }
                break;
                
            default:
                break;
        }
        
    } else if (TransactionStateReceivingFile == state) {
        if (frame.type == ARBinkFrameTypeData) {
            [currentRecvFile appendFrame:frame];
            if ([currentRecvFile receptionDone]) {
                // file complete
                [self.incoming addObject:currentRecvFile];
                NSLog(@"Got file! %@",currentRecvFile);
                if(self.delegate && [self.delegate respondsToSelector:@selector(pollDidGetFile:atPoller:)]) {
                    [self.delegate pollDidGetFile:currentRecvFile atPoller:self];
                }
                
                // Acknowledge we have the file
                [socket writeCommandFrame:M_GOT withString:currentRecvFile.stringRepresentation];
                currentRecvFile = nil;
                state = TransactionStateAuthed;
            }
        } else {
            // wtf
            NSLog(@"Unexpected frame in File sequence!");
            BinkLogFrame(frame);
            if (self.delegate && [self.delegate respondsToSelector:@selector(pollDidFail:withReason:)]) {
                [self.delegate pollDidFail:self withReason:PollErrorProtocolError];
            }
        }
    } else if (TransactionStateSendingAFile == state || TransactionStateSendingFiles == state) {
        switch (frame.command) {
            case M_GOT:
            case M_SKIP: // TODO!
                state = TransactionStateSendingFiles;
                if (self.delegate && [self.delegate respondsToSelector:@selector(pollDidSendFile:atPoller:)]) {
                    [self.delegate pollDidSendFile:currentSendFile atPoller:self];
                }
                [self.outgoing removeObject:currentSendFile];
                currentSendFile = nil;
                [self _sendNextFileIfNeeded];
                
                break;
            default:
                break;
        }
    }
    
}
- (void) _exitPoll {
    [socket disconnect];
    if (self.delegate && [self.delegate respondsToSelector:@selector(pollDidComplete:)]) {
        [self.delegate pollDidComplete:self];
    }
}
- (void) _sendNextFileIfNeeded {
    if (TransactionStateSendingFiles != state)
        return;
    
    if (self.outgoing.count == 0) {
        [socket writeCommandFrame:M_EOB]; // no more to send
        // we assume that all sending takes place at the end of session
        // so it would be safe to say the poll is complete
        [self _exitPoll];
        return;
    }
    
    currentSendFile = self.outgoing[0];
    currentSendPos = 0;
    
    // tell the server we are putting a file
    [socket writeCommandFrame:M_FILE withString:[currentSendFile.stringRepresentation stringByAppendingString:@" 0"]];
    state = TransactionStateSendingAFile;
    [self performSelectorInBackground:@selector(_sendFileLoop) withObject:nil];
}
- (void) _sendFileLoop {
    for(currentSendPos = 0; currentSendPos < currentSendFile.targetSize; currentSendPos+=32767) {
        if (state != TransactionStateSendingAFile) {
            break;
        }
        NSData *curFrameData = [currentSendFile.content subdataWithRange:NSMakeRange(currentSendPos, MIN(currentSendFile.targetSize,32767))];
        [socket writeDataFrameWithData:curFrameData];
    }
}
- (void) didConnectBinkpHost: (NSString*)host port:(uint16_t)port {
    NSLog(@"BINK CONNECTED %@:%hu",host,port);// return;
    
}
- (void) didGetBinkpError:(NSError*)error {
    NSLog(@"BINK ERR: %@",error);
    if (self.delegate && [self.delegate respondsToSelector:@selector(pollDidFail:dueToTransactionError::)]) {
        [self.delegate pollDidFail:self dueToTransactionError:error];
    }
}
- (void) poll {
    [socket connectToHost:self.point.host port:self.point.port];
}
@end
