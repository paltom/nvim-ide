if exists("g:loaded_ide_git")
  finish
endif
let g:loaded_ide_git = v:true

set updatetime=100
set signcolumn=yes
let g:gitgutter_diff_args = "--ignore-space-at-eol"

function! s:branches_complete(arg_lead, args)
  " only one argument should be completed, if there are already some args
  " fully entered, there is nothing to complete
  if len(a:args) > 1
    return []
  endif
  let l:other_branches = filter(ide#git#list_branches(),
        \ { _, branch -> branch !~# '\v^\s*\*\s+' }
        \)
  let l:other_branches_remote_removed = map(
        \ l:other_branches,
        \ { _, branch -> matchstr(branch, '\v^(\s*remotes/)?\zs.*\ze$') }
        \)
  return sort(l:other_branches_remote_removed)
endfunction

function! s:git_add_complete(arg_lead, args)
  " multiple paths can be completed
  let l:git_output = s:get_git_output(
        \ "ls-files --modified --others --exclude-standard"
        \)
  if empty(l:git_output)
    return []
  endif
  " filter out already added paths
  let l:paths = filter(l:git_output, { _, path -> index(a:args, path) < 0})
  return sort(l:paths)
endfunction

if !exists("g:custom_menu")
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
      \     },
      \     {
      \       "cmd": "diff",
      \       "action": function("ide#git#diff"),
      \     },
      \     {
      \       "cmd": "file",
      \       "menu": [
      \         {
      \           "cmd": "history",
      \           "action": { -> ide#git#file_log(bufname())},
      \         },
      \         {
      \           "cmd": "edit",
      \           "action": { -> ide#git#edit_working_file(bufname())},
      \         },
      \       ]
      \     }
      \   ]
      \ }
      \)

function! s:get_git_output(git_cmd)
  let l:git_cmd = "git --git-dir=%s --work-tree=%s %s"
  let l:git_dir = ide#git#root_dir()
  if empty(l:git_dir)
    return []
  endif
  let l:git_cmd_formatted = printf(
        \ l:git_cmd,
        \ l:git_dir.expand("/.git"),
        \ l:git_dir,
        \ a:git_cmd
        \)
  let l:git_output = systemlist(l:git_cmd_formatted)
  let l:git_output = map(l:git_output, { _, line -> trim(line)})
  return l:git_output
endfunction

function! s:git_changes()
  let l:git_output = s:get_git_output("diff --stat HEAD")
  function! s:get_summary_values(output)
    if empty(a:output)
      let l:files = 0
      let l:added = 0
      let l:removed = 0
    else
      let l:summary = a:output[-1]
      let [l:files, _, l:added, _, l:removed] = matchlist(
            \ l:summary,
            \ '\v((\d+) files? changed)'.
            \   '(, (\d+) insertions?\(\+\))?'.
            \   '(, (\d+) deletions?\(\-\))?'
            \)[2:6]
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
  let l:repo_path = ide#git#root_dir()
  if empty(l:repo_path)
    return "Not in git repository"
  endif
  let l:repo_path = fnamemodify(l:repo_path, ":~")
  return l:repo_path
endfunction

if !exists("g:info_sections")
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

function! s:git_buf_filename(bufname)
  let l:git_buf_type = matchstr(
        \ fnamemodify(a:bufname, ":p"),
        \ '\v\.git[/\\]{2}\zs\c[0-9a-f]+\ze'
        \)
  if empty(l:git_buf_type)
    return a:bufname
  endif
  if l:git_buf_type == "0"
    let l:git_type = "index"
  elseif l:git_buf_type == "2"
    let l:git_type = "current"
  elseif l:git_buf_type == "3"
    let l:git_type = "incoming"
  else
    let l:git_type = "(".l:git_buf_type[:7].")"
  endif
  let l:git_diff_filename = fnamemodify(a:bufname, ":t")." @ ".l:git_type
  return l:git_diff_filename
endfunction

if !exists("g:statusline_filename_special_name_patterns")
  let g:statusline_filename_special_name_patterns = []
endif
let g:statusline_filename_special_name_patterns = add(
      \ g:statusline_filename_special_name_patterns,
      \ {
      \   "if": { c ->
      \             fnamemodify(
      \               c["bufname"],
      \               ":p"
      \             ) =~# '\v^fugitive:[/\\]{2,}'
      \   },
      \   "call": { c -> s:git_buf_filename(c["bufname"]) }
      \ }
      \)

call ext#plugins#load(ide#git#plugins)
