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

import Foundation

@objc(OEGameStartupInfo) public class OEGameStartupInfo: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { return true }
    
    public let romPath: String
    public let romMD5: String
    public let romHeader: String
    public let romSerial: String
    public let systemRegion: String
    public let displayModeInfo: [String: Any]?
    public let shader: URL
    public let shaderParameters: [String: Double]
    public let corePluginURL: URL
    public let systemPluginURL: URL
    
    public init(romPath: String, romMD5: String, romHeader: String, romSerial: String,
                systemRegion: String,
                displayModeInfo: [String: Any]?,
                shader: URL, shaderParameters: [String: Double],
                corePluginURL: URL, systemPluginURL: URL) {
        self.romPath = romPath
        self.romMD5 = romMD5
        self.romHeader = romHeader
        self.romSerial = romSerial
        self.systemRegion = systemRegion
        self.displayModeInfo = displayModeInfo
        self.shader = shader
        self.shaderParameters = shaderParameters
        self.corePluginURL = corePluginURL
        self.systemPluginURL = systemPluginURL
    }
    
    // MARK: - NSSecureCoding
    
    public required init?(coder: NSCoder) {
        guard
            let romPath = coder.decodeObject(of: NSString.self, forKey: "romPath") as? String,
            let romMD5 = coder.decodeObject(of: NSString.self, forKey: "romMD5") as? String,
            let romHeader = coder.decodeObject(of: NSString.self, forKey: "romHeader") as? String,
            let romSerial = coder.decodeObject(of: NSString.self, forKey: "romSerial") as? String,
            let systemRegion = coder.decodeObject(of: NSString.self, forKey: "systemRegion") as? String,
            let displayModeInfo = coder.decodePropertyList(forKey: "displayModeInfo") as? [String: Any]?,
            let shader = coder.decodeObject(of: NSURL.self, forKey: "shader") as? URL,
            let shaderParameters = coder.decodeObject(of: [NSString.self, NSDictionary.self, NSNumber.self],
                                                      forKey: "shaderParameters") as? [String: Double],
            let corePluginURL = coder.decodeObject(of: NSURL.self, forKey: "corePluginURL") as? URL,
            let systemPluginURL = coder.decodeObject(of: NSURL.self, forKey: "systemPluginURL") as? URL
        else { return nil }
        
        self.romPath = romPath
        self.romMD5 = romMD5
        self.romHeader = romHeader
        self.romSerial = romSerial
        self.systemRegion = systemRegion
        self.displayModeInfo = displayModeInfo
        self.shader = shader
        self.shaderParameters = shaderParameters
        self.corePluginURL = corePluginURL
        self.systemPluginURL = systemPluginURL
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(romPath, forKey: "romPath")
        coder.encode(romMD5, forKey: "romMD5")
        coder.encode(romHeader, forKey: "romHeader")
        coder.encode(romSerial, forKey: "romSerial")
        coder.encode(systemRegion, forKey: "systemRegion")
        coder.encode(displayModeInfo, forKey: "displayModeInfo")
        coder.encode(shader, forKey: "shader")
        coder.encode(shaderParameters, forKey: "shaderParameters")
        coder.encode(corePluginURL, forKey: "corePluginURL")
        coder.encode(systemPluginURL, forKey: "systemPluginURL")
    }
}
