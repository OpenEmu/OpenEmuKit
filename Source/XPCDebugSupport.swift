// Copyright (c) 2021, OpenEmu Team
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
import Darwin

public class XPCDebugSupport {
    
    /// Returns a value indicating whether a debugger is attached to the current process
    public static var isDebuggerAttached: Bool {
        let keys = [CTL_KERN, KERN_PROC, KERN_PROC_PID, Int32(getpid())]
        return keys.withUnsafeBufferPointer { keysPtr -> Bool in
            var info = kinfo_proc()
            info.kp_proc.p_flag = 0
            
            var size = MemoryLayout.size(ofValue: info)
            let res = Darwin.sysctl(UnsafeMutablePointer<Int32>(mutating: keysPtr.baseAddress), UInt32(keys.count), &info, &size, nil, 0)
            // Assume no debugger if sysctl fails
            guard res == 0 else { return false }
            
            return (info.kp_proc.p_flag & P_TRACED) != 0
        }
    }
    
    /// Wait until a debuger is attached for a specific amount of time.
    /// - Parameter time: The time to wait for a debugger to be attached.
    /// - Returns: A value indicating whether the debugger is attached.
    @discardableResult public static func waitForDebugger(until time: Date = .distantFuture) -> Bool {
        while !isDebuggerAttached && Date() < time {
            // check every 100ms
            Thread.sleep(forTimeInterval: 0.100)
        }
        return isDebuggerAttached
    }
}
