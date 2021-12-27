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
    
    static let invalidCharacters = #"'":@#|[]{}$%^&*()/\;<>!?`.,"#
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
        
        var wroteName = false
        if options.contains(.name) {
            guard Self.isValidIdentifier(c.name) else { throw ShaderPresetWriteError.invalidCharacters }
            
            wroteName = true
            s.append("\"\(c.name)\"")
        }
        
        if options.contains(.shader) || wroteName {
            guard Self.isValidIdentifier(c.shader) else { throw ShaderPresetWriteError.invalidCharacters }
            
            if wroteName {
                s.append(",")
            }
            s.append("\"\(c.shader)\"")
        }
        
        if options.contains(.name) || options.contains(.shader) {
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
    
    public func read(text: String) throws -> ShaderPresetData {
        // do we have a signature?
        var paramsEnd = text.endIndex
        if let idx = text.lastIndex(of: "@") {
            paramsEnd = idx
            let sig = Crypto.MD5.digest(string: text[..<idx])
            guard text[text.index(after: idx)..<text.endIndex] == sig.prefix(3) else {
                throw ShaderPresetReadError.invalidSignature
            }
        }
        
        guard let tokens = try? PScanner.parse(text: text[..<paramsEnd])
        else { throw ShaderPresetReadError.malformed }
        
        var name: String?
        var shader: String?
        
        var tokIter = tokens.makePeekableIterator()
        if let (tok, _) = tokIter.peek(), tok == .name || tok == .shader {
            (name, shader) = parseHeader(&tokIter)
        }
        
        let params = parseParams(&tokIter)
        
        switch (name, shader) {
        case (.none, .none):
            return ShaderPresetData(name: "Unnamed", shader: "", parameters: params)
        case (.none, .some(let shader)):
            return ShaderPresetData(name: "Unnamed", shader: shader, parameters: params)
        case (.some(let id), .some(let shader)):
            return ShaderPresetData(name: id, shader: shader, parameters: params)
        default:
            throw ShaderPresetReadError.malformed
        }
    }
    
    func parseHeader(_ iter: inout PeekableIterator<Array<(ScannerToken, String)>.Iterator>) -> (String?, String?) {
        var id: String?
        var shader: String?
        
        if let (tok, text) = iter.peek(), tok == .name {
            iter.next()
            id = text
        }
        
        if let (tok, text) = iter.peek(), tok == .shader {
            iter.next()
            shader = text
        }
        
        return (id, shader)
    }
    
    func parseParams(_ iter: inout PeekableIterator<Array<(ScannerToken, String)>.Iterator>) -> [String: Double] {
        var res = [String: Double]()
        while true {
            guard
                let (tok, param) = iter.peek(),
                tok == .identifier
            else { break }
            iter.next()
            
            guard
                let (tok, val) = iter.peek(),
                tok == .float
            else { break }
            iter.next()
            
            res[param] = Double(val)
        }
        return res
    }
}

struct PeekableIterator<Base: IteratorProtocol>: IteratorProtocol {
    private var peeked: Base.Element??
    private var iter: Base
    
    init(_ base: Base) {
        iter = base
    }
    
    mutating func peek() -> Base.Element? {
        if peeked == nil {
            peeked = iter.next()
        }
        return peeked!
    }
    
    @discardableResult
    mutating func next() -> Base.Element? {
        if let val = peeked {
            peeked = nil
            return val
        }
        
        return iter.next()
    }
}

extension Sequence {
    func makePeekableIterator() -> PeekableIterator<Self.Iterator> {
        return PeekableIterator(makeIterator())
    }
}
