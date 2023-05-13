// Copyright (c) 2017-2021, OpenEmu Team
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
import QuartzCore

import OpenEmuBase
import OpenEmuSystem
import OpenEmuKitPrivate

public protocol OEGameViewDelegate: NSObjectProtocol {
    func gameView(_ gameView: OEGameLayerView, didReceiveMouseEvent event: OEEvent)
    func gameView(_ gameView: OEGameLayerView, updateBounds newBounds: CGRect)
    func gameView(_ gameView: OEGameLayerView, updateBackingScaleFactor newScaleFactor: CGFloat)
}

/// View which hosts and resizes the helper app’s game rendering.
/// NOTE: If this was tvOS, we'd set a preferred frame rate here. Can we do that?
public class OEGameLayerView: NSView, CALayerDelegate {
    
    public weak var delegate: OEGameViewDelegate?
    
    private var remoteLayer: CALayerHost?
    private var trackingArea: NSTrackingArea?
    private(set) var aspectCorrectedScreenSize = CGSize.zero
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    override public init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    private func commonInit() {
        wantsLayer = true
        layerContentsRedrawPolicy = .beforeViewResize
    }
    
    public override var wantsUpdateLayer: Bool {
        return true
    }
    
    public override var isOpaque: Bool {
        return true
    }
    
    public override func makeBackingLayer() -> CALayer {
        let layer = super.makeBackingLayer()
        layer.contentsGravity = .resize
        layer.backgroundColor = NSColor.black.cgColor
        
        if let remoteContextID = remoteContextID {
            updateTopLayer(layer, with: remoteContextID)
        }
        return layer
    }
    
    public override func updateLayer() {
        super.updateLayer()
        delegate?.gameView(self, updateBounds: bounds)
    }
    
    func updateTopLayer(_ layer: CALayer, with remoteContextID: OEContextID) {
        if remoteLayer == nil {
            remoteLayer = CALayerHost()
            
            layer.addSublayer(remoteLayer!)
        }
        
        remoteLayer!.contextId = remoteContextID
        remoteLayer!.delegate = self
        updateLayer()
    }
    
    // MARK: - View Scaling
    
    public func setScreenSize(_ newScreenSize: OEIntSize, aspectSize newAspectSize: OEIntSize) {
        let correct = newScreenSize.corrected(forAspectSize: newAspectSize)
        aspectCorrectedScreenSize = CGSize(width: Int(correct.width), height: Int(correct.height))
    }
    
    // MARK: - APIs
    
    public var remoteContextID: OEContextID? {
        didSet {
            if let layer = layer, let remoteContextID = remoteContextID {
                updateTopLayer(layer, with: remoteContextID)
            }
        }
    }
    
    // MARK: - NSResponder
    
    public override var acceptsFirstResponder: Bool {
        return true
    }
    
    public override func keyDown(with event: NSEvent) {
    }
    
    public override func keyUp(with event: NSEvent) {
    }
    
    public override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }
        trackingArea = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .mouseMoved, .activeInKeyWindow], owner: self)
        addTrackingArea(trackingArea!)
    }
    
    private func mouseEvent(with event: NSEvent) -> OEEvent {
        let frame = frame
        var location = event.locationInWindow
        location = convert(location, from: nil)
        location.y = frame.height - location.y
        
        var screenRect = CGRect(origin: .zero, size: aspectCorrectedScreenSize)
        
        let scale = min(frame.width / screenRect.width, frame.height / screenRect.height)
        
        screenRect.size.width *= scale
        screenRect.size.height *= scale
        screenRect.origin.x = frame.midX - frame.origin.x - screenRect.width / 2
        screenRect.origin.y = frame.midY - frame.origin.y - screenRect.height / 2
        
        location.x -= screenRect.origin.x
        location.y -= screenRect.origin.y
        
        let x = max(0, min(round(location.x * aspectCorrectedScreenSize.width / screenRect.width), aspectCorrectedScreenSize.width))
        let y = max(0, min(round(location.y * aspectCorrectedScreenSize.height / screenRect.height), aspectCorrectedScreenSize.height))
        let point = OEIntPoint(x: Int32(x), y: Int32(y))
        
        return OEEvent(mouseEvent: event, locationInGameView: point)
    }
    
    public override func mouseDown(with event: NSEvent) {
        delegate?.gameView(self, didReceiveMouseEvent: mouseEvent(with: event))
    }
    
    public override func rightMouseDown(with event: NSEvent) {
        delegate?.gameView(self, didReceiveMouseEvent: mouseEvent(with: event))
    }
    
    public override func otherMouseDown(with event: NSEvent) {
        delegate?.gameView(self, didReceiveMouseEvent: mouseEvent(with: event))
    }
    
    public override func mouseUp(with event: NSEvent) {
        delegate?.gameView(self, didReceiveMouseEvent: mouseEvent(with: event))
    }
    
    public override func rightMouseUp(with event: NSEvent) {
        delegate?.gameView(self, didReceiveMouseEvent: mouseEvent(with: event))
    }
    
    public override func otherMouseUp(with event: NSEvent) {
        delegate?.gameView(self, didReceiveMouseEvent: mouseEvent(with: event))
    }
    
    public override func mouseMoved(with event: NSEvent) {
        delegate?.gameView(self, didReceiveMouseEvent: mouseEvent(with: event))
    }
    
    public override func mouseDragged(with event: NSEvent) {
        delegate?.gameView(self, didReceiveMouseEvent: mouseEvent(with: event))
    }
    
    public override func scrollWheel(with event: NSEvent) {
        delegate?.gameView(self, didReceiveMouseEvent: mouseEvent(with: event))
    }
    
    public override func rightMouseDragged(with event: NSEvent) {
        delegate?.gameView(self, didReceiveMouseEvent: mouseEvent(with: event))
    }
    
    public override func otherMouseDragged(with event: NSEvent) {
        delegate?.gameView(self, didReceiveMouseEvent: mouseEvent(with: event))
    }
    
    public override func mouseEntered(with event: NSEvent) {
        delegate?.gameView(self, didReceiveMouseEvent: mouseEvent(with: event))
    }
    
    public override func mouseExited(with event: NSEvent) {
        delegate?.gameView(self, didReceiveMouseEvent: mouseEvent(with: event))
    }
}

extension OEGameLayerView: NSViewLayerContentScaleDelegate {
    public func layer(_ layer: CALayer, shouldInheritContentsScale newScale: CGFloat, from window: NSWindow) -> Bool {
        delegate?.gameView(self, updateBackingScaleFactor: newScale)
        return true
    }
}
