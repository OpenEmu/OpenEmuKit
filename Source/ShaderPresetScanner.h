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

@import Foundation;

typedef NS_ENUM(NSUInteger, ScannerToken) {
    ScannerTokenNone        =  -1,
    ScannerTokenError       = 128,
    ScannerTokenEOF         = 129,
    ScannerTokenIdentifier  = 130,
    ScannerTokenNumber      = 131,
    ScannerTokenString      = 132,
    ScannerTokenColor       = 133, // :
    ScannerTokenAssign      = 134, // =
    ScannerTokenAt          = 135, // @
};

NS_ASSUME_NONNULL_BEGIN

typedef struct Scanner * PScanner __attribute__((__swift_wrapper__(struct)));

extern PScanner     scanner_create(void)
                    NS_SWIFT_NAME(PScanner.init());
extern void         scanner_destroy(PScanner s);
extern void         scanner_init( PScanner s, uint8_t const * src, size_t src_len )
                    NS_SWIFT_NAME(PScanner.setData(self:_:length:));
extern ScannerToken scanner_scan( PScanner s )
                    NS_SWIFT_NAME(PScanner.scan(self:));
extern NSString * _Nullable scanner_text(PScanner ps)
                    NS_SWIFT_NAME(getter:PScanner.text(self:));

NS_ASSUME_NONNULL_END
