// Copyright 2014 The Chromium Authors. All rights reserved.
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

@import Foundation;
@import Quartz;

#include <stdint.h>

// https://chromium.googlesource.com/chromium/src/+/refs/heads/main/ui/base/cocoa/remote_layer_api.h

// The CAContextID type identifies a CAContext across processes. This is the
// token that is passed from the process that is sharing the CALayer that it is
// rendering to the process that will be displaying that CALayer.
typedef uint32_t CAContextID;

// The CAContext has a static CAContextID which can be sent to another process.
// When a CALayerHost is created using that CAContextID in another process, the
// content displayed by that CALayerHost will be the content of the CALayer
// that is set as the |layer| property on the CAContext.
@interface CAContext : NSObject
+ (instancetype)contextWithCGSConnection:(CAContextID)contextId options:(NSDictionary*)optionsDict;
@property(readonly) CAContextID contextId;
@property(retain) CALayer *layer;
@end

// The CALayerHost is created in the process that will display the content
// being rendered by another process. Setting the |contextId| property on
// an object of this class will make this layer display the content of the
// CALayer that is set to the CAContext with that CAContextID in the layer
// sharing process.
@interface CALayerHost : CALayer
@property CAContextID contextId;
@end

// The CGSConnectionID is used to create the CAContext in the process that is
// going to share the CALayers that it is rendering to another process to
// display.
typedef uint32_t CGSConnectionID;
CGSConnectionID CGSMainConnectionID(void);

extern NSString * const kCAContextCIFilterBehavior;
