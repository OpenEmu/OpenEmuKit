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

@frozen public struct ShaderPreset: Hashable, Identifiable {
    public let id: String
    public let shader: String
    public var parameters: [String: Double]
    
    public init(id: String, shader: String, parameters: [String: Double]) {
        self.id         = id
        self.shader     = shader
        self.parameters = parameters
    }
    
    public static func makeFrom(shader: String, params: [ShaderParamValue]) -> ShaderPreset {
        ShaderPreset(
            id: "Unnamed",
            shader: shader,
            parameters: Dictionary(uniqueKeysWithValues: params.compactMap { pv in
                pv.isInitial ? nil : (pv.name, pv.value.doubleValue)
            })
        )
    }
}

public enum ShaderPresetWriteError: Error {
    case invalidCharacters
}

/*
 EBNF for shader preset
 
 preset_id := '"' identifier '"'
 
 shader_name := '"' identifier '"'
 
 header := ( ( preset_id "," )? shader_name ':' )
 
 parameter := identifier '=' double
 
 parameters := parameter ( ',' parameter )*
 
 preset := header? parameters
 */

@frozen public struct ShaderPresetTextWriter {
    @frozen public struct Options: OptionSet {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static let name = Options(rawValue: 1 << 0)
        public static let shader = Options(rawValue: 1 << 1)
        public static let sign = Options(rawValue: 1 << 2)
        
        public static let all: Options = [.name, .shader]
    }
    
    static let invalidCharacters = #"'":@#|[]{}$%^&*()/\;<>!?`.,"#
    static let invalidCharacterSet = CharacterSet(charactersIn: invalidCharacters)
    
    /// A boolean value to determine if a string is a valid identifier.
    /// - Parameter s: The string to be validated.
    /// - Returns: `true` if s is a valid identifier.
    public static func isValidIdentifier(_ s: String) -> Bool {
        s.rangeOfCharacter(from: Self.invalidCharacterSet) == nil
    }
    
    public init() {}
    
    public func write(preset c: ShaderPreset, options: Options = [.shader]) throws -> String {
        var s = ""

        var wroteName = false
        if options.contains(.name) {
            guard Self.isValidIdentifier(c.id) else { throw ShaderPresetWriteError.invalidCharacters }
            
            wroteName = true
            s.append("\"\(c.id)\"")
        }
        
        if options.contains(.shader) || wroteName {
            guard Self.isValidIdentifier(c.shader) else { throw ShaderPresetWriteError.invalidCharacters }
            
            if wroteName {
                s.append(",")
            }
            s.append("\"\(c.shader)\"")
        }
        
        if options.contains([.name, .shader]) {
            s.append(":")
        }
        
        // Sort the keys for a consistent output
        var first = true
        for key in c.parameters.keys.sorted() {
            if !first {
                s.append(";")
            }
            s.append("\(key)=\(c.parameters[key]!)")
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
    
    public func read(text: String) throws -> ShaderPreset {
        
        var paramsStart = text.startIndex
        var paramsEnd   = text.endIndex

        let header: [String]?
        if let idx = text.firstIndex(of: ":") {
            paramsStart = text.index(after: idx)
            header = try parseHeader(text: text[..<idx])
        } else {
            header = nil
        }
        
        if let idx = text.lastIndex(of: "@") {
            paramsEnd = idx
            let sig = Crypto.MD5.digest(string: text[..<idx])
            guard text[text.index(after: idx)..<text.endIndex] == sig.prefix(3) else {
                throw ShaderPresetReadError.invalidSignature
            }
        }
        
        let params = try parseParams(text: text[paramsStart..<paramsEnd])
        
        if let header = header, !header.isEmpty {
            if header.count == 2 {
                return ShaderPreset(id: header[0], shader: header[1], parameters: params)
            } else if header.count == 1 {
                return ShaderPreset(id: "Unnamed", shader: header[0], parameters: params)
            }
        }
        
        return ShaderPreset(id: "Unnamed", shader: "", parameters: params)
    }
    
    func parseHeader<T: StringProtocol>(text: T) throws -> [String] {
        var header = [String]()
        var iter   = text.makeIterator()
        
        while let ch = iter.next() {
            switch ch {
            case "\"":
                // quoted string
                var s = ""
                while let ch = iter.next() {
                    if ch == "\"" {
                        header.append(s)
                        break
                    }
                    s.append(ch)
                }
            case ",":
                continue
            default:
                throw ShaderPresetReadError.malformed
            }
        }
        
        return header
    }
    
    func parseParams<T: StringProtocol>(text: T) throws -> [String: Double] {
        var params = [String: Double]()
        
        var iter = text.makeIterator()
        var state: State = .key
        var key = ""
        var current = ""
        while let ch = iter.next() {
            if ch == "=" {
                if state == .key {
                    key     = current
                    current = ""
                    state   = .value
                    continue
                }
                throw ShaderPresetReadError.malformed
            }
            
            if ch == ";" {
                if state == .value {
                    state = .key
                    params[key] = Double(current)
                    key = ""
                    current = ""
                    continue
                }
                throw ShaderPresetReadError.malformed
            }
            
            current.append(ch)
        }
        
        if state == .value {
            params[key] = Double(current)
        } else {
            throw ShaderPresetReadError.malformed
        }
        
        return params
    }
}
