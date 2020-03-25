if exists("g:loaded_test")
  finish
endif
let g:loaded_test = v:true

function! s:execute_tests(write_and_source, suite_name)
  if empty(a:suite_name)
    let l:suite_name = expand("%:p")
  elseif a:suite_name ==# "%"
    let l:suite_name = expand("%")
  else
    let l:suite_name = a:suite_name
  endif
  if a:write_and_source
    write
    source %
  endif
  call test#execute(l:suite_name)
  echo test#report(l:suite_name)
endfunction

command! -nargs=? -bang TestIt call s:execute_tests(<bang>v:false, <q-args>)

" for folding test code in pack/ directory
augroup test_set_folding_test_methods
  autocmd!
  function! s:setup_folds()
    let l:winnr = winnr()
    let s:original_fdm = getwinvar(l:winnr, "&foldmarker")
    let s:original_fdt = getwinvar(l:winnr, "&foldtext")
    setlocal foldmethod=marker
    let l:foldtext = "v:folddashes"
    let l:foldtext.= ".' '."
    let l:foldtext.= "matchstr(getline(v:foldstart),'\\v^\\s*function!?\\s+s:tests\\.\\zs.{-}\\ze\\(')"
    let l:foldtext.= ".' '."
    let l:foldtext.= "'('.(v:foldend - v:foldstart).' lines)'"
    call setwinvar(l:winnr, "&foldtext", l:foldtext)
  endfunction
  function! s:reset_folds()
    let l:winnr = winnr()
    call setwinvar(l:winnr, "&foldmarker", s:original_fdm)
    call setwinvar(l:winnr, "&foldtext", s:original_fdt)
  endfunction
  autocmd BufWinEnter pack/**/*.vim call s:setup_folds()
  autocmd BufWinLeave pack/**/*.vim call s:reset_folds()
augroup end

