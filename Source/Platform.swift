// Copyright (c) 2026, OpenEmu Team
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

public class Platform {
    
    public static var isAppleSilicon: Bool {
        var cpu: cpu_type_t = 0
        var size = MemoryLayout<cpu_type_t>.size
        
        let res = sysctlbyname("hw.cputype", &cpu, &size, nil, 0)
        guard res == 0 else { return false }
        
        // Check whether the CPU is ARM-family (or that Rosetta has translated)
        return ((UInt32(cpu) & ~CPU_ARCH_MASK) == cpu_type_t(CPU_TYPE_ARM)) || isRunningUnderRosetta()
    }
    
    public static var isIntelX86: Bool {
        var cpu: cpu_type_t = 0
        var size = MemoryLayout<cpu_type_t>.size
        
        let res = sysctlbyname("hw.cputype", &cpu, &size, nil, 0)
        guard res == 0 else { return false }
        
        // Check whether the CPU is X86-family (and that Rosetta hasn't translated, since
        // sysctlbyname("hw.cputype", ..) will return CPU_TYPE_X86 for Rosetta translated processes)
        return ((UInt32(cpu) & ~CPU_ARCH_MASK) == cpu_type_t(CPU_TYPE_X86)) && !isRunningUnderRosetta()
    }
    
    public static var isRosettaAvailable: Bool {
        if #unavailable(macOS 28.0), isAppleSilicon {
            return true     // Rosetta 2 is supported on Apple Silicon Macs on macOS 27 and lower
        } else {
            return false
        }
    }
    
    
    private static func isRunningUnderRosetta() -> Bool {
        var procTranslated: Int32 = 0
        var size = MemoryLayout<Int32>.size
        
        let res = sysctlbyname("sysctl.proc_translated", &procTranslated, &size, nil, 0)
        guard res == 0 else { return false }
        
        return procTranslated == 1
    }
}
