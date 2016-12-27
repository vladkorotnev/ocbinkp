//
//  ARBinkFile.h
//  ocbinkp
//
//  Created by Akasaka Ryuunosuke on 26/12/16.
//  Copyright (c) 2016 Akasaka Ryuunosuke. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARBinkStructs.h"

@interface ARBinkFile : NSObject
@property (nonatomic,retain) NSMutableData* content;
@property (nonatomic,retain) NSString* name;
@property unsigned long long targetSize;
@property unsigned long long unixTime;

- (ARBinkFile*) initWithName:(NSString*)name targetSize:(unsigned long long)size unixTime:(unsigned long long)timestamp;
- (ARBinkFile*) initWithName:(NSString*)name targetSize:(unsigned long long)size unixTime:(unsigned long long)timestamp content:(NSData*)content;
+ (ARBinkFile*) fileWithName:(NSString*)name targetSize:(unsigned long long)size unixTime:(unsigned long long)timestamp;
+ (ARBinkFile*) fileWithName:(NSString*)name targetSize:(unsigned long long)size unixTime:(unsigned long long)timestamp content:(NSData*)content;

- (void) appendFrame:(ARBinkFrame)frame;
- (BOOL) receptionDone;
- (NSString*)stringRepresentation;
@end
