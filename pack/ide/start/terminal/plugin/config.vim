if exists("g:loaded_ide_terminal")
  finish
endif
let g:loaded_ide_terminal = v:true

let g:neoterm_default_mod = "botright"
let g:neoterm_autoscroll = v:true
" TODO test it
let g:neoterm_term_per_tab = v:true
let g:neoterm_autoinsert = v:true
augroup ide_terminal_autoinsert
  autocmd!
  autocmd BufEnter term://* startinsert
  autocmd BufLeave term://* stopinsert
augroup end

if !exists("g:custom_menu")
  let g:custom_menu = {}
endif
let g:custom_menu["Ide"] = add(
      \ get(g:custom_menu, "Ide", []),
      \ {
      \   "cmd": "terminal",
      \   "menu": [
      \     {
      \       "cmd": "new",
      \       "action": function("ide#terminal#new")
      \     }
      \   ]
      \ }
      \)

function! s:terminal_filename(bufname)
  let l:bufname = fnamemodify(a:bufname, ":p")
  " term://.//15871:/bin/bash ;#neoterm
  " get rid of ' ;#neoterm' part
  let l:term_uri = split(l:bufname)[0]
  let l:filename_elems = matchlist(
        \ l:term_uri,
        \ '\v^(.{-}):.*/([0-9]+):(.*)$'
        \)[1:3]
  " FIXME handle tabpage's terminal
  let l:buffer_term_id = getbufvar(a:bufname, "neoterm_id")
  if !empty(l:buffer_term_id)
    let l:filename_elems = add(l:filename_elems, "#".l:buffer_term_id)
  endif
  return join(l:filename_elems, ":")
endfunction

if !exists("g:statusline_filename_special_name_patterns")
  let g:statusline_filename_special_name_patterns = []
endif
let g:statusline_filename_special_name_patterns = add(
      \ g:statusline_filename_special_name_patterns,
      \ {
      \   "if": { c -> fnamemodify(c["bufname"], ":p") =~# '\v^term:' },
      \   "call": { c -> s:terminal_filename(c["bufname"]) }
      \ }
      \)

call ext#plugins#load(ide#terminal#plugins)
