let ide#git#plugins = [
      \ "vim-fugitive",
      \ "vim-gitgutter",
      \]

function! ide#git#status()
  execute "tab Gstatus"
endfunction

function! ide#git#checkout(branch_name)
  execute "!git checkout ".a:branch_name
endfunction

function! ide#git#new_branch()
  let l:branch_name = input("New branch name: ")
  execute "normal! <c-u>"
  execute "!git checkout -b ".l:branch_name
endfunction

function! ide#git#list_branches()
  let l:branch_list = split(execute("!git branch -a"), "\n")[1:]
  let l:branch_list = map(l:branch_list, { _, line -> trim(line) })
  " Remove empty lines
  let l:branch_list = filter(l:branch_list, { _, line -> !empty(line) })
  " Remove remote HEAD reference
  let l:branch_list = filter(l:branch_list, { _, branch -> branch !~# '\v^\s*remotes/[^/]*/HEAD\s+-\>\s+'})
  return l:branch_list
endfunction

function! ide#git#git_dir()
  let l:git_dir = FugitiveGitDir()
  if empty(l:git_dir)
    return ""
  endif
  if fnamemodify(l:git_dir, ":t") =~# '.git'
    let l:git_dir = fnamemodify(l:git_dir, ":h")
  endif
  return l:git_dir
endfunction

function! ide#git#head()
  return FugitiveHead(8)
endfunction

function! ide#git#commit()
  Gcommit
endfunction

function! ide#git#push()
  Gpush
endfunction
