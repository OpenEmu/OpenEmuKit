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

public enum ShaderPresetWriteError: Error {
    case invalidCharacters
}

@frozen public struct ShaderPresetTextWriter {
    @frozen public struct Options: OptionSet {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static let name      = Self(rawValue: 1 << 0)
        public static let shader    = Self(rawValue: 1 << 1)
        public static let sign      = Self(rawValue: 1 << 2)
        
        public static let all: Self = [.name, .shader]
    }
    
    static var formatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 4
        formatter.decimalSeparator = "."
        formatter.groupingSeparator = ""
        return formatter
    }
    
    static let invalidCharacters   = #"#""#
    static let invalidCharacterSet = CharacterSet(charactersIn: invalidCharacters)
    
    /// A boolean value to determine if a string is a valid identifier.
    /// - Parameter s: The string to be validated.
    /// - Returns: `true` if s is a valid identifier.
    public static func isValidIdentifier(_ s: String) -> Bool {
        s.rangeOfCharacter(from: Self.invalidCharacterSet) == nil
    }
    
    public init() {}
    
    public func write(preset c: ShaderPresetData, options: Options = [.shader]) throws -> String {
        var s = ""
        
        var first = true
        if options.contains(.name) {
            guard Self.isValidIdentifier(c.name) else { throw ShaderPresetWriteError.invalidCharacters }
            first = false
            s.append("$name=\"\(c.name)\"")
        }
        
        if options.contains(.shader) {
            guard Self.isValidIdentifier(c.shader) else { throw ShaderPresetWriteError.invalidCharacters }
            if !first {
                s.append(";")
            } else {
                first = false
            }
            s.append("$shader=\"\(c.shader)\"")
        }
        
        // Sort the keys for a consistent output
        for key in c.parameters.keys.sorted() {
            if !first {
                s.append(";")
            }
            s.append("\(key)=\(Self.formatter.string(from: c.parameters[key]! as NSNumber)!)")
            first = false
        }
        
        if options.contains(.sign) {
            let sig = Crypto.MD5.digest(string: s).prefix(3)
            s.append("@")
            s.append(contentsOf: sig)
        }
        
        return s
    }
}

public enum ShaderPresetReadError: Error {
    /// Preset is malformed
    case malformed
    case invalidSignature
}

@frozen public struct ShaderPresetTextReader {
    enum State {
        case key, value
    }
    
    public init() {}
    
    /// Determines if text has a valid signature.
    public static func isSignedAndValid(text: String) -> Bool {
        let parts = text.split(separator: "@")
        if parts.count != 2 {
            return false
        }
        return Crypto.MD5.digest(string: parts[0]).prefix(3) == parts[1]
    }
    
    public func read(text: String, id: String? = nil) throws -> ShaderPresetData {
        // do we have a signature?
        var paramsEnd = text.endIndex
        if let idx = text.lastIndex(of: "@") {
            paramsEnd = idx
            let sig = Crypto.MD5.digest(string: text[..<idx])
            guard text[text.index(after: idx)..<text.endIndex] == sig.prefix(3) else {
                throw ShaderPresetReadError.invalidSignature
            }
        }
        
        guard let tokens = try? PKVScanner.parse(text: text[..<paramsEnd])
        else { throw ShaderPresetReadError.malformed }
        
        var name: String?
        var shader: String?
        var params = [String: Double]()

        var iter = tokens.makePeekableIterator()
        while let (tok, key) = iter.peek(), tok == .identifier || tok == .systemIdentifier {
            iter.next()
            
            if tok == .identifier {
                guard
                    let (tok, val) = iter.peek(),
                    tok == .float
                else { break }
                iter.next()
                params[key] = Double(val)
                continue
            }
            
            // tok == .reserveIdentifier
            guard
                let (tok, val) = iter.peek(),
                tok == .string
            else { break }
            iter.next()
            
            switch key {
            case "$name":
                name = val
            case "$shader":
                shader = val
            default:
                break
            }
            
        }
        
        switch (name, shader) {
        case (.none, .none):
            return ShaderPresetData(name: "Unnamed shader preset", shader: "", parameters: params, id: id)
        case (.none, .some(let shader)):
            return ShaderPresetData(name: "Unnamed shader preset", shader: shader, parameters: params, id: id)
        case (.some(let name), .some(let shader)):
            return ShaderPresetData(name: name, shader: shader, parameters: params, id: id)
        default:
            throw ShaderPresetReadError.malformed
        }
    }
}
