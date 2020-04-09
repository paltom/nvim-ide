let s:guard = "g:loaded_ide_git"
if exists(s:guard)
  finish
endif
let {s:guard} = v:true

set updatetime=100
set signcolumn=yes
let g:gitgutter_diff_args = "--ignore-space-at-eol"

function! s:git_buf_filename(bufname)
  let l:bufname = path#full(a:bufname)
  if l:bufname !~# '\v^'.path#join("fugitive:", "").'{2,}'
    return v:null
  endif
  let l:git_buf_type = matchstr(
        \ path#full(a:bufname),
        \ '\v'.escape(path#join(".git", ""), '\.').'{2}\zs\x+\ze',
        \)
  if empty(l:git_buf_type)
    return v:null
  endif
  if l:git_buf_type == "0"
    let l:git_type_name = "index"
  elseif l:git_buf_type == "2"
    let l:git_type_name = "current"
  elseif l:git_buf_type == "3"
    let l:git_type_name = "incoming"
  else
    let l:git_type_name = "(".l:git_buf_type[:7].")"
  endif
  let l:git_filename = path#filename(a:bufname)." @ ".l:git_type_name
  return l:git_filename
endfunction
call config#statusline#custom_filename_handler(funcref("s:git_buf_filename"))

call config#ext_plugins#load(ide#git#plugins)
