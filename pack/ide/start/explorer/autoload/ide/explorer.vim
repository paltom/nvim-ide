let ide#explorer#plugins = [
      \ "vim-dirvish",
      \]

function! ide#explorer#open(path, mods)
  let l:command = "Dirvish"
  if !empty(a:path)
    let l:command .= " ".a:path
  endif
  if !empty(a:mods)
    if a:mods =~# '\v<tab>'
      let l:command = "tabedit | ".l:command
    else
      let l:command = a:mods." split | ".l:command
    endif
  endif
  silent execute l:command
endfunction

function! s:do(what, arg)
  silent execute "Shdo ".a:what." {} ".a:arg
  silent normal Z!
endfunction

function! ide#explorer#rename(to)
  call s:do("mv", a:to)
endfunction
