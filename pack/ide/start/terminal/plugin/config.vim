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

let s:term_cmd = {"cmd": "Terminal"}
let s:term_menu = []
let s:term_cmd["menu"] = s:term_menu
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

call config#ext_plugins#load(ide#terminal#plugins)
