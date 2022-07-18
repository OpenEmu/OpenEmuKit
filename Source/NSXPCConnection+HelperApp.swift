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

extension NSXPCConnection {
    struct BrokerError: Error, LocalizedError {
        var errorDescription: String? { 
            NSLocalizedString("Failed to launch helper app", comment: "")
        }
        let failureReason: String?
    }
    
    static let helperIdentifierArgumentPrefix = "--org.openemu.broker.id="
    private static var xpcTaskKey = 0
    
    static func makeConnection(serviceName name: String, executableURL url: URL) throws -> NSXPCConnection {
        let identifier = UUID().uuidString
        
        /// 1. Launch Helper App
        /// This results in the helper app establishing a connection to the broker and registering its
        /// `identifier`
        let task = Process()
        task.executableURL = url
        task.arguments = ["\(Self.helperIdentifierArgumentPrefix)\(identifier)"]
        task.terminationHandler = { task in
            os_log(.error, log: .helper,
                   "Helper terminated unexpectedly. { id = %{public}@, reason = %ld, exit = %d }",
                   identifier,
                   task.terminationReason.rawValue,
                   task.terminationStatus)
        }
        task.standardError  = FileHandle.standardError
        task.standardOutput = FileHandle.standardOutput
        do {
            try task.run()
        } catch {
            throw BrokerError(failureReason: error.localizedDescription)
        }
        
        var success = false
        defer {
            // Terminate helper when broker connection fails
            if !success {
                os_log(.error, log: .helper,
                       "Terminating helper; failed to complete handshake. { id = %{public}@ }",
                       identifier)
                task.terminationHandler = nil
                task.terminate()
            }
        }
        
        /// 2. Launch a connection to the broker
        let cn = NSXPCConnection(serviceName: name)
        cn.invalidationHandler = {
            os_log(.error, log: .helper, "Broker connection was unexpectedely invalidated.")
        }
        
        cn.remoteObjectInterface = .init(with: OEXPCMatchMaking.self)
        cn.resume()
        
        // swiftlint:disable:next identifier_name
        let mm_ = cn.remoteObjectProxyWithErrorHandler { error in
            os_log(.error, log: .helper, "Error waiting for reply from OEXPCMatchMaking. { error = %{public}@ }", error.localizedDescription)
        } as? OEXPCMatchMaking
        
        guard let mm = mm_ else {
            os_log(.error, log: .helper, "Unexpected nil for OEXPCMatchMaking proxy.")
            throw BrokerError(failureReason: NSLocalizedString("OEXPCMatchMaking proxy was nil", comment: ""))
        }
        
        let sem = DispatchSemaphore(value: 0)
        var endpoint: NSXPCListenerEndpoint?
        mm.retrieveListenerEndpoint(forIdentifier: identifier) { ep in
            endpoint = ep
            sem.signal()
        }
        
#if XPC_WAIT_FOREVER
        sem.wait()
#else
        if sem.wait(timeout: .now() + .seconds(2)) == .timedOut {
            // mediation of connection between host and helper via broker timed out
            os_log(.error, log: .helper, "Timeout waiting for listener endpoint from broker.")
            
            throw BrokerError(failureReason: NSLocalizedString("Timeout waiting for connection from helper app", comment: ""))
        }
        
#endif
        
        cn.invalidationHandler = nil
        cn.invalidate()
        
        guard let listenerEndpoint = endpoint else {
            throw BrokerError(failureReason: NSLocalizedString("Broker endpoint is nil", comment: ""))
        }
        
        guard task.isRunning else {
            throw BrokerError(failureReason: NSLocalizedString("Helper unexpectedly terminated", comment: ""))
        }
        
        let newCn = NSXPCConnection(listenerEndpoint: listenerEndpoint)
        
        task.terminationHandler = { [weak newCn] task in
            os_log(.debug, log: .helper,
                   "Helper terminated. { id = %{public}@, exit = %d }.",
                   identifier,
                   task.terminationStatus)
            newCn?.invalidate()
        }
        
        objc_setAssociatedObject(newCn, &Self.xpcTaskKey, task, .OBJC_ASSOCIATION_RETAIN)
        
        success = true
        return newCn
    }
}
