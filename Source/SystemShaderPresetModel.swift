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

/// An object that manages the association of shader presets
/// to system cores.
public class SystemShaderPresetModel {
    let store: UserDefaults
    let presets: ShaderPresetModel
    let shaders: OEShadersModel
    
    public init(store: UserDefaults, presets: ShaderPresetModel, shaders: OEShadersModel) {
        self.store      = store
        self.presets    = presets
        self.shaders    = shaders
    }
    
    // MARK: - Public API
    
    /// Gets or sets the name for the default preset.
    public var defaultPresetByID: String {
        get {
            if let name = store.string(forKey: makeGlobalKey()),
               presets.exists(byID: name) {
                return name
            }
            return "Pixellate"
        }
        
        set {
            store.set(newValue, forKey: makeGlobalKey())
        }
    }
    
    /// Returns the default shader preset.
    public var defaultPreset: ShaderPreset {
        presets.defaultPresetForShader(shaders.defaultShader)
    }
    
    /// Set the shader preset for the specified system.
    /// - Parameters:
    ///   - preset: The preset to assign to the system.
    ///   - identifier: The identifier of the system.
    public func setPreset(_ preset: ShaderPreset, forSystem identifier: String) {
        store.set(preset.name, forKey: makeSystemKey(identifier))
    }
    
    /// Finds the shader preset assigned to the specified system.
    /// - Parameter identifier: The identifier for the system.
    /// - Returns: The shader preset assigned to the system.
    public func findPresetForSystem(_ identifier: String) -> ShaderPreset? {
        guard
            let name = store.string(forKey: makeSystemKey(identifier)),
            let preset = presets.findPreset(byName: name)
        else { return nil }
        
        return preset
    }
    
    // MARK: - Helpers
    
    func makeGlobalKey() -> String { "videoShader.preset" }
    func makeSystemKey(_ identifier: String) -> String { "videoShader.\(identifier).preset" }
}
