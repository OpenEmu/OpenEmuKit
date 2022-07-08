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
import OpenEmuShaders
import OpenEmuBase
import OpenGL

final class MTLGameRenderer: GameRenderer {
    var surfaceSize: OEIntSize { gameCore.bufferSize }
    let gameCore: OEGameCore
    var presentationFramebuffer: Any?
    
    var buffer: PixelBuffer!
    
    private let filterChain: FilterChain
    
    init(withFilterChain filterChain: FilterChain, gameCore: OEGameCore) {
        self.filterChain = filterChain
        self.gameCore    = gameCore
    }
    
    func update() {
        precondition(gameCore.gameCoreRendering == .rendering2DVideo, "Metal only supports 2D rendering")
        setup2D()
    }
    
    private func setup2D() {
        let pixelFormat = gameCore.pixelFormat
        let pixelType   = gameCore.pixelType
        let pf          = glToRPixelFormat(pixelFormat: pixelFormat, pixelType: pixelType)
        precondition(pf != .invalid)
        
        let rect       = gameCore.screenRect
        let sourceRect = CGRect(x: CGFloat(rect.origin.x), y: CGFloat(rect.origin.y),
                                width: CGFloat(rect.size.width), height: CGFloat(rect.size.height))
        let aspectSize = CGSize(width: CGFloat(gameCore.aspectSize.width),
                                height: CGFloat(gameCore.aspectSize.height))
        filterChain.setSourceRect(sourceRect, aspect: aspectSize)
        
        // bufferSize is fixed for 2D, so doesn't need to be reallocated.
        if buffer != nil { return }
        
        let bufferSize  = gameCore.bufferSize
        let bytesPerRow = gameCore.bytesPerRow
        
        buffer = filterChain.newBuffer(withFormat: pf, height: UInt(bufferSize.height), bytesPerRow: UInt(bytesPerRow))
        let buf = UnsafeMutableRawPointer(mutating: gameCore.getVideoBuffer(withHint: buffer.contents))
        if buf != buffer.contents {
            buffer = filterChain.newBuffer(withFormat: pf,
                                           height: UInt(bufferSize.height),
                                           bytesPerRow: UInt(bytesPerRow),
                                           bytes: buf)
        }
    }
    
    var canChangeBufferSize: Bool { true }
    
    func willExecuteFrame() {
        assert(buffer.contents == UnsafeMutableRawPointer(mutating: gameCore.getVideoBuffer(withHint: buffer.contents)),
               "Game suddenly stopped using direct rendering")
    }
    
    func didExecuteFrame() { }
    func presentDoubleBufferedFBO() { }
    func willRenderFrameOnAlternateThread() { }
    func didRenderFrameOnAlternateThread() { }
    func suspendFPSLimiting() { }
    func resumeFPSLimiting() { }
    
    private func glToRPixelFormat(pixelFormat: GLenum, pixelType: GLenum) -> OEMTLPixelFormat {
        switch Int32(pixelFormat) {
        case GL_BGRA:
            switch Int32(pixelType) {
            case GL_UNSIGNED_INT_8_8_8_8_REV:
                return .bgra8Unorm
            default:
                break
            }
            
        case GL_RGB:
            switch Int32(pixelType) {
            case GL_UNSIGNED_SHORT_5_6_5:
                return .b5g6r5Unorm
            default:
                break
            }
            
        case GL_RGBA:
            switch Int32(pixelType) {
            case GL_UNSIGNED_INT_8_8_8_8_REV:
                return .abgr8Unorm
            case GL_UNSIGNED_INT_8_8_8_8:
                return .rgba8Unorm
            case GL_UNSIGNED_SHORT_1_5_5_5_REV:
                return .r5g5b5a1Unorm
            default:
                break
            }
        default:
            break
        }
        
        return .invalid
    }
    
}
