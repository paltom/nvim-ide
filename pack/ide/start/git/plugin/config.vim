if exists('g:loaded_ide_git')
  finish
endif
let g:loaded_ide_git = v:true

set updatetime=100
set signcolumn=yes
let g:gitgutter_diff_args = '--ignore-space-at-eol'

function! s:branches_complete(arg_lead, args)
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

function! s:git_add_complete(arg_lead, args)
  " multiple paths can be completed
  let l:git_output = s:get_git_output("ls-files --modified --others --exclude-standard")
  if empty(l:git_output)
    return []
  endif
  " filter out already added paths
  let l:paths = filter(l:git_output, { _, path -> index(a:args, path) < 0})
  return l:paths
endfunction

if !exists('g:custom_menu')
  let g:custom_menu = {}
endif
let g:custom_menu["Ide"] = add(
      \ get(g:custom_menu, "Ide", []),
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
      \       "complete": function("s:branches_complete")
      \     },
      \     {
      \       "cmd": "commit",
      \       "action": function("ide#git#commit")
      \     },
      \     {
      \       "cmd": "push",
      \       "action": function("ide#git#push")
      \     },
      \     {
      \       "cmd": "pull",
      \       "action": function("ide#git#pull")
      \     },
      \     {
      \       "cmd": "merge",
      \       "action": function("ide#git#merge"),
      \       "complete": function("s:branches_complete")
      \     },
      \     {
      \       "cmd": "fetch",
      \       "action": function("ide#git#fetch")
      \     },
      \     {
      \       "cmd": "head",
      \       "action": function("ide#git#head")
      \     },
      \     {
      \       "cmd": "add",
      \       "action": function("ide#git#add"),
      \       "complete": function("s:git_add_complete")
      \     }
      \   ]
      \ }
      \)

function! s:get_git_output(git_cmd)
  let l:git_cmd = "git --git-dir=%s --work-tree=%s %s"
  let l:git_dir = ide#git#git_dir()
  if empty(l:git_dir)
    return []
  endif
  let l:git_cmd_formatted = printf(l:git_cmd,
        \                     l:git_dir.expand("/.git"),
        \                     l:git_dir,
        \                     a:git_cmd)
  let l:git_output = split(execute("!".l:git_cmd_formatted), "\n")
  let l:git_output = map(l:git_output, { _, line -> trim(line)})
  " Remove Neovim-added lines
  let l:git_output = l:git_output[2:]
  return l:git_output
endfunction

function! s:git_changes()
  let l:git_output = s:get_git_output("diff --stat")
  function! s:get_summary_values(output)
    if empty(a:output)
      let l:files = 0
      let l:added = 0
      let l:removed = 0
    else
      let l:summary = a:output[-1]
      let [l:files, _, l:added, _, l:removed] =
            \ matchlist(l:summary, '\v((\d+) files? changed)(, (\d+) insertions?\(\+\))?(, (\d+) deletions?\(\-\))?')[2:6]
      let l:files = empty(l:files) ? 0 : l:files
      let l:added = empty(l:added) ? 0 : l:added
      let l:removed = empty(l:removed) ? 0 : l:removed
    endif
    return [l:files, l:added, l:removed]
  endfunction
  let [l:files, l:added, l:removed] = s:get_summary_values(l:git_output)
  return printf("+%d -%d (in %d files)", l:added, l:removed, l:files)
endfunction

function! s:git_changed_files()
  let l:git_output = s:get_git_output("ls-files --modified")
  return l:git_output
endfunction

function! s:git_repo_path()
  let l:repo_path = ide#git#git_dir()
  if empty(l:repo_path)
    return 'Not in git repository'
  endif
  let l:repo_path = fnamemodify(l:repo_path, ":~")
  return l:repo_path
endfunction

if !exists('g:info_sections')
  let g:info_sections = {}
endif
let g:info_sections["git"] = {
      \ "name": "Git",
      \ "subsections": [
      \   {
      \     "name": "Repository path",
      \     "function": function("s:git_repo_path")
      \   },
      \   {
      \     "name": "Status",
      \     "subsections": [
      \       {
      \         "name": "Current HEAD",
      \         "function": function("ide#git#head")
      \       },
      \       {
      \         "name": "Changes summary",
      \         "function": function("s:git_changes")
      \       },
      \       {
      \         "name": "Files changed",
      \         "function": function("s:git_changed_files")
      \       }
      \     ]
      \   }
      \ ]
      \}

call ext#plugins#load(ide#git#plugins)
