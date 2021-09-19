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

import Foundation
import OpenEmuShaders

@objc
public final class ShaderParamValue: NSObject {
    @objc dynamic public var index: Int
    @objc dynamic public var name: String
    @objc dynamic public var desc: String
    @objc dynamic public var value: NSNumber {
        didSet {
            if step.doubleValue > 0.0 {
                let d = 1.0 / step.doubleValue
                let v = (value.doubleValue * d) / d
                value = NSNumber(value: v.toPrecision(4))
            }
        }
    }
    @objc dynamic public var initial: NSNumber
    @objc dynamic public var minimum: NSNumber
    @objc dynamic public var maximum: NSNumber
    @objc dynamic public var step: NSNumber
    
    init(parameter p: ShaderParameter, at index: Int) {
        self.index = index
        name    = p.name
        desc    = p.desc
        value   = NSNumber(value: p.initial)
        initial = NSNumber(value: p.initial)
        minimum = NSNumber(value: p.minimum)
        maximum = NSNumber(value: p.maximum)
        step    = NSNumber(value: p.step)
    }
    
    public static func from(parameters params: [ShaderParameter]) -> [ShaderParamValue] {
        params.enumerated().map { el in
            ShaderParamValue(parameter: el.element, at: el.offset)
        }
    }
    
    var isInitial: Bool {
        value.doubleValue.isApproximatelyEqual(to: initial.doubleValue)
    }
}

@objc
public final class ShaderParamGroupValue: NSObject {
    @objc dynamic public var index: Int
    @objc dynamic public var name: String
    @objc dynamic public var desc: String
    @objc dynamic public var hidden: Bool
    @objc dynamic public var parameters: [ShaderParamValue]
    
    public init(index: Int, name: String, desc: String, hidden: Bool = false, parameters: [ShaderParamValue] = []) {
        self.index      = index
        self.name       = name
        self.desc       = desc
        self.hidden     = hidden
        self.parameters = parameters
        
        super.init()
    }
}

fileprivate extension Double {
    func toPrecision(_ i: Self) -> Self {
        (pow(10, i) * self).rounded(.awayFromZero) / pow(10, i)
    }
}
