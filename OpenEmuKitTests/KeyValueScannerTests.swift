// Copyright (c) 2022, OpenEmu Team
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

class KeyValueScannerTests: XCTestCase {
    
    // MARK: - Valid Input
    
    func testIsValidWithAllParts() {
        let str = #"$name="The Name";$shader="MAME HLSL";ccvalue=3.5795;chromaa_y=0.3401;neg=-1.1;pos=+0.3"#
        let (tokens, text) = parse(text: str)
        
        let expTok: [KVToken] = [
            .systemIdentifier, .string, .systemIdentifier, .string,
            .identifier, .float,
            .identifier, .float,
            .identifier, .float,
            .identifier, .float,
        ]
        expect(tokens).to(equal(expTok))
        
        let expText: [String] = [
            "$name", "The Name", "$shader", "MAME HLSL",
            "ccvalue", "3.5795",
            "chromaa_y", "0.3401",
            "neg", "-1.1",
            "pos", "+0.3",
        ]
        expect(text).to(equal(expText))
    }
    
    func testIsValidWithStringPartsInUTF8() {
        let str = #"$name="The Name ❤️";$shader="MÄMÉ HLSL";ccvalue=3.5795;chromaa_y=1"#
        let (tokens, text) = parse(text: str)
        
        let expTok: [KVToken] = [.systemIdentifier, .string, .systemIdentifier, .string, .identifier, .float, .identifier, .float]
        expect(tokens).to(equal(expTok))
        
        let expText: [String] = ["$name", "The Name ❤️", "$shader", "MÄMÉ HLSL", "ccvalue", "3.5795", "chromaa_y", "1"]
        expect(text).to(equal(expText))
    }

    func testIsValidWithNoReserved() {
        let str = #"ccvalue=3.5795;chromaa_y=0.3401"#
        let (tokens, text) = parse(text: str)
        
        let expTok: [KVToken] = [.identifier, .float, .identifier, .float]
        expect(tokens).to(equal(expTok))
        
        let expText: [String] = ["ccvalue", "3.5795", "chromaa_y", "0.3401"]
        expect(text).to(equal(expText))
    }

    // MARK: - Invalid Input

    func testIsInvalidUnclosedQuoteInName() {
        let str = #"$name="The Name;$shader="MAME HLSL";ccvalue=3.5795;chromaa_y=0.3401"#
        expect {
            try PKVScanner.parse(text: str)
        }
        .to(throwError(PKVScanner.Error.malformed))

    }

    func testIsInvalidMissingSeparator() {
        let str = #"$name="The Name"$shader="MAME HLSL";ccvalue=3.5795;chromaa_y=0.3401"#
        expect {
            try PKVScanner.parse(text: str)
        }
        .to(throwError(PKVScanner.Error.malformed))

    }

    func testIsInvalidMissingParameterName() {
        let str = #"=3.5795;chromaa_y=0.3401"#
        expect {
            try PKVScanner.parse(text: str)
        }
        .to(throwError(PKVScanner.Error.malformed))
    }

    func testIsInvalidNotValidFloat() {
        expect {
            try PKVScanner.parse(text: #"ccvalue=foo;chromaa_y=0.3401"#)
        }
        .to(throwError(PKVScanner.Error.malformed))
    }

    func parse(text: String) -> ([KVToken], [String]) {
        guard let tokens = try? PKVScanner.parse(text: text) else { return ([], []) }
        
        return (tokens.map { $0.0 }, tokens.map { $0.1 })
    }
}
