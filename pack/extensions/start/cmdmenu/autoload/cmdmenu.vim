let s:command_name_pattern = '\v^(\U)*\zs\u\a+\ze'
function! s:cmdline_command_name(cmdline)
  return matchstr(a:cmdline, s:command_name_pattern)
endfunction

let s:command_args_pattern = '\v^(\U)*\u\a+!?\s+\zs.*\ze$'
function! s:cmdline_command_args(cmdline)
  let l:args_str = matchstr(a:cmdline, s:command_args_pattern)
  return split(l:args_str, '\v\ +')
endfunction

function! s:get_cmdline_tokens()
  return s:cmdline_tokens
endfunction

function! s:reset_cmdline_tokens()
  let s:cmdline_tokens = {
        \ "cmd": "",
        \ "args": [],
        \}
endfunction

function! s:cmdline_parse(cmdline)
  let s:cmdline_tokens["cmd"] = s:cmdline_command_name(a:cmdline)
  let s:cmdline_tokens["args"] = s:cmdline_command_args(a:cmdline)
endfunction

augroup cmdmenu_monitor_cmdline
  autocmd!
  autocmd CmdlineEnter : call <sid>reset_cmdline_tokens()
  autocmd CmdlineChanged : call <sid>cmdline_parse(getcmdline())
  autocmd CmdlineLeave : call <sid>reset_cmdline_tokens()
augroup end

if !exists("g:cmdmenu")
  let g:cmdmenu = []
endif

function! s:get_cmd_obj_from_menu(menu, cmd)
  let l:cmd_obj = func#filter(
        \ { _, c -> c["cmd"] ==# a:cmd },
        \)
        \(a:menu)
  return !empty(l:cmd_obj) ? l:cmd_obj[0] : {}
endfunction

function! s:get_all_cmds_from_menu(menu)
  return func#map({ _, c -> c["cmd"] })(a:menu)
endfunction

function! s:get_cmd_obj_by_path(menu, path)
  let l:cmd_obj = {}
  if empty(a:path)
    return [l:cmd_obj, []]
  endif
  let l:menu = copy(a:menu)
  let l:path = a:path
  while !empty(l:path)
    let [l:next_cmd; l:path] = l:path
    let l:menu_cmds = s:get_all_cmds_from_menu(l:menu)
    let l:cmd = util#single_matching_prefix(l:next_cmd)(l:menu_cmds)
    if empty(l:cmd)
      return [l:cmd_obj, insert(l:path, l:next_cmd)]
    endif
    let l:cmd_obj = s:get_cmd_obj_from_menu(l:menu, l:cmd)
    let l:menu = get(l:cmd_obj, "menu", [])
  endwhile
  return [l:cmd_obj, l:path]
endfunction

function! cmdmenu#update_commands()
  for cmd in s:get_all_cmds_from_menu(g:cmdmenu)
    call s:update_command(cmd)
  endfor
endfunction

function! s:update_command(cmd)
  let l:cmd_rhs_func_args = [
        \ "<bang>v:false",
        \ "split(<q-args>)",
        \ "<q-mods>",
        \]
  let l:cmd_rhs_func_args = join(l:cmd_rhs_func_args, ", ")
  let l:execute_cmd_func = "<line1>,<line2>call s:execute_cmd(".l:cmd_rhs_func_args.")"
  let l:cmd_def = [
        \ "command!",
        \ "-nargs=*",
        \ "-range",
        \ "-bang",
        \ a:cmd,
        \ l:execute_cmd_func,
        \]
  let l:cmd_def = join(l:cmd_def, " ")
  execute l:cmd_def
endfunction
