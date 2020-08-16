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

import Foundation

@objc
public class OEXPCMatchMaker: NSObject {
    
    let listenerQueue = DispatchQueue(label: "com.psychoinc.MatchMaker.ListenerQueue")
    let listener: NSXPCListener
    
    var pendingClients = [String: ClientHandler]()
    var pendingListeners = [String: MatchMakerListener]()
    
    public override init() {
        listener = NSXPCListener.service()
        
        super.init()
        
        listener.delegate = self
    }
    
    @objc public func resume() {
        listener.resume()
    }
    
    typealias ClientHandler = (NSXPCListenerEndpoint) -> Void
    
    struct MatchMakerListener {
        let endpoint: NSXPCListenerEndpoint
        let handler: () -> Void
    }
}

extension OEXPCMatchMaker: OEXPCMatchMaking {
    public func register(_ endpoint: NSXPCListenerEndpoint, forIdentifier identifier: String, completionHandler handler: @escaping () -> Void) {
        listenerQueue.async {
            if let client = self.pendingClients.removeValue(forKey: identifier) {
                client(endpoint)
                handler()
            } else {
                self.pendingListeners[identifier] = MatchMakerListener(endpoint: endpoint, handler: handler)
            }
        }
    }
    
    public func retrieveListenerEndpoint(forIdentifier identifier: String, completionHandler handler: @escaping (NSXPCListenerEndpoint) -> Void) {
        listenerQueue.async {
            if let listener = self.pendingListeners.removeValue(forKey: identifier) {
                handler(listener.endpoint)
                listener.handler()
            } else {
                self.pendingClients[identifier] = handler
            }
        }
    }
}

extension OEXPCMatchMaker: NSXPCListenerDelegate {
    public func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: OEXPCMatchMaking.self)
        newConnection.exportedObject = self
        newConnection.resume()
        return true
    }
}
