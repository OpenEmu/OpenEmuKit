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

import XCTest
import Nimble
@testable import OpenEmuKit

class ShaderPresetModelTests: XCTestCase {
    
    struct ShadersModel: OpenEmuKit.ShadersModel {
        let shaders: [String: OEShaderModel]
        
        init(models: OEShaderModel...) {
            shaders = Dictionary(uniqueKeysWithValues: models.map { ($0.name, $0) })
        }
        
        subscript(name: String) -> OEShaderModel? {
            shaders[name]
        }
    }
    
    private var defaults: UserDefaults!
    private var store: ShaderPresetStorage!
    private var presets: ShaderPresetStore!
    
    private var path: String!
    
    override func setUp() {
        path = FileManager.default
            .temporaryDirectory
            .appendingPathComponent("OpenEmuKitTests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString).absoluteString
        
        defaults = UserDefaults(suiteName: path)
        defaults.removePersistentDomain(forName: path)
        
        store = UserDefaultsPresetStorage(store: defaults)
        // swiftlint:disable force_try
        try! store.save(ShaderPresetData(name: "shader 1", shader: "CRT", parameters: [:], id: "id1"))
        try! store.save(ShaderPresetData(name: "shader 2", shader: "MAME", parameters: [:], id: "id2"))
        try! store.save(ShaderPresetData(name: "shader 3", shader: "MAME", parameters: [:], id: "id3"))
        try! store.save(ShaderPresetData(name: "shader 4", shader: "Retro", parameters: [:], id: "id4"))

        let shaders = ShadersModel(models:
            OEShaderModel(name: "CRT"),
            OEShaderModel(name: "MAME"),
            OEShaderModel(name: "NTSC"),
            OEShaderModel(name: "Retro")
        )
        presets = ShaderPresetStore(store: store, shaders: shaders)
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(atPath: path)
    }

    func testCanFindPreset() {
        expect(self.presets.findPreset(byID: "id1"))
            .toNot(be(nil))
    }
    
    func testInstancesAreSame() {
        expect(self.presets.findPreset(byID: "id2")) === presets.findPreset(byID: "id2")
    }
    
    func testFindPresets() {
        expect(self.presets.findPresets(byShader: "MAME"))
            .to(haveCount(2), description: "expected two presets for MAME shader")
        
        expect(self.presets.findPresets(byShader: "foo"))
            .to(haveCount(0), description: "expected no presets for foo shader")
    }
    
    func testExists() {
        expect(self.presets.exists(byID: "id2")) == true
        expect(self.presets.exists(byID: "foo")) == false
    }
    
    func testRemovePreset() {
        let a = presets.findPreset(byID: "id2")
        expect(a).toNot(beNil())
        presets.removePreset(a!)
        expect(self.presets.findPreset(byID: "id2")).to(beNil())
        expect(self.presets.findPresets(byShader: "MAME"))
            .to(haveCount(1), description: "expected one preset for MAME shader")
    }
    
    func testRenamePreset() throws {
        guard let a = presets.findPreset(byID: "id2")
        else {
            XCTFail("Expected to find id2")
            return
        }
        a.name = "dummy name"
        try presets.savePreset(a)
        guard let b = presets.findPreset(byID: "id2")
        else { return XCTFail("Expected to find id2") }
        expect(b.name).to(equal("dummy name"))
    }
}
