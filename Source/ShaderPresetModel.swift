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

public class ShaderPresetModel {
    public enum Error: LocalizedError {
        case shaderDoesNotExist
    }

    let store: ShaderPresetStore
    let shaders: OEShadersModel
    
    public init(store: ShaderPresetStore, shaders: OEShadersModel) {
        self.store      = store
        self.shaders    = shaders
    }
    
    public func newPresetForShader(_ name: String, parameters: [ShaderParamValue]? = nil) throws -> ShaderPreset {
        guard let shader = shaders[name]
        else {
            throw Error.shaderDoesNotExist
        }
        
        let kv = (parameters ?? shader.defaultParameters).map { ($0.name, $0.value.doubleValue) }
        
        return ShaderPreset(name: "Unnamed \(name) preset", shader: name, parameters: Dictionary(uniqueKeysWithValues: kv))
    }
    
    public func savePreset(_ preset: ShaderPreset) throws {
        try store.save(preset)
    }
    
    private func removePreset(_ preset: ShaderPreset) {
        store.remove(preset.name)
    }
    
    /// Find all presets that depend on the specified shader name.
    /// - Parameter name: Name of the shader.
    /// - Returns: An array of matching shader presets.
    public func findPresets(forShader name: String) -> [ShaderPreset] {
        store.presets { $0.shader == name }
    }
    
    /// Return the shader preset matching the specified name.
    ///
    /// - Important:
    /// This function returns `nil` if a preset is found
    /// but no valid shader is installed.
    ///
    /// - Parameter name: The name of the preset to locate.
    /// - Returns: A matching preset.
    public func findPreset(forName name: String) -> ShaderPreset? {
        guard let preset = store.findPreset(forName: name)
        else { return nil }
        
        return isValidShaderName(preset.shader) ? preset : nil
    }
    
    /// Return the default preset for the specified shader name.
    /// - Parameter name: Name of the shader.
    /// - Returns: A matching preset.
    public func findPresetWithShaderName(_ name: String) -> ShaderPreset {
        fatalError("Not implemented")
    }
    
    /// Determines if a preset exists with the specified name.
    /// - Parameter name: Name of the preset to search for.
    /// - Returns: `true` if a preset exists.
    public func exists(_ name: String) -> Bool {
        store.exists(name)
    }

    // MARK: - Helpers
    
    func isValidShaderName(_ name: String) -> Bool {
        shaders[name] != nil
    }
}
