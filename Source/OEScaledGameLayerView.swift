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
import OpenEmuKitPrivate

@objc public class OEScaledGameLayerView: NSView {
    var contentViewConstraints = [NSLayoutConstraint]()
    
    @objc public var contentView: NSView? {
        willSet {
            guard let view = contentView else { return }
            view.removeFromSuperview()
            contentViewConstraints.removeAll(keepingCapacity: true)
        }
        
        didSet {
            guard let view = contentView else { return }
            
            subviews.insert(view, at: 0)
            setContentViewSizeFill(animated: false)
        }
    }
    
    public override var isOpaque: Bool {
        return true
    }
    
    /// Specifies the size of the content view and optionally animates the change.
    /// - Parameters:
    ///   - size: The new size of the contentView. Sending `NSSize.zero` will cause the view to fill the parent.
    ///   - animated: `true` to animate the change in size.
    @objc public func setContentViewSize(_ size: NSSize, animated: Bool) {
        let size = size == .zero ? bounds.size : size
        // do not animate size change if 'Reduce motion' accessibility setting is enabled
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        let animated = reduceMotion ? false : animated
        
        guard let view = contentView else { return }
        if contentViewConstraints.isEmpty {
            view.translatesAutoresizingMaskIntoConstraints = false
            let frameSize = view.frame.size
            contentViewConstraints.append(contentsOf: [
                view.widthAnchor.constraint(equalToConstant: frameSize.width),
                view.heightAnchor.constraint(equalToConstant: frameSize.height),
                view.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                view.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            ])
            NSLayoutConstraint.activate(contentViewConstraints)
        }
        
        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.250
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                
                contentViewConstraints[0].animator().constant = size.width
                contentViewConstraints[1].animator().constant = size.height
            }
        } else {
            contentViewConstraints[0].constant = size.width
            contentViewConstraints[1].constant = size.height
        }
    }
    
    @objc public func setContentViewSizeFill(animated: Bool) {
        guard let view = contentView else { return }
        
        NSLayoutConstraint.deactivate(contentViewConstraints)
        contentViewConstraints.removeAll(keepingCapacity: true)
        view.autoresizingMask = [.width, .height]
        view.translatesAutoresizingMaskIntoConstraints = true
        view.frame = bounds
    }
}
