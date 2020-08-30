// Copyright (c) 2020, OpenEmu Team
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

#import "OEGameStartupInfo.h"

@implementation OEGameStartupInfo

- (instancetype)initWithROMPath:(NSString *)romPath romMD5:(NSString *)romMD5 romHeader:(NSString *)romHeader romSerial:(NSString *)romSerial systemRegion:(NSString *)systemRegion displayModeInfo:(NSDictionary <NSString *, id> *)displayModeInfo shader:(NSURL *)shader corePluginPath:(NSString *)pluginPath systemPluginPath:(NSString *)systemPluginPath
{
    if (self = [super init]) {
        _romPath            = romPath;
        _romMD5             = romMD5;
        _romHeader          = romHeader;
        _romSerial          = romSerial;
        _shader             = shader;
        _systemRegion       = systemRegion;
        _displayModeInfo    = displayModeInfo;
        _corePluginPath     = pluginPath;
        _systemPluginPath   = systemPluginPath;
    }
    return self;
}

- (NSString *)description
{
    return _romPath;
}

#pragma mark - NSSecureCoding

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super init]) {
        _romPath            = [coder decodeObjectOfClass:NSString.class forKey:@"romPath"];
        _romMD5             = [coder decodeObjectOfClass:NSString.class forKey:@"romMD5"];
        _romHeader          = [coder decodeObjectOfClass:NSString.class forKey:@"romHeader"];
        _romSerial          = [coder decodeObjectOfClass:NSString.class forKey:@"romSerial"];
        _shader             = [coder decodeObjectOfClass:NSURL.class forKey:@"shader"];
        _systemRegion       = [coder decodeObjectOfClass:NSString.class forKey:@"systemRegion"];
        _displayModeInfo    = [coder decodePropertyListForKey:@"displayModeInfo"];
        _corePluginPath     = [coder decodeObjectOfClass:NSString.class forKey:@"pluginPath"];
        _systemPluginPath   = [coder decodeObjectOfClass:NSString.class forKey:@"systemPluginPath"];
    }
    return self;
}

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:_romPath forKey:@"romPath"];
    [coder encodeObject:_romMD5 forKey:@"romMD5"];
    [coder encodeObject:_romHeader forKey:@"romHeader"];
    [coder encodeObject:_romSerial forKey:@"romSerial"];
    [coder encodeObject:_shader forKey:@"shader"];
    [coder encodeObject:_systemRegion forKey:@"systemRegion"];
    [coder encodeObject:_displayModeInfo forKey:@"displayModeInfo"];
    [coder encodeObject:_corePluginPath forKey:@"pluginPath"];
    [coder encodeObject:_systemPluginPath forKey:@"systemPluginPath"];
}

@end

