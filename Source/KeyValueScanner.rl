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

// ****
// Generated with
//
// ragel -L -C KeyValueScanner.rl -o KeyValueScanner.gen.m
//
// ****

#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "KeyValueScanner+Private.h"

%%{
    machine KVScanner;
    write data;
}%%

void kv_scanner_init( PKVScanner ps, uint8_t const * src, size_t src_len )
{
    KVScanner *s  = (KVScanner *)ps;
    memset (s, 0, sizeof(KVScanner));
    s->src      = src;
    s->src_len  = src_len;
    s->p        = src;
    s->pe       = src + src_len;
    s->eof      = s->pe;
    %% write init;
}

#define ret_tok( _tok ) token = _tok;

KVToken kv_scanner_scan( PKVScanner ps )
{
    KVScanner *s = (KVScanner *)ps;
    KVToken token = KVTokenNone;
    
    while ( !s->done ) {
        // Check for EOF
        if ( s->p >= s->pe ) {
            s->len  = 0;
            token   = KVTokenEOF;
            s->done = true;
            break;
        }
        
        %%{
            machine KVScanner;
            access s->;
            variable p s->p;
            variable pe s->pe;
            variable eof s->eof;
            
            action token_start { /* action: token_start */ s->ts = s->p; }
            action token_end   { /* action: token_end   */ s->te = s->p; }
            
            string =
                '"' %token_start ( [^\\"] | '\\' any ) * %token_end %{ ret_tok( KVTokenString ); fbreak; } '"'
                ;
            
            identifier =
                ( [a-zA-Z_] >token_start ( alnum | [_] )* ) %token_end %{ ret_tok( KVTokenIdentifier ); fbreak; }
                ;

            system_identifier =
                ( '$' >token_start ( alnum | [_] )* ) %token_end %{ ret_tok( KVTokenSystemIdentifier ); fbreak; }
                ;

            float =
                ( [+\-]? >token_start digit+ ( '.' digit* )? ) %token_end %{ ret_tok( KVTokenFloat ); fbreak; }
                ;
                
            key_value =
                ( system_identifier '=' string ) |
                (        identifier '=' float  )
                ;
                
            key_values =
                key_value ( ';' key_value )*
                ;
            
            main := key_values
                ;
            
            write exec;
        }%%
        
        if ( s->cs == KVScanner_error )
        {
            return KVTokenError;
        }
        
        if ( token != KVTokenNone )
        {
            s->len = s->te - s->ts;
            return token;
        }
    }
    
    return KVTokenEOF;
}
