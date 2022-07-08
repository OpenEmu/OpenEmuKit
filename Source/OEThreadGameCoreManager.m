/*
 Copyright (c) 2013, OpenEmu Team

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
     * Redistributions of source code must retain the above copyright
       notice, this list of conditions and the following disclaimer.
     * Redistributions in binary form must reproduce the above copyright
       notice, this list of conditions and the following disclaimer in the
       documentation and/or other materials provided with the distribution.
     * Neither the name of the OpenEmu Team nor the
       names of its contributors may be used to endorse or promote products
       derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY OpenEmu Team ''AS IS'' AND ANY
 EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL OpenEmu Team BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "OEThreadGameCoreManager.h"
#import "OEThreadProxy.h"
#import "OECorePlugin.h"
#import "OEGameCoreManager_Internal.h"
#import "OESystemPlugin.h"
#import <OpenEmuKit/OpenEmuKit-Swift.h>

@interface OEThreadStartup: NSObject
@property (nonatomic, nullable) void(^completionHandler)(void);
@property (nonatomic, nullable) void(^errorHandler)(NSError *error);
- (instancetype)initWithCompletionHandler:(void(^)(void))completion errorHandler:(void(^)(NSError *error))error;
@end

@implementation OEThreadStartup

- (instancetype)initWithCompletionHandler:(void(^)(void))completion errorHandler:(void(^)(NSError *error))error
{
    if (self = [super init])
    {
        _completionHandler = [completion copy];
        _errorHandler      = [error copy];
    }
    return self;
}

@end


@implementation OEThreadGameCoreManager
{
    NSThread         *_helperThread;
    NSTimer          *_dummyTimer;

    OEThreadProxy    *_helperProxy;
    OpenEmuHelperApp *_helper;

    OEThreadProxy    *_gameCoreOwnerProxy;

    void(^_stopHandler)(void);
}

- (void)loadROMWithCompletionHandler:(void(^)(void))completionHandler errorHandler:(void(^)(NSError *))errorHandler
{
    OEThreadStartup *startup = [[OEThreadStartup alloc] initWithCompletionHandler:completionHandler errorHandler:errorHandler];

    _helperThread = [[NSThread alloc] initWithTarget:self selector:@selector(_executionThread:) object:startup];
    _helperThread.name = @"org.openemu.core-manager-thread";
    _helperThread.qualityOfService = NSQualityOfServiceUserInitiated;

    _helper = [[OpenEmuHelperApp alloc] init];
    _helperProxy = [OEThreadProxy threadProxyWithTarget:_helper thread:_helperThread];

    _gameCoreOwnerProxy = [OEThreadProxy threadProxyWithTarget:[self gameCoreOwner] thread:[NSThread mainThread]];

    [_helperThread start];
}

- (void)loadROMWithCompletionHandler:(OEStartupCompletionHandler)completionHandler
{
    _helperThread = [[NSThread alloc] initWithTarget:self selector:@selector(_executionThreadNew:) object:completionHandler];
    _helperThread.name = @"org.openemu.core-manager-thread";
    _helperThread.qualityOfService = NSQualityOfServiceUserInitiated;

    _helper = [[OpenEmuHelperApp alloc] init];
    _helperProxy = [OEThreadProxy threadProxyWithTarget:_helper thread:_helperThread];

    _gameCoreOwnerProxy = [OEThreadProxy threadProxyWithTarget:[self gameCoreOwner] thread:[NSThread mainThread]];

    [_helperThread start];
}

- (void)_executionThread:(OEThreadStartup *)startup
{
    @autoreleasepool
    {
        [self setGameCoreHelper:(id<OEGameCoreHelper>)_helperProxy];
        [_helper setGameCoreOwner:(id<OEGameCoreOwner>)_gameCoreOwnerProxy];

        NSError *error;
        if(![_helper loadWithStartupInfo:self.startupInfo error:&error])
        {
            if(startup.errorHandler != nil)
            {
                __block __auto_type errorHandler = startup.errorHandler;
                CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^{
                    errorHandler(error);
                });
            }
            return;
        }

        if (startup.completionHandler) {
            __block __auto_type completionHandler = startup.completionHandler;
            CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, completionHandler);
        }
        
        startup = nil;

        _dummyTimer = [NSTimer scheduledTimerWithTimeInterval:1e9 repeats:YES block:^(NSTimer * _Nonnull timer) {}];

        CFRunLoopRun();

        if(_stopHandler)
        {
            CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, _stopHandler);
            _stopHandler = nil;
        }
    }
    
    [self _notifyGameCoreDidTerminate];
}

- (void)_executionThreadNew:(OEStartupCompletionHandler)handler
{
    @autoreleasepool
    {
        [self setGameCoreHelper:(id<OEGameCoreHelper>)_helperProxy];
        [_helper setGameCoreOwner:(id<OEGameCoreOwner>)_gameCoreOwnerProxy];

        NSError *error;
        if(![_helper loadWithStartupInfo:self.startupInfo error:&error])
        {
            CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^{
                handler(error);
            });
            return;
        }

        CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^{
            handler(nil);
        });
        
        handler = nil;

        _dummyTimer = [NSTimer scheduledTimerWithTimeInterval:1e9 repeats:YES block:^(NSTimer * _Nonnull timer) {}];

        CFRunLoopRun();

        if(_stopHandler)
        {
            CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, _stopHandler);
            _stopHandler = nil;
        }
    }
    
    [self _notifyGameCoreDidTerminate];
}

- (void)_stopHelperThread:(id)object
{
    [_dummyTimer invalidate];
    _dummyTimer = nil;

    CFRunLoopStop(CFRunLoopGetCurrent());

    [self setGameCoreHelper:nil];

    _helperThread       = nil;
    _helperProxy        = nil;
    _helper             = nil;
    _gameCoreOwnerProxy = nil;
}

- (void)stop
{
    if([NSThread currentThread] == _helperThread)
        [self _stopHelperThread:nil];
    else
        [self performSelector:@selector(_stopHelperThread:) onThread:_helperThread withObject:nil waitUntilDone:NO];
}

- (void)stopEmulationWithCompletionHandler:(void (^)(void))handler
{
    _stopHandler = [handler copy];
    [[self gameCoreHelper] stopEmulationWithCompletionHandler:
     ^{
         [self stop];
     }];
}

@end
