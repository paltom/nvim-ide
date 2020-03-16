let ide#terminal#plugins = [
      \ "neoterm",
      \]

function! s:root_dir_if_exists(ide_function, context)
  if exists("*".matchstr(string(a:ide_function), '\vfunction\(''\zs.*\ze'''))
    let l:root_dir = a:ide_function()
    if !empty(l:root_dir)
      call call#set_result(a:context, l:root_dir)
    endif
  endif
endfunction

function! s:file_dir_if_not_empty(context)
  " only if file exists
  let l:directory = glob(expand("%:p:h"))
  if !empty(l:directory)
    call call#set_result(a:context, l:directory)
  endif
endfunction

function! s:shell_eol()
  if has("win32")
    return "\u000d"
  else
    return ""
  endif
endfunction
function! s:clear_line_keys()
  if &shell =~# "bash"
    return "\u0005\u0015" " Ctrl-e Ctrl-u
  elseif &shell =~# "cmd.exe"
    return "\u001b" " Esc
  else
    echohl WarningMsg
    echomsg "Clearing command line in ".&shell." shell is not supported."
    echohl None
    return ""
  endif
endfunction

let s:terminal_work_dir_functions = [
      \ function("s:root_dir_if_exists", [function("ide#project#root_dir")]),
      \ function("s:root_dir_if_exists", [function("ide#git#root_dir")]),
      \ function("s:file_dir_if_not_empty"),
      \ { c -> call#set_result(c, expand(getcwd())) },
      \]
function! ide#terminal#new()
  " go through working directories functions
  " terminal pack handles which functions are called
  let l:working_directory = call#until_result(
        \ s:terminal_work_dir_functions,
        \ {}
        \)
  let l:term_id = neoterm#new({})["id"]
  " wait for shell to initialize
  sleep 200m
  " go to working directory
  let l:cd_cmd = "cd ".l:working_directory.s:shell_eol()
  call neoterm#do({"cmd": l:cd_cmd, "target": l:term_id})
  " add terminal id to list of tabpage's terminals
  call s:add_tabpage_terminal(l:term_id)
  " TODO call command
endfunction

let s:tabpage_term_ids_var_name = "ide_terminal_ids"

function! ide#terminal#get_tabpage_term_ids(tabpagenr)
  return gettabvar(
        \ a:tabpagenr,
        \ s:tabpage_term_ids_var_name,
        \ []
        \)
endfunction

function! s:set_tabpage_term_ids(tabpagenr, term_ids)
  call settabvar(
        \ a:tabpagenr,
        \ s:tabpage_term_ids_var_name,
        \ a:term_ids
        \)
endfunction

function! s:add_tabpage_terminal(term_id)
  let l:tabpagenr = tabpagenr()
  let l:tabpage_term_ids = ide#terminal#get_tabpage_term_ids(l:tabpagenr)
  let l:tabpage_term_ids = add(
        \ l:tabpage_term_ids,
        \ a:term_id
        \)
  call s:set_tabpage_term_ids(l:tabpagenr, l:tabpage_term_ids)
  " set autocmd for when terminal is exited
  function! s:get_buf_id_with_term(term_id)
    " Find a buffer id associated with term_id
    " Return 0 if buffer not found
    let l:loaded_bufs = filter(
          \ nvim_list_bufs(),
          \ { _, b -> nvim_buf_is_loaded(b) }
          \)
    let l:buf_with_term_id = get(
          \ filter(
          \   l:loaded_bufs,
          \   { _, b -> getbufvar(b, "neoterm_id", 0) == a:term_id}
          \ ),
          \ 0,
          \)
    return l:buf_with_term_id
  endfunction

  function! s:remove_tabpage_terminal(term_id)
    let l:tabpagenr = tabpagenr()
    let l:tabpage_term_ids = ide#terminal#get_tabpage_term_ids(l:tabpagenr)
    let l:term_id_idx = index(l:tabpage_term_ids, a:term_id)
    if l:term_id_idx > -1
      call remove(l:tabpage_term_ids, l:term_id_idx)
    endif
    call s:set_tabpage_term_ids(l:tabpagenr, l:tabpage_term_ids)
  endfunction

  let l:buf_id = s:get_buf_id_with_term(a:term_id)
  if l:buf_id
    execute "autocmd BufDelete <buffer=".l:buf_id."> ".
          \   "call s:remove_tabpage_terminal(".a:term_id.")"
  endif
endfunction

function! ide#terminal#open(...)
  let Open = { term_id -> neoterm#open({"target": term_id}) }
  if empty(a:000) && empty(ide#terminal#get_tabpage_term_ids(tabpagenr()))
    " if no terminals were open in tabpage yet and no explicit terminal id to
    " open was passed, create a new terminal
    call ide#terminal#new()
  endif
  call s:call_handling_arguments(a:000, Open)
endfunction

function! ide#terminal#close(...)
  let Close = { term_id -> neoterm#close({"force": v:false, "target": term_id}) }
  call s:call_handling_arguments(a:000, Close)
endfunction

function! ide#terminal#exit(...)
  let l:exit_cmd = s:clear_line_keys()."exit".s:shell_eol()
  let Exit = { term_id -> neoterm#do({"cmd": l:exit_cmd, "target": term_id}) }
  call s:call_handling_arguments(a:000, Exit)
endfunction

function! s:call_handling_arguments(args, handler_func)
  let l:tabpage_term_ids = ide#terminal#get_tabpage_term_ids(tabpagenr())
  if empty(a:args)
    if !empty(l:tabpage_term_ids)
      call a:handler_func(l:tabpage_term_ids[0])
    endif
  else
    let l:first_arg = a:args[0]
    if l:first_arg ==? "all"
      for term_id in l:tabpage_term_ids
        call a:handler_func(term_id)
      endfor
    else
      let l:term_id = str2nr(l:first_arg)
      if index(l:tabpage_term_ids, l:term_id) > -1
        call a:handler_func(l:term_id)
      endif
    endif
  endif
endfunction

