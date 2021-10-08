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

class ShaderPresetsModelTests: XCTestCase {
    private var defaults: UserDefaults!
    private var store: KeyValueStore!
    
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
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(atPath: path)
        super.tearDown()
    }
    
    func testOnlyListsPresets() throws {
        let name = ShaderPresetsModel.makeKey(name:)
        
        store.add([
            name("second"): "",
            name("first"): "",
            "another": "",
            "\(ShaderPresetsModel.presetPrefix.dropLast())notme": "",
        ])
        let sp = ShaderPresetsModel(store: store)
        let names = sp.presetNames
        expect(names).to(contain("first", "second"))
    }
    
    func testFoo() {
        let name = ShaderPresetsModel.makeKey(name:)
        
        store.add([
            name("second"): "",
            name("first"): "",
            "another": "",
            "\(ShaderPresetsModel.presetPrefix.dropLast())notme": "",
        ])
    }
}

extension KeyValueStore {
    mutating func add(_ dict: [String: String]) {
        for (key, val) in dict {
            set(val, forKey: key)
        }
    }
}
