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
