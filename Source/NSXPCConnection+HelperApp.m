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

#import "NSXPCConnection+HelperApp.h"
#import <OpenEmuKit/OpenEmuKit-Swift.h>
#import <objc/runtime.h>
#import "OELogging.h"

NSString * const OEXPCErrorDomain          = @"org.openemu.openemukit.xpc";
NSString *kHelperIdentifierArgumentPrefix = @"--org.openemu.broker.id=";
int xpc_task_key = 0;

@implementation NSXPCConnection(HelperApp)

+ (nullable instancetype)connectionWithServiceName:(NSString *)name executableURL:(NSURL *)url error:(NSError **)error
{
    NSString *identifier = NSUUID.UUID.UUIDString;
    
    /// 1. Launch Helper App
    /// This results in the helper app establishing a connection to the broker and registering its
    /// `identifier` 
    NSTask *task = [NSTask new];
    task.executableURL = url;
    task.arguments = @[[@[kHelperIdentifierArgumentPrefix, identifier] componentsJoinedByString:@""]];
    [task setTerminationHandler:^(NSTask * task) {
        os_log_error(OE_LOG_HELPER, "Helper terminated unexpectedly. { id = %{public}@, reason = %ld, exit = %d }", identifier, task.terminationReason, task.terminationStatus);
    }];
    task.standardError = NSFileHandle.fileHandleWithStandardError;
    task.standardOutput = NSFileHandle.fileHandleWithStandardOutput;
    @try {
        [task launch];
    } @catch (NSException *ex) {
        if (error != nil) {
            *error = [NSError errorWithDomain:OEXPCErrorDomain code:OEXPCErrorHelperAppLaunch userInfo:@{
                NSLocalizedDescriptionKey: NSLocalizedString(@"Failed to launch helper app" , ""),
                NSLocalizedFailureReasonErrorKey: ex.reason ?: @"???",
            }];
        }
        return nil;
    }
    
    __block NSError * err = nil;
    
    /// 2. Launch a connection to the broker
    @try {
        __auto_type cn = [[NSXPCConnection alloc] initWithServiceName:name];
        [cn setInvalidationHandler:^{
            os_log_error(OE_LOG_HELPER, "Broker connection was unexpectedely invalidated.");
        }];
        
        cn.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OEXPCMatchMaking)];
        [cn resume];
        
        id<OEXPCMatchMaking> mm = [cn remoteObjectProxyWithErrorHandler:^(NSError * _Nonnull error) {
            os_log_error(OE_LOG_HELPER, "Error waiting for reply from OEXPCMatchMaking. { error = %{public}@ }", error);
        }];
        
        if (mm == nil)
        {
            os_log_error(OE_LOG_HELPER, "Unexpected nil for OEXPCMatchMaking proxy.");
            err = [NSError errorWithDomain:OEXPCErrorDomain code:OEXPCErrorBrokerProxy userInfo:@{
                NSLocalizedDescriptionKey: NSLocalizedString(@"Failed to launch helper app" , ""),
                NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"OEXPCMatchMaking proxy was nil", ""),
            }];
            return nil;
        }
        
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        __block NSXPCListenerEndpoint *endpoint = nil;
        [mm retrieveListenerEndpointForIdentifier:identifier completionHandler:^(NSXPCListenerEndpoint *ep) {
            endpoint = ep;
            dispatch_semaphore_signal(sem);
        }];

#ifdef DEBUG_PRINT
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
#else
        dispatch_time_t waitTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(NSEC_PER_SEC * 2));
        if (dispatch_semaphore_wait(sem, waitTime) != 0)
        {
            // mediation of connection between host and helper via broker timed out
            os_log_error(OE_LOG_HELPER, "Timeout waiting for listener endpoint from broker.");
            
            if (err == nil)
            {
                err = [NSError errorWithDomain:OEXPCErrorDomain code:OEXPCErrorBrokerConnectionTimeout userInfo:@{
                    NSLocalizedDescriptionKey: NSLocalizedString(@"Timeout waiting for connection from helper app" , ""),
                }];
            }
        }
#endif
        
        [cn setInvalidationHandler:nil];
        [cn invalidate];
        
        if (endpoint == nil)
        {
            return nil;
        }
        
        if (!task.isRunning)
        {
            return nil;
        }
        
        NSXPCConnection *newCn = [[NSXPCConnection alloc] initWithListenerEndpoint:endpoint];
        
        __weak __typeof(newCn) weakCn = newCn;
        [task setTerminationHandler:^(NSTask *task) {
            os_log_debug(OE_LOG_HELPER, "Helper terminated. { id = %{public}@, exit = %d }.", identifier, task.terminationStatus);
            __strong __typeof(weakCn) strongCn = weakCn;
            [strongCn invalidate];
        }];
        
        objc_setAssociatedObject(newCn, &xpc_task_key, task, OBJC_ASSOCIATION_RETAIN);
        task = nil;
        
        return newCn;
    } @finally {
        
        // cleanup when broker connection fails
        if (task)
        {
            os_log_error(OE_LOG_HELPER, "Terminating helper; failed to complete handshake. { id = %{public}@ }", identifier);
            [task setTerminationHandler:nil];
            [task terminate];
        }
        
        // return error
        if (err != nil && error != nil)
        {
            *error = err;
        }
    }
}

@end
