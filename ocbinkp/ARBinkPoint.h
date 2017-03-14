//
//  ARBinkPoint.h
//  ocbinkp
//
//  Created by Akasaka Ryuunosuke on 26/12/16.
//  Copyright (c) 2016 Akasaka Ryuunosuke. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ARBinkPoint : NSObject

@property (nonatomic,retain) NSString* address;
@property (nonatomic,retain) NSString* sysop;
@property (nonatomic,retain) NSString* host;
@property (nonatomic,retain) NSString* password;
@property (nonatomic,retain) NSString* location;
@property uint16_t port;

+ (ARBinkPoint*) pointWithHost:(NSString*)host andPort:(uint16_t)port atAddress:(NSString*)address location:(NSString*)location sysop:(NSString*)sysop withPassword:(NSString*)password;

@end
