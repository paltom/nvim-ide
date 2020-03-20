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
