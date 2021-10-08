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

#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "ShaderPresetScanner+Private.h"

%%{
    machine Scanner;
    write data;
}%%

void scanner_init( PScanner ps, uint8_t const * src, size_t src_len )
{
    Scanner *s  = (Scanner *)ps;
    memset (s, 0, sizeof(Scanner));
    s->src      = src;
    s->src_len  = src_len;
    s->p        = src;
    s->pe       = src + src_len;
    s->eof      = 0;
    %% write init;
}

#define ret_tok( _tok ) token = _tok; s->data = s->ts

ScannerToken scanner_scan( PScanner ps )
{
    Scanner *s = (Scanner *)ps;
    ScannerToken token = ScannerTokenNone;
    
    while ( !s->done ) {
        // Check for EOF
        if ( s->p == s->pe ) {
            s->len  = 0;
            token   = ScannerTokenEOF;
            s->done = true;
            break;
        }
        
        %%{
            machine Scanner;
            access s->;
            variable p s->p;
            variable pe s->pe;
            variable eof s->eof;
            
            main := |*
            
                # Identifiers
                ( [a-zA-Z_] [a-zA-Z0-9_]* ) => { ret_tok( ScannerTokenIdentifier ); fbreak; };
            
                # Ignore Whitespace
                [ \t\n];
            
                '"' ( [^\\"] | '\\' any ) * '"' => { ret_tok( ScannerTokenString ); fbreak; };
            
                # Number
                digit+ => { ret_tok( ScannerTokenNumber ); fbreak; };
            
                # Anything else
                any => { ret_tok( *s->p ); fbreak; };
            *|;
            
            write exec;
        }%%
        
        if ( s->cs == Scanner_error )
        {
            return ScannerTokenError;
        }
        
        if ( token != ScannerTokenNone )
        {
            s->len = s->p - s->data;
            return token;
        }
    }
    
    return ScannerTokenEOF;
}
