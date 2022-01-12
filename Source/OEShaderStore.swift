// Copyright (c) 2019, OpenEmu Team
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
import OpenEmuBase
import OpenEmuShaders

extension NSNotification.Name {
    public static let shaderModelCustomShadersDidChange = NSNotification.Name("shaderModelCustomShadersDidChange")
}

/// The main object used for accessing system and user-installed shaders.
@objc public class OEShaderStore: NSObject {
    private let store: UserDefaults
    private let userPathName: String
    private let bundle: Bundle
    
    private var systemShaders = [OEShaderModel]()
    private var customShaders = [OEShaderModel]()
    
    /// Creates a shader model used for accessing shaders and their user state.
    /// - Parameters:
    ///   - store: The user defaults store to read and write to.
    ///   - bundle: The main bundle used to locate shaders.
    ///   - name: The name of the path used to read and write user-specified shaders,
    ///     from within the application support directory. A `nil`
    ///     value will use the `kCFBundleNameKey` from the main bundle; otherwise, `OpenEmuKit` will be used.
    @objc public init(store: UserDefaults, bundle: Bundle = .main, userPathName name: String? = nil) {
        self.store          = store
        self.bundle         = bundle
        self.userPathName   = name ?? bundle.infoDictionary?[kCFBundleNameKey as String] as? String ?? "OpenEmuKit"
        super.init()
        
        self.systemShaders  = loadSystemShaders()
        self.customShaders  = loadCustomShaders()
        
        store.register(defaults: [
            makeGlobalKey(): "Pixellate",
        ])
    }
    
    @objc public func reload() {
        customShaders       = loadCustomShaders()
        _customShaderNames  = nil
        _sortedCustomShaderNames = nil
        NotificationCenter.default.post(name: .shaderModelCustomShadersDidChange, object: nil)
    }
    
    /// Returns the default shader name or `Pixellate` if the current default does
    /// not exist.
    @objc public var defaultShaderName: String {
        get {
            if let name = store.string(forKey: makeGlobalKey()), self[name] != nil {
                return name
            }
            return "Pixellate"
        }
        
        set {
            store.set(newValue, forKey: makeGlobalKey())
        }
    }
    
    /// Returns the default shader model or Pixellate if the current default does not exist.
    @objc public var defaultShader: OEShaderModel {
        get {
            self[defaultShaderName]!
        }
        
        set {
            defaultShaderName = newValue.name
        }
    }
    
    @objc public func shader(withName name: String) -> OEShaderModel? {
        return self[name]
    }
    
    private var _systemShaderNames: [String]!
    @objc public var systemShaderNames: [String] {
        if _systemShaderNames == nil {
            _systemShaderNames = systemShaders.map(\.name)
        }
        return _systemShaderNames
    }
    
    private var _customShaderNames: [String]!
    @objc public var customShaderNames: [String] {
        if _customShaderNames == nil {
            _customShaderNames = customShaders.map(\.name)
        }
        return _customShaderNames
    }
    
    private var _sortedSystemShaderNames: [String]!
    /// Returns `systemShaderNames` as sorted by the Finder.
    @objc public var sortedSystemShaderNames: [String] {
        if _sortedSystemShaderNames == nil {
            _sortedSystemShaderNames = systemShaderNames.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        }
        return _sortedSystemShaderNames
    }
    
    private var _sortedCustomShaderNames: [String]!
    /// Returns `customShaderNames` as sorted by the Finder.
    @objc public var sortedCustomShaderNames: [String] {
        if _sortedCustomShaderNames == nil {
            _sortedCustomShaderNames = customShaderNames.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        }
        return _sortedCustomShaderNames
    }
    
    @objc public var userShadersPath: URL? {
        guard
            let path = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        else { return nil }
        
        return path.appendingPathComponent(userPathName, isDirectory: true).appendingPathComponent("Shaders", isDirectory: true)
    }
    
    @objc public var shadersCachePath: URL? {
        guard
            let path = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        else { return nil }
        
        return path.appendingPathComponent(userPathName, isDirectory: true).appendingPathComponent("Shaders", isDirectory: true)
    }
    
    // MARK: - Helpers
    
    func makeGlobalKey() -> String { "videoShader" }
    
    subscript(name: String) -> OEShaderModel? {
        systemShaders.first { $0.name == name } ?? customShaders.first { $0.name == name }
    }
    
    private func loadSystemShaders() -> [OEShaderModel] {
        if let path = bundle.resourcePath {
            let url = URL(fileURLWithPath: path, isDirectory: true).appendingPathComponent("Shaders", isDirectory: true)
            let urls = Self.urlsForShaders(at: url)
            return urls.map(OEShaderModel.init(url:))
        }
        return []
    }
    
    private func loadCustomShaders() -> [OEShaderModel] {
        guard let path = userShadersPath else { return [] }
        return Self.urlsForShaders(at: path).map(OEShaderModel.init(url:))
    }
    
    private static func urlsForShaders(at url: URL) -> [URL] {
        var res = [URL]()
        
        let fm = FileManager.default
        
        guard
            let urls = try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: .skipsSubdirectoryDescendants)
        else { return [] }
        
        let dirs = urls.filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false }
        for dir in dirs {
            guard
                let files = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil,
                                                        options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
            else { continue }
            if let slangp = files.first(where: { $0.pathExtension == "slangp" }) {
                res.append(slangp)
            }
        }
        
        return res
    }
}

@objc public class OEShaderModel: NSObject {
    @objc public var name: String
    @objc public var url: URL
    
    private lazy var slangShader: SlangShader? = {
        try? SlangShader(fromURL: url)
    }()
    
    fileprivate init(url: URL) {
        self.name   = url.deletingLastPathComponent().lastPathComponent
        self.url    = url
    }
    
    /// Testing initializer.
    init(name: String) {
        self.name = name
        self.url  = URL(fileURLWithPath: "/shaders/\(name)")
    }
    
    /// Returns the default parameters for the shader.
    @objc public var defaultParameters: [ShaderParamValue] {
        ShaderParamValue.from(parameters: slangShader?.parameters ?? [])
    }
    
    override public var description: String {
        return name
    }
    
    public override var debugDescription: String {
        return "\(name) \(url.absoluteString)"
    }
    
    /// Returns an array of the parameter groups for the shader.
    /// - Returns: An array of the parameter groups for the shader.
    @objc public func readGroups() -> [ShaderParamGroupValue] {
        guard let ss = slangShader else { return [] }
        
        if let groups = readGroupsModel() {
            var all = ss.parameters
            var dg: ShaderParamGroupValue?
            
            let res: [ShaderParamGroupValue] = groups.enumerated().map { (i, g) in
                let gv = ShaderParamGroupValue(index: i, name: g.name, desc: g.desc, hidden: g.hidden)
                
                if g.name == "default" {
                    dg = gv
                }
                
                // return a list of parameters from SlangShader in same order as g.parameters
                let p = g.parameters.compactMap { name in
                    all.first { $0.name == name }
                }
                all.removeAll { p.contains($0) }
                
                gv.parameters = ShaderParamValue.from(parameters: p)
                return gv
            }
            
            if let dg = dg, !all.isEmpty {
                dg.parameters = ShaderParamValue.from(parameters: all)
            }
            
            return res
        }
        
        let gv = ShaderParamGroupValue(index: 0, name: "default", desc: "Default")
        gv.parameters = ShaderParamValue.from(parameters: ss.parameters)
        return [gv]
    }
    
    func readGroupsModel() -> [ShaderParameterGroupModel]? {
        let groupsURL = url.deletingLastPathComponent().appendingPathComponent("parameterGroups.plist")
        guard let data = try? Data(contentsOf: groupsURL) else { return nil }
        
        let dec = PropertyListDecoder()
        return try? dec.decode([ShaderParameterGroupModel].self, from: data)
    }
}
