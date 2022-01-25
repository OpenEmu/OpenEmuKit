
/* #line 1 "KeyValueScanner.rl" */
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


/* #line 41 "KeyValueScanner.gen.m" */
static const char _KVScanner_actions[] = {
	0, 1, 0, 2, 1, 2, 2, 1, 
	3, 2, 1, 4, 2, 1, 5, 3, 
	0, 1, 2
};

static const char _KVScanner_key_offsets[] = {
	0, 0, 6, 14, 15, 17, 19, 19, 
	27, 31, 33, 34, 38
};

static const char _KVScanner_trans_keys[] = {
	36, 95, 65, 90, 97, 122, 61, 95, 
	48, 57, 65, 90, 97, 122, 34, 34, 
	92, 34, 92, 61, 95, 48, 57, 65, 
	90, 97, 122, 43, 45, 48, 57, 48, 
	57, 59, 46, 59, 48, 57, 59, 48, 
	57, 0
};

static const char _KVScanner_single_lengths[] = {
	0, 2, 2, 1, 2, 2, 0, 2, 
	2, 0, 1, 2, 1
};

static const char _KVScanner_range_lengths[] = {
	0, 2, 3, 0, 0, 0, 0, 3, 
	1, 1, 0, 1, 1
};

static const char _KVScanner_index_offsets[] = {
	0, 0, 5, 11, 13, 16, 19, 20, 
	26, 30, 32, 34, 38
};

static const char _KVScanner_indicies[] = {
	0, 2, 2, 2, 1, 4, 3, 3, 
	3, 3, 1, 5, 1, 7, 8, 6, 
	10, 11, 9, 9, 13, 12, 12, 12, 
	12, 1, 14, 14, 15, 1, 16, 1, 
	17, 1, 18, 19, 16, 1, 19, 18, 
	1, 0
};

static const char _KVScanner_trans_targs[] = {
	2, 0, 7, 2, 3, 4, 5, 10, 
	6, 5, 10, 6, 7, 8, 9, 11, 
	11, 1, 12, 1
};

static const char _KVScanner_trans_actions[] = {
	1, 0, 1, 0, 9, 0, 1, 15, 
	1, 0, 3, 0, 0, 6, 1, 1, 
	0, 0, 0, 12
};

static const char _KVScanner_eof_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 12, 12
};

static const int KVScanner_start = 1;
static const int KVScanner_first_final = 10;
static const int KVScanner_error = 0;

static const int KVScanner_en_main = 1;


/* #line 40 "KeyValueScanner.rl" */


void kv_scanner_init( PKVScanner ps, uint8_t const * src, size_t src_len )
{
    KVScanner *s  = (KVScanner *)ps;
    memset (s, 0, sizeof(KVScanner));
    s->src      = src;
    s->src_len  = src_len;
    s->p        = src;
    s->pe       = src + src_len;
    s->eof      = s->pe;
    
/* #line 123 "KeyValueScanner.gen.m" */
	{
	 s->cs = KVScanner_start;
	}

/* #line 52 "KeyValueScanner.rl" */
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
        
        
/* #line 148 "KeyValueScanner.gen.m" */
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
	_keys = _KVScanner_trans_keys + _KVScanner_key_offsets[ s->cs];
	_trans = _KVScanner_index_offsets[ s->cs];

	_klen = _KVScanner_single_lengths[ s->cs];
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

	_klen = _KVScanner_range_lengths[ s->cs];
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
	_trans = _KVScanner_indicies[_trans];
	 s->cs = _KVScanner_trans_targs[_trans];

	if ( _KVScanner_trans_actions[_trans] == 0 )
		goto _again;

	_acts = _KVScanner_actions + _KVScanner_trans_actions[_trans];
	_nacts = (unsigned int) *_acts++;
	while ( _nacts-- > 0 )
	{
		switch ( *_acts++ )
		{
	case 0:
/* #line 77 "KeyValueScanner.rl" */
	{ /* action: token_start */ s->ts = s->p; }
	break;
	case 1:
/* #line 78 "KeyValueScanner.rl" */
	{ /* action: token_end   */ s->te = s->p; }
	break;
	case 2:
/* #line 81 "KeyValueScanner.rl" */
	{ ret_tok( KVTokenString ); {( s->p)++; goto _out; } }
	break;
	case 3:
/* #line 85 "KeyValueScanner.rl" */
	{ ret_tok( KVTokenIdentifier ); {( s->p)++; goto _out; } }
	break;
	case 4:
/* #line 89 "KeyValueScanner.rl" */
	{ ret_tok( KVTokenSystemIdentifier ); {( s->p)++; goto _out; } }
	break;
	case 5:
/* #line 93 "KeyValueScanner.rl" */
	{ ret_tok( KVTokenFloat ); {( s->p)++; goto _out; } }
	break;
/* #line 246 "KeyValueScanner.gen.m" */
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
	const char *__acts = _KVScanner_actions + _KVScanner_eof_actions[ s->cs];
	unsigned int __nacts = (unsigned int) *__acts++;
	while ( __nacts-- > 0 ) {
		switch ( *__acts++ ) {
	case 1:
/* #line 78 "KeyValueScanner.rl" */
	{ /* action: token_end   */ s->te = s->p; }
	break;
	case 5:
/* #line 93 "KeyValueScanner.rl" */
	{ ret_tok( KVTokenFloat ); {( s->p)++; goto _out; } }
	break;
/* #line 270 "KeyValueScanner.gen.m" */
		}
	}
	}

	_out: {}
	}

/* #line 109 "KeyValueScanner.rl" */

        
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
