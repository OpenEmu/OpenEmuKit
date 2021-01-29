/*
 Copyright (c) 2010, OpenEmu Team
 
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

@import OpenEmuBase;

#import "OEGameCoreManager.h"
#import "OECorePlugin.h"
#import "OEGameCoreManager_Internal.h"
#import "OESystemPlugin.h"
#import "OEGameStartupInfo.h"

NSString * const OEGameCoreErrorDomain = @"OEGameCoreErrorDomain";

@implementation OEGameCoreManager

- (instancetype)initWithStartupInfo:(OEGameStartupInfo *)startupInfo
                         corePlugin:(OECorePlugin *)plugin
                       systemPlugin:(OESystemPlugin *)systemPlugin
                      gameCoreOwner:(id<OEGameCoreOwner>)gameCoreOwner
                              queue:(dispatch_queue_t _Nullable)queue
{
    if (self = [super init])
    {
        _startupInfo    = startupInfo;
        _plugin         = plugin;
        _systemPlugin   = systemPlugin;
        _gameCoreOwner  = gameCoreOwner;
        _queue          = queue ?: dispatch_get_main_queue();
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ %p, ROM: %@, System: %@, Core: %@, Display Helper: %@>", [self class], self, _startupInfo, [_plugin bundleIdentifier], [_systemPlugin systemIdentifier], _gameCoreOwner];
}

- (void)stop
{
    [self doesNotImplementSelector:_cmd];
}

- (void)loadROMWithCompletionHandler:(void(^)(void))completionHandler errorHandler:(void(^)(NSError *))errorHandler;
{
    [self doesNotImplementSelector:_cmd];
}

- (void)setVolume:(CGFloat)value;
{
    [_gameCoreHelper setVolume:value];
}

- (void)setPauseEmulation:(BOOL)pauseEmulation;
{
    [_gameCoreHelper setPauseEmulation:pauseEmulation];
}

- (void)setAudioOutputDeviceID:(AudioDeviceID)deviceID;
{
    [_gameCoreHelper setAudioOutputDeviceID:deviceID];
}

- (void)setCheat:(NSString *)cheatCode withType:(NSString *)type enabled:(BOOL)enabled
{
    [_gameCoreHelper setCheat:cheatCode withType:type enabled:enabled];
}

- (void)setDisc:(NSUInteger)discNumber
{
    [_gameCoreHelper setDisc:discNumber];
}

- (void)insertFileAtURL:(NSURL *)url completionHandler:(void (^)(BOOL success, NSError *error))block
{
    [_gameCoreHelper insertFileAtURL:url completionHandler:
     ^(BOOL success, NSError *error)
     {
         dispatch_async(self->_queue, ^{
             block(success, error);
         });
     }];
}
- (void)changePreferenceOption:(NSString *)corePreference prefGroupID:(NSString *)prefGroupID
{
    [_gameCoreHelper changePreferenceOption:corePreference prefGroupID:prefGroupID];
}

- (void)changeDisplayWithMode:(NSString *)displayMode
{
    [_gameCoreHelper changeDisplayWithMode:displayMode];
}

- (void)setOutputBounds:(NSRect)rect
{
    [_gameCoreHelper setOutputBounds:rect];
}

- (void)setBackingScaleFactor:(CGFloat)newScaleFactor
{
    [_gameCoreHelper setBackingScaleFactor:newScaleFactor];
}

- (void)setShaderURL:(NSURL *)url parameters:(NSDictionary<NSString *, NSNumber *> *)parameters completionHandler:(void (^)(BOOL success, NSError * _Nullable error))block
{
    __block __auto_type queue = _queue;
    [_gameCoreHelper setShaderURL:url parameters:parameters completionHandler:^(BOOL success, NSError *error) {
        dispatch_async(queue, ^{
            block(success, error);
        });
    }];
}

- (void)setShaderParameterValue:(CGFloat)value forKey:(NSString *)key
{
    [_gameCoreHelper setShaderParameterValue:value forKey:key];
}

- (void)setupEmulationWithCompletionHandler:(void(^)(OEIntSize screenSize, OEIntSize aspectSize))handler;
{
    [_gameCoreHelper setupEmulationWithCompletionHandler:^(OEIntSize screenSize, OEIntSize aspectSize) {
        dispatch_async(self->_queue, ^{
            handler(screenSize, aspectSize);
        });
    }];
}

- (void)startEmulationWithCompletionHandler:(void(^)(void))handler;
{
    [_gameCoreHelper startEmulationWithCompletionHandler:
     ^{
         dispatch_async(self->_queue, ^{
             handler();
         });
     }];
}

- (void)resetEmulationWithCompletionHandler:(void(^)(void))handler;
{
    [_gameCoreHelper resetEmulationWithCompletionHandler:
     ^{
         dispatch_async(self->_queue, ^{
             handler();
         });
     }];
}

- (void)stopEmulationWithCompletionHandler:(void(^)(void))handler;
{
    [_gameCoreHelper stopEmulationWithCompletionHandler:
     ^{
         dispatch_async(self->_queue, ^{
             handler();
             [self stop];
         });
     }];
}

- (void)saveStateToFileAtPath:(NSString *)fileName completionHandler:(void (^)(BOOL success, NSError *error))block;
{
    [_gameCoreHelper saveStateToFileAtPath:fileName completionHandler:
     ^(BOOL success, NSError *error)
     {
         dispatch_async(self->_queue, ^{
             block(success, error);
         });
     }];
}

- (void)loadStateFromFileAtPath:(NSString *)fileName completionHandler:(void (^)(BOOL success, NSError *error))block;
{
    [_gameCoreHelper loadStateFromFileAtPath:fileName completionHandler:
     ^(BOOL success, NSError *error)
     {
         dispatch_async(self->_queue, ^{
             block(success, error);
         });
     }];
}

- (void)captureOutputImageWithCompletionHandler:(void (^)(NSBitmapImageRep *image))block
{
    [_gameCoreHelper captureOutputImageWithCompletionHandler:^(NSBitmapImageRep *image) {
        block(image);
    }];
}

- (void)captureSourceImageWithCompletionHandler:(void (^)(NSBitmapImageRep *image))block
{
    [_gameCoreHelper captureSourceImageWithCompletionHandler:^(NSBitmapImageRep *image) {
        block(image);
    }];
}

- (void)handleMouseEvent:(OEEvent *)event
{
    [_gameCoreHelper handleMouseEvent:event];
}

- (void)setHandleEvents:(BOOL)handleEvents
{
    [_gameCoreHelper setHandleEvents:handleEvents];
}

- (void)setHandleKeyboardEvents:(BOOL)handleKeyboardEvents
{
    [_gameCoreHelper setHandleKeyboardEvents:handleKeyboardEvents];
}

- (void)systemBindingsDidSetEvent:(OEHIDEvent *)event forBinding:(__kindof OEBindingDescription *)bindingDescription playerNumber:(NSUInteger)playerNumber
{
    [_gameCoreHelper systemBindingsDidSetEvent:event forBinding:bindingDescription playerNumber:playerNumber];
}

- (void)systemBindingsDidUnsetEvent:(OEHIDEvent *)event forBinding:(__kindof OEBindingDescription *)bindingDescription playerNumber:(NSUInteger)playerNumber
{
    [_gameCoreHelper systemBindingsDidUnsetEvent:event forBinding:bindingDescription playerNumber:playerNumber];
}

- (void)_notifyGameCoreDidTerminate
{
    __weak OEGameCoreManager *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        OEGameCoreManager *strongSelf = weakSelf;
        if (!strongSelf)
            return;
        id<OEGameCoreOwner> strongCoreOwner = strongSelf.gameCoreOwner;
        if (!strongCoreOwner)
            return;
        if ([strongCoreOwner respondsToSelector:@selector(gameCoreDidTerminate)])
            [strongCoreOwner gameCoreDidTerminate];
    });
}

@end
