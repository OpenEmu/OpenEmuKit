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

/// An client for interacting with all shader presets
@objc public class ShaderPresetsModel: NSObject {
    private var store: KeyValueStore
    
    public init(store: KeyValueStore) {
        self.store = store
        super.init()
    }
    
    static let presetPrefix = "videoShader.user.preset.obj."
    static let presetPrefixCount = presetPrefix.count
    
    public var presetNames: [String] {
        store.keys(withPrefix: Self.presetPrefix).map { String($0.dropFirst(Self.presetPrefixCount)) }
    }
    
    static func makeKey(name: String) -> String {
        "\(Self.presetPrefix)\(name)"
    }
    
    public func read(presetNamed name: String) -> ShaderPreset? {
        guard let d = store.string(forKey: Self.makeKey(name: name)) else { return nil }
        return try? ShaderPresetTextReader().read(text: d)
    }
    
    public func write(preset: ShaderPreset) throws {
        let text = try ShaderPresetTextWriter().write(preset: preset, options: [.name, .shader])
        store.set(text, forKey: Self.makeKey(name: preset.id))
    }
    
    public func remove(presetNamed name: String) {
        store.removeValue(forKey: name)
    }
    
    public func contains(presetNamed name: String) -> Bool {
        store.string(forKey: Self.makeKey(name: name)) != nil
    }
}
