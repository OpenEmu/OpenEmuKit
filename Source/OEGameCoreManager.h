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

@import Cocoa;

#import <OpenEmuKit/OEGameCoreHelper.h>

@protocol OEGameCoreOwner;
@class OECorePlugin, OEGameCoreController, OESystemPlugin, OEGameStartupInfo;

typedef void(^OEStartupCompletionHandler)(NSError * _Nullable);

NS_ASSUME_NONNULL_BEGIN

typedef NS_ERROR_ENUM(OEGameCoreErrorDomain, OEGameCoreManagerErrorCodes)
{
    OEHelperAppNotRunningError     = -3,
    OEConnectionTimedOutError      = -4,
    OEInvalidHelperConnectionError = -5,
    OENilRootProxyObjectError      = -6,
};

@interface OEGameCoreManager : NSObject <OEGameCoreHelper>

/*! @brief Initializes an @c OEGameCoreManager object with the specified parameters.
 * @details
 * The @c OEGameCoreManager is responsible for brokering communication between the
 * host and the game core.
 */
- (instancetype)initWithStartupInfo:(OEGameStartupInfo *)startupInfo corePlugin:(OECorePlugin *)plugin systemPlugin:(OESystemPlugin *)systemPlugin gameCoreOwner:(id<OEGameCoreOwner>)gameCoreOwner;

@property(readonly, copy) OEGameStartupInfo             *startupInfo;
@property(readonly, weak) OECorePlugin                  *plugin;
@property(readonly, weak) OESystemPlugin                *systemPlugin;
@property(readonly, weak) id<OEGameCoreOwner>            gameCoreOwner;

#pragma mark - Abstract methods, must be overrode in subclasses

- (void)loadROMWithCompletionHandler:(void(^)(void))completionHandler errorHandler:(void(^)(NSError *))errorHandler;
- (void)loadROMWithCompletionHandler:(OEStartupCompletionHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END
