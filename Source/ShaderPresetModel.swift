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

extension NSNotification.Name {
    // Posted when a shader preset is updated.
    public static let shaderPresetDidChange = NSNotification.Name("shaderPresetDidChange")
}

/// A type that can lookup an ``OEShaderModel`` by name.
protocol ShadersModel {
    subscript(name: String) -> OEShaderModel? { get }
}

public class ShaderPresetModel {
    public enum Error: LocalizedError {
        case shaderDoesNotExist
    }
    
    let store: ShaderPresetStore
    let shaders: ShadersModel
    let queue = DispatchQueue(label: "org.openemu.shaderPresetModel")
    
    // Indices
    var byID = [String: ShaderPreset]() // map id   → preset
    var byName = [String: String]()     // map name → id
    
    // tracks the persisted name of the shader
    var idToName = [String: String]()
    
    public init(store: ShaderPresetStore, shaders: OEShadersModel) {
        self.store      = store
        self.shaders    = OEShadersModelAdapter(inner: shaders)
    }
    
    /// Initializer for testing
    init(store: ShaderPresetStore, shaders: ShadersModel) {
        self.store      = store
        self.shaders    = shaders
    }
    
    /// Return the default preset for the matching shader.
    /// - Parameter shader: The shader to retrieve the default preset.
    /// - Returns: A matching preset.
    public func defaultPresetForShader(_ shader: OEShaderModel) -> ShaderPreset {
        if let preset = findPreset(byID: shader.name) {
            return preset
        }
        
        let kv = shader.defaultParameters.map { ($0.name, $0.value.doubleValue) }
        let data = ShaderPresetData(name: shader.name, shader: shader.name, parameters: Dictionary(uniqueKeysWithValues: kv), id: shader.name)
        
        return queue.sync {
            makePreset(data: data, shader: shader)
        }
    }
    
    public func savePreset(_ preset: ShaderPreset) throws {
        let data = ShaderPresetData(preset: preset)
        try store.save(data)
        
        queue.async(flags: .barrier) {
            if self.byID[data.id] == nil {
                // new item
                self.byID[data.id] = preset
                self.byName[data.name] = data.id
                self.idToName[data.id] = data.name
            } else if let name = self.idToName[data.id], name != data.name {
                self.byName.removeValue(forKey: name)
                self.byName[data.name] = data.id
                self.idToName[data.id] = data.name
            }
        }
    }
    
    public func removePreset(_ preset: ShaderPreset) {
        let data = ShaderPresetData(preset: preset)
        store.remove(data)
        queue.async(flags: .barrier) {
            self.byID.removeValue(forKey: data.id)
            if let name = self.idToName.removeValue(forKey: data.id) {
                self.byName.removeValue(forKey: name)
            }
        }
    }
    
    /// Find all presets that depend on the specified shader.
    /// - Parameter name: Name of the shader.
    /// - Returns: An array of matching shader presets.
    public func findPresets(byShader name: String) -> [ShaderPreset] {
        guard let shader = shaders[name] else { return [] }
        
        return queue.sync {
            store.findPresets(byShader: name)
                .map {
                    byID[$0.id] ?? makePreset(data: $0, shader: shader)
                }
        }
    }
    
    /// Return the shader preset matching the specified name.
    ///
    /// - Note:
    /// This function returns `nil` if a preset is found
    /// but no valid shader is installed.
    ///
    /// - Parameter name: The name of the preset to locate.
    /// - Returns: A matching preset or `nil`.
    public func findPreset(byName name: String) -> ShaderPreset? {
        queue.sync {
            getPreset(byName: name)
        }
    }
    
    public func findPreset(byID id: String) -> ShaderPreset? {
        queue.sync {
            getPreset(byID: id)
        }
    }
    
    /// Determines if a preset exists with the specified name.
    /// - Parameter name: The unique name of the preset to search for.
    /// - Returns: `true` if a preset exists.
    public func exists(byName name: String) -> Bool {
        store.exists(byName: name)
    }
    
    /// Determines if a preset exists with the specified id.
    /// - Parameter id: The unique identifier of the preset to search for.
    /// - Returns: `true` if a preset exists.
    public func exists(byID id: String) -> Bool {
        store.exists(byID: id)
    }
    
    // MARK: - Helpers
    
    /// Load the preset matching the specified identifier.
    ///
    /// - warning:
    /// Must be called from dispatch queue only.
    private func getPreset(byID id: String) -> ShaderPreset? {
        if let loaded = byID[id] {
            return loaded
        }
        
        guard
            let data = store.findPreset(byID: id),
            let shader = shaders[data.shader]
        else { return nil }
        
        return makePreset(data: data, shader: shader)
    }
    
    private func getPreset(byName name: String) -> ShaderPreset? {
        if let id = byName[name] {
            return getPreset(byID: id)
        }
        
        guard
            let data   = store.findPreset(byName: name),
            let shader = shaders[data.shader]
        else { return nil }
        
        return makePreset(data: data, shader: shader)
    }
    
    private func makePreset(data: ShaderPresetData, shader: OEShaderModel) -> ShaderPreset {
        let preset = ShaderPreset(name: data.name, shader: shader, parameters: data.parameters, id: data.id)
        byID[data.id]     = preset
        byName[data.name] = preset.id
        idToName[data.id] = preset.name
        return preset
    }
}

/// An object that adapts ``OEShaderModel`` to the ``ShadersModel`` protocol.
struct OEShadersModelAdapter: ShadersModel {
    let inner: OEShadersModel
    
    subscript(name: String) -> OEShaderModel? {
        inner[name]
    }
}
