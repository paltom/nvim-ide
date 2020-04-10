let s:guard = "g:loaded_ide_session"
if exists(s:guard)
  finish
endif
let {s:guard} = v:true

let g:session_directory = path#join(config#vim_home, "sessions")
set sessionoptions-=help
set sessionoptions+=resize
" help mentions 'terminal' option, but it doesn't work
"set sessionoptions+=terminal
set sessionoptions+=winpos
let g:session_autoload = "no"
let g:session_autosave = "yes"
let g:session_default_to_last = 1

function! s:session_name()
  echo xolox#session#find_current_session()
endfunction
let s:session_cmd = {"cmd": "Session", "action": {a,f,m -> s:session_name()}}
function! s:session_action(command, flag, args)
  execute a:command.(a:flag ? "!" : "")." ".join(a:args, " ")
endfunction
function! s:complete_session(arglead, args)
  if len(a:args) > 1
    return []
  endif
  return xolox#session#complete_names(a:arglead, getcmdline(), getcmdpos())
endfunction
let s:session_open = {
      \ "cmd": "open",
      \ "action": {a,f,m -> s:session_action("OpenSession", f, a)},
      \ "complete": funcref("s:complete_session"),
      \}
let s:session_close = {
      \ "cmd": "close",
      \ "action": {a,f,m -> s:session_action("CloseSession", f, a)},
      \ "complete": funcref("s:complete_session"),
      \}
let s:session_delete = {
      \ "cmd": "delete",
      \ "action": {a,f,m -> s:session_action("DeleteSession", f, a)},
      \ "complete": funcref("s:complete_session"),
      \}
let s:session_current = {"cmd": "current", "action": {a,f,m -> s:session_name()}}
let s:session_save = {
      \ "cmd": "save",
      \ "action": {a,f,m -> s:session_action("SaveSession", f, a)},
      \ "complete": funcref("s:complete_session"),
      \}
let s:session_cmd["menu"] = [
      \ s:session_open,
      \ s:session_close,
      \ s:session_delete,
      \ s:session_current,
      \ s:session_save,
      \]
let g:cmd_tree = add(get(g:, "cmd_tree", []), s:session_cmd)
call cmd_tree#update_commands()

call config#ext_plugins#load(ide#session#plugins)
