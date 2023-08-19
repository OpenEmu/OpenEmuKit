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

import AppKit

@objc extension NSWindow {
    final public func maximumIntegralScale(forSize size: NSSize) -> Int {
        guard let screen = screen ?? NSScreen.main else { return 1 }
        let maxContentSize = contentRect(forFrameRect: screen.visibleFrame).size
        return OEIntegralWindowResizing.maximumIntegralScale(forContentSize: maxContentSize, withScreenSize: size)
    }
}

@objc final public class OEIntegralWindowResizing: NSObject {
    @objc public static func maximumIntegralScale(forContentSize contentSize: NSSize, withScreenSize size: NSSize) -> Int {
        let maxScale = max(
            min((contentSize.height / size.height).rounded(.down),
                (contentSize.width / size.width).rounded(.down)),
            1)
        
        return Int(maxScale)
    }
    
    @objc public static func integralScaleForSize(_ size: CGSize, withScreenSize screenSize: CGSize) -> NSNumber? {
        guard size.width.remainder(dividingBy: screenSize.width) == 0,
              size.height.remainder(dividingBy: screenSize.height) == 0
        else { return nil }
        
        guard
            let scaleWidth  = Int(exactly: size.width /  screenSize.width),
            let scaleHeight = Int(exactly: size.height / screenSize.height)
        else { return nil }
        
        return scaleWidth == scaleHeight ? NSNumber(value: scaleWidth) : nil
    }
    
    /// Calculate the integral scale of the `proposed` size with respect to the `existing` size, using `screenSize` as the basis
    /// - Parameters:
    ///   - existing: <#existing description#>
    ///   - proposed: <#proposed description#>
    ///   - screenSize: <#screenSize description#>
    /// - Returns: The integral scale or -1 if the `proposed` and `existing` sizes are almost equal
    @objc public static func integralScale(existing: CGSize, proposed: CGSize, screenSize: CGSize) -> Int {
        if let size = integralScale(existing: existing, proposed: proposed, screenSize: screenSize) {
            return size
        }
        return -1
    }
    
    static func integralScale(existing: CGSize, proposed: CGSize, screenSize: CGSize) -> Int? {
        // determine if a single axis is being resized
        let deltaX = abs(existing.width - proposed.width)
        let deltaY = abs(existing.height - proposed.height)
        if !deltaX.isNormal && !deltaY.isNormal {
            return nil
        }
        
        var scale = CGFloat(1)
        let scaleX = round(proposed.width  / screenSize.width)
        let scaleY = round(proposed.height / screenSize.height)
        
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
}

@objc final public class OEIntegralWindowResizingDelegate: NSObject {
    var tracking: Bool = false
    
    var lastSize: NSSize = .zero
    
    /// specifies the number of points the size must change to trigger the snap
    var distance: CGFloat = 25
    
    @objc public var screenSize: NSSize = .zero
    @objc public var currentScale: Int = 1
    var maximumIntegralScale: Int = 1
    
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

@objc extension OEIntegralWindowResizingDelegate: NSWindowDelegate {
    public func windowWillStartLiveResize(_ notification: Notification) {
        guard
            !screenSize.equalTo(.zero),
            let window = notification.object as? NSWindow
        else { return }
        
        tracking = true
        lastSize = window.frame.size
        maximumIntegralScale = window.maximumIntegralScale(forSize: screenSize)
    }
    
    public func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        guard tracking else { return frameSize }
        
        let existing = sender.frame.size
        
        if let proposedScale = OEIntegralWindowResizing.integralScale(existing: existing, proposed: frameSize, screenSize: screenSize),
           proposedScale != currentScale && proposedScale <= maximumIntegralScale {
            currentScale = proposedScale
            return self.frameSize(for: sender, integralScale: currentScale)
        }
        return existing
    }
    
    public func windowDidEndLiveResize(_ notification: Notification) {
        tracking = false
    }
}
