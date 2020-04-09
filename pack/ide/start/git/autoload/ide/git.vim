let ide#git#plugins = [
      \ "vim-fugitive",
      \ "vim-gitgutter",
      \]

function! ide#git#root_dir()
  let l:git_root_dir = FugitiveGitDir()
  if empty(l:git_root_dir)
    return ""
  endif
  if path#filename(l:git_root_dir) =~# ".git"
    let l:git_root_dir = path#basedir(l:git_root_dir)
  endif
  return l:git_root_dir
endfunction

function! ide#git#status()
  silent execute "tab Gstatus"
endfunction

function! ide#git#commit()
  silent execute "Gcommit"
endfunction

function! ide#git#push()
  silent execute "Gpush"
endfunction

function! ide#git#pull()
  silent execute "Gpull"
endfunction

function! ide#git#fetch()
  silent execute "Gfetch"
endfunction

function! ide#git#head()
  return FugitiveHead(8)
endfunction

function! ide#git#file_diff()
  silent execute "tab vertical Gdiffsplit"
endfunction

function! ide#git#file_log(filename)
  silent execute "tabedit ".a:filename
  silent execute "0Gllog"
endfunction

function! ide#git#file_edit_working()
  silent execute "Gedit"
endfunction

function! ide#git#hunk_next()
  silent execute "GitGutterNextHunk"
endfunction

function! ide#git#hunk_prev()
  silent execute "GitGutterPrevHunk"
endfunction

function! ide#git#hunk_view()
  silent execute "GitGutterPreviewHunk"
endfunction

function! ide#git#hunk_add()
  silent execute "GitGutterStageHunk"
endfunction

function! ide#git#hunk_revert()
  silent execute "GitGutterUndoHunk"
endfunction

function! ide#git#hunk_focus()
  silent execute "GitGutterFold"
endfunction

let s:git_command = "git --git-dir=%s --work-tree=%s %s"
function! s:git_command(command)
  let l:git_root_dir = ide#git#root_dir()
  if empty(l:git_root_dir)
    return []
  endif
  let l:git_command = printf(
        \ s:git_command,
        \ path#join(l:git_root_dir, ".git"),
        \ l:git_root_dir,
        \ a:command,
        \)
  let l:output = split(execute("!".l:git_command), "\n")[1:]
  let l:output = list#map({_, line -> trim(line)})(l:output)
  return l:output
endfunction

function! ide#git#branches_all()
  let l:branch_list = s:git_command("branch -a")
  " remove empty lines and HEAD reference
  let l:branch_list = func#compose(
        \ list#filter({_, branch -> !empty(branch)}),
        \ list#filter({_, branch -> branch !~# '\v^\s*remotes/.{-}/HEAD\s+-\>\s+'}),
        \)
        \(l:branch_list)
  return l:branch_list
endfunction

function! ide#git#checkout(what)
  call s:git_command("checkout ".a:what)
endfunction

function! ide#git#branch_new(branch_name)
  call s:git_command("branch --track ".a:branch_name)
endfunction
