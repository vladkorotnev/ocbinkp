//
//  ARBinkFile.m
//  ocbinkp
//
//  Created by Akasaka Ryuunosuke on 26/12/16.
//  Copyright (c) 2016 Akasaka Ryuunosuke. All rights reserved.
//

#import "ARBinkFile.h"

@implementation ARBinkFile
+ (ARBinkFile*) fileWithName:(NSString*)name targetSize:(unsigned long long)size unixTime:(unsigned long long)timestamp{
    return [[ARBinkFile alloc]initWithName:name targetSize:size unixTime:timestamp];
}

- (ARBinkFile*) initWithName:(NSString *)name targetSize:(unsigned long long)size  unixTime:(unsigned long long)timestamp{
    self = [super init];
    if (self) {
        self.name = name;
        self.content = [NSMutableData new];
        self.targetSize = size;
        self.unixTime = timestamp;
    }
    return self;
}

- (ARBinkFile*) initWithName:(NSString*)name targetSize:(unsigned long long)size unixTime:(unsigned long long)timestamp content:(NSData*)content {
    self = [self initWithName:name targetSize:size unixTime:timestamp];
    if (self) {
        self.content = content.mutableCopy;
    }
    return self;
}
+ (ARBinkFile*) fileWithName:(NSString*)name targetSize:(unsigned long long)size unixTime:(unsigned long long)timestamp content:(NSData*)content {
    return [[ARBinkFile alloc]initWithName:name targetSize:size unixTime:timestamp content:content];
}
- (BOOL) receptionDone {
    return self.content.length == self.targetSize;
}

- (void) appendFrame:(ARBinkFrame)frame {
    [self.content appendBytes:&frame.data length:frame.datalen];
}

- (NSString*)stringRepresentation {
    return [NSString stringWithFormat:@"%@ %llu %llu",self.name,self.targetSize,self.unixTime];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"<ARBinkFile: %@>",self.stringRepresentation];
}
@end
