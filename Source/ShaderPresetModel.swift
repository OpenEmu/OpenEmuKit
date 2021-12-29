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
    var presets = [String: ShaderPreset]()
    
    public init(store: ShaderPresetStore, shaders: OEShadersModel) {
        self.store      = store
        self.shaders    = OEShadersModelAdapter(inner: shaders)
    }
    
    /// Initializer for testing
    init(store: ShaderPresetStore, shaders: ShadersModel) {
        self.store      = store
        self.shaders    = shaders
    }

    /// Return the default preset for the specified shader.
    /// - Parameter shader: The shader to retrieve the default preset.
    /// - Returns: A matching preset.
    public func defaultPresetForShader(_ shader: OEShaderModel) -> ShaderPreset {
        if let preset = findPreset(forName: shader.name) {
            return preset
        }
        
        let kv = shader.defaultParameters.map { ($0.name, $0.value.doubleValue) }
        let data = ShaderPresetData(name: shader.name, shader: shader.name, parameters: Dictionary(uniqueKeysWithValues: kv))
        
        return queue.sync {
            self.getOrStorePreset(data: data, shader: shader)
        }
    }
    
    public func newPresetForShader(_ shader: OEShaderModel, parameters: [ShaderParamValue]? = nil) -> ShaderPreset {
        let kv = (parameters ?? shader.defaultParameters).map { ($0.name, $0.value.doubleValue) }
        
        return ShaderPreset(name: "Unnamed \(shader.name) preset",
                            shader: shader,
                            parameters: Dictionary(uniqueKeysWithValues: kv))
    }
    
    public func savePreset(_ preset: ShaderPreset) throws {
        try store.save(ShaderPresetData(preset: preset))
        queue.async {
            self.presets[preset.name] = preset
        }
    }
    
    public func removePreset(_ preset: ShaderPreset) {
        store.remove(preset.name)
        queue.async {
            self.presets[preset.name] = nil
        }
    }
    
    /// Find all presets that depend on the specified shader.
    /// - Parameter name: Name of the shader.
    /// - Returns: An array of matching shader presets.
    public func findPresets(forShader name: String) -> [ShaderPreset] {
        guard let shader = shaders[name] else { return [] }
        
        return queue.sync {
            store
                .presets { $0.shader == name }
                .map {
                    self.getOrStorePreset(data: $0, shader: shader)
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
    public func findPreset(forName name: String) -> ShaderPreset? {
        queue.sync {
            self.getPreset(name)
        }
    }
    
    /// Determines if a preset exists with the specified name.
    /// - Parameter name: Name of the preset to search for.
    /// - Returns: `true` if a preset exists.
    public func exists(_ name: String) -> Bool {
        store.exists(name)
    }
    
    // MARK: - Helpers
    
    /// Load the preset by name.
    ///
    /// - warning:
    /// Must be called from dispatch queue only.
    private func getPreset(_ name: String) -> ShaderPreset? {
        if let loaded = presets[name] {
            return loaded
        }

        guard
            let data = store.findPreset(forName: name),
            let shader = shaders[data.shader]
        else { return nil }
        
        let preset = ShaderPreset(name: data.name, shader: shader, parameters: data.parameters)
        presets[name] = preset
        return preset
    }
    
    private func getOrStorePreset(data: ShaderPresetData, shader: OEShaderModel) -> ShaderPreset {
        if let loaded = presets[data.name] {
            return loaded
        }
        
        let preset = ShaderPreset(name: data.name, shader: shader, parameters: data.parameters)
        presets[data.name] = preset
        return preset
    }
}

/// A ShaderPresetStore describes the behaviour required to
/// persist ``ShaderPresetData``.
public protocol ShaderPresetStore {
    // MARK: - Shader preset persistence functions
    
    func presets(matching predicate: (ShaderPresetData) -> Bool) -> [ShaderPresetData]
    func findPreset(forName name: String) -> ShaderPresetData?
    func save(_ preset: ShaderPresetData) throws
    func remove(_ name: String)
    func exists(_ name: String) -> Bool
}

/// An object that adapts ``OEShaderModel`` to the ``ShadersModel`` protocol.
struct OEShadersModelAdapter: ShadersModel {
    let inner: OEShadersModel
    
    subscript(name: String) -> OEShaderModel? {
        inner[name]
    }
}
