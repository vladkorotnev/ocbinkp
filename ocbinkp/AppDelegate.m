//
//  AppDelegate.m
//  ocbinkp
//
//  Created by Akasaka Ryuunosuke on 26/12/16.
//  Copyright (c) 2016 Akasaka Ryuunosuke. All rights reserved.
//

#import "AppDelegate.h"


#define BINK_PORT 24554

@interface AppDelegate ()
@property (weak) IBOutlet NSWindow *window;
@property (strong) ARBinkTransactionManager *mgr;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    // create account
    ARBinkPoint * point = [ARBinkPoint pointWithHost:@"127.0.0.1" andPort:BINK_PORT atAddress:@"2:228/14.88@susnet" location:@"Objective C" sysop:@"Leonid Yakubovich" withPassword:@"test"];
    
    // create poller
    self.mgr = [[ARBinkTransactionManager alloc]initWithPoint:point delegate:self];
    
    // example file to transmit
    NSData *fileData = [@"Hello FTN!" dataUsingEncoding:NSUTF8StringEncoding];
    ARBinkFile *file = [ARBinkFile fileWithName:@"test.txt" targetSize:fileData.length unixTime:[NSDate timeIntervalSinceReferenceDate]+NSTimeIntervalSince1970 content:fileData];
    
    // add file to poller
    [self.mgr.outgoing addObject:file];
    
    // do a barrel poll
    [self.mgr poll];
}
- (void) pollDidSendFile:(ARBinkFile *)file atPoller:(ARBinkTransactionManager *)poller {
    NSLog(@"!! Sent file %@ !!",file.name);
}
- (void) pollDidGetFile:(ARBinkFile *)file atPoller:(ARBinkTransactionManager *)poller {
    NSLog(@"!! Got file %@ !!",file.name);
    // send this file back to the server :-)
    [self.mgr.outgoing addObject:file];
}
- (void) pollDidComplete:(ARBinkTransactionManager*)poller {
    // log any files we got
    for (ARBinkFile *inFile in poller.incoming) {
        NSLog(@"========== %@ ===========",inFile.name);
        NSString*s = [[NSString alloc]initWithData:inFile.content encoding:NSUTF8StringEncoding];
        NSLog(@"%@",s);
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
