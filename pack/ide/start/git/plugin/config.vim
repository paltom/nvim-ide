if exists('g:loaded_ide_git')
  finish
endif
let g:loaded_ide_git = v:true

set updatetime=100
set signcolumn=yes
let g:gitgutter_diff_args = '--ignore-space-at-eol'

function! s:checkout_complete(arg_lead, args)
  " only one argument should be completed, if there are already some args
  " fully entered, there is nothing to complete
  if len(a:args) > 1
    return []
  endif
  return map(
      \   filter(
      \     ide#git#list_branches(),
      \     { _, branch -> branch !~# '\v^\s*\*\s+'}),
      \   { _, branch -> matchstr(branch, '\v^(\s*remotes/)?\zs.*\ze$')})
endfunction

if !exists('g:custom_menu')
  let g:custom_menu = {}
endif
let g:custom_menu["IDE"] = add(
      \ get(g:custom_menu, "IDE", []),
      \ {
      \   "cmd": "git",
      \   "menu": [
      \     {
      \       "cmd": "status",
      \       "action": function("ide#git#status")
      \     },
      \     {
      \       "cmd": "branch",
      \       "action": "echo join(ide#git#list_branches(), '\n')",
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
      \       "complete": function("s:checkout_complete")
      \     },
      \   ]
      \ }
      \)

function! s:get_git_output(git_cmd)
  let l:git_cmd = "git --git-dir=%s --work-tree=%s %s"
  let l:git_cmd_formatted = printf(l:git_cmd,
        \                     b:git_dir,
        \                     fnamemodify(b:git_dir, ":p:h:h"),
        \                     a:git_cmd)
  let l:git_output = split(execute("!".l:git_cmd_formatted), "\n")
  let l:git_output = map(l:git_output, { _, line -> trim(line)})
  " Remove command line
  let l:git_output = l:git_output[2:]
  return l:git_output
endfunction

function! s:git_changes()
  let l:git_output = s:get_git_output("diff --stat")
  let l:summary = l:git_output[-1]
  let [l:files, l:added, l:removed] =
        \ matchlist(l:summary, '\v(\d+) files changed, (\d+) insertions\(\+\), (\d+) deletions\(\-\)')[1:3]
  return printf("+%d -%d (in %d files)", l:added, l:removed, l:files)
endfunction

function! s:git_changed_files()
  let l:git_output = s:get_git_output("diff --name-only")
  return l:git_output
endfunction

if !exists('g:info_sections')
  let g:info_sections = {}
endif
let g:info_sections["git"] = {
      \ "name": "Git",
      \ "subsections": {
      \   "repository": {
      \     "name": "Repository path",
      \     "function": { -> fnamemodify(b:git_dir, ":~:h") }
      \   },
      \   "status": {
      \     "name": "Status",
      \     "subsections": {
      \       "changes summary": {
      \         "name": "Changes summary",
      \         "function": function("s:git_changes")
      \       },
      \       "file list": {
      \         "name": "Files changed",
      \         "function": function("s:git_changed_files")
      \       }
      \     }
      \   }
      \ }
      \}

call ext#plugins#load(ide#git#plugins)
