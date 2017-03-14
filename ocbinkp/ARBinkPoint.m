//
//  ARBinkPoint.m
//  ocbinkp
//
//  Created by Akasaka Ryuunosuke on 26/12/16.
//  Copyright (c) 2016 Akasaka Ryuunosuke. All rights reserved.
//

#import "ARBinkPoint.h"

@implementation ARBinkPoint
+ (ARBinkPoint*) pointWithHost:(NSString*)host andPort:(uint16_t)port atAddress:(NSString*)address location:(NSString*)location sysop:(NSString*)sysop withPassword:(NSString*)password {
    ARBinkPoint *point = [ARBinkPoint new];
    if (point) {
        point.host = host;
        point.port = port;
        point.address = address;
        point.location = location;
        point.sysop = sysop;
        point.password = password;
    }
    return point;
}
@end
