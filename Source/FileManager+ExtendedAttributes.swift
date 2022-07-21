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

public extension FileManager {
    /// Returns a boolean value that indicates whether the path has an extended attribute of the given name.
    ///
    /// - Parameters:
    ///   - name: The name of the extended attribute.
    ///   - path: The path of a file or directory.
    ///   - follow: Specify `true` to follow symbolic links.
    ///
    /// - Returns: A value indicating whether the item has an extended attribute of the given name.
    /// - Throws: `POSIXError` if `getxattr` fails.
    func hasExtendedAttribute(_ name: String, at url: URL, traverseLink follow: Bool) throws -> Bool {
        let flags = follow ? 0 : XATTR_NOFOLLOW
        guard getxattr((url as NSURL).fileSystemRepresentation, name, nil, 0, 0, flags) != -1 else {
            switch errno {
            case ENOATTR:
                return false
            default:
                throw POSIXError(POSIXErrorCode(rawValue: errno)!)
            }
        }
        return true
    }
    
    /// Removes the extended attribute for the given file or directory.
    ///
    /// - Parameters:
    ///   - name: The name of the extended attribute.
    ///   - path: The path of a file or directory.
    ///   - follow: Specify `true` to follow symbolic links.
    ///
    /// - Throws: `PosixError` if `removexattr` fails.
    func removeExtendedAttribute(_ name: String, at url: URL, traverseLink follow: Bool) throws {
        let flags = follow ? 0 : XATTR_NOFOLLOW
        if removexattr((url as NSURL).fileSystemRepresentation, name, flags) == 0 {
            return
        }
        
        throw POSIXError(POSIXErrorCode(rawValue: errno)!)
    }
}
