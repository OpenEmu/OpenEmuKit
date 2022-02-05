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
    /// Posted when a shader preset is updated.
    public static let shaderPresetDidChange = NSNotification.Name("shaderPresetDidChange")
}

/// A type that can lookup an ``OEShaderModel`` by name.
protocol ShadersModel {
    subscript(name: String) -> OEShaderModel? { get }
}

public class ShaderPresetStore {
    public enum Error: LocalizedError {
        case shaderDoesNotExist
    }
    
    let store: ShaderPresetStorage
    let shaders: ShadersModel
    let queue = DispatchQueue(label: "org.openemu.shaderPresetModel", target: DispatchQueue.global(qos: .userInitiated))
    
    // Indices
    var byID = [String: ShaderPreset]() // map id   → preset
    
    public init(store: ShaderPresetStorage, shaders: OEShaderStore) {
        self.store      = store
        self.shaders    = OEShadersModelAdapter(inner: shaders)
    }
    
    /// Initializer for testing
    init(store: ShaderPresetStorage, shaders: ShadersModel) {
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
        
        let data = ShaderPresetData(name: shader.name,
                                    shader: shader.name,
                                    parameters: Dictionary(allParams: shader.defaultParameters),
                                    id: shader.name)
        
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
            }
        }
    }
    
    public func removePreset(_ preset: ShaderPreset) {
        let data = ShaderPresetData(preset: preset)
        store.remove(data)
        queue.async(flags: .barrier) {
            self.byID.removeValue(forKey: data.id)
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
    
    public func findPreset(byID id: String) -> ShaderPreset? {
        queue.sync {
            getPreset(byID: id)
        }
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
    
    private func makePreset(data: ShaderPresetData, shader: OEShaderModel) -> ShaderPreset {
        let createdAt = data.createdAt != nil ? Date(timeIntervalSince1970: data.createdAt!) : Date()
        let preset = ShaderPreset(name: data.name, shader: shader, parameters: data.parameters, id: data.id, createdAt: createdAt)
        byID[data.id] = preset
        return preset
    }
}

/// An object that adapts ``OEShaderModel`` to the ``ShadersModel`` protocol.
struct OEShadersModelAdapter: ShadersModel {
    let inner: OEShaderStore
    
    subscript(name: String) -> OEShaderModel? {
        inner[name]
    }
}
