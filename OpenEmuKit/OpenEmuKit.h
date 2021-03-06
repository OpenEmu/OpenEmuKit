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

#import <Foundation/Foundation.h>

//! Project version number for OpenEmuKit.
FOUNDATION_EXPORT double OpenEmuKitVersionNumber;

//! Project version string for OpenEmuKit.
FOUNDATION_EXPORT const unsigned char OpenEmuKitVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <OpenEmuKit/PublicHeader.h>

#import <OpenEmuKit/OEPlugin.h>
#import <OpenEmuKit/OECorePlugin.h>
#import <OpenEmuKit/OESystemPlugin.h>
#import <OpenEmuKit/OEShaderParamValue.h>
#import <OpenEmuKit/OEGameCoreHelper.h>
#import <OpenEmuKit/OpenEmuHelperApp.h>
#import <OpenEmuKit/OpenEmuXPCHelperAppBase.h>
#import <OpenEmuKit/OEGameCoreManager.h>
#import <OpenEmuKit/OEThreadGameCoreManager.h>
#import <OpenEmuKit/OEXPCGameCoreManagerBase.h>
#import <OpenEmuKit/OEGameLayerView.h>
#import <OpenEmuKit/NSXPCConnection+HelperApp.h>
#import <OpenEmuKit/NSXPCListener+HelperApp.h>
#import <OpenEmuKit/OEXPCDebugSupport.h>
#import <OpenEmuKit/OEGameStartupInfo.h>
#import <OpenEmuKit/NSFileManager+ExtendedAttributes.h>
