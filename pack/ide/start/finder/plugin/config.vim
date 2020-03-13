if exists("g:loaded_ide_finder")
  finish
endif
let g:loaded_ide_finder = v:true

let g:fzf_layout = {"window": "botright 12 split enew"}
let g:fzf_action = {
      \ "ctrl-t": "tab split",
      \ "ctrl-s": "split",
      \ "ctrl-v": "vsplit",
      \}

function! s:find_git_branches()
  let l:dict = {
        \ "source": ide#git#list_branches()
        \}
  function! l:dict.sink(lines)
    " take no action if current branch is selected (starts with '*')
    if a:lines !~ '\v^\s*\*'
      let l:remote_branch_name_pattern = '\v^\s*remotes/[^/]*/\zs.*\ze$'
      " remove 'remotes/' prefix if remote branch is selected
      if a:lines =~# l:remote_branch_name_pattern
        let l:branch_name = matchstr(a:lines, l:remote_branch_name_pattern)
      else
        let l:branch_name = a:lines
      endif
      call ide#git#checkout(l:branch_name)
    endif
  endfunction
  call fzf#run(fzf#wrap(l:dict))
endfunction

" Ide custom menu configuration
if !exists("g:custom_menu")
  let g:custom_menu = {}
endif
let g:custom_menu["Ide"] = add(
      \ get(g:custom_menu, "Ide", []),
      \ {
      \   "cmd": "find",
      \   "menu": [
      \     {
      \       "cmd": "git",
      \       "menu": [
      \         {
      \           "cmd": "branch",
      \           "action": function("s:find_git_branches")
      \         },
      \         {
      \           "cmd": "files",
      \           "action": "GitFiles"
      \         },
      \         {
      \           "cmd": "commits",
      \           "action": "Commits",
      \           "menu": [
      \             {
      \               "cmd": "file",
      \               "action": "BCommits"
      \             }
      \           ]
      \         }
      \       ]
      \     },
      \     {
      \       "cmd": "files",
      \       "action": "Files"
      \     },
      \     {
      \       "cmd": "buffers",
      \       "action": "Buffers"
      \     },
      \     {
      \       "cmd": "windows",
      \       "action": "Windows"
      \     }
      \   ]
      \ }
      \)

call ext#plugins#load(ide#finder#plugins)
