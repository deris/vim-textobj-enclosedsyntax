syntax enable

let s:test_perl = themis#suite('Test textobj-enclosedsyntax for perl syntax')

function! s:test_perl.__regex__()
  let regex = themis#suite('Test for regex textobj')

  function! regex.before_each()
    new
    silent put! =[
      \ '/',
      \ 'hoge',
      \ '/;',
      \ '/',
      \ 'fuga',
      \ '/;',
      \ ]
    set filetype=perl
  endfunction

  function! regex.after_each()
    quit!
  endfunction

  " 1つ目のdaqで/hoge/を削除して、2つ目のdaqで/fuga/を削除するテストだが、
  " :2で移動したタイミングでsyntaxが['perlMatch', 'perlMatchStartEnd']と
  " なるのを期待しているが、themisで実行すると想定と異なり['perlMatchStartEnd']が返る
  " (Vimを起動して操作した場合は想定通りの動きになる)
  " なお、textobj-enclosedsyntaxはsyntaxを考慮するため、ファイル頭でsyntax enableしている
  function! regex.daq_NG_case()
    1
    normal daq
    2
    Assert Equals(map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")'), ['perlMatch', 'perlMatchStartEnd'])
    normal daq
    Assert Equals(getline(1),  ';')
    Assert Equals(getline(2),  ';')
  endfunction

  " 1つ目のdaq後にsyntax enableすると、想定通りの動きになる
  " 1つ目のdaq後のsyntaxがおかしくなっている模様
  function! regex.daq_OK_case()
    1
    normal daq
    syntax enable
    2
    Assert Equals(map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")'), ['perlMatch', 'perlMatchStartEnd'])
    normal daq
    Assert Equals(getline(1),  ';')
    Assert Equals(getline(2),  ';')
  endfunction
endfunction
