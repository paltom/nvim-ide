let ide#terminal#plugins = [
      \ "neoterm",
      \]

let s:tabpage_terminals = []
function! s:get_term_ids(term_ids)
  if empty(a:term_ids)
    return s:tabpage_terminals[tabpagenr() - 1][0:0]
  else
    return list#filter({_, term_id -> list#contains(s:tabpage_terminals, term_id)})(a:term_ids)
  endif
endfunction

function! s:terminal_show(term_ids)
  let l:term_ids = s:get_term_ids(a:term_ids)
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
  let l:term_ids = s:get_term_ids(a:term_ids)
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
  let l:term_ids = s:get_term_ids(a:term_ids)
  let l:exit_cmd = s:clear_line_keys()."exit".s:shell_eol()
  for term_id in l:term_ids
    call neoterm#do({"target": term_id, "cmd": l:exit_cmd})
  endfor
endfunction
function! ide#terminal#exit(...)
  return func#wrap#list_vararg(funcref("s:terminal_exit"))(a:000)
endfunction

function! ide#terminal#new()
  let l:working_directory = path#full(func#until_result([{ -> getcwd()}])())
  let l:term_id = neoterm#new({})["id"]
  " wait for shell initialization
  sleep 200m
  " cd to working directory
  let l:cd_cmd = "cd ".l:working_directory.s:shell_eol()
  call neoterm#do({"target": l:term_id, "cmd": l:cd_cmd})
  " TODO
  " add terminal id to tabpage's terminals
endfunction
