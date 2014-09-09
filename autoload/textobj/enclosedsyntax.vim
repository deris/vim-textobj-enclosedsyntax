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

" Public API "{{{1

function! textobj#enclosedsyntax#select_a() "{{{2
  call s:check_syntax_on()

  if empty(&ft)
    return 0
  endif

  if !has_key(g:enclosedsyntax_custom_mapping, &ft)
    return 0
  endif

  let [save_ww, save_lz] = [&whichwrap, &lazyredraw]
  set whichwrap=h,l lazyredraw

  try
    let res = s:traverse_enclosedsyntax()
  finally
    let [&whichwrap, &lazyredraw] = [save_ww, save_lz]
  endtry

  return res
endfunction
"}}}

function! textobj#enclosedsyntax#select_i() "{{{2
  call s:check_syntax_on()

  let c = getpos('.')
  let outer = textobj#enclosedsyntax#select_a()
  if type(outer) == type(0)
    return 0
  endif
  let [b, e] = outer[1:]

  let [save_ww, save_lz] = [&whichwrap, &lazyredraw]
  set whichwrap=h,l lazyredraw

  try
    let b = s:get_innerpos(b, 'l')
    let e = s:get_innerpos(e, 'h')
  finally
    let [&whichwrap, &lazyredraw] = [save_ww, save_lz]
  endtry

  call setpos('.', c)
  if b[1] > e[1] ||
        \ b[1] == e[1] && b[2] > e[2]
    return 0
  endif

  return ['v', b, e]
endfunction
"}}}

"}}}

" Private "{{{1
function! s:traverse_enclosedsyntax() "{{{2
  let c = getpos('.')
  let [b, e] = [c, c]


  let stack = []
  let prev_res = {}
  let first_flag = 1
  while 1
    let cur_line = line('.')
    let cur_col = col('.')
    let cur_syn = s:synname_stack(cur_line, cur_col)

    let res = s:match_enclosedsyntax(stack, prev_res, cur_syn)
    if type(res) == type(0)
      break
    endif
    if first_flag == 1 && has_key(res, 'end')
      let res = {}
      call remove(stack, -1)
    else
      let first_flag = 0
    endif
    if !empty(prev_res) && res != prev_res
      if !empty(stack) && has_key(stack[-1], 'start') && has_key(stack[-1], 'end')
        call remove(stack, -1)
      elseif len(stack) == 1 && has_key(stack[-1], 'start') && !has_key(stack[-1], 'end')
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
  call s:get_innerpos(b, 'l')

  let btm_line = line('$')
  let prev_res = {}
  let end_flag = 0
  while 1
    let cur_line = line('.')
    let cur_col  = col('.')
    let cur_syn = s:synname_stack(cur_line, cur_col)

    let res = s:match_enclosedsyntax(stack, prev_res, cur_syn)
    if type(res) == type(0)
      break
    endif
    if res != prev_res
      if !empty(stack) && has_key(stack[-1], 'start') && has_key(stack[-1], 'end')
        if len(stack) == 1
          if end_flag
            normal! h
            break
          else
            let end_flag = 1
          endif
        else
          call remove(stack, -1)
        endif
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
"}}}

function! s:match_enclosedsyntax(stack, prev_res, cur_syn) "{{{2
  for enc_syn in g:enclosedsyntax_custom_mapping[&ft]
    let start_diff = len(a:cur_syn) - len(enc_syn.start)
    if start_diff >= 0 && a:cur_syn[start_diff :] == enc_syn.start
      if !empty(a:stack) && has_key(a:stack[-1], 'end')
        if enc_syn == { 'start': a:cur_syn[start_diff :], 'end': a:stack[-1].end }
          let a:stack[-1].start = a:cur_syn[start_diff :]
          return a:stack[-1]
        endif
      else
        if empty(a:stack) ||
              \ (!empty(a:prev_res) && a:stack[-1] != a:prev_res)
          call add(a:stack, { 'start': a:cur_syn[start_diff :] })
        endif
        return a:stack[-1]
      endif
    endif
  endfor
  for enc_syn in g:enclosedsyntax_custom_mapping[&ft]
    let end_diff = len(a:cur_syn) - len(enc_syn.end)
    if end_diff >= 0 && a:cur_syn[end_diff :] == enc_syn.end
      if !empty(a:stack) && has_key(a:stack[-1], 'start')
        if enc_syn == { 'start': a:stack[-1].start, 'end': a:cur_syn[end_diff :] }
          let a:stack[-1].end = a:cur_syn[end_diff :]
          return a:stack[-1]
        endif
      else
        if empty(a:stack) ||
              \ (!empty(a:prev_res) && a:stack[-1] != a:prev_res)
          call add(a:stack, { 'end': a:cur_syn[end_diff :] })
        endif
        return a:stack[-1]
      endif
    endif
  endfor
  return {}
endfunction
"}}}

function! s:synname_stack(line, col) "{{{2
  let syns = synstack(a:line, a:col)
  let stack = []
  for syn in syns
    let synname = synIDattr(syn, "name")
    call add(stack, synname)
  endfor
  return stack
endfunction
"}}}

function! s:get_innerpos(pos, direct) "{{{2
  call setpos('.', a:pos)
  let first_syn = synstack(line('.'), col('.'))
  let cur_syn = first_syn
  while cur_syn == first_syn
    execute 'normal! ' a:direct
    let cur_syn = synstack(line('.'), col('.'))
  endwhile
  return getpos('.')
endfunction
"}}}

function! s:check_syntax_on() "{{{2
  if !exists('g:syntax_on')
    echoerr 'textobj-enclosedsyntax.vim needs `syntax on`'
  endif
endfunction
"}}}

"}}}

" __END__ "{{{1
" vim: foldmethod=marker
