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

/// The main object used for managing shaders and parameters assigned to a system.
@objc public class OESystemShaderStore: NSObject {
    private let store: UserDefaults
    private let shaders: OEShaderStore
    
    public init(store: UserDefaults, shaders: OEShaderStore) {
        self.store      = store
        self.shaders    = shaders
        
        super.init()
    }
    
    @objc public func shader(withShader shader: OEShaderModel, forSystem identifier: String) -> OESystemShaderModel {
        OESystemShaderModel(shader: shader, identifier: identifier, store: store)
    }
    
    @objc public func shader(forSystem identifier: String) -> OESystemShaderModel {
        findSystemShader(identifier)
    }
    
    /// Returns the name of the shader for the specified system, falling back to the default shader if none is set.
    @objc public func shaderName(forSystem identifier: String) -> String {
        findShader(forSystem: identifier).name
    }
    
    /// Reset to the default shader for the specified system.
    @objc public func resetShader(forSystem identifier: String) {
        store.removeObject(forKey: makeSystemKey(identifier))
    }
    
    /// Set the default shader for the specified system.
    /// - Parameters:
    ///   - shader: The shader to assign to the system..
    ///   - identifier: The identifier of the system.
    @objc public func setShader(_ shader: OEShaderModel, forSystem identifier: String) {
        store.set(shader.name, forKey: makeSystemKey(identifier))
    }
    
    // MARK: - Internal methods
    // These are used to avoid deprecation warnings within OpenEmuKit
    
    func findSystemShader(_ identifier: String) -> OESystemShaderModel {
        OESystemShaderModel(shader: findShader(forSystem: identifier), identifier: identifier, store: store)
    }
    
    func findShader(forSystem identifier: String) -> OEShaderModel {
        if let name = store.string(forKey: makeSystemKey(identifier)),
           let model = shaders[name] {
            return model
        }
        return shaders.defaultShader
    }
    
    // MARK: - Helpers
    
    func makeSystemKey(_ identifier: String) -> String { "videoShader.\(identifier)" }
    
    // MARK: - Shader parameter storage
    
    public func read(parametersForShader name: String, identifier: String) -> String? {
        store.read(parametersForShader: name, identifier: identifier)
    }
    
    public func write(parameters params: String, forShader name: String, identifier: String) {
        store.write(parameters: params, forShader: name, identifier: identifier)
    }
    
    public func remove(parametersForShader name: String, identifier: String) {
        store.remove(parametersForShader: name, identifier: identifier)
    }
}

protocol ShaderModelStore {
    /// Read the customised shader parameters for the shader and system identifer.
    func read(parametersForShader name: String, identifier: String) -> String?
    
    /// Write the customised shader parameters for the shader and system identifer.
    func write(parameters params: String, forShader name: String, identifier: String)
    
    /// Remove the customised shader parameters for the shader and system identifer.
    func remove(parametersForShader name: String, identifier: String)
}

extension UserDefaults: ShaderModelStore {
    func read(parametersForShader name: String, identifier: String) -> String? {
        string(forKey: makeSystemKey(name, identifier))
    }
    
    func write(parameters params: String, forShader name: String, identifier: String) {
        set(params, forKey: makeSystemKey(name, identifier))
    }
    
    func remove(parametersForShader name: String, identifier: String) {
        removeObject(forKey: makeSystemKey(name, identifier))
    }
    
    func makeSystemKey(_ shader: String, _ identifier: String) -> String {
        "videoShader.\(identifier).\(shader).params"
    }
}

@objc public class OESystemShaderModel: NSObject {
    public let shader: OEShaderModel
    public let system: String
    let store: ShaderModelStore
    
    init(shader: OEShaderModel, identifier: String, store: ShaderModelStore) {
        self.shader = shader
        self.system = identifier
        self.store  = store
        super.init()
    }
    
    public var parameters: [String: Double]? {
        if let state = store.read(parametersForShader: shader.name, identifier: system) {
            var res = [String: Double]()
            for param in state.split(separator: ";") {
                let vals = param.split(separator: "=")
                if vals.count == 2,
                   let d = Double(vals[1]) {
                    res[String(vals[0])] = d
                }
            }
            return res
        }
        
        return nil
    }
    
    public func write(parameters params: [ShaderParamValue]) {
        let state = params
            .filter { !$0.isInitial }
            .map { "\($0.name)=\($0.value)" }
        
        if state.isEmpty {
            store.remove(parametersForShader: shader.name, identifier: system)
        } else {
            store.write(parameters: state.joined(separator: ";"), forShader: shader.name, identifier: system)
        }
    }
}
