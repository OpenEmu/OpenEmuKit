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

#import "OEXPCGameCoreManagerBase.h"
#import "OEXPCGameCoreHelper.h"
#import "OECorePlugin.h"
#import "OEGameCoreManager_Internal.h"
#import "OESystemPlugin.h"
#import "OEThreadProxy.h"
#import "OEShaderParamValue.h"
#import "NSXPCConnection+HelperApp.h"
#import "OEGameStartupInfo.h"
#import "OELogging.h"

@interface OEXPCGameCoreManagerBase ()
{
    NSXPCConnection *_helperConnection;
    OEThreadProxy   *_gameCoreOwnerProxy;
}

@property(nonatomic, strong) id<OEXPCGameCoreHelper> gameCoreHelper;
@end

@implementation OEXPCGameCoreManagerBase
@dynamic gameCoreHelper;

- (NSString *)serviceName
{
    [self doesNotImplementSelector:_cmd];
    return nil;
}

- (NSURL *)executableURL
{
    [self doesNotImplementSelector:_cmd];
    return nil;
}

- (void)loadROMWithCompletionHandler:(void(^)(void))completionHandler errorHandler:(void(^)(NSError *))errorHandler;
{
    NSError *error = nil;
    _helperConnection = [NSXPCConnection connectionWithServiceName:self.serviceName executableURL:self.executableURL error:&error];
    if(_helperConnection == nil)
    {
        os_log_error(OE_LOG_HELPER, "No listener endpoint for identifier: %@", self.executableURL);

        if (error == nil)
        {
            error = [NSError errorWithDomain:OEGameCoreErrorDomain
                                        code:OEGameCoreCouldNotLoadROMError
                                    userInfo:nil];
        }
        
        dispatch_async(self.queue, ^{
            errorHandler(error);
        });
        
        // There's no listener endpoint, so don't bother trying to create an NSXPCConnection.
        // Returning now since calling initWithListenerEndpoint: and passing it nil results in a memory leak.
        // Also, there's no point in trying to get the gameCoreHelper if there's no _helperConnection.
        return;
    }
    
    __weak OEXPCGameCoreManagerBase *weakSelf = self;
    [_helperConnection setInvalidationHandler:^{
        OEXPCGameCoreManagerBase *strongSelf = weakSelf;
        if (strongSelf)
            [strongSelf _notifyGameCoreDidTerminate];
    }];
    
    _gameCoreOwnerProxy = [OEThreadProxy threadProxyWithTarget:[self gameCoreOwner] thread:[NSThread mainThread]];
    
    [_helperConnection setExportedInterface:[NSXPCInterface interfaceWithProtocol:@protocol(OEGameCoreOwner)]];
    [_helperConnection setExportedObject:_gameCoreOwnerProxy];

    NSXPCInterface *intf = [NSXPCInterface interfaceWithProtocol:@protocol(OEXPCGameCoreHelper)];
    
    // shader parameters
    NSSet *set = [NSSet setWithObjects:OEShaderParamValue.class, NSArray.class, OEShaderParamGroupValue.class, nil];
    [intf setClasses:set forSelector:@selector(shaderParamGroupsWithCompletionHandler:) argumentIndex:0 ofReply:YES];
    
    // startup
    [intf setClasses:[NSSet setWithObject:OEGameStartupInfo.class]
         forSelector:@selector(loadWithStartupInfo:completionHandler:)
       argumentIndex:0
             ofReply:NO];
   
    [_helperConnection setRemoteObjectInterface:intf];
    [_helperConnection resume];

    __block void *gameCoreHelperPointer;
    id<OEXPCGameCoreHelper> gameCoreHelper =
    [_helperConnection remoteObjectProxyWithErrorHandler:
     ^(NSError *error)
     {
        os_log_error(OE_LOG_HELPER, "Helper Connection (%p) failed with error: %{public}@",
                     gameCoreHelperPointer, error);
        
        dispatch_async(self.queue, ^{
            errorHandler(error);
            [self stop];
        });
    }];

    gameCoreHelperPointer = (__bridge void *)gameCoreHelper;

    if(gameCoreHelper == nil) return;

    [gameCoreHelper loadWithStartupInfo:self.startupInfo completionHandler:
     ^(NSError *error)
     {
         if(error != nil)
         {
             dispatch_async(self.queue, ^{
                 errorHandler(error);
                 [self stop];
             });

             // There's no listener endpoint, so don't bother trying to create an NSXPCConnection.
             // Returning now since calling initWithListenerEndpoint: and passing it nil results in a memory leak.
             return;
         }

         [self setGameCoreHelper:gameCoreHelper];
         dispatch_async(self.queue, ^{
             completionHandler();
         });
     }];
}

- (void)stop{
    [self setGameCoreHelper:nil];
    _gameCoreOwnerProxy = nil;
    [_helperConnection invalidate];
}

@end
