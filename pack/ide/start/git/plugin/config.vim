let s:guard = "g:loaded_ide_git"
if exists(s:guard)
  finish
endif
let {s:guard} = v:true

set updatetime=100
set signcolumn=yes
let g:gitgutter_diff_args = "--ignore-space-at-eol"

let s:git_cmd = {"cmd": "Git", "action": {a,f,m -> ide#git#status()}}
let s:git_status = {"cmd": "status", "action": {a,f,m -> ide#git#status()}}
function! s:git_head()
  echo ide#git#head()
endfunction
let s:git_head = {"cmd": "head", "action": {a,f,m -> s:git_head()}}
let s:git_commit = {"cmd": "commit", "action": {a,f,m -> ide#git#commit()}}
let s:git_push = {"cmd": "push", "action": {a,f,m -> ide#git#push()}}
let s:git_pull = {"cmd": "pull", "action": {a,f,m -> ide#git#pull()}}
let s:git_fetch = {"cmd": "fetch", "action": {a,f,m -> ide#git#fetch()}}
let s:git_diff = {"cmd": "diff", "action": {a,f,m -> ide#git#file_diff()}}
let s:git_log = {"cmd": "log"}
let s:git_log_file = {"cmd": "file", "action": {a,f,m -> ide#git#file_log(bufname())}}
let s:git_log["menu"] = [
      \ s:git_log_file,
      \]
let s:git_working_copy = {"cmd": "working", "action": {a,f,m -> ide#git#file_edit_working()}}
let s:git_hunk = {"cmd": "hunk"}
let s:git_hunk_next = {"cmd": "next", "action": {a,f,m -> ide#git#hunk_next()}}
let s:git_hunk_prev = {"cmd": "previous", "action": {a,f,m -> ide#git#hunk_prev()}}
let s:git_hunk_view = {"cmd": "view", "action": {a,f,m -> ide#git#hunk_view()}}
let s:git_hunk_add = {"cmd": "add", "action": {a,f,m -> ide#git#hunk_add()}}
let s:git_hunk_revert = {"cmd": "revert", "action": {a,f,m -> ide#git#hunk_revert()}}
let s:git_hunk_focus = {"cmd": "focus", "action": {a,f,m -> ide#git#hunk_focus()}}
let s:git_hunk["menu"] = [
      \ s:git_hunk_next,
      \ s:git_hunk_prev,
      \ s:git_hunk_view,
      \ s:git_hunk_add,
      \ s:git_hunk_revert,
      \ s:git_hunk_focus,
      \]
function! s:complete_git_branch(arglead, args)
  " if there are already args, just leave
  if len(a:args) > 1
    return []
  endif
  let l:branch_names = func#compose(
        \ list#filter({_, branch -> branch !~# '\v^\s*\*\s+'}),
        \ list#map({_, branch -> matchstr(branch, '\v^(\s*remotes/)?\zs.*\ze$')}),
        \)
        \(ide#git#branches_all())
  return l:branch_names
endfunction
let s:git_checkout = {
      \ "cmd": "checkout",
      \ "action": {a,f,m -> ide#git#checkout(a[0])},
      \ "complete": funcref("s:complete_git_branch")
      \}
function! s:git_branches()
  echo join(ide#git#branches_all(), "\n")
endfunction
let s:git_branch = {"cmd": "branch", "action": {a,f,m -> s:git_branches()}}
function! s:git_new_branch(args)
  if empty(a:args)
    let l:branch_name = input("New branch name: ")
  else
    let l:branch_name = a:args[0]
  endif
  silent execute "normal! <c-u>"
  call ide#git#branch_new(l:branch_name)
endfunction
let s:git_branch_new = {"cmd": "new", "action": {a,f,m -> s:git_new_branch(a)}}
let s:git_branch["menu"] = [
      \ s:git_branch_new,
      \]
let s:git_cmd["menu"] = [
      \ s:git_status,
      \ s:git_head,
      \ s:git_commit,
      \ s:git_push,
      \ s:git_pull,
      \ s:git_fetch,
      \ s:git_diff,
      \ s:git_log,
      \ s:git_working_copy,
      \ s:git_hunk,
      \ s:git_checkout,
      \ s:git_branch,
      \]
let g:cmd_tree = add(get(g:, "cmd_tree", []), s:git_cmd)
call cmd_tree#update_commands()

function! s:git_buf_filename(bufname)
  let l:bufname = path#full(a:bufname)
  if l:bufname !~# '\v^'.path#join("fugitive:", "").'{2,}'
    return v:null
  endif
  let l:git_buf_type = matchstr(
        \ path#full(a:bufname),
        \ '\v'.escape(path#join(".git", ""), '\.').'{2}\zs\x+\ze',
        \)
  if empty(l:git_buf_type)
    return v:null
  endif
  if l:git_buf_type == "0"
    let l:git_type_name = "index"
  elseif l:git_buf_type == "2"
    let l:git_type_name = "current"
  elseif l:git_buf_type == "3"
    let l:git_type_name = "incoming"
  else
    let l:git_type_name = "(".l:git_buf_type[:7].")"
  endif
  let l:git_filename = path#filename(a:bufname)." @ ".l:git_type_name
  return l:git_filename
endfunction
call config#statusline#custom_filename_handler(funcref("s:git_buf_filename"))

call config#ext_plugins#load(ide#git#plugins)
