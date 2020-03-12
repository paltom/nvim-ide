if exists('g:loaded_ide_terminal')
  finish
endif
let g:loaded_ide_terminal = v:true

let g:neoterm_default_mod = "botright"
let g:neoterm_autoscroll = v:true
" TODO test it
let g:neoterm_term_per_tab = v:true
let g:neoterm_autoinsert = v:true

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

call ext#plugins#load(ide#terminal#plugins)
