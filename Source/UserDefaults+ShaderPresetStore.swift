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

extension UserDefaults: ShaderPresetStore {
    static let presetPrefix     = "videoShader.user.preset.data."
    static let presetPrefixLen  = presetPrefix.count
    
    static func makeKey(name: String) -> String {
        "\(Self.presetPrefix)\(name)"
    }
    
    var shaderPresetKeys: [String] {
        dictionaryRepresentation().keys.compactMap { key in
            key.hasPrefix(Self.presetPrefix) ? key : nil
        }
    }
    
    public func exists(_ name: String) -> Bool {
        string(forKey: Self.makeKey(name: name)) != nil
    }
    
    public func presets(matching predicate: (ShaderPresetData) -> Bool) -> [ShaderPresetData] {
        let r = ShaderPresetTextReader()
        return shaderPresetKeys.compactMap {
            guard let text = string(forKey: $0) else { return nil }
            return try? r.read(text: text)
        }
        .filter(predicate)
    }
    
    public func findPresent(forName name: String) -> ShaderPresetData? {
        fatalError("Not implemented")
    }
    
    public func findPreset(forName name: String) -> ShaderPresetData? {
        if let text = string(forKey: Self.makeKey(name: name)) {
            return try? ShaderPresetTextReader().read(text: text)
        }
        return nil
    }
    
    public func save(_ preset: ShaderPresetData) throws {
        let text = try ShaderPresetTextWriter().write(preset: preset, options: [.name, .shader])
        set(text, forKey: Self.makeKey(name: preset.name))
    }
    
    public func remove(_ name: String) {
        removeObject(forKey: Self.makeKey(name: name))
    }
}
