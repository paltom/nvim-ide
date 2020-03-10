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

function! ide#git#pull()
  Gpull
endfunction

function! ide#git#merge(from_branch)
  execute "Gmerge ".a:from_branch
endfunction

function! ide#git#fetch()
  Gfetch
endfunction

function! ide#git#add(paths)
  execute "Git add ".join(a:paths, " ")
endfunction

function! ide#git#test(arg_lead, cmdline, curpos)
  " git ls-files --modified --others --exclude-standard
  let l:git_root = ide#git#git_dir()
  if empty(l:git_root)
    return ""
  endif
  let l:relative_basedir = fnamemodify(a:arg_lead, ":h")
  let l:globs = split(globpath(l:relative_basedir, "*"), "\n")
  " Remove leading ./ if any
  let l:globs = map(l:globs, { _, elem -> matchstr(elem, '\v^(\./)?\zs.*\ze')})
  " Add slash at the end if elem is directory
  let l:globs = map(l:globs, { _, elem -> isdirectory(elem) ? elem.expand("/") : elem})
  return join(l:globs, "\n")
endfunction
