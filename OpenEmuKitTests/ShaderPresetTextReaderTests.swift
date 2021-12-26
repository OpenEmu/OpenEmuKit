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

class ShaderPresetTextReaderTests: XCTestCase {
    var r: ShaderPresetTextReader!
    
    override func setUp() {
        r = ShaderPresetTextReader()
    }
    
    // MARK: - Without signature
    
    func testReadShaderParams() throws {
        let got = try r.read(text: #""CRT":a=5.0;b=6.0"#)
        expect(got) == ShaderPreset(name: "Unnamed", shader: "CRT", parameters: ["a": 5, "b": 6])
    }
    
    func testReadNameShaderParams() throws {
        let got = try r.read(text: #""Name","CRT":a=5.0;b=6.0"#)
        expect(got) == ShaderPreset(name: "Name", shader: "CRT", parameters: ["a": 5, "b": 6])
    }

    func testReadParams() throws {
        let got = try r.read(text: #"a=5.0;b=6.0"#)
        expect(got) == ShaderPreset(name: "Unnamed", shader: "", parameters: ["a": 5, "b": 6])
    }

    // MARK: - With signature
    
    func testReadShaderParamsSignature() throws {
        let got = try r.read(text: #""CRT":a=5.0;b=6.0@d80"#)
        expect(got) == ShaderPreset(name: "Unnamed", shader: "CRT", parameters: ["a": 5, "b": 6])
    }

    func testShaderParamsIsValidSignature() throws {
        let got = ShaderPresetTextReader.isSignedAndValid(text: #""CRT":a=5.0;b=6.0@d80"#)
        expect(got).to(beTrue())
    }

    func testShortSignatureIsNotValid() throws {
        let got = ShaderPresetTextReader.isSignedAndValid(text: #""CRT":a=5.0;b=6.0@d8"#)
        expect(got).to(beFalse())
    }

    func testLongSignatureIsNotValid() throws {
        let got = ShaderPresetTextReader.isSignedAndValid(text: #""CRT":a=5.0;b=6.0@d803dd"#)
        expect(got).to(beFalse())
    }

    func testShaderParamsIsNotValidSignature() throws {
        let got = ShaderPresetTextReader.isSignedAndValid(text: #""CRT":a=5.0;b=6.0@d81"#)
        expect(got).to(beFalse())
    }

    func testMissingSignatureIsNotValid() throws {
        let got = ShaderPresetTextReader.isSignedAndValid(text: #""CRT":a=5.0;b=6.0"#)
        expect(got).to(beFalse())
    }

    func testReadNameShaderParamsSignature() throws {
        let got = try r.read(text: #""Name","CRT":a=5.0;b=6.0@462"#)
        expect(got) == ShaderPreset(name: "Name", shader: "CRT", parameters: ["a": 5, "b": 6])
    }

    func testNameShaderParamsIsValidSignature() throws {
        let got = ShaderPresetTextReader.isSignedAndValid(text: #""Name","CRT":a=5.0;b=6.0@462"#)
        expect(got).to(beTrue())
    }

    func testReadParamsSignature() throws {
        let got = try r.read(text: #"a=5.0;b=6.0@346"#)
        expect(got) == ShaderPreset(name: "Unnamed", shader: "", parameters: ["a": 5, "b": 6])
    }
    
    func testInvalidSignature() {
        let r = r!
        expect {
            try r.read(text: #"a=5.0;b=6.0@foo"#)
        }.to(throwError(ShaderPresetReadError.invalidSignature))
    }
    
    func testSignatureTooShort() {
        let r = r!
        expect {
            try r.read(text: #"a=5.0;b=6.0@34"#)
        }.to(throwError(ShaderPresetReadError.invalidSignature))
    }
    
    func testSignatureTooLong() {
        let r = r!
        expect {
            try r.read(text: #"a=5.0;b=6.0@346f"#)
        }.to(throwError(ShaderPresetReadError.invalidSignature))
    }
}
