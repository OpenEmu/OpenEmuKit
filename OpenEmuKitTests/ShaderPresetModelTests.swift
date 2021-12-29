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
    private var store: ShaderPresetStore!
    private var presets: ShaderPresetModel!
    
    private var path: String!
    
    override func setUp() {
        super.setUp()
        
        path = FileManager.default
            .temporaryDirectory
            .appendingPathComponent("OpenEmuKitTests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString).absoluteString
        
        defaults = UserDefaults(suiteName: path)
        defaults.removePersistentDomain(forName: path)
        
        store = defaults
        // swiftlint:disable force_try
        try! store.save(ShaderPresetData(name: "id1", shader: "CRT", parameters: [:]))
        try! store.save(ShaderPresetData(name: "id2", shader: "MAME", parameters: [:]))
        try! store.save(ShaderPresetData(name: "id3", shader: "MAME", parameters: [:]))
        try! store.save(ShaderPresetData(name: "id4", shader: "Retro", parameters: [:]))

        let shaders = ShadersModel(models:
            OEShaderModel(name: "CRT"),
            OEShaderModel(name: "MAME"),
            OEShaderModel(name: "NTSC"),
            OEShaderModel(name: "Retro")
        )
        presets = ShaderPresetModel(store: store, shaders: shaders)
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(atPath: path)
        super.tearDown()
    }

    func testCanFindPreset() {
        expect(self.presets.findPreset(forName: "id1"))
            .toNot(be(nil))
    }
    
    func testInstancesAreSame() {
        let a = presets.findPreset(forName: "id1")
        let b = presets.findPreset(forName: "id1")
        expect(a) === b
    }
    
    func testFindPresets() {
        expect(self.presets.findPresets(forShader: "MAME"))
            .to(haveCount(2), description: "expected two presets for MAME shader")
        
        expect(self.presets.findPresets(forShader: "foo"))
            .to(haveCount(0), description: "expected no presets for foo shader")
    }
    
    func testExists() {
        expect(self.presets.exists("id1")) == true
        expect(self.presets.exists("foo")) == false
    }
    
    func testRemovePreset() {
        let a = presets.findPreset(forName: "id2")
        expect(a).toNot(beNil())
        presets.removePreset(a!)
        expect(self.presets.findPreset(forName: "id2")).to(beNil())
        expect(self.presets.findPresets(forShader: "MAME"))
            .to(haveCount(1), description: "expected one preset for MAME shader")
    }
}
