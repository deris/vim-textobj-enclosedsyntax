" Text objects for an enclosed syntax.
" Version: 0.1.2
" Author : deris0126 <deris0126@gmail.com>
" License: So-called MIT/X license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}

if exists('g:loaded_textobj_enclosedsyntax')
  finish
endif
let g:loaded_textobj_enclosedsyntax = 1

let s:save_cpo = &cpo
set cpo&vim

if exists('g:enclosedsyntax_custom_mapping')
  " TODO:validate valiable more strictly
else
  let g:enclosedsyntax_custom_mapping = {
    \ 'perl': [
    \   { 'start': ['perlQQ','perlStringStartEnd'], 'end': ['perlStringStartEnd'] },
    \   { 'start': ['perlStringUnexpanded','perlStringStartEnd'], 'end': ['perlStringStartEnd'] },
    \   { 'start': ['perlString','perlStringStartEnd'], 'end': ['perlStringStartEnd'] },
    \   { 'start': ['perlHereDoc','perlStringStartEnd'], 'end': ['perlStringStartEnd'] },
    \   { 'start': ['perlAutoload','perlStringStartEnd'], 'end': ['perlStringStartEnd'] },
    \   { 'start': ['perlShellCommand','perlMatchStartEnd'], 'end': ['perlMatchStartEnd'] },
    \   { 'start': ['perlMatch','perlMatchStartEnd'], 'end': ['perlMatchStartEnd'] },
    \   { 'start': ['perlMatch','perlMatchStartEnd'], 'end': ['perlSubstitutionGQQ','perlMatchStartEnd'] },
    \   { 'start': ['perlMatch','perlMatchStartEnd'], 'end': ['perlSubstitutionSQ','perlMatchStartEnd'] },
    \   { 'start': ['perlMatch','perlMatchStartEnd'], 'end': ['perlTranslationGQ','perlMatchStartEnd'] },
    \ ],
    \ 'ruby': [
    \   { 'start': ['rubyString','rubyStringDelimiter'], 'end': ['rubyStringDelimiter'] },
    \   { 'start': ['rubyHeredocStart','rubyStringDelimiter'], 'end': ['rubyStringDelimiter'] },
    \   { 'start': ['rubyRegexp','rubyRegexpDelimiter'], 'end': ['rubyRegexpDelimiter'] },
    \   { 'start': ['rubySymbol','rubySymbolDelimiter'], 'end': ['rubySymbolDelimiter'] },
    \ ],
    \ 'eruby': [
    \   { 'start': ['erubyBlock','erubyDelimiter'], 'end': ['erubyDelimiter'] },
    \   { 'start': ['erubyExpression','erubyDelimiter'], 'end': ['erubyDelimiter'] },
    \   { 'start': ['erubyComment','erubyDelimiter'], 'end': ['erubyDelimiter'] },
    \ ],
    \ }
endif

call textobj#user#plugin('enclosedsyntax', {
\      '-': {
\        '*sfile*': expand('<sfile>:p'),
\        'select-a': 'aq',  '*select-a-function*': 'textobj#enclosedsyntax#select_a',
\        'select-i': 'iq',  '*select-i-function*': 'textobj#enclosedsyntax#select_i',
\      }
\    })

let &cpo = s:save_cpo
unlet s:save_cpo

" __END__  "{{{1
" vim: foldmethod=marker
