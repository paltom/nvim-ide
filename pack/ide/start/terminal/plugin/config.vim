if exists("g:loaded_ide_terminal")
  finish
endif
let g:loaded_ide_terminal = v:true

let g:neoterm_default_mod = "botright"
let g:neoterm_autoscroll = v:true
let g:neoterm_autoinsert = v:true
augroup ide_terminal_autoinsert
  autocmd!
  autocmd BufEnter term://* startinsert
  autocmd BufLeave term://* stopinsert
augroup end

function! s:tabpage_term_ids_complete(arg_lead, args)
  " complete only if there are no arguments already given
  if len(a:args) > 1
    return []
  endif
  let l:term_ids = copy(ide#terminal#get_tabpage_term_ids(tabpagenr()))
  echomsg string(l:term_ids)
  if empty(l:term_ids)
    return []
  endif
  let l:term_ids = add(l:term_ids, "all")
  return l:term_ids
endfunction

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
      \     },
      \     {
      \       "cmd": "open",
      \       "action": function("ide#terminal#open"),
      \       "complete": function("s:tabpage_term_ids_complete")
      \     },
      \     {
      \       "cmd": "close",
      \       "action": function("ide#terminal#close"),
      \       "complete": function("s:tabpage_term_ids_complete")
      \     },
      \     {
      \       "cmd": "exit",
      \       "action": function("ide#terminal#exit"),
      \       "complete": function("s:tabpage_term_ids_complete")
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
