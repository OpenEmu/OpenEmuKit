
/* #line 1 "ShaderPresetScanner.rl" */
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

// ****
// Generated with
//
// ragel -L -C ShaderPresetScanner.rl -o ShaderPresetScanner.gen.m
//
// ****

#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "ShaderPresetScanner+Private.h"


/* #line 41 "ShaderPresetScanner.gen.m" */
static const char _Scanner_actions[] = {
	0, 1, 0, 1, 1, 1, 4, 1, 
	5, 2, 0, 1, 2, 1, 2, 2, 
	1, 3
};

static const char _Scanner_key_offsets[] = {
	0, 0, 6, 8, 10, 12, 13, 15, 
	17, 18, 23, 31, 33, 33, 33, 37
};

static const char _Scanner_trans_keys[] = {
	34, 95, 65, 90, 97, 122, 34, 92, 
	34, 92, 44, 58, 34, 34, 92, 34, 
	92, 58, 95, 65, 90, 97, 122, 61, 
	95, 48, 57, 65, 90, 97, 122, 48, 
	57, 46, 59, 48, 57, 59, 48, 57, 
	0
};

static const char _Scanner_single_lengths[] = {
	0, 2, 2, 2, 2, 1, 2, 2, 
	1, 1, 2, 0, 0, 0, 2, 1
};

static const char _Scanner_range_lengths[] = {
	0, 2, 0, 0, 0, 0, 0, 0, 
	0, 2, 3, 1, 0, 0, 1, 1
};

static const char _Scanner_index_offsets[] = {
	0, 0, 5, 8, 11, 14, 16, 19, 
	22, 24, 28, 34, 36, 37, 38, 42
};

static const char _Scanner_trans_targs[] = {
	2, 10, 10, 10, 0, 4, 13, 3, 
	4, 13, 3, 5, 9, 0, 6, 0, 
	8, 12, 7, 8, 12, 7, 9, 0, 
	10, 10, 10, 0, 11, 10, 10, 10, 
	10, 0, 14, 0, 7, 3, 15, 9, 
	14, 0, 9, 15, 0, 0
};

static const char _Scanner_trans_actions[] = {
	0, 1, 1, 1, 0, 9, 1, 1, 
	3, 0, 0, 5, 7, 0, 0, 0, 
	9, 1, 1, 3, 0, 0, 7, 0, 
	1, 1, 1, 0, 12, 0, 0, 0, 
	0, 0, 1, 0, 0, 0, 0, 15, 
	0, 0, 15, 0, 0, 0
};

static const char _Scanner_eof_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 15, 15
};

static const int Scanner_start = 1;
static const int Scanner_first_final = 14;
static const int Scanner_error = 0;

static const int Scanner_en_main = 1;


/* #line 40 "ShaderPresetScanner.rl" */


void scanner_init( PScanner ps, uint8_t const * src, size_t src_len )
{
    Scanner *s  = (Scanner *)ps;
    memset (s, 0, sizeof(Scanner));
    s->src      = src;
    s->src_len  = src_len;
    s->p        = src;
    s->pe       = src + src_len;
    s->eof      = s->pe;
    
/* #line 120 "ShaderPresetScanner.gen.m" */
	{
	 s->cs = Scanner_start;
	}

/* #line 52 "ShaderPresetScanner.rl" */
}

#define ret_tok( _tok ) token = _tok;

ScannerToken scanner_scan( PScanner ps )
{
    Scanner *s = (Scanner *)ps;
    ScannerToken token = ScannerTokenNone;
    
    while ( !s->done ) {
        // Check for EOF
        if ( s->p >= s->pe ) {
            s->len  = 0;
            token   = ScannerTokenEOF;
            s->done = true;
            break;
        }
        
        
/* #line 145 "ShaderPresetScanner.gen.m" */
	{
	int _klen;
	unsigned int _trans;
	const char *_acts;
	unsigned int _nacts;
	const char *_keys;

	if ( ( s->p) == ( s->pe) )
		goto _test_eof;
	if (  s->cs == 0 )
		goto _out;
_resume:
	_keys = _Scanner_trans_keys + _Scanner_key_offsets[ s->cs];
	_trans = _Scanner_index_offsets[ s->cs];

	_klen = _Scanner_single_lengths[ s->cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + _klen - 1;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + ((_upper-_lower) >> 1);
			if ( (*( s->p)) < *_mid )
				_upper = _mid - 1;
			else if ( (*( s->p)) > *_mid )
				_lower = _mid + 1;
			else {
				_trans += (unsigned int)(_mid - _keys);
				goto _match;
			}
		}
		_keys += _klen;
		_trans += _klen;
	}

	_klen = _Scanner_range_lengths[ s->cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + (_klen<<1) - 2;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( (*( s->p)) < _mid[0] )
				_upper = _mid - 2;
			else if ( (*( s->p)) > _mid[1] )
				_lower = _mid + 2;
			else {
				_trans += (unsigned int)((_mid - _keys)>>1);
				goto _match;
			}
		}
		_trans += _klen;
	}

_match:
	 s->cs = _Scanner_trans_targs[_trans];

	if ( _Scanner_trans_actions[_trans] == 0 )
		goto _again;

	_acts = _Scanner_actions + _Scanner_trans_actions[_trans];
	_nacts = (unsigned int) *_acts++;
	while ( _nacts-- > 0 )
	{
		switch ( *_acts++ )
		{
	case 0:
/* #line 77 "ShaderPresetScanner.rl" */
	{ /* action: token_start */ s->ts = s->p; }
	break;
	case 1:
/* #line 78 "ShaderPresetScanner.rl" */
	{ /* action: token_end   */ s->te = s->p; }
	break;
	case 2:
/* #line 85 "ShaderPresetScanner.rl" */
	{ ret_tok( ScannerTokenIdentifier ); {( s->p)++; goto _out; } }
	break;
	case 3:
/* #line 89 "ShaderPresetScanner.rl" */
	{ ret_tok( ScannerTokenFloat ); {( s->p)++; goto _out; } }
	break;
	case 4:
/* #line 101 "ShaderPresetScanner.rl" */
	{ ret_tok( ScannerTokenName   ); {( s->p)++; goto _out; } }
	break;
	case 5:
/* #line 102 "ShaderPresetScanner.rl" */
	{ ret_tok( ScannerTokenShader ); {( s->p)++; goto _out; } }
	break;
/* #line 242 "ShaderPresetScanner.gen.m" */
		}
	}

_again:
	if (  s->cs == 0 )
		goto _out;
	if ( ++( s->p) != ( s->pe) )
		goto _resume;
	_test_eof: {}
	if ( ( s->p) == ( s->eof) )
	{
	const char *__acts = _Scanner_actions + _Scanner_eof_actions[ s->cs];
	unsigned int __nacts = (unsigned int) *__acts++;
	while ( __nacts-- > 0 ) {
		switch ( *__acts++ ) {
	case 1:
/* #line 78 "ShaderPresetScanner.rl" */
	{ /* action: token_end   */ s->te = s->p; }
	break;
	case 3:
/* #line 89 "ShaderPresetScanner.rl" */
	{ ret_tok( ScannerTokenFloat ); {( s->p)++; goto _out; } }
	break;
/* #line 266 "ShaderPresetScanner.gen.m" */
		}
	}
	}

	_out: {}
	}

/* #line 109 "ShaderPresetScanner.rl" */

        
        if ( s->cs == Scanner_error )
        {
            return ScannerTokenError;
        }
        
        if ( token != ScannerTokenNone )
        {
            s->len = s->te - s->ts;
            return token;
        }
    }
    
    return ScannerTokenEOF;
}
