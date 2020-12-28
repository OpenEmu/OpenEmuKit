// Copyright (c) 2020, OpenEmu Team
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//     * Neither the name of the OpenEmu Team nor the
//       names of its contributors may be used to endorse or promote products
//       derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY OpenEmu Team ''AS IS'' AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL OpenEmu Team BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "OEXPCGameCoreHelper.h"
#import "OpenEmuXPCHelperAppBase.h"
#import <OpenEmuSystem/OpenEmuSystem.h>
#import "OEShaderParamValue.h"
#import "NSXPCListener+HelperApp.h"
#import "OEGameStartupInfo.h"
#import "OELogging.h"

@interface OpenEmuXPCHelperAppBase () <NSXPCListenerDelegate, OEXPCGameCoreHelper>
{
    NSXPCListener *_mainListener;
    NSXPCConnection *_gameCoreConnection;
    NSRunningApplication *_parentApplication; // the process id of the parent app (Open Emu)
    // poll parent ID, KVO does not seem to be working with NSRunningApplication
    NSTimer              *_pollingTimer;
}

@end

@implementation OpenEmuXPCHelperAppBase

- (NSString *)serviceName
{
    [self doesNotImplementSelector:_cmd];
    return nil;
}

- (void)launchApplication
{
    NSError *err;
    _mainListener = [NSXPCListener helperListenerWithServiceName:self.serviceName error:&err];
    if (_mainListener == nil)
    {
        if (err != nil)
        {
            os_log_error(OE_LOG_HELPER, "Unable to retrieve helper listener. { error = %{public}@ }", err);
        }
        else
        {
            os_log_error(OE_LOG_HELPER, "Unable to retrieve helper listener.");
        }
        _Exit(EXIT_FAILURE);
    }
    
    [_mainListener setDelegate:self];
    [_mainListener resume];
    
    [self setup];
    
    CFRunLoopRun();
    _Exit(EXIT_SUCCESS);
}

- (void)setup
{
    _parentApplication = [NSRunningApplication runningApplicationWithProcessIdentifier:getppid()];
    [_parentApplication addObserver:self forKeyPath:@"terminated" options:NSKeyValueObservingOptionNew context:nil];
    if(_parentApplication != nil)
    {
        os_log_debug(OE_LOG_HELPER, "Parent application is %{public}@", [_parentApplication localizedName]);
        [self setupProcessPollingTimer];
    }
    
    OEDeviceManager *dm = [OEDeviceManager sharedDeviceManager];
    if (@available(macOS 10.15, *))
    {
        if (dm.accessType != OEDeviceAccessTypeGranted)
        {
            [dm requestAccess];
            os_log(OE_LOG_HELPER, "Input monitoring failed: Access Denied");
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context
{
    [self terminate];
}

- (void)setupProcessPollingTimer
{
    _pollingTimer = [NSTimer scheduledTimerWithTimeInterval:5
                                                     target:self
                                                   selector:@selector(pollParentProcess)
                                                   userInfo:nil
                                                    repeats:YES];
    _pollingTimer.tolerance = 1;
}

- (void)pollParentProcess
{
    if([_parentApplication isTerminated])
    {
        [self terminate];
    }
}

- (void)terminate
{
    os_log_debug(OE_LOG_HELPER, "Terminating helper");
    
    [_pollingTimer invalidate];
    CFRunLoopStop(CFRunLoopGetMain());
}

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
{
    if(listener == _mainListener)
    {
        if(_gameCoreConnection != nil)
            return NO;

        NSXPCInterface *intf = [NSXPCInterface interfaceWithProtocol:@protocol(OEXPCGameCoreHelper)];
        NSSet *set = [NSSet setWithObjects:OEShaderParamValue.class, NSArray.class, OEShaderParamGroupValue.class, nil];
        // shader parameters
        [intf setClasses:set forSelector:@selector(shaderParamGroupsWithCompletionHandler:) argumentIndex:0 ofReply:YES];
        
        // load ROM
        [intf setClasses:[NSSet setWithObject:OEGameStartupInfo.class]
             forSelector:@selector(loadWithStartupInfo:completionHandler:)
           argumentIndex:0
                 ofReply:NO];
        _gameCoreConnection = newConnection;
        [_gameCoreConnection setExportedInterface:intf];
        [_gameCoreConnection setExportedObject:self];
        [_gameCoreConnection setRemoteObjectInterface:[NSXPCInterface interfaceWithProtocol:@protocol(OEGameCoreOwner)]];
        [_gameCoreConnection setInvalidationHandler:^{
            _Exit(EXIT_SUCCESS);
        }];
        
        [_gameCoreConnection setInterruptionHandler:^{
            _Exit(EXIT_SUCCESS);
        }];

        [_gameCoreConnection resume];

        self.gameCoreOwner = [_gameCoreConnection remoteObjectProxyWithErrorHandler:^(NSError *error) {
            [self stopEmulationWithCompletionHandler:^{}];
        }];

        return YES;
    }

    return NO;
}

// NOTE: OEGameStartupInfo will evenually be replaced with a more generic container
- (void)loadWithStartupInfo:(OEGameStartupInfo *)info completionHandler:(void(^)(NSError *error))completionHandler
{
    NSError *error;
    [self loadWithStartupInfo:info error:&error];
    completionHandler(error);
}

- (void)stopEmulationWithCompletionHandler:(void(^)(void))handler
{
    [super stopEmulationWithCompletionHandler:^{
        handler();
    }];
}

@end
