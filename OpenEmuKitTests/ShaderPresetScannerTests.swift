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
// @testable import OpenEmuKit
@testable import OpenEmuKitPrivate
@testable import OpenEmuKit

class ShaderPresetScannerTests: XCTestCase {
    func testOne() {
        let sc2 = PScanner()
        defer { scanner_destroy(sc2) }
        
        // swiftlint:disable line_length
        //var str = #""MAME HLSL":ccvalue=3.5795;chromaa_y=0.3401;chromab_x=0.3101;chromab_y=0.6;chromac_x=0.16;chromac_y=0.0701;col_saturation=1.2001;distort_corner_amount=0.0502;distortion_amount=0.0502;humbar_hertz_rate=0.002;humbaralpha=0.06;ifreqresponse=1.2001;ntscsignal=1.0;phosphor_b=0.45;phosphor_g=0.45;phosphor_r=0.45;qfreqresponse=0.6001;reflection_amount=0.0502;round_corner_amount=0.0502;scanline_crawl=1.0;scanlinealpha=0.35;scantime=52.6;smooth_border_amount=0.03;vignette_amount=0.08;ygain_b=0.12;ygain_g=0.69@1f4"#
        var str = #""MAME HLSL":"#
        str.withUTF8 { bp in
            sc2.setData(bp.baseAddress!, length: bp.count)
            
            let v1 = sc2.scan()
            print(sc2.text)
            let v2 = sc2.scan()
            print(sc2.text)
            let v3 = sc2.scan()
            print(sc2.text)
            
        }
    }
}
