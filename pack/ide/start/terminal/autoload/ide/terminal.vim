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
  let l:directory = expand("%:p:h")
  if !empty(l:directory)
    call call#set_result(a:context, l:directory)
  endif
endfunction

let s:terminal_work_dir_functions = [
      \ function("s:root_dir_if_exists", [function("ide#project#root_dir")]),
      \ function("s:root_dir_if_exists", [function("ide#git#root_dir")]),
      \ function("s:file_dir_if_not_empty"),
      \ { c -> call#set_result(c, expand(getcwd())) },
      \]
function! ide#terminal#new(mods)
  " go through working directories functions
  " terminal pack handles which functions are called
  let l:working_directory = call#until_result(
        \ s:terminal_work_dir_functions,
        \ {}
        \)
  let l:term_id = neoterm#new({"mod": a:mods})["id"]
  " wait for shell to initialize
  sleep 200m
  " go to working directory
  call neoterm#do({"cmd": "cd ".l:working_directory, "target": l:term_id})
  " TODO handle tabpage's terminal
  " TODO call command
endfunction
