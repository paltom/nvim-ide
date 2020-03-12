if exists('g:loaded_ide_terminal')
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

let s:tab_terminals_map = {}
" move to autoload?
function! s:terminal_new()
  Tnew
  let s:tab_terminals_map[tabpagenr()] = g:neoterm.last_id
endfunction

if !exists('g:custom_menu')
  let g:custom_menu = {}
endif
let g:custom_menu["Ide"] = add(
      \ get(g:custom_menu, "Ide", []),
      \ {
      \   "cmd": "terminal",
      \   "menu": [
      \     {
      \       "cmd": "new",
      \       "action": "Tnew"
      \     }
      \   ]
      \ }
      \)

function! s:terminal_filename(bufname)
  let l:bufname = fnamemodify(a:bufname, ":p")
  let l:shell_name = matchstr(split(l:bufname)[0], '\v\/\zs[^/]*$')
  let l:filename = l:shell_name
  if exists("t:neoterm_id")
    let l:filename = l:shell_name.":#".t:neoterm_id
  endif
  return "term:".l:filename
endfunction

if !exists("g:statusline_filename_special_patterns")
  let g:statusline_filename_special_patterns = []
endif
let g:statusline_filename_special_patterns =
      \ add(g:statusline_filename_special_patterns, {
      \   "pattern": '\v^term:',
      \   "filename_function": function("s:terminal_filename")
      \ }
      \)

call ext#plugins#load(ide#terminal#plugins)
