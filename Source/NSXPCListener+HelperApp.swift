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
import OSLog

extension NSXPCListener {
    private static var helperIdentifierFromArguments: String? {
        ProcessInfo.processInfo
            .arguments
            // find the first argument with the helper identifier option
            .first { $0.hasPrefix(NSXPCConnection.helperIdentifierArgumentPrefix) }
            // trim the prefix to return just the identifier
            .map { String($0.suffix(from: NSXPCConnection.helperIdentifierArgumentPrefix.endIndex)) }
    }
    
    static func makeHelperListener(serviceName name: String) throws -> NSXPCListener {
        guard let identifier = Self.helperIdentifierFromArguments else {
            fatalError("Expected to find helper identifier")
        }
        
        os_log(.info, log: .helper, "Registering helper listener endpoint with broker. { id = %{public}@ }", identifier)
        
        let cn = NSXPCConnection(serviceName: name)
        cn.invalidationHandler = {
            os_log(.error, log: .helper, "Broker connection was unexpectedely invalidated.")
        }
        
        cn.remoteObjectInterface = .init(with: OEXPCMatchMaking.self)
        cn.resume()
        
        // swiftlint: disable identifier_name
        let mm_ = cn.remoteObjectProxyWithErrorHandler { error in
            os_log(.error, log: .helper, "Error waiting for reply from OEXPCMatchMaking. { error = %{public}@ }", error.localizedDescription)
        } as? OEXPCMatchMaking
        
        guard let mm = mm_ else {
            os_log(.error, log: .helper, "Unexpected nil for OEXPCMatchMaking proxy.")
            fatalError("Unexpected nil for OEXPCMatchMaking proxy.")
        }
        
        let sem = DispatchSemaphore(value: 0)
        
        let listener = NSXPCListener.anonymous()
        mm.register(listener.endpoint, forIdentifier: identifier) {
            os_log(.info, log: .helper, "Successfully connected helper to host. { id = '%{public}@' }", identifier)
            sem.signal()
        }
        
        #if XPC_WAIT_FOREVER
        sem.wait()
        #else
        if sem.wait(timeout: .now() + .seconds(2)) == .timedOut {
            // mediation of connection between host and helper via broker timed out
            os_log(.error, log: .helper, "Timeout waiting for host connection.")
            listener.invalidate()
            fatalError("Timeout waiting for host connection.")
        }
        #endif
        
        cn.invalidationHandler = nil
        cn.invalidate()
        
        return listener
    }
}
