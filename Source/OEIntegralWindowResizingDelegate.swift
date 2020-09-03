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

import Cocoa

@objc public class OEIntegralWindowResizingDelegate: NSObject, NSWindowDelegate {
    var tracking: Bool = false
    var initialSize: NSSize = .zero
    
    @objc public var screenSize: NSSize = .zero
    @objc public var currentScale: Int = 1
    var maximumIntegralScale: Int = 1
    
    @objc static public func maximumIntegralScale(forWindow window: NSWindow, withScreenSize size: NSSize) -> Int {
        guard let screen = window.screen ?? NSScreen.main else { return 1 }
        
        let maxContentSize = window.contentRect(forFrameRect: screen.visibleFrame).size
        let maxScale = max(min(floor(maxContentSize.height / size.height),
                               floor(maxContentSize.width / size.width)),
                           1)
        
        return Int(maxScale)
        
    }
    
    @objc public func windowWillStartLiveResize(_ notification: Notification) {
        guard
            !screenSize.equalTo(.zero),
            let window = notification.object as? NSWindow
        else { return }
        
        tracking = true
        initialSize = window.frame.size
        maximumIntegralScale = Self.maximumIntegralScale(forWindow: window, withScreenSize: screenSize)
    }
    
    @objc public func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        guard tracking else { return frameSize }
        
        let existing = sender.frame.size
        if let proposedScale = integralScale(existing: existing, proposed: frameSize),
           proposedScale != currentScale && proposedScale <= maximumIntegralScale
        {
            currentScale = proposedScale
            return self.frameSize(for: sender, integralScale: currentScale)
        }
        return existing
    }
    
    @objc public func windowDidEndLiveResize(_ notification: Notification) {
        tracking = false
    }
    
    func integralScale(existing: CGSize, proposed: CGSize) -> Int?
    {
        // determine if a single axis is being resized
        let deltaX = abs(existing.width - proposed.width)
        let deltaY = abs(existing.height - proposed.height)
        if !deltaX.isNormal && !deltaY.isNormal {
            return nil
        }
        
        var scale = CGFloat(1)
        let scaleX = round(proposed.width  / screenSize.width);
        let scaleY = round(proposed.height / screenSize.height);
        
        if !deltaY.isNormal {
            // resizing X axis
            scale = scaleX
        } else if !deltaX.isNormal {
            // resizing Y axis
            scale = scaleY
        } else {
            // else same, pick the larger?
            scale = max(scaleX, scaleY)
        }
        
        return max(Int(scale), 1)
    }
    
    @objc public func windowContentSize(forIntegralScale scale: Int) -> NSSize {
        let scale = CGFloat(scale)
        return screenSize.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
    
    
    /// Returns the window frame size derived from `screenSize` for the specified `integralScale`.
    ///
    /// Returns an `NSSize` which ensures the content size is a multiple of `screenSize`.
    ///
    /// - Parameters:
    ///   - window: The source window used to determine the new frame size, accounting for style mask and other attributes which affect the final frame.
    ///   - scale: The desired scale.
    /// - Returns: A frame
    @objc public func frameSize(for window: NSWindow, integralScale scale: Int) -> NSSize {
        let contentSize = windowContentSize(forIntegralScale: scale)
        let windowFrame = window.frameRect(forContentRect: NSRect(origin: .zero, size: contentSize))
        return windowFrame.size
    }
}
