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

public class UserDefaultsPresetStore: ShaderPresetStore {
    static let presetPrefix     = "videoShader.user.preset.data."
    static let presetPrefixLen  = presetPrefix.count

    let store: UserDefaults
    let queue: DispatchQueue = DispatchQueue(label: "org.openemu.userDefaultsPresetStore", attributes: .concurrent)
    
    var indexByName: [String: String] = [:]
    var indexByShader: [String: [String]] = [:]
    
    public init(store: UserDefaults) {
        self.store = store
        
        // populate indices
        queue.async(flags: .barrier) {
            // Collect all the shader preset keys
            let keys = store.dictionaryRepresentation().keys.filter { $0.hasPrefix(Self.presetPrefix) }
            let presets = keys.compactMap(self.load(_:))
            
            self.indexByName = Dictionary(uniqueKeysWithValues: presets.map { ($0.name, $0.id) })
            
            // Groups presets by shader and then remaps the values from [ShaderPresetData] → [\.id]
            self.indexByShader = Dictionary(grouping: presets, by: { $0.shader })
                .mapValues { $0.map(\.id) }
        }
    }
    
    static func makeKey(_ name: String) -> String {
        "\(Self.presetPrefix)\(name)"
    }
    
    public func exists(byName name: String) -> Bool {
        queue.sync {
            indexByName[name] != nil
        }
    }
    
    public func exists(byID id: String) -> Bool {
        queue.sync {
            store.string(forKey: Self.makeKey(id)) != nil
        }
    }
    
    public func presets(matching predicate: (ShaderPresetData) -> Bool) -> [ShaderPresetData] {
        queue.sync {
            indexByName.values.compactMap(load(_:)).filter(predicate)
        }
    }
    
    public func findPresets(byShader name: String) -> [ShaderPresetData] {
        queue.sync {
            indexByShader[name]?.compactMap(load(_:)) ?? []
        }
    }
    
    public func findPreset(byName name: String) -> ShaderPresetData? {
        queue.sync {
            guard let id = indexByName[name] else { return nil }
            return load(id)
        }
    }
    
    public func findPreset(byID id: String) -> ShaderPresetData? {
        queue.sync {
            load(id)
        }
    }
    
    public func save(_ preset: ShaderPresetData) throws {
        try queue.sync(flags: .barrier) {
            if let existing = indexByName[preset.name], existing != preset.id {
                throw ShaderPresetStoreError.duplicateName
            }
            
            let existing = load(preset.id)
            
            if let existing = existing, existing.shader != preset.shader {
                // verify the shader hasn't changed
                throw ShaderPresetStoreError.shaderModified
            }
            
            do {
                let text = try ShaderPresetTextWriter().write(preset: preset, options: [.name, .shader])
                store.set(text, forKey: Self.makeKey(preset.id))
                
                //
                // Update indices
                //
                if let existing = existing {
                    if existing.name != preset.name {
                        // Preset was renamed
                        indexByName[existing.name] = nil
                        indexByName[preset.name] = preset.id
                    }
                } else {
                    indexByName[preset.name] = preset.id
                    var idsByShader = indexByShader[preset.shader] ?? []
                    idsByShader.append(preset.id)
                    indexByShader[preset.shader] = idsByShader
                }
            } catch let error as ShaderPresetWriteError {
                throw ShaderPresetStoreError.writeError(error)
            }
        }
    }
    
    public func remove(_ preset: ShaderPresetData) {
        guard let existing = load(preset.id) else { return }
        
        queue.sync(flags: .barrier) {
            store.removeObject(forKey: Self.makeKey(existing.id))
            
            //
            // Update indices
            //
            indexByName.removeValue(forKey: existing.name)
            if
                var idsByShader = indexByShader[existing.shader],
                let index = idsByShader.firstIndex(of: existing.id)
            {
                idsByShader.remove(at: index)
                indexByShader[existing.shader] = idsByShader
            }
        }
    }
    
    // MARK: - Helpers
    
    func load(_ id: String) -> ShaderPresetData? {
        guard let text = store.string(forKey: Self.makeKey(id)) else { return nil }
        return try? ShaderPresetTextReader().read(text: text, id: id)
    }
}
