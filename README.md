# ocbinkp

A collection of classes for connecting to FidoNet-Type Networks (FTNs) from Objective-C applications.

__Work in progress!__ _Wow, much software, such beta_

# Usage

```
    // Initialize your account settings
    ARBinkPoint * point = [ARBinkPoint    pointWithHost:@"127.0.0.1"
                                                andPort:24554
                                              atAddress:@"2:228/14.88@susnet"
                                               location:@"Objective C"
                                                  sysop:@"Leonid Yakubovich"
                                           withPassword:@"test"];
    
    // Create a poller
    self.mgr = [[ARBinkTransactionManager alloc] initWithPoint:point 
                                                      delegate:self];
    
    // Let's transmit a text file
    NSData *fileData = [@"Hello FTN!" dataUsingEncoding:NSUTF8StringEncoding];
    ARBinkFile *file = [ARBinkFile fileWithName:@"test.txt" 
                                     targetSize:fileData.length 
                                       unixTime:[NSDate timeIntervalSinceReferenceDate]+NSTimeIntervalSince1970 
                                        content:fileData];
    
    // Add file to the poller Outbound Queue
    [self.mgr.outgoing addObject:file];
    
    // Do a barrel poll
    [self.mgr poll];
    

```

# Delegate methods

```

    /* Event of getting a new file in the incoming queue */
    - (void) pollDidGetFile:(ARBinkFile *)file atPoller:(ARBinkTransactionManager *)poller {
        NSLog(@"!! Got file %@ !!",file.name);
        // send this file back to the server :-)
        [self.mgr.outgoing addObject:file];
    }
    
    /* Event of finishing transaction with server */
    - (void) pollDidComplete:(ARBinkTransactionManager*)poller {
        // log any files we got
        for (ARBinkFile *inFile in poller.incoming) {
            NSLog(@"========== %@ ===========",inFile.name);
            NSString*s = [[NSString alloc]initWithData:inFile.content encoding:NSUTF8StringEncoding];
            NSLog(@"%@",s);
        }
    }

```