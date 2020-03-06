let ide#git#plugins = [
      \ "vim-fugitive",
      \ "vim-gitgutter",
      \]

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
