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

@objc public class ShaderPreset: NSObject, Identifiable {
    public let id: String
    public var name: String
    public let shader: OEShaderModel
    public var parameters: [String: Double]
    public let createdAt: Date
    
    public init(name: String, shader: OEShaderModel, parameters: [String: Double]? = nil, id: String? = nil, createdAt: Date = Date()) {
        // generate an ID that is useful for us humans, but still unique enough
        // that a client won't generate duplicates.
        self.id         = id ?? "\(shader.name):\(UInt(Date().timeIntervalSince1970))"
        self.name       = name
        self.shader     = shader
        self.parameters = parameters ?? Dictionary(allParams: shader.defaultParameters)
        self.createdAt  = createdAt
        super.init()
    }
}

extension ShaderPreset: Comparable {
    public static func < (lhs: ShaderPreset, rhs: ShaderPreset) -> Bool {
        let res = lhs.name.localizedCompare(rhs.name)
        if res == .orderedSame {
            return lhs.createdAt < rhs.createdAt
        }
        return res == .orderedAscending
    }
}

extension ShaderPresetData {
    public init(preset: ShaderPreset) {
        id          = preset.id
        name        = preset.name
        shader      = preset.shader.name
        parameters  = preset.parameters
        createdAt   = preset.createdAt.timeIntervalSince1970
    }
}
