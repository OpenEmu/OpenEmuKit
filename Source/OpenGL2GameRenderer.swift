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
import OpenEmuBase
import OpenGL
@_implementationOnly import Atomics
@_implementationOnly import os.log

final class OpenGL2GameRenderer: GameRenderer {
    let gameCore: OEGameCore
    
    let texture: CoreVideoTexture
    
    // GL stuff
    var glContext: CGLContextObj!
    var glPixelFormat: CGLPixelFormatObj!
    var coreVideoFBO: GLuint = 0    // Framebuffer object which the Core Video pixel buffer is tied to
    var depthStencilRB: GLuint = 0  // FBO RenderBuffer Attachment for depth and stencil buffer
    
    // Double buffered FBO rendering (3D mode)
    var isDoubleBufferFBOMode = false
    var alternateFBO: GLuint = 0                    // 3D games may render into this FBO which is blit into the IOSurface.
                                                    // Used if game accidentally syncs surface.
    var tempRB = [GLuint](repeating: 0, count: 2)   // Color and depth buffers backing alternate FBO.
    
    // Alternate-thread rendering (3D mode)
    var alternateContext: CGLContextObj?
    var renderingThreadCanProceed   = DispatchSemaphore(value: 0)
    var executeThreadCanProceed     = DispatchSemaphore(value: 0)
    
    var isFPSLimiting = ManagedAtomic(0)
    
    init(withInteropTexture texture: CoreVideoTexture, gameCore: OEGameCore) {
        self.texture    = texture
        self.gameCore   = gameCore
    }
    
    deinit {
        if alternateContext != nil {
            renderingThreadCanProceed.signal()
        }
        destroyGLResources()
    }
    
    var surfaceSize: OEIntSize {
        .init(width: Int32(texture.size.width), height: Int32(texture.size.height))
    }
    
    func update() {
        destroyGLResources()
        setupVideo()
    }
    
    // 3D games can only change buffer size.
    // We'll be in trouble if a game core does software vector drawing.
    // TODO: Test alternate threads - might need to call glViewport() again on that thread.
    // TODO: Implement for double buffered FBO - need to reallocate alternateFBO.
    var canChangeBufferSize: Bool = true
    
    var presentationFramebuffer: Any? {
        isDoubleBufferFBOMode ? alternateFBO : coreVideoFBO
    }
    
    private func setupVideo() {
        setupGLContext()
        setupFramebuffer()
        
        if gameCore.needsDoubleBufferedFBO {
            setupDoubleBufferedFBO()
        } else if gameCore.hasAlternateRenderingThread {
            setupAlternateRenderingThread()
        }
        
        clearFramebuffer()
        glFlushRenderAPPLE()
    }
    
    static let attributes: [CGLPixelFormatAttribute] = [
        kCGLPFAAccelerated,
        kCGLPFAAllowOfflineRenderers,
        kCGLPFANoRecovery,
        kCGLPFAColorSize, CGLPixelFormatAttribute(24),
        kCGLPFADepthSize, CGLPixelFormatAttribute(24),
        CGLPixelFormatAttribute(0),
    ]
    
    private func setupGLContext() {
        var numPixelFormats: GLint = 0
        var err = CGLChoosePixelFormat(Self.attributes, &glPixelFormat, &numPixelFormats)
        if err != kCGLNoError {
            os_log(.error, log: .renderer,
                   "Error choosing pixel format %{public}s",
                   CGLErrorString(err))
            NSApp.terminate(nil)
        }
        
        err = CGLCreateContext(glPixelFormat, nil, &glContext)
        if err != kCGLNoError {
            os_log(.error, log: .renderer,
                   "Error creating context %{public}s",
                   CGLErrorString(err))
            NSApp.terminate(nil)
        }
        
        CGLSetCurrentContext(glContext)
        texture.openGLContext = glContext
    }
    
    private func setupFramebuffer() {
        glGenFramebuffersEXT(1, &coreVideoFBO)
        glBindFramebufferEXT(GLenum(GL_FRAMEBUFFER), coreVideoFBO)
        glFramebufferTexture2DEXT(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_TEXTURE_RECTANGLE_ARB), texture.openGLTexture, 0)
        var status = glGetError()
        if status != 0 {
            os_log(.error, log: .renderer,
            "Setup failed: create interop texture FBO 1, OpenGL error %04X",
            status)
        }

        // Complete the FBO
        glGenRenderbuffersEXT(1, &depthStencilRB)
        glBindRenderbufferEXT(GLenum(GL_RENDERBUFFER_EXT), depthStencilRB)
        glRenderbufferStorage(GLenum(GL_RENDERBUFFER_EXT), GLenum(GL_DEPTH24_STENCIL8), GLsizei(texture.size.width), GLsizei(texture.size.height))
        glFramebufferRenderbufferEXT(GLenum(GL_FRAMEBUFFER_EXT), GLenum(GL_DEPTH_STENCIL_ATTACHMENT), GLenum(GL_RENDERBUFFER_EXT), depthStencilRB)
        status = glGetError()
        if status != 0 {
            os_log(.error, log: .renderer,
                   "Setup failed: create ioSurface FBO 2, OpenGL error %04X",
                   status)
        }

        status = glCheckFramebufferStatusEXT(GLenum(GL_FRAMEBUFFER_EXT))
        if status != GL_FRAMEBUFFER_COMPLETE_EXT {
            os_log(.error, log: .renderer,
                   "Cannot create FBO, OpenGL error %04X",
                   status)
        }
    }
    
    private func setupAlternateRenderingThread() {
        if alternateContext == nil {
            CGLCreateContext(glPixelFormat, glContext, &alternateContext)
        }
        
        os_log(.debug, log: .renderer, "Setup GL2.1 3D 'alternate-threaded' rendering")
    }
    
    private func setupDoubleBufferedFBO() {
        // Clear the other one while we're on this one.
        clearFramebuffer()
        
        glGenFramebuffersEXT(1, &alternateFBO)
        glBindFramebufferEXT(GLenum(GL_FRAMEBUFFER_EXT), alternateFBO)
        
        glGenRenderbuffersEXT(2, &tempRB)
        glBindRenderbufferEXT(GLenum(GL_RENDERBUFFER_EXT), tempRB[0])
        glRenderbufferStorage(GLenum(GL_RENDERBUFFER_EXT), GLenum(GL_RGB8), GLsizei(texture.size.width), GLsizei(texture.size.height))
        glFramebufferRenderbufferEXT(GLenum(GL_FRAMEBUFFER_EXT), GLenum(GL_COLOR_ATTACHMENT0_EXT), GLenum(GL_RENDERBUFFER_EXT), tempRB[0])

        glBindRenderbufferEXT(GLenum(GL_RENDERBUFFER_EXT), tempRB[1])
        glRenderbufferStorage(GLenum(GL_RENDERBUFFER_EXT), GLenum(GL_DEPTH32F_STENCIL8), GLsizei(texture.size.width), GLsizei(texture.size.height))
        glFramebufferRenderbufferEXT(GLenum(GL_FRAMEBUFFER_EXT), GLenum(GL_DEPTH_STENCIL_ATTACHMENT), GLenum(GL_RENDERBUFFER_EXT), tempRB[1])

        let status = glCheckFramebufferStatusEXT(GLenum(GL_FRAMEBUFFER_EXT))
        if status != GL_FRAMEBUFFER_COMPLETE_EXT {
            os_log(.error, log: .renderer, "Cannot create temp FBO. OpenGL error %04X", status)

            glDeleteFramebuffersEXT(1, &alternateFBO)
        }

        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))

        isDoubleBufferFBOMode = true

        os_log(.debug, log: .renderer, "Setup GL2.1 3D 'double-buffered FBO' rendering")
    }
    
    private func clearFramebuffer() {
        glClearColor(0.0, 0.0, 0.0, 0.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
    }
    
    private func bindFBO(_ fbo: GLuint) {
        // Bind our FBO / and thus our IOSurface
        glBindFramebufferEXT(GLenum(GL_FRAMEBUFFER_EXT), fbo)
        // Assume FBOs JUST WORK, because we checked on startExecution
        var status = glGetError()
        if status != 0 {
            os_log(.error, log: .renderer, "bindFBO: OpenGL error %04X", status)
        }

        status = glCheckFramebufferStatusEXT(GLenum(GL_FRAMEBUFFER_EXT))
        if status != GL_FRAMEBUFFER_COMPLETE_EXT {
            os_log(.error, log: .renderer, "OpenGL error %04X in draw, check FBO", status)
        }
    }
    
    func presentDoubleBufferedFBO() {
        glBindFramebufferEXT(GLenum(GL_READ_FRAMEBUFFER_EXT), alternateFBO)
        glBindFramebufferEXT(GLenum(GL_DRAW_FRAMEBUFFER_EXT), coreVideoFBO)

        glBlitFramebufferEXT(0, 0, GLint(texture.size.width), GLint(texture.size.height),
                             0, 0, GLint(texture.size.width), GLint(texture.size.height), GLbitfield(GL_COLOR_BUFFER_BIT), GLenum(GL_NEAREST))
        let status = glGetError()
        if status != 0 {
            os_log(.error, log: .renderer, "glBlitFramebufferEXT: OpenGL error %04X", status)
        }

        glBindFramebufferEXT(GLenum(GL_FRAMEBUFFER_EXT), alternateFBO)
    }
    
    private func destroyGLResources() {
        if let glContext = glContext {
            if let alternateContext = alternateContext {
                CGLReleaseContext(alternateContext)
            }
            CGLReleasePixelFormat(glPixelFormat)
            CGLReleaseContext(glContext)
        }
        
        alternateContext        = nil
        texture.openGLContext   = nil
        glContext               = nil
        glPixelFormat           = nil
    }

    func resumeFPSLimiting() {
        guard isFPSLimiting.load(ordering: .sequentiallyConsistent) != 1
        else { return }
        
        isFPSLimiting.wrappingIncrement(ordering: .sequentiallyConsistent)
    }
    
    func suspendFPSLimiting() {
        guard isFPSLimiting.load(ordering: .sequentiallyConsistent) != 0
        else { return }
        
        isFPSLimiting.wrappingDecrement(ordering: .sequentiallyConsistent)
    }

    func willExecuteFrame() {
        if alternateContext != nil {
            // Tell the rendering thread to go ahead.
            if isFPSLimiting.load(ordering: .sequentiallyConsistent) != 0 {
                renderingThreadCanProceed.signal()
            }
            return
        }
        
        CGLSetCurrentContext(glContext)
        bindFBO(isDoubleBufferFBOMode ? alternateFBO : coreVideoFBO)
        
        // Save state in case the game messes it up.
        glPushAttrib(GLenum(GL_ALL_ATTRIB_BITS))
        glPushClientAttrib(GLenum(GL_CLIENT_ALL_ATTRIB_BITS))
    }
    
    func didExecuteFrame() {
        if alternateContext != nil {
            // Wait for the rendering thread to complete this frame.
            // Most cores with rendering threads don't seem to handle timing themselves - they're probably relying on Vsync.
            if isFPSLimiting.load(ordering: .sequentiallyConsistent) != 0 {
                executeThreadCanProceed.wait()
            }

            // Don't do any other work.
            return
        }
        
        // Reset anything the core did.
        glPopAttrib()
        glPopClientAttrib()

        // Update the IOSurface.
        glFlushRenderAPPLE()
    }
    
    func willRenderFrameOnAlternateThread() {
        CGLSetCurrentContext(alternateContext)
        bindFBO(isDoubleBufferFBOMode ? alternateFBO : coreVideoFBO)
    }
    
    func didRenderFrameOnAlternateThread() {
        // Update the IOSurface.
        glFlushRenderAPPLE()

        // Do FPS limiting, but only once setup is over.
        if isFPSLimiting.load(ordering: .sequentiallyConsistent) != 0 {
            // Technically the above should be a glFinish(), but I'm hoping the GPU work
            // is fast enough that it's not needed.
            executeThreadCanProceed.signal()

            // Wait to be allowed to start next frame.
            renderingThreadCanProceed.wait()
        }
    }
}
