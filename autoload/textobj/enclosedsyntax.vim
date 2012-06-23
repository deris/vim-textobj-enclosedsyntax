" Text objects for an enclosed syntax.
" Version: 0.0.1
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

" Interface  "{{{1
" TODO:validate valiable
let g:enclosedsyntax_custom_mapping = {
  \ 'perl': [
  \   { 'start': ['perlQQ','perlStringStartEnd'], 'end': ['perlStringStartEnd'] },
  \   { 'start': ['perlMatch','perlMatchStartEnd'], 'end': ['perlMatchStartEnd'] },
  \   { 'start': ['perlMatch','perlMatchStartEnd'], 'end': ['perlSubstitutionGQQ','perlMatchStartEnd'] },
  \   { 'start': ['perlMatch','perlMatchStartEnd'], 'end': ['perlSubstitutionSQ','perlMatchStartEnd'] },
  \   { 'start': ['perlMatch','perlMatchStartEnd'], 'end': ['perlTranslationGQ','perlMatchStartEnd'] },
  \   { 'start': ['perlHereDoc','perlStringStartEnd'], 'end': ['perlStringStartEnd'] },
  \   { 'start': ['perlAutoload','perlStringStartEnd'], 'end': ['perlStringStartEnd'] },
  \ ],
  \ }

function! textobj#enclosedsyntax#select_a()  "{{{2
  return s:select(0)
endfunction

function! textobj#enclosedsyntax#select_i()  "{{{2
  return s:select(1)
endfunction



" Misc.  "{{{1
function! s:select(in)  "{{{2
  if empty(&ft)
    return 0
  endif

  if !has_key(g:enclosedsyntax_custom_mapping, &ft)
    return 0
  endif

  let [save_ww, save_lz] = [&whichwrap, &lazyredraw]
  set whichwrap=h,l lazyredraw

  let res = s:traverse_enclosedsyntax(a:in)

  let [&whichwrap, &lazyredraw] = [save_ww, save_lz]

  echo res
  return res
endfunction

function! s:traverse_enclosedsyntax(in)  "{{{2
  let c = getpos('.')
  let [b, e] = [c, c]


  let stack = []
  let prev_res = {}
  while 1
    let cur_line = line('.')
    let cur_col = col('.')
    let cur_syn = s:synname_stack(cur_line, cur_col)

    let res = s:match_enclosedsyntax(stack, prev_res, cur_syn)
    if type(res) == type(0)
      break
    endif
    if !empty(prev_res) && res != prev_res
      if !empty(stack) && has_key(stack[-1], 'start') && has_key(stack[-1], 'end')
        call remove(stack, -1)
      elseif len(stack) == 1 && has_key(stack[-1], 'start') && !has_key(stack[-1], 'end')
        normal! l
        break
      endif
    elseif a:in && !empty(res)
      if len(stack) == 1 && has_key(stack[-1], 'start') && !has_key(stack[-1], 'end')
        normal! l
        break
      endif
    endif
    let prev_res = deepcopy(res)

    if cur_line == 1 && cur_col == 1
      break
    endif
    normal! h
  endwhile

  if !(len(stack) == 1 && has_key(stack[-1], 'start') && !has_key(stack[-1], 'end'))
    call setpos('.', c)
    return 0
  endif

  let b = getpos('.')

  let btm_line = line('$')
  let prev_res = {}
  while 1
    let cur_line = line('.')
    let cur_col  = col('.')
    let cur_syn = s:synname_stack(cur_line, cur_col)

    let res = s:match_enclosedsyntax(stack, prev_res, cur_syn)
    if type(res) == type(0)
      break
    endif
    if !empty(prev_res) && res != prev_res
      if !empty(stack) && has_key(stack[-1], 'start') && has_key(stack[-1], 'end')
        if len(stack) == 1
          normal! h
          break
        elseif !empty(stack)
          call remove(stack, -1)
        endif
      endif
    elseif a:in && !empty(res)
      if len(stack) == 1 && has_key(stack[-1], 'start') && has_key(stack[-1], 'end')
        normal! h
        break
      endif
    endif
    let prev_res = deepcopy(res)

    if cur_line == btm_line && cur_col == col('$') - 1
      break
    endif
    normal! l
  endwhile

  if !(len(stack) == 1 && has_key(stack[-1], 'start') && has_key(stack[-1], 'end'))
    call setpos('.', c)
    return 0
  endif

  let e = getpos('.')
  call setpos('.', c)

  return ['v', b, e]
endfunction

function! s:match_enclosedsyntax(stack, prev_res, cur_syn)  "{{{2
  for enc_syn in g:enclosedsyntax_custom_mapping[&ft]
    if a:cur_syn == enc_syn.start
      if !empty(a:stack) && has_key(a:stack[-1], 'end')
        if enc_syn == { 'start': a:cur_syn, 'end': a:stack[-1].end }
          let a:stack[-1].start = a:cur_syn
          return a:stack[-1]
        else
          " TODO: error handling
          return 0
        endif
      else
        if empty(a:stack) ||
              \ (!empty(a:prev_res) && a:stack[-1] != a:prev_res)
          call add(a:stack, { 'start': a:cur_syn })
        endif
        return a:stack[-1]
      endif
    elseif a:cur_syn == enc_syn.end
      if !empty(a:stack) && has_key(a:stack[-1], 'start')
        if enc_syn == { 'start': a:stack[-1].start, 'end': a:cur_syn }
          let a:stack[-1].end = a:cur_syn
          return a:stack[-1]
        else
          " TODO: error handling
          return 0
        endif
      else
        if empty(a:stack) ||
              \ (!empty(a:prev_res) && a:stack[-1] != a:prev_res)
          call add(a:stack, { 'end': a:cur_syn })
        endif
        return a:stack[-1]
      endif
    endif
  endfor
  return {}
endfunction

function! s:synname_stack(line, col)  "{{{2
  let syns = synstack(a:line, a:col)
  let stack = []
  for syn in syns
    let synname = synIDattr(syn, "name")
    call add(stack, synname)
  endfor
  return stack
endfunction



" __END__  "{{{1
" vim: foldmethod=marker
