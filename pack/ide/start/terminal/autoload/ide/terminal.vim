let ide#terminal#plugins = [
      \ "neoterm",
      \]

function! s:get_tabpage_term_bufs(tabpagenr)
  return gettabvar(a:tabpagenr, "ide_term_bufs", [])
endfunction
function! s:set_tabpage_term_bufs(tabpagenr, term_bufs)
  return settabvar(a:tabpagenr, "ide_term_bufs", a:term_bufs)
endfunction
function! s:add_term_buf(term_bufnr)
  let l:tabpage_term_bufs = s:get_tabpage_term_bufs(tabpagenr())
  let l:tabpage_term_bufs = list#unique_append(l:tabpage_term_bufs, str2nr(a:term_bufnr))
  call s:set_tabpage_term_bufs(tabpagenr(), l:tabpage_term_bufs)
endfunction
function! s:remove_term_buf(term_bufnr)
  let l:tabpage_term_bufs = s:get_tabpage_term_bufs(tabpagenr())
  let l:term_buf_idx = index(l:tabpage_term_bufs, str2nr(a:term_bufnr))
  if l:term_buf_idx >= 0
    unlet l:tabpage_term_bufs[l:term_buf_idx]
  endif
  call s:set_tabpage_term_bufs(tabpagenr(), l:tabpage_term_bufs)
endfunction
augroup ide_terminal_tabpage_term_id
  autocmd!
  autocmd TermOpen * call s:add_term_buf(expand("<abuf>"))
  autocmd TermClose * call s:remove_term_buf(expand("<abuf>"))
augroup end

function! s:tabpage_term_ids(term_ids)
  let l:tabpage_term_bufs = s:get_tabpage_term_bufs(tabpagenr())
  let l:tabpage_term_ids = []
  for bufnr in l:tabpage_term_bufs
    " translate bufnr into neoterm_id
    let l:tabpage_term_ids = list#map(
          \ {_, bufnr -> getbufvar(bufnr, "neoterm_id")}
          \)
          \(l:tabpage_term_bufs)
  endfor
  let l:tabpage_term_ids = sort(l:tabpage_term_ids)
  if empty(a:term_ids)
    return l:tabpage_term_ids[0:0]
  else
    return list#filter(
          \ {_, term_id -> list#contains(l:tabpage_term_ids, term_id)}
          \)
          \(a:term_ids)
  endif
endfunction

function! s:terminal_show(term_ids)
  let l:term_ids = s:tabpage_term_ids(a:term_ids)
  if empty(l:term_ids)
    call ide#terminal#new()
  else
    for term_id in l:term_ids
      call neoterm#open({"target": term_id})
    endfor
  endif
endfunction
function! ide#terminal#show(...)
  return func#wrap#list_vararg(funcref("s:terminal_show"))(a:000)
endfunction

function! s:terminal_hide(term_ids)
  let l:term_ids = s:tabpage_term_ids(a:term_ids)
  for term_id in l:term_ids
    call neoterm#close({"target": term_id, "force": v:false})
  endfor
endfunction
function! ide#terminal#hide(...)
  return func#wrap#list_vararg(funcref("s:terminal_hide"))(a:000)
endfunction

function! s:clear_line_keys()
  if &shell =~# "bash"
    return "\u0005\u0015" " Ctrl-e Ctrl-u
  elseif &shell =~# "cmd.exe"
    return "\u001b" " Esc
  else
    echohl WarningMsg
    echomsg "Shell ".&shell." not supported"
    echohl None
    return ""
  endif
endfunction
function! s:shell_eol()
  if has("win32")
    return "\u000d"
  else
    return ""
  endif
endfunction

function! s:terminal_exit(term_ids)
  let l:term_ids = s:tabpage_term_ids(a:term_ids)
  let l:exit_cmd = s:clear_line_keys()."exit".s:shell_eol()
  for term_id in l:term_ids
    call neoterm#do({"target": term_id, "cmd": l:exit_cmd})
  endfor
endfunction
function! ide#terminal#exit(...)
  return func#wrap#list_vararg(funcref("s:terminal_exit"))(a:000)
endfunction

function! s:get_root_dir(func_name)
  if exists("*".a:func_name)
    let l:root_dir = call(a:func_name, [])
    if !empty(l:root_dir)
      return l:root_dir
    endif
  endif
  return v:null
endfunction
function! s:current_file_basedir()
  let l:basedir = path#basedir(bufname())
  if !empty(l:basedir)
    return l:basedir
  endif
  return v:null
endfunction
let s:working_directory_funcs = [
      \ "ide#project#root_dir",
      \ "ide#git#root_dir",
      \ "s:current_file_basedir",
      \ "getcwd",
      \]
function! ide#terminal#new()
  let l:working_directory = path#full(
        \ func#until_result(
        \   list#map(
        \     {_, func_name -> funcref("s:get_root_dir", [func_name])}
        \   )(s:working_directory_funcs)
        \ )()
        \)
  let l:term_id = neoterm#new({})["id"]
  " wait for shell initialization
  sleep 200m
  " cd to working directory
  let l:cd_cmd = "cd ".l:working_directory.s:shell_eol()
  call neoterm#do({"target": l:term_id, "cmd": l:cd_cmd})
  " TODO user-defined commands (e.g. activating python virtual environment)
  call neoterm#clear({"target": l:term_id, "force_clear": v:false})
endfunction
