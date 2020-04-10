let s:guard = "g:loaded_ide_terminal"
if exists(s:guard)
  finish
endif
let {s:guard} = v:true

let g:neoterm_default_mod = "botright"
let g:neoterm_autoscroll = v:true
let g:neoterm_autoinsert = v:true
augroup ide_terminal_autoinsertmode
  autocmd!
  autocmd BufEnter term://* startinsert
  autocmd BufLeave term://* stopinsert
augroup end

let s:term_cmd = {"cmd": "Terminal", "action": {a,f,m -> ide#terminal#show()}}
let s:term_new = {"cmd": "new", "action": {a,f,m -> ide#terminal#new()}}
function! s:complete_tabpage_term_ids(arglead, args)
  let l:tabpage_term_ids = ide#terminal#tabpage_term_ids()
  let l:args = list#map({_, a -> str2nr(a)})(a:args)
  let l:tabpage_term_ids = list#filter({_, term_id -> !list#contains(l:args, term_id)})
        \(l:tabpage_term_ids)
  return l:tabpage_term_ids
endfunction
let s:term_show = {
      \ "cmd": "show",
      \ "action": {a,f,m -> ide#terminal#show(a)},
      \ "complete": funcref("s:complete_tabpage_term_ids"),
      \}
let s:term_hide = {
      \ "cmd": "hide",
      \ "action": {a,f,m -> ide#terminal#hide(a)},
      \ "complete": funcref("s:complete_tabpage_term_ids"),
      \}
let s:term_exit = {
      \ "cmd": "exit",
      \ "action": {a,f,m -> ide#terminal#exit(a)},
      \ "complete": funcref("s:complete_tabpage_term_ids"),
      \}
" TODO repl submenu
let s:term_cmd["menu"] = [
      \ s:term_new,
      \ s:term_show,
      \ s:term_hide,
      \ s:term_exit,
      \]
let g:cmd_tree = add(get(g:, "cmd_tree", []), s:term_cmd)
call cmd_tree#update_commands()

function! s:terminal_filename(bufname)
  let l:bufname = path#full(a:bufname)
  if l:bufname !~# '\v^term:'
    return v:null
  endif
  let l:term_uri = split(l:bufname)[0]
  let l:filename_tokens = matchlist(
        \ l:term_uri,
        \ '\v^(.{-}):.*/(\d+):(.*)$',
        \)[1:3]
  let l:buf_term_id = getbufvar(a:bufname, "neoterm_id")
  if !empty(l:buf_term_id)
    let l:filename_tokens = add(l:filename_tokens, "#".l:buf_term_id)
  endif
  return join(l:filename_tokens, ":")
endfunction
call config#statusline#custom_filename_handler(funcref("s:terminal_filename"))
function! s:terminal_tabline_name(bufname)
  let l:bufname = path#full(a:bufname)
  if l:bufname !~# '\v^term:'
    return v:null
  endif
  let l:term_uri = split(l:bufname)[0]
  let l:filename_tokens = matchlist(
        \ l:term_uri,
        \ '\v^(.{-}):.*/\d+:(.*)$',
        \)[1:2]
  return join(l:filename_tokens, ":")
endfunction
call config#tabline#custom_filename_handler(funcref("s:terminal_tabline_name"))

call config#ext_plugins#load(ide#terminal#plugins)
