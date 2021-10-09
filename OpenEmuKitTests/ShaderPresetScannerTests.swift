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

@testable import OpenEmuKitPrivate
@testable import OpenEmuKit

class ShaderPresetScannerTests: XCTestCase {
    
    // MARK: - Valid Input
    
    func testIsValidWithAllParts() {
        let str = #""The Name","MAME HLSL":ccvalue=3.5795;chromaa_y=0.3401"#
        let (tokens, text) = parse(text: str)
        
        let expTok: [ScannerToken] = [.name, .shader, .identifier, .float, .identifier, .float]
        expect(tokens).to(equal(expTok))
        
        let expText: [String] = ["The Name", "MAME HLSL", "ccvalue", "3.5795", "chromaa_y", "0.3401"]
        expect(text).to(equal(expText))
    }
    
    func testIsValidWithNoName() {
        let str = #""MAME HLSL":ccvalue=3.5795;chromaa_y=0.3401"#
        let (tokens, text) = parse(text: str)
        
        let expTok: [ScannerToken] = [.shader, .identifier, .float, .identifier, .float]
        expect(tokens).to(equal(expTok))
        
        let expText: [String] = ["MAME HLSL", "ccvalue", "3.5795", "chromaa_y", "0.3401"]
        expect(text).to(equal(expText))
    }
    
    func testIsValidWithNoHeader() {
        let str = #"ccvalue=3.5795;chromaa_y=0.3401"#
        let (tokens, text) = parse(text: str)
        
        let expTok: [ScannerToken] = [.identifier, .float, .identifier, .float]
        expect(tokens).to(equal(expTok))
        
        let expText: [String] = ["ccvalue", "3.5795", "chromaa_y", "0.3401"]
        expect(text).to(equal(expText))
    }
    
    func testIsValidWithNoHeaderAndSignature() {
        let str = #"ccvalue=3.5795;chromaa_y=0.3401"#
        let (tokens, text) = parse(text: str)
        
        let expTok: [ScannerToken] = [.identifier, .float, .identifier, .float]
        expect(tokens).to(equal(expTok))
        
        let expText: [String] = ["ccvalue", "3.5795", "chromaa_y", "0.3401"]
        expect(text).to(equal(expText))
    }

    // MARK: - Invalid Input

    func testIsInvalidUnclosedQuoteInName() {
        let str = #""The Name,"MAME HLSL":ccvalue=3.5795;chromaa_y=0.3401"#
        expect {
            try PScanner.parse(text: str)
        }
        .to(throwError(PScanner.Error.malformed))

    }

    func testIsInvalidUnclosedQuoteInShader() {
        let str = #""The Name",MAME HLSL":ccvalue=3.5795;chromaa_y=0.3401"#
        expect {
            try PScanner.parse(text: str)
        }
        .to(throwError(PScanner.Error.malformed))

    }

    func testIsInvalidMissingCommaInHeader() {
        let str = #""The Name""MAME HLSL":ccvalue=3.5795;chromaa_y=0.3401"#
        expect {
            try PScanner.parse(text: str)
        }
        .to(throwError(PScanner.Error.malformed))

    }

    func testIsInvalidMissingColonInHeader() {
        let str = #""The Name","MAME HLSL"ccvalue=3.5795;chromaa_y=0.3401"#
        expect {
            try PScanner.parse(text: str)
        }
        .to(throwError(PScanner.Error.malformed))
    }

    func testIsInvalidMissingParameterName() {
        let str = #"=3.5795;chromaa_y=0.3401"#
        expect {
            try PScanner.parse(text: str)
        }
        .to(throwError(PScanner.Error.malformed))
    }

    func testIsInvalidNotValidFloat() {
        expect {
            try PScanner.parse(text: #"ccvalue=foo;chromaa_y=0.3401"#)
        }
        .to(throwError(PScanner.Error.malformed))
    }

    func parse(text: String) -> ([ScannerToken], [String]) {
        guard let tokens = try? PScanner.parse(text: text) else { return ([], []) }
        
        let result = ([ScannerToken](), [String]())
        return tokens.reduce(into: result) { acc, pair in
            acc.0.append(pair.0)
            acc.1.append(pair.1)
        }
    }
}
