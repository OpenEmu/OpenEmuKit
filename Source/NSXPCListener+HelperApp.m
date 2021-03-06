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

#import "NSXPCListener+HelperApp.h"
#import <OpenEmuKit/OpenEmuKit-Swift.h>
#import "OELogging.h"

extern NSString *kHelperIdentifierArgumentPrefix;

@implementation NSXPCListener (HelperApp)

+ (NSString *)helperIdentifierFromArguments
{
    for(NSString *argument in NSProcessInfo.processInfo.arguments)
        if([argument hasPrefix:kHelperIdentifierArgumentPrefix])
            return [argument substringFromIndex:kHelperIdentifierArgumentPrefix.length];

    return nil;
}

+ (nullable instancetype)helperListenerWithServiceName:(NSString *)name error:(NSError **)error
{
    NSString *identifier = self.helperIdentifierFromArguments;
    
    os_log_info(OE_LOG_HELPER, "Registering helper listener endpoint with broker. { id = %{public}@ }", identifier);
    
    __auto_type cn = [[NSXPCConnection alloc] initWithServiceName:name];
    [cn setInvalidationHandler:^{
        os_log_error(OE_LOG_HELPER, "Broker connection was unexpectedely invalidated.");
    }];
    
    cn.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OEXPCMatchMaking)];
    [cn resume];
    
    id<OEXPCMatchMaking> mm = [cn remoteObjectProxyWithErrorHandler:^(NSError * _Nonnull error) {
        os_log_error(OE_LOG_HELPER, "Error waiting for reply from OEXPCMatchMaking. { error = %{public}@ }", error);
    }];
    
    if (mm == nil) {
        os_log_error(OE_LOG_HELPER, "Unexpected nil for OEXPCMatchMaking proxy.");
        return nil;
    }
    
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    __auto_type listener = [NSXPCListener anonymousListener];
    [mm registerListenerEndpoint:listener.endpoint forIdentifier:identifier completionHandler:^{
        os_log_info(OE_LOG_HELPER, "Successfully connected helper to host. { id = '%{public}@' }", identifier);
        dispatch_semaphore_signal(sem);
    }];

#ifdef DEBUG_PRINT
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
#else
    dispatch_time_t waitTime = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 2);
    if (dispatch_semaphore_wait(sem, waitTime) != 0)
    {
        // mediation of connection between host and helper via broker timed out
        os_log_error(OE_LOG_HELPER, "Timeout waiting for host connection.");
        [listener invalidate];
        listener = nil;
    }
#endif
    
    [cn setInvalidationHandler:nil];
    [cn invalidate];
    
    return listener;
}

@end
