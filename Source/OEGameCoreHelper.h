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

#import <Cocoa/Cocoa.h>
#import <CoreAudio/CoreAudio.h>
#import <OpenEmuSystem/OpenEmuSystem.h>

@class OEEvent;

NS_ASSUME_NONNULL_BEGIN

typedef uint32_t OEContextID; // == CAContextID, see QuartzCoreSPI.h

typedef struct _OEGameCoreHelperSetupResult {
    OEIntSize screenSize;
    OEIntSize aspectSize;
} OEGameCoreHelperSetupResult;

typedef NS_ENUM(NSUInteger, OEGameCoreEffectsMode) {
    /*! Shader effects are displayed when the game core is running and
     * paused when game core is paused. This is the default mode.
     */
    OEGameCoreEffectsModeReflectPaused,
    /*! Shader effects continue to run when game core is paused.
     */
    OEGameCoreEffectsModeDisplayAlways,
};

/*!
 * A protocol that defines the behaviour required to control an emulator core.
 *
 * A host application obtains an instance of @c OEGameCoreHelper in order
 * to communicate with the core, which may be running in another thread or
 * a remote process.
 */
@protocol OEGameCoreHelper <NSObject>

/*!
 * Adjust the output volume of the core.
 * @param value The new volume level, from @c [0,1.0]
 */
- (void)setVolume:(float)value;

/*!
 * Manage the paused status of the core.
 *
 * @param pauseEmulation Specify @c true to pause the core.
 */
- (void)setPauseEmulation:(BOOL)pauseEmulation;

/*! Specifies how and when shader effects are rendered.
 *
 * Shader effects are normally paused when the core is paused. This
 * API allows futher control over when the effects are rendered.
 *
 * @param mode Determines how and when shader effects are rendered.
 */
- (void)setEffectsMode:(OEGameCoreEffectsMode)mode;
- (void)setAudioOutputDeviceID:(AudioDeviceID)deviceID;
- (void)setOutputBounds:(NSRect)rect;
- (void)setBackingScaleFactor:(CGFloat)newBackingScaleFactor;

#pragma mark - Shader management

- (void)setShaderURL:(NSURL *)url parameters:(NSDictionary<NSString *, NSNumber *> * _Nullable)parameters completionHandler:(void (^)(BOOL success, NSError * _Nullable error))block;
- (void)setShaderParameterValue:(CGFloat)value forKey:(NSString *)key;

#pragma mark - Emulator control

- (void)setupEmulationWithCompletionHandler:(void(^)(OEGameCoreHelperSetupResult result))handler;
- (void)startEmulationWithCompletionHandler:(void(^)(void))handler;
- (void)resetEmulationWithCompletionHandler:(void(^)(void))handler;
- (void)stopEmulationWithCompletionHandler:(void(^)(void))handler;

- (void)saveStateToFileAtPath:(NSString *)fileName completionHandler:(void (^)(BOOL success, NSError * _Nullable error))block;
- (void)loadStateFromFileAtPath:(NSString *)fileName completionHandler:(void (^)(BOOL success, NSError * _Nullable error))block;

- (void)setCheat:(NSString *)cheatCode withType:(NSString *)type enabled:(BOOL)enabled;
- (void)setDisc:(NSUInteger)discNumber;
- (void)changeDisplayWithMode:(NSString *)displayMode;

- (void)insertFileAtURL:(NSURL *)url completionHandler:(void (^)(BOOL success, NSError * _Nullable error))block;

- (void)handleMouseEvent:(OEEvent *)event;

- (void)setHandleEvents:(BOOL)handleEvents;
- (void)setHandleKeyboardEvents:(BOOL)handleKeyboardEvents;
- (void)systemBindingsDidSetEvent:(OEHIDEvent *)event forBinding:(__kindof OEBindingDescription *)bindingDescription playerNumber:(NSUInteger)playerNumber;
- (void)systemBindingsDidUnsetEvent:(OEHIDEvent *)event forBinding:(__kindof OEBindingDescription *)bindingDescription playerNumber:(NSUInteger)playerNumber;

#pragma mark - Screenshot support

/**
 * Capture an image of the core's video display buffer, which includes all shader effects.
 */
- (void)captureOutputImageWithCompletionHandler:(void (^)(NSBitmapImageRep *image))block;

/**
 * Capture an image of the core's raw video display buffer with no effects.
 */
- (void)captureSourceImageWithCompletionHandler:(void (^)(NSBitmapImageRep *image))block;

@end

@protocol OEGameCoreOwner <NSObject>

#pragma mark - Actions

// These actions are triggered from the game core via the OEGlobalEventsHandler protocol

/*! Notify the host application of the user request to save the current state
 */
- (void)saveState;
- (void)loadState;
- (void)quickSave;
- (void)quickLoad;
- (void)toggleFullScreen;
- (void)toggleAudioMute;
- (void)volumeDown;
- (void)volumeUp;
- (void)stopEmulation;
- (void)resetEmulation;
- (void)toggleEmulationPaused;
- (void)takeScreenshot;
- (void)fastForwardGameplay:(BOOL)enable;
- (void)rewindGameplay:(BOOL)enable;
- (void)stepGameplayFrameForward;
- (void)stepGameplayFrameBackward;
- (void)nextDisplayMode;
- (void)lastDisplayMode;

/**
 * Notify the host application that the screen and aspect sizes have changed for the core.
 *
 * The host application would use this information to adjust the size of the display window.
 *
 * @param newScreenSize The updated screen size
 * @param newAspectSize The updated aspect size
 */
- (void)setScreenSize:(OEIntSize)newScreenSize aspectSize:(OEIntSize)newAspectSize;
/**
 * Notify the host application that the disc count has changed
 *
 *
 */
- (void)setDiscCount:(NSUInteger)discCount;
- (void)setDisplayModes:(NSArray <NSDictionary <NSString *, id> *> *)displayModes;
- (void)setRemoteContextID:(OEContextID)contextID;

@optional

/** Invoked when the game core execution has terminated, either because it
 *  was asked to stop, or because it terminated spontaneously (for example
 *  in case of a helper application crash).
 *  @warning This message may not be sent in certain situations (for example
 *    when the core manager is deallocated right after the game core is
 *    stopped). */
- (void)gameCoreDidTerminate;

@end

NS_ASSUME_NONNULL_END
