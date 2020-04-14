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

let s:explorer_cmd = {"cmd": "Explore", "action": {a,f,m -> ide#explorer#open("", m)}}
let s:explorer_path = {
      \ "cmd": "path",
      \ "action": {a,f,m -> ide#explorer#open(a[0], m)},
      \ "complete": {al,as -> getcompletion(al, "file")},
      \}
let s:explorer_rename = {
      \ "cmd": "rename",
      \ "action": {a,f,m -> ide#explorer#rename(a[0])},
      \ "condition": { -> &filetype ==# "dirvish"},
      \}
let s:explorer_cmd["menu"] = [
      \ s:explorer_path,
      \ s:explorer_rename,
      \]
let g:cmd_tree = add(get(g:, "cmd_tree", []), s:explorer_cmd)
call cmd_tree#update_commands()

function! s:explorer_buf_filename(bufname)
  if &filetype ==# "dirvish"
    return path#full(a:bufname)
  endif
  return v:null
endfunction
call config#statusline#custom_filename_handler(funcref("s:explorer_buf_filename"))

call config#ext_plugins#load(ide#explorer#plugins)
