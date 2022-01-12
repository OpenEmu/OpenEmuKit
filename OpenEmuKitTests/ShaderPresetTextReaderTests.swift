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
        let got = try r.read(text: #"$shader="CRT";a=5.0;b=6"#)
        expect(got) == ShaderPresetData(name: "Unnamed shader preset", shader: "CRT", parameters: ["a": 5, "b": 6])
    }
    
    func testReadShaderParamsWithID() throws {
        let got = try r.read(text: #"$shader="CRT";a=5.0;b=6.0"#, id: "id1")
        expect(got) == ShaderPresetData(name: "Unnamed shader preset", shader: "CRT", parameters: ["a": 5, "b": 6], id: "id1")
    }
    
    func testReadNameShaderParams() throws {
        let got = try r.read(text: #"$name="Name";$shader="CRT";a=5.0;b=6.0"#)
        expect(got) == ShaderPresetData(name: "Name", shader: "CRT", parameters: ["a": 5, "b": 6])
    }

    func testReadNameShaderParamsWithID() throws {
        let got = try r.read(text: #"$name="Name";$shader="CRT";a=5.0;b=6.0"#, id: "id1")
        expect(got) == ShaderPresetData(name: "Name", shader: "CRT", parameters: ["a": 5, "b": 6], id: "id1")
    }

    func testReadParams() throws {
        let got = try r.read(text: #"a=5.0;b=6.0"#)
        expect(got) == ShaderPresetData(name: "Unnamed shader preset", shader: "", parameters: ["a": 5, "b": 6])
    }

    // MARK: - With signature
    
    func testReadShaderParamsSignature() throws {
        let got = try r.read(text: #"$shader="CRT";a=5.0;b=6.0@9a2"#)
        expect(got) == ShaderPresetData(name: "Unnamed shader preset", shader: "CRT", parameters: ["a": 5, "b": 6])
    }

    func testShaderParamsIsValidSignature() throws {
        let got = ShaderPresetTextReader.isSignedAndValid(text: #"$shader="CRT";a=5.0;b=6.0@9a2"#)
        expect(got).to(beTrue())
    }

    func testShortSignatureIsNotValid() throws {
        let got = ShaderPresetTextReader.isSignedAndValid(text: #"$shader="CRT";a=5.0;b=6.0@6a"#)
        expect(got).to(beFalse())
    }

    func testLongSignatureIsNotValid() throws {
        let got = ShaderPresetTextReader.isSignedAndValid(text: #"$shader="CRT";a=5.0;b=6.0@9a3"#)
        expect(got).to(beFalse())
    }

    func testShaderParamsIsNotValidSignature() throws {
        let got = ShaderPresetTextReader.isSignedAndValid(text: #"$shader="CRT";a=5.0;b=6.0@6b0"#)
        expect(got).to(beFalse())
    }

    func testMissingSignatureIsNotValid() throws {
        let got = ShaderPresetTextReader.isSignedAndValid(text: #"$shader="CRT";a=5.0;b=6.0"#)
        expect(got).to(beFalse())
    }

    func testReadNameShaderParamsSignature() throws {
        let got = try r.read(text: #"$name="Name";$shader="CRT";a=5.0;b=6.0@3b4"#)
        expect(got) == ShaderPresetData(name: "Name", shader: "CRT", parameters: ["a": 5, "b": 6])
    }

    func testNameShaderParamsIsValidSignature() throws {
        let got = ShaderPresetTextReader.isSignedAndValid(text: #"$name="Name";$shader="CRT";a=5.0;b=6.0@3b4"#)
        expect(got).to(beTrue())
    }

    func testReadParamsSignature() throws {
        let got = try r.read(text: #"a=5.0;b=6.0@346"#)
        expect(got) == ShaderPresetData(name: "Unnamed shader preset", shader: "", parameters: ["a": 5, "b": 6])
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
    
    func testReadPerformance() {
        measure {
            _ = try? r.read(text: #"$name="Name";$shader="CRT";a=5.0;b=6.0;c=2.2;d=1.1;e=1.1;f=1.1"#)
        }
    }
}
