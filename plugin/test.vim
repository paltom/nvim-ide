if exists("g:loaded_test")
  finish
endif
let g:loaded_test = v:true

function! s:execute_tests(write_and_source)
  if a:write_and_source
    write
    source %
  endif
  let l:suite_name = expand("%:p")
  call test#execute(l:suite_name)
  echo test#report(l:suite_name)
endfunction

command! -bang TestIt call s:execute_tests(<bang>v:false)
