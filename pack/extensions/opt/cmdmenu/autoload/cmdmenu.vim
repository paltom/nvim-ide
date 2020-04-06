if !exists("g:cmdmenu")
  let g:cmdmenu = []
endif

function! cmdmenu#cmds(menu)
  const l:key = "cmd"
  return func#compose(
        \ list#filter({_, co -> has_key(co, l:key)}),
        \ list#map({_,co -> co[l:key]})
        \)
        \(a:menu)
endfunction

function! cmdmenu#update_commands()
  for cmd in cmdmenu#cmds(g:cmdmenu)
    call s:update_command(cmd)
  endfor
endfunction

function! s:update_command(cmd)
  let l:cmd_rhs_func_args = [
        \ "'".a:cmd."'",
        \ "<bang>0",
        \ "split(<q-args>)",
        \ "<q-mods>",
        \]
  let l:cmd_rhs_func_args = join(l:cmd_rhs_func_args, ", ")
  let l:cmd_rhs_func_call = "<line1>,<line2>call s:execute_cmd(".l:cmd_rhs_func_args.")"
  let l:cmd_def = [
        \ "command!",
        \ "-nargs=*",
        \ "-range",
        \ "-bang",
        \ "-complete=custom,s:complete_cmd",
        \ a:cmd,
        \ l:cmd_rhs_func_call,
        \]
  let l:cmd_def = join(l:cmd_def, " ")
  execute l:cmd_def
endfunction

function! s:execute_cmd(cmd, flag, args, mods) range abort
  let l:cmdline_state = cmdmenu#monitoring#get_state()
  call cmdmenu#monitoring#reset()
  let l:cmd_obj = l:cmdline_state["cmd_obj"]
  let l:cmd_args = l:cmdline_state["cmd_args"]
  if !has_key(l:cmd_obj, "action")
    echohl WarningMsg
    echomsg "No action for this command"
    echohl None
    return
  endif
  execute a:firstline.",".a:lastline."call l:cmd_obj['action'](l:cmd_args, a:flag, a:mods)"
endfunction

function! s:complete_cmd(arglead, cmdline, curpos)
  let [l:cmd_obj, l:cmd_args] = cmdmenu#monitoring#cmd_obj(a:cmdline, a:curpos, v:true)
  " invoke custom completion function only if there is no possibility to go
  " deeper into submenus, otherwise there is unambiguity in completions
  " provider
  if !has_key(l:cmd_obj, "menu") && has_key(l:cmd_obj, "complete")
    let l:completion_candidates = l:cmd_obj["complete"](a:arglead, l:cmd_args)
  elseif empty(l:cmd_args)
    let l:submenu = get(l:cmd_obj, "menu", [])
    let l:completion_candidates = cmdmenu#cmds(l:submenu)
  else
    let l:completion_candidates = []
  endif
  return join(l:completion_candidates, "\n")
endfunction
