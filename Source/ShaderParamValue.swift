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

@objc public final class ShaderParamValue: NSObject {
    @objc dynamic public var index: Int
    @objc dynamic public var name: String
    @objc dynamic public var desc: String
    @objc dynamic public var value: NSNumber
    @objc dynamic public var initial: NSNumber
    @objc dynamic public var minimum: NSNumber
    @objc dynamic public var maximum: NSNumber
    @objc dynamic public var step: NSNumber
    @objc public var isInitial: Bool {
        value.doubleValue.isApproximatelyEqual(to: initial.doubleValue, relativeTolerance: 0.001)
    }
    
    init(parameter p: ShaderParameter, at index: Int) {
        self.index = index
        name       = p.name
        desc       = p.desc
        value      = p.initial as NSNumber
        initial    = p.initial as NSNumber
        minimum    = p.minimum as NSNumber
        maximum    = p.maximum as NSNumber
        step       = p.step    as NSNumber
    }
    
    public func reset() {
        value = initial
    }
    
    public static func reset(_ param: ShaderParamValue) {
        param.reset()
    }
    
    public static func from(parameters params: [ShaderParameter]) -> [ShaderParamValue] {
        params.enumerated().map { el in
            ShaderParamValue(parameter: el.element, at: el.offset)
        }
    }
}

@objc public final class ShaderParamGroupValue: NSObject {
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

extension Double {
    func toPrecision(_ i: Self) -> Self {
        (pow(10, i) * self).rounded(.awayFromZero) / pow(10, i)
    }
}

extension Dictionary where Dictionary.Key == String, Dictionary.Value == Double {
    
    /// Creates a new dictionary from the array of parameters.
    /// - Parameter params: An array of shader parameters to use to create the dictionary.
    public init(allParams params: [ShaderParamValue]) {
        self.init(uniqueKeysWithValues: params.map { ($0.name, $0.value.doubleValue) })
    }
    
    /// Creates a new dictionary from the array of parameters, excluding those that are assigned
    /// their initial value.
    /// - Parameter params: An array of shader parameters to use to create the dictionary.
    public init(changedParams params: [ShaderParamValue]) {
        self.init(uniqueKeysWithValues: params.compactMap { $0.isInitial ? nil : ($0.name, $0.value.doubleValue) })
    }
}
