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

import AVFoundation
import XCTest
@testable import OpenEmuKit

final class GameAudioBufferTests: XCTestCase {
    func testUnderrunsReturnFullBuffersWithSilence() {
        for bytesAvailable in [0, 4, 16] {
            let data = UnsafeMutableRawPointer.allocate(byteCount: 16, alignment: 8)
            defer { data.deallocate() }
            memset(data, 0x7f, 16)
            var buffer = AudioBuffer(mNumberChannels: 2, mDataByteSize: 16, mData: data)
            var requested = UInt(0)
            let silence = GameAudio2.renderAudioBuffer(&buffer, byteCount: 16) { destination, count in
                requested = count
                memset(destination, 0x23, bytesAvailable)
                return UInt(bytesAvailable)
            }

            XCTAssertEqual(requested, 16)
            XCTAssertEqual(buffer.mDataByteSize, 16)
            XCTAssertEqual(buffer.mNumberChannels, 2)
            XCTAssertEqual(silence, bytesAvailable == 0)
            let bytes = data.assumingMemoryBound(to: UInt8.self)
            XCTAssertEqual(Array(UnsafeBufferPointer(start: bytes, count: bytesAvailable)),
                           Array(repeating: 0x23, count: bytesAvailable))
            XCTAssertEqual(Array(UnsafeBufferPointer(start: bytes.advanced(by: bytesAvailable), count: 16 - bytesAvailable)),
                           Array(repeating: 0, count: 16 - bytesAvailable))
        }
    }

    func testFillsOnlyTheRequestedFrames() {
        let data = UnsafeMutableRawPointer.allocate(byteCount: 16, alignment: 8)
        defer { data.deallocate() }
        memset(data, 0x7f, 16)
        var buffer = AudioBuffer(mNumberChannels: 2, mDataByteSize: 16, mData: data)
        let silence = GameAudio2.renderAudioBuffer(&buffer, byteCount: 8) { _, _ in 0 }

        XCTAssertTrue(silence)
        XCTAssertEqual(buffer.mDataByteSize, 8)
        let bytes = data.assumingMemoryBound(to: UInt8.self)
        XCTAssertEqual(Array(UnsafeBufferPointer(start: bytes, count: 8)), Array(repeating: 0, count: 8))
        XCTAssertEqual(Array(UnsafeBufferPointer(start: bytes.advanced(by: 8), count: 8)), Array(repeating: 0x7f, count: 8))
    }
}
