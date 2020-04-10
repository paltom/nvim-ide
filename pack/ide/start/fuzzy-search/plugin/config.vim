let s:guard = "g:loaded_ide_fuzzy_search"
if exists(s:guard)
  finish
endif
let {s:guard} = v:true

let g:fzf_layout = {"window": "botright 12 split enew"}
let g:fzf_action = {
      \ "ctrl-t": "tab split",
      \ "ctrl-s": "split",
      \ "ctrl-v": "vsplit",
      \}

function! s:search_git_branches()
  let l:dict = {"source": ide#git#branches_all()}
  function! l:dict.sink(lines)
    if a:lines !~# '\v^\s*\*'
      " remove 'remotes/' prefix
      let l:branch_name = matchstr(a:lines, '\v^\s*remotes/.{-}/\zs.*\ze$')
      call ide#git#checkout(l:branch_name)
    endif
  endfunction
  call fzf#run(fzf#wrap(l:dict))
endfunction

let s:search_cmd = {"cmd": "Search"}
let s:search_git = {"cmd": "git"}
let s:search_git_files = {"cmd": "files", "action": {a,f,m -> execute("GitFiles")}}
let s:search_git_branches = {"cmd": "branches", "action": {a,f,m -> funcref("s:search_git_branches")}}
let s:search_git_commits = {"cmd": "commits", "action": {a,f,m -> execute("Commits")}}
let s:search_git_commits_file = {"cmd": "file", "action": {a,f,m -> execute("BCommits")}}
let s:search_git_commits["menu"] = [
      \ s:search_git_commits_file,
      \]
let s:search_git["menu"] = [
      \ s:search_git_files,
      \ s:search_git_branches,
      \ s:search_git_commits,
      \]
let s:search_files = {"cmd": "files", "action": {a,f,m -> execute("Files")}}
let s:search_buffers = {"cmd": "buffers", "action": {a,f,m -> execute("Buffers")}}
let s:search_windows = {"cmd": "windows", "action": {a,f,m -> execute("Windows")}}
let s:search_cmd["menu"] = [
      \ s:search_git,
      \ s:search_files,
      \ s:search_buffers,
      \ s:search_windows,
      \]

call config#ext_plugins#load(ide#fuzzy_search#plugins)
