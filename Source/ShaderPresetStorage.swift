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

public enum ShaderPresetStorageError: Error {
    /// The preset shader was changed
    case shaderModified
    
    case writeError(ShaderPresetWriteError)
}

/// A ShaderPresetStorage describes the behaviour required to
/// persist ``ShaderPresetData``.
public protocol ShaderPresetStorage {
    /// Returns an array of shader presets matching the specified shader name.
    /// - Parameter name: The name of the shader to use to fetch the matching presets.
    /// - Returns: An array of ``ShaderPresetData`` objects.
    func findPresets(byShader name: String) -> [ShaderPresetData]

    /// Returns the shader preset for the specified identifier.
    /// - Parameter id: The identifier of the preset to find.
    /// - Returns: A preset matching the specified identifier.
    func findPreset(byID id: String) -> ShaderPresetData?
    func save(_ preset: ShaderPresetData) throws
    func remove(_ preset: ShaderPresetData)
    func exists(byID id: String) -> Bool
}
