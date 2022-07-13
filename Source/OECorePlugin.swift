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
import OpenEmuBase

public class OECorePlugin: OEPlugin {
    
    override public class var pluginExtension: String {
        "oecoreplugin"
    }
    
    override public class var pluginFolder: String {
        "Cores"
    }
    
    @objc public class var allPlugins: [OECorePlugin] {
        return plugins() as! [OECorePlugin]
    }
    
    required init(bundleAtPath path: String, name: String?) throws {
        try super.init(bundleAtPath: path, name: name)
        
        // invalidate global cache
        Self.cachedRequiredFiles = nil
    }
    
    public static func corePlugin(bundleAtPath bundlePath: String) -> OECorePlugin? {
        return try? plugin(bundleAtPath: bundlePath)
    }
    
    public static func corePlugin(bundleIdentifier identifier: String) -> OECorePlugin? {
        return allPlugins.first(where: {
            $0.bundleIdentifier.caseInsensitiveCompare(identifier) == .orderedSame
        })
    }
    
    public static func corePlugins(forSystemIdentifier identifier: String) -> [OECorePlugin] {
        var validCores: [OECorePlugin] = []
        
        for plugin in allPlugins {
            if plugin.systemIdentifiers.contains(identifier) {
                validCores.append(plugin)
            }
        }
        
        return validCores
    }
    
    // MARK: -
    
    typealias Controller = OEGameCoreController
    
    private var _controller: Controller?
    public var controller: OEGameCoreController! {
        if _controller == nil,
           let principalClass = bundle.principalClass
        {
            _controller = newPluginController(with: principalClass)
        }
        return _controller
    }
    
    private func newPluginController(with bundleClass: AnyClass) -> Controller? {
        guard let bundleClass = bundleClass as? Controller.Type else { return nil }
        return bundleClass.init(bundle: bundle)
    }
    
    // MARK: -
    
    private static var cachedRequiredFiles: [[String : Any]]?
    public static var requiredFiles: [[String : Any]] {
        if cachedRequiredFiles == nil {
            var files: [[String : Any]] = []
            for plugin in allPlugins {
                files.append(contentsOf: plugin.requiredFiles)
            }
            
            cachedRequiredFiles = files
        }
        
        return cachedRequiredFiles!
    }
    
    public var gameCoreClass: AnyClass? {
        return controller?.gameCoreClass
    }
    
    public var bundleIdentifier: String {
        return infoDictionary["CFBundleIdentifier"] as! String
    }
    
    public var systemIdentifiers: [String] {
        return infoDictionary[OEGameCoreSystemIdentifiersKey] as? [String] ?? []
    }
    
    public var coreOptions: [String : Any] {
        return infoDictionary[OEGameCoreOptionsKey] as? [String : Any] ?? [:]
    }
    
    public var requiredFiles: [[String : Any]] {
        var allRequiredFiles: [[String : Any]] = []
        
        for value in coreOptions.values {
            if let resultDict = value as? [String : Any],
               let object = resultDict[OEGameCoreRequiredFilesKey] as? [[String : Any]]
            {
                allRequiredFiles.append(contentsOf: object)
            }
        }
        
        return allRequiredFiles
    }
    
    // MARK: -
    
    private var isMarkedDeprecatedInInfoPlist: Bool {
        if infoDictionary[OEGameCoreDeprecatedKey] as? Bool != true {
            return false
        }
        
        func isValidVersionString(_ string: String) -> Bool {
            if string.isEmpty { return false }
            let validCharacters: Set<Character> = [".", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
            return Set(string).isSubset(of: validCharacters)
        }
        
        guard let minMacOSVer = self.infoDictionary[OEGameCoreDeprecatedMinMacOSVersionKey] as? String,
              isValidVersionString(minMacOSVer)
        else { return true }
        
        let macOSVerComponents = minMacOSVer.components(separatedBy: ".")
        if macOSVerComponents.count < 2 {
            return true
        }
        let minMacOSVerParsed = OperatingSystemVersion(majorVersion: Int(macOSVerComponents[0])!,
                                                       minorVersion: Int(macOSVerComponents[1])!,
                                                       patchVersion: macOSVerComponents.count > 2 ? Int(macOSVerComponents[2])! : 0)
        if ProcessInfo.processInfo.isOperatingSystemAtLeast(minMacOSVerParsed) {
            return true
        }
        return false
    }
    
    override public var isDeprecated: Bool {
        if isOutOfSupport {
            return true
        }
        return isMarkedDeprecatedInInfoPlist
    }
    
    override public var isOutOfSupport: Bool {
        // plugins deprecated 2017-11-04
        let bundleFileName = bundle.bundleURL.lastPathComponent
        let deprecatedPlugins = [
            "Dolphin-Core.oecoreplugin",
            "NeoPop.oecoreplugin",
            "TwoMbit.oecoreplugin",
            "VisualBoyAdvance.oecoreplugin",
            "Yabause.oecoreplugin",
        ]
        if deprecatedPlugins.contains(bundleFileName) {
            return true
        }
        
        // beta-era plugins
        if let appcastURL = infoDictionary["SUFeedURL"] as? String,
           appcastURL.contains("openemu.org/update")
        {
            return true
        }
        
        // plugins marked as deprecated in the Info.plist keys
        if isMarkedDeprecatedInInfoPlist,
           let deadline = infoDictionary[OEGameCoreSupportDeadlineKey] as? Date,
           Date().compare(deadline) == .orderedDescending
        {
            // we are past the support deadline; return true to remove the core
            prepareForRemoval()
            return true
        }
        
        // missing value for required key 'CFBundleIdentifier' in Info.plist
        if infoDictionary["CFBundleIdentifier"] as? String == nil {
            return true
        }
        
        return false
    }
    
    private func prepareForRemoval() {
        let replacements = infoDictionary[OEGameCoreSuggestedReplacement] as? [String : String]
        
        let defaults = UserDefaults.standard
        for systemIdentifier in systemIdentifiers {
            let prefKey = "defaultCore." + systemIdentifier
            if let currentCore = defaults.string(forKey: prefKey),
               currentCore == bundleIdentifier
            {
                if let replacement = replacements?[systemIdentifier] {
                    defaults.set(replacement, forKey: prefKey)
                } else {
                    defaults.removeObject(forKey: prefKey)
                }
            }
        }
    }
}
