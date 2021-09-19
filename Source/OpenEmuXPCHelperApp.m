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
#import "OpenEmuXPCHelperApp.h"
#import <OpenEmuSystem/OpenEmuSystem.h>
#import "NSXPCListener+HelperApp.h"
#import "OEGameStartupInfo.h"
#import "OELogging.h"

@interface OpenEmuXPCHelperApp () <NSXPCListenerDelegate, OEXPCGameCoreHelper>
{
    NSXPCListener *_mainListener;
    NSXPCConnection *_gameCoreConnection;
}

@end

@implementation OpenEmuXPCHelperApp

- (NSDictionary<NSString *, NSString *> *)infoDictionary {
    id obj = [NSBundle.mainBundle objectForInfoDictionaryKey:@"OpenEmuKit"];
    if ([obj isKindOfClass:NSDictionary.class]) {
        return obj;
    }
    return nil;
}

- (NSString *)serviceName
{
    return [self.infoDictionary objectForKey:@"XPCBrokerServiceName"];
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

- (void)terminate
{
    os_log_debug(OE_LOG_HELPER, "Terminating helper");
    CFRunLoopStop(CFRunLoopGetMain());
}

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
{
    if(listener == _mainListener)
    {
        if(_gameCoreConnection != nil)
            return NO;

        NSXPCInterface *intf = [NSXPCInterface interfaceWithProtocol:@protocol(OEXPCGameCoreHelper)];
        
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
            os_log_debug(OE_LOG_HELPER, "Connection was invalidated; exiting.");
            _Exit(EXIT_SUCCESS);
        }];
        
        [_gameCoreConnection setInterruptionHandler:^{
            os_log_debug(OE_LOG_HELPER, "Connection was interrupted; exiting.");
            _Exit(EXIT_SUCCESS);
        }];

        [_gameCoreConnection resume];

        self.gameCoreOwner = [_gameCoreConnection remoteObjectProxyWithErrorHandler:^(NSError *error) {
            os_log_debug(OE_LOG_HELPER, "Error communicating with OEGameCoreOwner proxy: %{public}@", error.localizedDescription);
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

@end
