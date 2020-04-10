let s:guard = "g:loaded_ide_explorer"
if exists(s:guard)
  finish
endif
let {s:guard} = v:true

let g:dirvish_mode = ':sort ,^.*[\/],'
augroup ide_explorer_settings
  autocmd!
  autocmd FileType dirvish setlocal nonumber norelativenumber
augroup end

function! s:explorer_buf_filename(bufname)
  if &filetype ==# "dirvish"
    return path#full(a:bufname)
  endif
  return v:null
endfunction
call config#statusline#custom_filename_handler(funcref("s:explorer_buf_filename"))

call config#ext_plugins#load(ide#explorer#plugins)
