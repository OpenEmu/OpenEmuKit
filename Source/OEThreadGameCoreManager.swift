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
import OpenEmuKitPrivate

@objc public class OEThreadGameCoreManager: GameCoreManager {
    var helperThread: Thread!
    var dummyTimer: Timer!
    
    var helper: OpenEmuHelperApp!
    
    typealias StopHandler = () -> Void
    var stopHandler: StopHandler?
    
    public override func loadROM(completionHandler: @escaping () -> Void, errorHandler: @escaping (Error) -> Void) {
        loadROM { error in
            if let error = error {
                errorHandler(error)
            } else {
                completionHandler()
            }
        }
    }
    
    public override func loadROM(completionHandler: @escaping StartupCompletionHandler) {
        helperThread = Thread {
            self.execute(completionHandler: completionHandler)
        }
        helperThread.name = "org.openemu.core-manager-thread"
        helperThread.qualityOfService = .userInitiated
        
        helper = .init()
        
        if let proxy = OEThreadProxy(target: gameCoreOwner, thread: .main) as? OEGameCoreOwner {
            helper.gameCoreOwner = proxy
        } else {
            fatalError("Unable to cast to OEGameCoreOwner proxy")
        }

        helperThread.start()
    }
    
    public override func stopEmulation(completionHandler handler: @escaping () -> Void) {
        stopHandler = handler
        gameCoreHelper?.stopEmulation {
            self.stop()
        }
    }
    
    override func stop() {
        if Thread.current == helperThread {
            stopHelperThread(nil)
        } else {
            perform(#selector(stopHelperThread(_:)), on: helperThread, with: nil, waitUntilDone: false)
        }
    }
    
    private func execute(completionHandler handler: @escaping StartupCompletionHandler) {
        autoreleasepool {
            do {
                if let proxy = OEThreadProxy(target: helper, thread: .current) as? OEGameCoreHelper {
                    gameCoreHelper = proxy
                } else {
                    fatalError("Unable to cast to OEGameCoreHelper proxy")
                }

                try helper.load(withStartupInfo: startupInfo)
                RunLoop.main.perform {
                    handler(nil)
                }
                
                dummyTimer = .scheduledTimer(withTimeInterval: 1e9, repeats: true, block: { _ in })
                
                CFRunLoopRun()
                
                if let stopHandler = stopHandler {
                    RunLoop.main.perform(stopHandler)
                }
                notifyGameCoreDidTerminate()
            } catch {
                RunLoop.main.perform {
                    handler(error)
                }
            }
        }
    }

    @objc private func stopHelperThread(_ id: Any?) {
        dummyTimer.invalidate()
        dummyTimer = nil
        
        CFRunLoopStop(CFRunLoopGetCurrent())
        
        gameCoreHelper  = nil
        helperThread    = nil
        helper          = nil
    }
}
