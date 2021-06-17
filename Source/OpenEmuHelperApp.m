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

@import OpenEmuShaders;

#import "OpenEmuHelperApp.h"

// Open Emu
#import "OEGameAudio.h"
#import "OECorePlugin.h"
#import "OEGameRenderer.h"
#import "OEOpenGL2GameRenderer.h"
#import "OEOpenGL3GameRenderer.h"
#import "OEMTLGameRenderer.h"
#import "OESystemPlugin.h"
#import "OEGameHelperMetalLayer.h"
#import <OpenEmuSystem/OpenEmuSystem.h>
#import "OECoreVideoTexture.h"
#import "OEShaderParamValue.h"
#import "OEGameStartupInfo.h"
#import <OpenEmuKit/OpenEmuKit-Swift.h>
#import "OELogging.h"

#import "OpenEmuKitPrivate/OpenEmuKitPrivate.h"

/// Only send 1 frame at once to the GPU.
/// Since we aren't synced to the display, even one more
/// is enough to block in nextDrawable for more than a frame
/// and cause audio skipping.
/// TODO(sgc): implement triple buffering
#define MAX_INFLIGHT 1

@interface OpenEmuHelperApp () <OEGameCoreDelegate, OEGlobalEventsHandler>
@property (nonatomic) BOOL loadedRom;
@property(readonly) OEIntSize screenSize;
@property(readonly) OEIntSize aspectSize;

@end

@implementation OpenEmuHelperApp
{
    OEIntRect _previousScreenRect;
    OEIntSize _previousAspectSize;
    
    // Video
    id <OEGameRenderer>   _gameRenderer;
    OECoreVideoTexture    *_surface;
    
    // OE stuff
    OEGameCoreController *_gameController;
    OESystemController   *_systemController;
    OESystemResponder    *_systemResponder;
    OEGameAudio          *_gameAudio;
    
    // initial shader and parameters
    NSURL                                   *_shader;
    NSDictionary<NSString *, NSNumber *>    *_shaderParameters;
    
    NSMutableDictionary<OEDeviceHandlerPlaceholder *, NSMutableArray<void(^)(void)> *> *_pendingDeviceHandlerBindings;
    
    CAContext             *_gameVideoCAContext;
    
    OEGameHelperMetalLayer  *_videoLayer;
    OEFilterChain           *_filterChain;
    dispatch_semaphore_t    _inflightSemaphore;
    id<MTLCaptureScope>     _scope;
    id<MTLDevice>           _device;
    id<MTLCommandQueue>     _commandQueue;
    MTLClearColor           _clearColor;
    NSUInteger              _skippedFrames;
    
    id   _unhandledEventsMonitor;
    BOOL _hasStartedAudio;
}

/// Log messages related to display.
static os_log_t LOG_DISPLAY;

+ (void)initialize
{
    if (self != OpenEmuHelperApp.class) return;
    
    os_log_debug(OE_LOG_DEFAULT, "Initializing %{public}@ loggers", NSStringFromClass(self));
    
    LOG_DISPLAY = os_log_create(OE_LOG_NAME, "display");
}

- (instancetype)init
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    _pendingDeviceHandlerBindings = [NSMutableDictionary dictionary];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_deviceHandlerPlaceholderDidResolveNotification:) name:OEDeviceHandlerPlaceholderOriginalDeviceDidBecomeAvailableNotification object:nil];
    
    return self;
}

#pragma mark -

- (void)launchApplication
{
    
}

- (void)OE_loadPlugins
{
    
}

- (void)setupGameCoreAudioAndVideo
{
    // 1. Audio
    _gameAudio = [[OEGameAudio alloc] initWithCore:_gameCore];
    [_gameAudio setVolume:1.0];
    
    // 2. Video
    _inflightSemaphore = dispatch_semaphore_create(MAX_INFLIGHT);
    _device            = MTLCreateSystemDefaultDevice();
    _scope             = [[MTLCaptureManager sharedCaptureManager] newCaptureScopeWithDevice:_device];
    _commandQueue      = [_device newCommandQueue];
    _clearColor        = MTLClearColorMake(0, 0, 0, 1);
    _filterChain       = [[OEFilterChain alloc] initWithDevice:_device];
    
    [self updateScreenSize];
    [self updateGameRenderer];
    [self setupCVBuffer];
    [self setupRemoteLayer];
    if (_shader) {
        [self setShaderURL:_shader parameters:_shaderParameters error:nil];
        _shader = nil;
        _shaderParameters = nil;
    }
}

#pragma mark - Core Video and Generic Video

- (void)updateScreenSize
{
    _previousAspectSize = _gameCore.aspectSize;
    _previousScreenRect = _gameCore.screenRect;
}

- (void)updateGameRenderer
{
    OEGameCoreRendering rendering = _gameCore.gameCoreRendering;
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    _videoLayer = [OEGameHelperMetalLayer new];
    _videoLayer.device = _device;
    _videoLayer.opaque = YES;
    _videoLayer.framebufferOnly = YES;
    _videoLayer.displaySyncEnabled = YES;

    switch (rendering) {
        case OEGameCoreRendering2DVideo:
            _gameRenderer = [[OEMTLGameRenderer alloc] initWithFilterChain:_filterChain];
            break;
            
        case OEGameCoreRenderingOpenGL2Video:
        case OEGameCoreRenderingOpenGL3Video:
            _surface = [[OECoreVideoTexture alloc] initMetalPixelFormat:MTLPixelFormatBGRA8Unorm];
            _surface.metalDevice = _device;
            
            if (rendering == OEGameCoreRenderingOpenGL2Video) {
                _gameRenderer = [[OEOpenGL2GameRenderer alloc] initWithInteropTexture:_surface];
            } else {
                _gameRenderer = [[OEOpenGL3GameRenderer alloc] initWithInteropTexture:_surface];
            }
            break;
            
        default:
            NSAssert(0, @"Rendering API %u not supported yet", (unsigned)rendering);
            break;
    }

    [CATransaction commit];
    
    _gameRenderer.gameCore = _gameCore;
}

- (void)setupCVBuffer
{
    // init our texture and IOSurface
    OEIntSize surfaceSize = _gameCore.bufferSize;
    CGSize size = CGSizeMake(surfaceSize.width, surfaceSize.height);

    if (_gameCore.gameCoreRendering != OEGameCoreRendering2DVideo) {
        _surface.size = size;
        os_log_debug(LOG_DISPLAY, "Updated GL render surface size to %{public}@", NSStringFromOEIntSize(surfaceSize));
        _filterChain.sourceTexture          = _surface.metalTexture;
        _filterChain.sourceTextureIsFlipped = _surface.metalTextureIsFlipped;
    }
    else
    {
        os_log_debug(LOG_DISPLAY, "Set 2D buffer size to %{public}@", NSStringFromOEIntSize(surfaceSize));
    }

    [_gameRenderer updateRenderer];
    OEIntRect rect = _gameCore.screenRect;
    CGRect sourceRect = {.origin = {.x = rect.origin.x, .y = rect.origin.y}, .size = {.width = rect.size.width, .height = rect.size.height}};
    CGSize aspectSize = {.width = _gameCore.aspectSize.width, .height = _gameCore.aspectSize.height};
    
    os_log_debug(LOG_DISPLAY, "Set FilterChain sourceRect to %{public}@, aspectSize to %{public}@",
                 NSStringFromRect(sourceRect),
                 NSStringFromSize(aspectSize));
    [_filterChain setSourceRect:sourceRect aspect:aspectSize];
}

- (void)setupRemoteLayer
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    // TODO: If there's a good default bounds, use that.
    [_videoLayer setBounds:NSMakeRect(0, 0, _gameCore.bufferSize.width, _gameCore.bufferSize.height)];
    [_filterChain setDrawableSize:_videoLayer.drawableSize];
    
    CGSConnectionID connection_id = CGSMainConnectionID();
    _gameVideoCAContext       = [CAContext contextWithCGSConnection:connection_id options:@{kCAContextCIFilterBehavior: @"ignore"}];
    _gameVideoCAContext.layer = _videoLayer;
    [CATransaction commit];
    
    [self updateRemoteContextID:_gameVideoCAContext.contextId];
}

- (void)setOutputBounds:(NSRect)rect
{
    os_log_debug(LOG_DISPLAY, "Output bounds changed to %{public}@", NSStringFromRect(rect));
    
    if (_videoLayer && !NSEqualRects(_videoLayer.bounds, rect)) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        _videoLayer.bounds = rect;
        [_filterChain setDrawableSize:_videoLayer.drawableSize];
        [CATransaction commit];
    }

    // Game will try to render at the window size on its next frame.
    if ([_gameRenderer canChangeBufferSize] == NO) return;
    
    OEIntSize newBufferSize = OEIntSizeMake(ceil(rect.size.width), ceil(rect.size.height));
    if ([_gameCore tryToResizeVideoTo:newBufferSize] == NO) return;
}

- (void)setBackingScaleFactor:(CGFloat)newBackingScaleFactor
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    _videoLayer.contentsScale = newBackingScaleFactor;
    [_filterChain setDrawableSize:_videoLayer.drawableSize];
    [CATransaction commit];
}

- (void)setShaderURL:(NSURL *)url parameters:(NSDictionary<NSString *, NSNumber *> *)parameters completionHandler:(void (^)(BOOL success, NSError * _Nullable error))block
{
    [_gameCore performBlock:^{
        NSError *err = nil;
        BOOL success = [self setShaderURL:url parameters:parameters error:&err];
        block(success, err);
    }];
}

- (ShaderCompilerOptions *)makeOptions
{
    return [ShaderCompilerOptions makeOptions];
}

- (BOOL)setShaderURL:(NSURL *)url parameters:(NSDictionary<NSString *, NSNumber *> *)parameters error:(NSError **)error
{
    BOOL success = [_filterChain setShaderFromURL:url options:[self makeOptions] error:error];
    if (success)
    {
        __block __auto_type filter = _filterChain;
        [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSNumber *obj, BOOL *stop) {
            [filter setValue:obj.doubleValue forParameterName:key];
        }];
    }
    
    return success;
}

- (void)setShaderParameterValue:(CGFloat)value forKey:(NSString *)key
{
    [_filterChain setValue:value forParameterName:key];
}

#pragma mark - Game Core methods

- (BOOL)loadWithStartupInfo:(OEGameStartupInfo *)info error:(NSError **)error
{
    if(self.loadedRom) return NO;
    
    NSString *aPath = [info.romPath stringByStandardizingPath];
    
    os_log_info(OE_LOG_HELPER, "Load ROM at path %{public}@", aPath);
    self.loadedRom = NO;
    
    _shader = info.shader;
    _shaderParameters = info.shaderParameters;
    _systemController = [[OESystemPlugin systemPluginWithBundleAtPath:info.systemPluginPath] controller];
    _systemResponder = [_systemController newGameSystemResponder];
    
    _gameController = [[OECorePlugin corePluginWithBundleAtPath:info.corePluginPath] controller];
    _gameCore = [_gameController newGameCore];
    
    NSString *systemIdentifier = [_systemController systemIdentifier];
    
    [_gameCore setOwner:_gameController];
    [_gameCore setDelegate:self];
    [_gameCore setRenderDelegate:self];
    [_gameCore setAudioDelegate:self];
    
    [_gameCore setSystemIdentifier:systemIdentifier];
    [_gameCore setSystemRegion:info.systemRegion];
    [_gameCore setDisplayModeInfo:info.displayModeInfo ?: @{}];
    [_gameCore setROMMD5:info.romMD5];
    [_gameCore setROMHeader:info.romHeader];
    [_gameCore setROMSerial:info.romSerial];
    
    _systemResponder.client = _gameCore;
    _systemResponder.globalEventsHandler = self;

    __weak typeof(self) weakSelf = self;
    _unhandledEventsMonitor = [[OEDeviceManager sharedDeviceManager] addUnhandledEventMonitorHandler:^(OEDeviceHandler *handler, OEHIDEvent *event) {
        typeof(self) strongSelf = weakSelf;

        if (strongSelf == nil) return;

        if (!strongSelf->_handleEvents)
            return;

        if (!strongSelf->_handleKeyboardEvents && event.type == OEHIDEventTypeKeyboard)
            return;

        [strongSelf->_systemResponder handleHIDEvent:event];
    }];
    
    os_log_debug(OE_LOG_HELPER, "Loaded bundle.");
    
    if ([NSFileManager.defaultManager isReadableFileAtPath:aPath] == NO)
    {
        os_log_error(OE_LOG_HELPER, "Unable to access file at path %{public}@", aPath);
        _gameCore = nil;
        if (error && !*error) {
            *error = [NSError errorWithDomain:OEGameCoreErrorDomain
                                         code:OEGameCoreCouldNotLoadROMError
                                     userInfo:@{
                                         NSLocalizedDescriptionKey: NSLocalizedString(@"The emulator does not have read permissions to the ROM.", @"Error when loading a ROM."),
                                     }];
        }
        return NO;
    }
    
    if([_gameCore loadFileAtPath:aPath error:error])
    {
        os_log_debug(OE_LOG_HELPER, "Loaded new ROM: %{public}@", aPath);

        [_gameCoreOwner setDiscCount:[_gameCore discCount]];
        [_gameCoreOwner setDisplayModes:[_gameCore displayModes]];

        self.loadedRom = YES;
        
        return YES;
    }
    
    if (error && !*error) {
        *error = [NSError errorWithDomain:OEGameCoreErrorDomain
                                     code:OEGameCoreCouldNotLoadROMError
                                 userInfo:@{
                                     NSLocalizedDescriptionKey: NSLocalizedString(@"The emulator could not load ROM.", @"Error when loading a ROM."),
                                 }];
    }
    
    os_log_error(OE_LOG_HELPER, "Failed to load ROM.");

    _gameCore = nil;
    
    return NO;
}

- (OEIntSize)aspectSize
{
    return [_gameCore aspectSize];
}

- (BOOL)isEmulationPaused
{
    return _gameCore.isEmulationPaused;
}

#pragma mark - OEGameCoreHelper methods

- (void)setVolume:(CGFloat)volume
{
    [_gameCore performBlock:^{
        [self->_gameAudio setVolume:volume];
    }];
    
}

- (void)setPauseEmulation:(BOOL)paused
{
    [_gameCore performBlock:^{
        [self->_gameCore setPauseEmulation:paused];
    }];
}

- (void)setAudioOutputDeviceID:(AudioDeviceID)deviceID
{
    os_log_debug(OE_LOG_HELPER, "Set audio output to device number %lu", (unsigned long)deviceID);

    [_gameCore performBlock:^{
        [self->_gameAudio setOutputDeviceID:deviceID];
    }];
}

- (void)setupEmulationWithCompletionHandler:(void(^)(OEGameCoreHelperSetupResult result))handler
{
    [_gameCore setupEmulationWithCompletionHandler:^{
        [self setupGameCoreAudioAndVideo];
        
        if(handler)
        {
            handler((OEGameCoreHelperSetupResult){
                .screenSize = self->_previousScreenRect.size,
                .aspectSize = self->_previousAspectSize
            });
        }
    }];
}

- (void)startEmulationWithCompletionHandler:(void(^)(void))handler
{
    [_gameCore startEmulationWithCompletionHandler:handler];
}

- (void)resetEmulationWithCompletionHandler:(void(^)(void))handler
{
    [_gameCore resetEmulationWithCompletionHandler:handler];
}

- (void)stopEmulationWithCompletionHandler:(void(^)(void))handler
{
    [_gameCore stopEmulationWithCompletionHandler: ^{
        [self->_gameAudio stopAudio];
        [self->_gameCore setRenderDelegate:nil];
        [self->_gameCore setAudioDelegate:nil];
        self->_gameCoreOwner = nil;
        self->_gameCore      = nil;
        self->_gameAudio     = nil;

        if (handler != nil)
            handler();
    }];
}

- (void)saveStateToFileAtPath:(NSString *)fileName completionHandler:(void (^)(BOOL, NSError *))block
{
    [_gameCore performBlock:^{
        [self->_gameCore saveStateToFileAtPath:fileName completionHandler:block];
    }];
}

- (void)loadStateFromFileAtPath:(NSString *)fileName completionHandler:(void (^)(BOOL, NSError *))block
{
    [_gameCore performBlock:^{
        [self->_gameCore loadStateFromFileAtPath:fileName completionHandler:block];
    }];
}

- (void)setCheat:(NSString *)cheatCode withType:(NSString *)type enabled:(BOOL)enabled;
{
    [_gameCore performBlock:^{
        [self->_gameCore setCheat:cheatCode setType:type setEnabled:enabled];
    }];
}

- (void)setDisc:(NSUInteger)discNumber
{
    [_gameCore performBlock:^{
        [self->_gameCore setDisc:discNumber];
    }];
}

- (void)insertFileAtURL:(NSURL *)url completionHandler:(void (^)(BOOL, NSError *))block
{
    [_gameCore performBlock:^{
        [self->_gameCore insertFileAtURL:url completionHandler:block];
    }];
}

- (void)changeDisplayWithMode:(NSString *)displayMode
{
    [_gameCore performBlock:^{
        [self->_gameCore changeDisplayWithMode:displayMode];
        [self->_gameCoreOwner setDisplayModes:[self->_gameCore displayModes]];
    }];
}

- (void)handleMouseEvent:(OEEvent *)event
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_systemResponder handleMouseEvent:event];
    });
}

- (void)systemBindingsDidSetEvent:(OEHIDEvent *)event forBinding:(__kindof OEBindingDescription *)bindingDescription playerNumber:(NSUInteger)playerNumber
{
    [self _updateBindingForEvent:event withBlock:^{
        [self->_systemResponder systemBindingsDidSetEvent:event forBinding:bindingDescription playerNumber:playerNumber];
    }];
}

- (void)systemBindingsDidUnsetEvent:(OEHIDEvent *)event forBinding:(__kindof OEBindingDescription *)bindingDescription playerNumber:(NSUInteger)playerNumber
{
    [self _updateBindingForEvent:event withBlock:^{
        [self->_systemResponder systemBindingsDidUnsetEvent:event forBinding:bindingDescription playerNumber:playerNumber];
    }];
}

- (void)_updateBindingForEvent:(OEHIDEvent *)event withBlock:(void(^)(void))block
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!event.hasDeviceHandlerPlaceholder) {
            block();
            return;
        }
        
        OEDeviceHandlerPlaceholder *placeholder = event.deviceHandler;
        NSMutableArray<void(^)(void)> *pendingBlocks = self->_pendingDeviceHandlerBindings[placeholder];
        if (!pendingBlocks) {
            pendingBlocks = [NSMutableArray array];
            self->_pendingDeviceHandlerBindings[placeholder] = pendingBlocks;
        }
        
        [pendingBlocks addObject:[^{
            [event resolveDeviceHandlerPlaceholder];
            block();
        } copy]];
    });
}

- (void)_deviceHandlerPlaceholderDidResolveNotification:(NSNotification *)notification
{
    OEDeviceHandlerPlaceholder *placeholder = notification.object;
    
    NSMutableArray<void(^)(void)> *pendingBlocks = _pendingDeviceHandlerBindings[placeholder];
    if (!pendingBlocks)
        return;
    
    for (void(^block)(void) in pendingBlocks)
        block();
    
    [_pendingDeviceHandlerBindings removeObjectForKey:placeholder];
}

#pragma mark - OEGameCoreOwner image capture

- (void)captureOutputImageWithCompletionHandler:(void (^)(NSBitmapImageRep *image))block
{
    __block OEFilterChain *chain = _filterChain;
    [_gameCore performBlock:^{
        block(chain.captureOutputImage);
    }];
}

- (void)captureSourceImageWithCompletionHandler:(void (^)(NSBitmapImageRep *image))block
{
    __block OEFilterChain *chain = _filterChain;
    [_gameCore performBlock:^{
        block(chain.captureSourceImage);
    }];
}


#pragma mark - OEGameCoreOwner subclass handles

- (void)updateScreenSize:(OEIntSize)newScreenSize aspectSize:(OEIntSize)newAspectSize
{
    os_log_debug(LOG_DISPLAY, "Notify OEGameCoreOwner of display size update: screenSize = %{public}@, aspectSize = %{public}@",
                 NSStringFromOEIntSize(newScreenSize), NSStringFromOEIntSize(newAspectSize));
    
    [_gameCoreOwner setScreenSize:newScreenSize aspectSize:newAspectSize];
}

- (void)updateRemoteContextID:(CAContextID)newContextID
{
    [_gameCoreOwner setRemoteContextID:newContextID];
}

#pragma mark - OEGameCoreDelegate protocol methods

- (void)gameCoreDidFinishFrameRefreshThread:(OEGameCore *)gameCore
{
    os_log_debug(OE_LOG_HELPER, "Finishing separate thread, stopping");
    CFRunLoopStop(CFRunLoopGetCurrent());
}

#pragma mark - OERenderDelegate protocol methods

- (id)presentationFramebuffer
{
    return _gameRenderer.presentationFramebuffer;
}

- (void)willExecute
{
    [_scope beginScope];
    [_gameRenderer willExecuteFrame];
}

- (void)didExecute
{
    OEIntSize previousBufferSize = _gameRenderer.surfaceSize;
    OEIntSize previousAspectSize = _previousAspectSize;
    OEIntRect previousScreenRect = _previousScreenRect;
    
    OEIntSize bufferSize = _gameCore.bufferSize;
    OEIntRect screenRect = _gameCore.screenRect;
    OEIntSize aspectSize = _gameCore.aspectSize;
    BOOL mustUpdate = NO;

    [CATransaction begin];
    [CATransaction setDisableActions:YES];

    if (!OEIntSizeEqualToSize(previousBufferSize, bufferSize)) {
        os_log_debug(LOG_DISPLAY, "Game core buffer size change: %{public}@ → %{public}@",
                     NSStringFromOEIntSize(previousBufferSize),
                     NSStringFromOEIntSize(bufferSize));
        NSAssert(_gameRenderer.canChangeBufferSize == YES, @"Game tried changing IOSurface in a state we don't support");
        
        [self setupCVBuffer];
    } else {
        if (!OEIntRectEqualToRect(screenRect, previousScreenRect))
        {
            NSAssert((screenRect.origin.x + screenRect.size.width) <= bufferSize.width, @"screen rect must not be larger than buffer size");
            NSAssert((screenRect.origin.y + screenRect.size.height) <= bufferSize.height, @"screen rect must not be larger than buffer size");
            
            os_log_debug(LOG_DISPLAY, "Game core screen rect change: %{public}@ → %{public}@",
                         NSStringFromOEIntRect(previousScreenRect),
                         NSStringFromOEIntRect(screenRect));
            mustUpdate = YES;
        }
        
        if(!OEIntSizeEqualToSize(aspectSize, previousAspectSize))
        {
            os_log_debug(LOG_DISPLAY, "Game core aspect size change: %{public}@ → %{public}@",
                         NSStringFromOEIntSize(previousAspectSize),
                         NSStringFromOEIntSize(aspectSize));
            mustUpdate = YES;
        }
        
        if (mustUpdate) {
            [self updateScreenSize];
            [self updateScreenSize:_previousScreenRect.size aspectSize:_previousAspectSize];
            [self setupCVBuffer];
        }
    }
    
    [_gameRenderer didExecuteFrame];
    
    @autoreleasepool {
        if (dispatch_semaphore_wait(_inflightSemaphore, DISPATCH_TIME_NOW) != 0) {
            _skippedFrames++;
        } else {
            id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
            commandBuffer.label = @"offscreen";
            [commandBuffer enqueue];
            [_filterChain renderOffscreenPassesWithCommandBuffer:commandBuffer];
            [commandBuffer commit];

            id<CAMetalDrawable> drawable = _videoLayer.nextDrawable;
            if (drawable != nil) {
                MTLRenderPassDescriptor *rpd = [MTLRenderPassDescriptor new];
                rpd.colorAttachments[0].clearColor = self->_clearColor;
                // TODO: Investigate whether we can avoid the MTLLoadActionClear
                // Frame buffer should be overwritten completely by final pass.
                rpd.colorAttachments[0].loadAction = MTLLoadActionClear;
                rpd.colorAttachments[0].texture    = drawable.texture;
                commandBuffer = [_commandQueue commandBuffer];
                commandBuffer.label = @"final";
                id<MTLRenderCommandEncoder> rce = [commandBuffer renderCommandEncoderWithDescriptor:rpd];
                [_filterChain renderFinalPassWithCommandEncoder:rce];
                [rce endEncoding];

                __block dispatch_semaphore_t inflight = _inflightSemaphore;
                [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> _) {
                    dispatch_semaphore_signal(inflight);
                }];

                [commandBuffer presentDrawable:drawable];
                [commandBuffer commit];
            } else {
                dispatch_semaphore_signal(self->_inflightSemaphore);
            }
        }
    }
    
    [_scope endScope];

    [_videoLayer display];
    [CATransaction commit];

    if(!_hasStartedAudio)
    {
        [_gameAudio startAudio];
        _hasStartedAudio = YES;
    }
}

- (void)willRenderFrameOnAlternateThread
{
    [_gameRenderer willRenderFrameOnAlternateThread];
}

- (void)presentDoubleBufferedFBO
{
    [_gameRenderer presentDoubleBufferedFBO];
}

- (void)didRenderFrameOnAlternateThread
{
    [_gameRenderer didRenderFrameOnAlternateThread];
}

- (void)resumeFPSLimiting
{
    [_gameRenderer resumeFPSLimiting];
}

- (void)suspendFPSLimiting
{
    [_gameRenderer suspendFPSLimiting];
}

- (BOOL)enableVSync {
    return NO;
}

- (void)setEnableVSync:(BOOL)enableVSync
{
// TODO: Stub. Remove this when remote-layer lands
}

#pragma mark - OEAudioDelegate

- (void)audioSampleRateDidChange
{
    [_gameCore performBlock:^{
        [self->_gameAudio audioSampleRateDidChange];
    }];
}

- (void)pauseAudio
{
    [_gameCore performBlock:^{
        [self->_gameAudio pauseAudio];
    }];
}

- (void)resumeAudio
{
    [_gameCore performBlock:^{
        [self->_gameAudio resumeAudio];
    }];
}

#pragma mark - OEGlobalEventsHandler

- (void)saveState:(id)sender
{
    [_gameCoreOwner saveState];
}

- (void)loadState:(id)sender
{
    [_gameCoreOwner loadState];
}

- (void)quickSave:(id)sender
{
    [_gameCoreOwner quickSave];
}

- (void)quickLoad:(id)sender
{
    [_gameCoreOwner quickLoad];
}

- (void)toggleFullScreen:(id)sender
{
    [_gameCoreOwner toggleFullScreen];
}

- (void)toggleAudioMute:(id)sender
{
    [_gameCoreOwner toggleAudioMute];
}

- (void)volumeDown:(id)sender
{
    [_gameCoreOwner volumeDown];
}

- (void)volumeUp:(id)sender
{
    [_gameCoreOwner volumeUp];
}

- (void)stopEmulation:(id)sender
{
    [_gameCoreOwner stopEmulation];
}

- (void)resetEmulation:(id)sender
{
    [_gameCoreOwner resetEmulation];
}

- (void)toggleEmulationPaused:(id)sender
{
    [_gameCoreOwner toggleEmulationPaused];
}

- (void)takeScreenshot:(id)sender
{
    [_gameCoreOwner takeScreenshot];
}

- (void)fastForwardGameplay:(BOOL)enable
{
    [_gameCoreOwner fastForwardGameplay:enable];
}

- (void)rewindGameplay:(BOOL)enable
{
    // TODO: technically a data race, but it is only updating a single NSInteger
    _filterChain.frameDirection = enable ? -1 : 1;
    [_gameCoreOwner rewindGameplay:enable];
}

- (void)stepGameplayFrameForward:(id)sender
{
    [_gameCoreOwner stepGameplayFrameForward];
}

- (void)stepGameplayFrameBackward:(id)sender
{
    [_gameCoreOwner stepGameplayFrameBackward];
}

- (void)nextDisplayMode:(id)sender
{
    [_gameCoreOwner nextDisplayMode];
}

- (void)lastDisplayMode:(id)sender
{
    [_gameCoreOwner lastDisplayMode];
}

@end
