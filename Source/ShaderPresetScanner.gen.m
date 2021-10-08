
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

#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "ShaderPresetScanner+Private.h"


/* #line 34 "ShaderPresetScanner.gen.m" */
static const char _Scanner_actions[] = {
	0, 1, 0, 1, 1, 1, 2, 1, 
	3, 1, 4, 1, 5, 1, 6, 1, 
	7, 1, 8, 1, 9
};

static const char _Scanner_key_offsets[] = {
	0, 2, 2, 13, 15, 17
};

static const char _Scanner_trans_keys[] = {
	34, 92, 32, 34, 95, 9, 10, 48, 
	57, 65, 90, 97, 122, 34, 92, 48, 
	57, 95, 48, 57, 65, 90, 97, 122, 
	0
};

static const char _Scanner_single_lengths[] = {
	2, 0, 3, 2, 0, 1
};

static const char _Scanner_range_lengths[] = {
	0, 0, 4, 0, 1, 3
};

static const char _Scanner_index_offsets[] = {
	0, 3, 4, 12, 15, 17
};

static const char _Scanner_trans_targs[] = {
	2, 1, 0, 0, 2, 3, 5, 2, 
	4, 5, 5, 2, 2, 1, 0, 4, 
	2, 5, 5, 5, 5, 2, 2, 2, 
	2, 2, 2, 0
};

static const char _Scanner_trans_actions[] = {
	9, 0, 0, 0, 7, 5, 0, 7, 
	0, 0, 0, 11, 9, 0, 0, 0, 
	15, 0, 0, 0, 0, 13, 19, 19, 
	17, 15, 13, 0
};

static const char _Scanner_to_state_actions[] = {
	0, 0, 1, 0, 0, 0
};

static const char _Scanner_from_state_actions[] = {
	0, 0, 3, 0, 0, 0
};

static const char _Scanner_eof_trans[] = {
	24, 24, 0, 25, 26, 27
};

static const int Scanner_start = 2;
static const int Scanner_first_final = 2;
static const int Scanner_error = -1;

static const int Scanner_en_main = 2;


/* #line 33 "ShaderPresetScanner.rl" */


void scanner_init( PScanner ps, uint8_t const * src, size_t src_len )
{
    Scanner *s  = (Scanner *)ps;
    memset (s, 0, sizeof(Scanner));
    s->src      = src;
    s->src_len  = src_len;
    s->p        = src;
    s->pe       = src + src_len;
    s->eof      = 0;
    
/* #line 110 "ShaderPresetScanner.gen.m" */
	{
	 s->cs = Scanner_start;
	 s->ts = 0;
	 s->te = 0;
	 s->act = 0;
	}

/* #line 45 "ShaderPresetScanner.rl" */
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
        
        
/* #line 138 "ShaderPresetScanner.gen.m" */
	{
	int _klen;
	unsigned int _trans;
	const char *_acts;
	unsigned int _nacts;
	const char *_keys;

	if ( ( s->p) == ( s->pe) )
		goto _test_eof;
_resume:
	_acts = _Scanner_actions + _Scanner_from_state_actions[ s->cs];
	_nacts = (unsigned int) *_acts++;
	while ( _nacts-- > 0 ) {
		switch ( *_acts++ ) {
	case 1:
/* #line 1 "NONE" */
	{ s->ts = ( s->p);}
	break;
/* #line 157 "ShaderPresetScanner.gen.m" */
		}
	}

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
_eof_trans:
	 s->cs = _Scanner_trans_targs[_trans];

	if ( _Scanner_trans_actions[_trans] == 0 )
		goto _again;

	_acts = _Scanner_actions + _Scanner_trans_actions[_trans];
	_nacts = (unsigned int) *_acts++;
	while ( _nacts-- > 0 )
	{
		switch ( *_acts++ )
		{
	case 2:
/* #line 1 "NONE" */
	{ s->te = ( s->p)+1;}
	break;
	case 3:
/* #line 76 "ShaderPresetScanner.rl" */
	{ s->te = ( s->p)+1;}
	break;
	case 4:
/* #line 78 "ShaderPresetScanner.rl" */
	{ s->te = ( s->p)+1;{ ret_tok( ScannerTokenString ); {( s->p)++; goto _out; } }}
	break;
	case 5:
/* #line 84 "ShaderPresetScanner.rl" */
	{ s->te = ( s->p)+1;{ ret_tok( *s->p ); {( s->p)++; goto _out; } }}
	break;
	case 6:
/* #line 73 "ShaderPresetScanner.rl" */
	{ s->te = ( s->p);( s->p)--;{ ret_tok( ScannerTokenIdentifier ); {( s->p)++; goto _out; } }}
	break;
	case 7:
/* #line 81 "ShaderPresetScanner.rl" */
	{ s->te = ( s->p);( s->p)--;{ ret_tok( ScannerTokenNumber ); {( s->p)++; goto _out; } }}
	break;
	case 8:
/* #line 84 "ShaderPresetScanner.rl" */
	{ s->te = ( s->p);( s->p)--;{ ret_tok( *s->p ); {( s->p)++; goto _out; } }}
	break;
	case 9:
/* #line 84 "ShaderPresetScanner.rl" */
	{{( s->p) = (( s->te))-1;}{ ret_tok( *s->p ); {( s->p)++; goto _out; } }}
	break;
/* #line 254 "ShaderPresetScanner.gen.m" */
		}
	}

_again:
	_acts = _Scanner_actions + _Scanner_to_state_actions[ s->cs];
	_nacts = (unsigned int) *_acts++;
	while ( _nacts-- > 0 ) {
		switch ( *_acts++ ) {
	case 0:
/* #line 1 "NONE" */
	{ s->ts = 0;}
	break;
/* #line 267 "ShaderPresetScanner.gen.m" */
		}
	}

	if ( ++( s->p) != ( s->pe) )
		goto _resume;
	_test_eof: {}
	if ( ( s->p) == ( s->eof) )
	{
	if ( _Scanner_eof_trans[ s->cs] > 0 ) {
		_trans = _Scanner_eof_trans[ s->cs] - 1;
		goto _eof_trans;
	}
	}

	_out: {}
	}

/* #line 88 "ShaderPresetScanner.rl" */

        
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
