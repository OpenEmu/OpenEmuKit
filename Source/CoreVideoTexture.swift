// Copyright (c) 2022, OpenEmu Team
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

import Foundation
import OpenGL
import CoreVideo

// source: https://developer.apple.com/documentation/metal/mixing_metal_and_opengl_rendering_in_a_view

final class CoreVideoTexture {
    let mtlPixelFormat: MTLPixelFormat
    let cvPixelFormat: OSType
    let metalDevice: MTLDevice
    
    public init(device: MTLDevice, metalPixelFormat mtlPixelFormat: MTLPixelFormat) {
        guard let cv = Self.metalToCVMap[mtlPixelFormat]
        else { fatalError("Unsupported Metal pixel format") }
        self.metalDevice    = device
        self.mtlPixelFormat = mtlPixelFormat
        self.cvPixelFormat  = cv
    }
    
    var cvPixelBuffer: CVPixelBuffer?
    
    var size: CGSize = .zero {
        didSet {
            let cvBufferProperties = [
                kCVPixelBufferOpenGLCompatibilityKey: true,
                kCVPixelBufferMetalCompatibilityKey: true,
            ]
            
            guard CVPixelBufferCreate(kCFAllocatorDefault,
                                      Int(size.width), Int(size.height),
                                      cvPixelFormat,
                                      cvBufferProperties as CFDictionary, &cvPixelBuffer) == kCVReturnSuccess
            else {
                fatalError("Failed to create CVPixelBuffer")
            }
            
            if let openGLContext = openGLContext {
                createGLTexture(context: openGLContext)
            }
            
            createMetalTexture(device: metalDevice)
        }
    }
    
    // MARK: - Metal resources
    
    var metalTexture: MTLTexture?
    
    var cvMTLTextureCache: CVMetalTextureCache?
    var cvMTLTexture: CVMetalTexture?
    
    private func releaseMetalTexture() {
        metalTexture        = nil
        cvMTLTexture        = nil
        cvMTLTextureCache   = nil
    }
    
    private func createMetalTexture(device: MTLDevice) {
        releaseMetalTexture()
        guard size != .zero else { return }
        
        // 1. Create a Metal Core Video texture cache from the pixel buffer.
        guard
            CVMetalTextureCacheCreate(kCFAllocatorDefault,
                                      nil,
                                      device,
                                      nil,
                                      &cvMTLTextureCache) == kCVReturnSuccess
        else { return }
        
        // 2. Create a CoreVideo pixel buffer backed Metal texture image from the texture cache.
        guard
            CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                      cvMTLTextureCache!,
                                                      cvPixelBuffer!,
                                                      nil,
                                                      mtlPixelFormat,
                                                      Int(size.width),
                                                      Int(size.height),
                                                      0,
                                                      &cvMTLTexture) == kCVReturnSuccess
        else {
            fatalError("Failed to create Metal texture cache")
        }
        
        // 3. Get a Metal texture using the CoreVideo Metal texture reference.
        metalTexture = CVMetalTextureGetTexture(cvMTLTexture!)
        guard
            metalTexture != nil
        else {
            fatalError("Failed to get Metal texture from CVMetalTexture")
        }
    }
    
    var metalTextureIsFlippedVertically: Bool {
        if let cvMTLTexture = cvMTLTexture {
            return CVMetalTextureIsFlipped(cvMTLTexture)
        }
        return false
    }
    
    // MARK: - OpenGL resources
    
    var openGLContext: CGLContextObj? {
        didSet {
            if let openGLContext = openGLContext {
                cglPixelFormat = CGLGetPixelFormat(openGLContext)
                createGLTexture(context: openGLContext)
            }
        }
    }
    var openGLTexture: GLuint = 0
    
    var cvGLTextureCache: CVOpenGLTextureCache?
    var cvGLTexture: CVOpenGLTexture?
    var cglPixelFormat: CGLPixelFormatObj?
    
    private func releaseGLTexture() {
        openGLTexture       = 0
        cvGLTexture         = nil
        cvGLTextureCache    = nil
    }
    
    private func createGLTexture(context: CGLContextObj) {
        releaseGLTexture()
        
        guard size != .zero else { return }
        
        // 1. Create an OpenGL CoreVideo texture cache from the pixel buffer.
        guard
            CVOpenGLTextureCacheCreate(kCFAllocatorDefault,
                                       nil,
                                       context,
                                       cglPixelFormat!,
                                       nil,
                                       &cvGLTextureCache) == kCVReturnSuccess
        else {
            fatalError("Failed to create OpenGL texture cache")
        }
        
        // 2. Create a CVPixelBuffer-backed OpenGL texture image from the texture cache.
        guard
            CVOpenGLTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       cvGLTextureCache!,
                                                       cvPixelBuffer!,
                                                       nil,
                                                       &cvGLTexture) == kCVReturnSuccess
        else {
            fatalError("Failed to create OpenGL texture from image")
        }
        
        // 3. Get an OpenGL texture name from the CVPixelBuffer-backed OpenGL texture image.
        openGLTexture = CVOpenGLTextureGetName(cvGLTexture!)
    }
    
    // MARK: - Static helpers
    
    // source: https://developer.apple.com/documentation/metal/mixing_metal_and_opengl_rendering_in_a_view
    
    private static let metalToCVMap: [MTLPixelFormat: OSType] = [
        .bgra8Unorm: kCVPixelFormatType_32BGRA,
        .bgr10a2Unorm: kCVPixelFormatType_ARGB2101010LEPacked,
        .bgra8Unorm_srgb: kCVPixelFormatType_32BGRA,
        .rgba16Float: kCVPixelFormatType_64RGBAHalf,
    ]
}
