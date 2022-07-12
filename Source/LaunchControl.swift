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
import OpenEmuKitPrivate

/// `LaunchControl` provides programmatic access to `launchctl` commands.
public struct LaunchControl {
    
    /// Unloads the specified service name from launchd.
    ///
    /// A use case is to remove application-specific xpc services at exit of an application. This
    /// allows the application bundle to be moved around and the xpc service will be automatically
    /// registered with `launchd` each time the application is opened.
    /// 
    /// - Parameter name: The name of the service.
    ///
    /// - Throws: `POSIXError` if the command fails.
    /// - Throws: `NSError` if the `launchctl` command is inaccessible.
    public static func remove(service name: String) throws {
        try run("remove", args: name)
    }
    
    private static func run(_ cmd: String, args: String...) throws {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        p.arguments = [cmd] + args
        try p.run()
        p.waitUntilExit()
        if p.terminationStatus == 0 {
            return
        }
        
        if let code = POSIXErrorCode(rawValue: p.terminationStatus) {
            throw POSIXError(code)
        }
        
        // TODO: Should throw a generic error
    }
}
