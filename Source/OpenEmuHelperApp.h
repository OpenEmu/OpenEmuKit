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


#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#import <OpenEmuKit/OEGameCoreHelper.h>

// DO  object
#import <OpenEmuBase/OpenEmuBase.h>

enum _OEHelperAppErrorCodes
{
    OEHelperNoError                      =  0,
    OEHelperCouldNotStartConnectionError = -1,
    OEHelperIncorrectFileError           = -2,
};

OE_EXPORTED_CLASS
@interface OpenEmuHelperApp : NSResponder <NSApplicationDelegate, OEGameCoreHelper, OERenderDelegate, OEAudioDelegate>

@property(nonatomic) id<OEGameCoreOwner> gameCoreOwner;
@property(nonatomic, readonly) OEGameCore *gameCore;
@property(nonatomic, readonly) Protocol *gameSystemResponderClientProtocol;
@property(nonatomic) BOOL handleEvents;
@property(nonatomic) BOOL handleKeyboardEvents;

- (void)launchApplication;

- (BOOL)loadROMAtPath:(NSString *)aPath romCRC32:(NSString *)romCRC32 romMD5:(NSString *)romMD5 romHeader:(NSString *)romHeader romSerial:(NSString *)romSerial systemRegion:(NSString *)systemRegion displayModeInfo:(NSDictionary <NSString *, id> *)displayModeInfo withCorePluginAtPath:(NSString *)pluginPath systemPluginPath:(NSString *)systemPluginPath error:(NSError **)error;

@end