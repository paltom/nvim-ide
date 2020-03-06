if exists('g:loaded_ide_git')
  finish
endif
let g:loaded_ide_git = v:true

set updatetime=100
set signcolumn=yes
let g:gitgutter_diff_args = '--ignore-space-at-eol'

if !exists('g:custom_menu')
  let g:custom_menu = {}
endif
let g:custom_menu["IDE"] = add(
      \ get(g:custom_menu, "IDE", []),
      \ {
      \   "cmd": "git",
      \   "menu": [
      \     {
      \       "cmd": "branch",
      \       "action": { ->
      \                   execute("echo join(ide#git#list_branches(), '\n')", "")},
      \       "menu": [
      \         {
      \           "cmd": "new",
      \           "action": function("ide#git#new_branch")
      \         },
      \       ]
      \     },
      \     {
      \       "cmd": "checkout",
      \       "action": function("ide#git#checkout"),
      \       "complete": { ->
      \                     join(
      \                       map(
      \                         filter(
      \                           ide#git#list_branches(),
      \                           { _, branch -> branch !~# '\v^\s*\*\s+'}),
      \                         { _, branch -> matchstr(branch, '\v^(\s*remotes/)?\zs.*\ze$')}),
      \                       "\n"
      \                     )
      \                   }
      \     },
      \   ]
      \ }
      \)

call ext#plugins#load(ide#git#plugins)
