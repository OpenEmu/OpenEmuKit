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

NSString *kHelperIdentifierArgumentPrefix = @"--org.openemu.broker.id=";
int xpc_task_key = 0;

@implementation NSXPCConnection(HelperApp)

+ (nullable instancetype)connectionWithServiceName:(NSString *)name executableURL:(NSURL *)url error:(NSError **)error
{
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    NSString *identifier = NSUUID.UUID.UUIDString;
    
    NSTask *task = [NSTask new];
    task.executableURL = url;
    task.arguments = @[[@[kHelperIdentifierArgumentPrefix, identifier] componentsJoinedByString:@""]];
    [task setTerminationHandler:^(NSTask * _){
        NSLog(@"Helper task %@ terminated unexpectedly", identifier);
        dispatch_semaphore_signal(sem);
    }];
    task.standardError = NSFileHandle.fileHandleWithStandardError;
    task.standardOutput = NSFileHandle.fileHandleWithStandardOutput;
    @try {
        [task launch];
    } @catch (NSException *ex) {
        if (error != nil) {
            *error = [NSError errorWithDomain:ex.name code:0 userInfo:@{
                NSLocalizedFailureReasonErrorKey: ex.reason ?: @"???",
            }];
        }
        return nil;
    }
    
    __auto_type cn = [[NSXPCConnection alloc] initWithServiceName:name];
    cn.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OEXPCMatchMaking)];
    [cn resume];
    
    __block NSError *proxyErr = nil;
    id<OEXPCMatchMaking> mm = [cn remoteObjectProxyWithErrorHandler:^(NSError * _Nonnull error) {
        proxyErr = error;
    }];
    
    if (mm == nil || proxyErr != nil) {
        if (error != nil && proxyErr != nil)
        {
            *error = proxyErr;
        }
        return nil;
    }
    
    __block NSXPCListenerEndpoint *endpoint = nil;
    [mm retrieveListenerEndpointForIdentifier:identifier completionHandler:^(NSXPCListenerEndpoint *ep) {
        endpoint = ep;
        dispatch_semaphore_signal(sem);
    }];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    [cn invalidate];
    
    if (endpoint == nil || !task.isRunning)
    {
        return nil;
    }
    
    NSXPCConnection *newCn = [[NSXPCConnection alloc] initWithListenerEndpoint:endpoint];

    __weak __typeof(newCn) weakCn = newCn;
    [task setTerminationHandler:^(NSTask *task) {
        NSLog(@"Helper %@ terminating", identifier);
        __strong __typeof(weakCn) strongCn = weakCn;
        [strongCn invalidate];
    }];
    
    objc_setAssociatedObject(newCn, &xpc_task_key, task, OBJC_ASSOCIATION_RETAIN);
    
    return newCn;
}

@end
