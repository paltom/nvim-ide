" Find cmd object in list of objects (menu) that matches `cmd_to_find` name
function! s:find_menu_by_command(cmds, cmd_to_find)
  return filter(copy(a:cmds), { _, cmd_obj -> cmd_obj["cmd"] == a:cmd_to_find})
endfunction

" Walk through menu following `path` (matching cmd names)
" Return cmd object that is identified by `path`
" Follows `path` as long as 'menu' key is found in cmd object
" 1. If there is 'menu' key in cmd object and there is no matching cmd object
" in 'menu' list, return empty object and path not consumed - this is for
" allowing to complete cmd object's action by 'complete' key
" 2. If there is no 'menu' key in cmd object and there are still path
" elements, return current cmd object and path left
function! s:get_cmd_by_path(menu, path)
  let l:next_cmd = get(a:path, 0, "")
  let l:cmd_obj = s:find_menu_by_command(a:menu, l:next_cmd)
  " fulfills 1.
  " l:cmd_obj here is a filtered list of matching objects in 'menu'
  if empty(l:cmd_obj)
    return [{}, a:path]
  endif
  " unpack first matching cmd object
  let l:cmd_obj = l:cmd_obj[0]
  " path left to follow
  let l:next_path = a:path[1:]
  " if there is not path to follow, we found submenu object, return it
  if empty(l:next_path)
    return [l:cmd_obj, []]
  endif
  " fulfills 2.
  if !has_key(l:cmd_obj, "menu")
    return [l:cmd_obj, l:next_path]
  endif
  " follow path left in cmd object's 'menu' list
  return s:get_cmd_by_path(l:cmd_obj["menu"], l:next_path)
endfunction

" Return cmd object from menu for `command` that can be reached by `path`
function! custom_menu#get_menu_by_path(command, path)
  let l:menu = g:custom_menu[a:command]
  let [l:cmd_obj, l:path_left] = s:get_cmd_by_path(l:menu, a:path)
  if empty(l:cmd_obj) || !empty(l:path_left)
    return {}
  endif
  return l:cmd_obj
endfunction

" Complete menu contextually - already entered arguments determine path to
" identify cmd object for which completions should be provided
function! s:menu_completions(cmd_lead, cmdline, cursor_pos)
  " helper function - map list of cmd objects to list of cmd names
  function! s:map_cmd(cmd_list)
    return map(copy(a:cmd_list), { _, cmd_obj -> cmd_obj["cmd"]})
  endfunction
  let l:cmdline_splitted = split(a:cmdline)
  " get command name from cmdline - which top object from g:custom_menu to
  " use
  let l:command = l:cmdline_splitted[0]
  " get entered cmdline arguments - path will determine which cmd object from
  " menu is the current one
  let l:path = l:cmdline_splitted[1:]
  " if there is partial completion already entered, skip it - Neovim will
  " match completions with cmd_lead as -complete=custom option is used
  if !empty(a:cmd_lead)
    let l:path = l:path[:-2]
  endif
  " match command that *starts with* entered command name - Neovim triggers
  " completion when entered command is unambiguous, it doesn't have to be
  " fully enetered
  " it is guaranteed here that there is exactly one matching command name
  let l:command = filter(keys(g:custom_menu),
          \ { _, comm -> comm =~# '\v^'.l:command}
          \)[0]
  " get command sub object from all custom menus by full command name
  let l:command_menu = g:custom_menu[l:command]
  if empty(l:path)
    " if there are no arguments entered yet - completions are cmd names from
    " top menu for command name
    let l:completions = s:map_cmd(l:command_menu)
  else
    " there are some arguments already fully entered (not taking into account
    " last argument that is curently partially being entered) - they make up a
    " path for menu to follow to find which exact cmd object is selected and
    " for which cmd object contextual completions should be provided

    " follow path to get cmd object identified by path
    " path is followed as much as possible - what's left in path is passed
    " later to 'complete' function of cmd_obj (if any exists) in order to
    " allow actual arguments completions for cmd
    let [l:cmd_obj, l:path_left] = s:get_cmd_by_path(l:command_menu, l:path)
    if has_key(l:cmd_obj, "menu")
      " cmd object has 'menu' key - path should be fully consumed here
      " see `get_cmd_by_path` function
      " completions are taken from found object menu list cmd names
      let l:completions = s:map_cmd(l:cmd_obj["menu"])
    else
      " cmd object has no 'menu' key - completions are provided by 'complete'
      " function from cmd object (if such a function exists)
      " path that is left from getting to cmd object is passed to custom
      " 'complete' function
      let l:completions = get(l:cmd_obj, "complete", { _ -> []})(l:path_left)
    endif
  endif
  return join(l:completions, "\n")
endfunction

" Execute action from cmd object
" Command arguments that were not used for getting cmd object are passed to
" action function
function! s:execute_action(action, args)
  if type(a:action) == v:t_string
    execute(a:action)
  elseif type(a:action) == v:t_func
    call call(a:action, a:args)
  else
    echohl WarningMsg
    echomsg "Unknown action type: ".string(a:action)
    echohl None
  endif
endfunction

" Select action for cmd object identified by `path` and execute it passing
" additional arguments
function! s:menu_action(command, menu_path)
  " helper function for echoing warning message with command location that we
  " tried to execute
  function! s:warning_msg(msg) closure
    let l:location_msg = " for command '".join(a:menu_path, " ").
          \ "' in '".a:command."' menu"
    echohl WarningMsg
    echomsg a:msg.l:location_msg
    echohl None
  endfunction
  " identify which cmd object to use for action, get additional arguments to
  " be passed to action function
  let [l:cmd_obj, l:cmd_args] = s:get_cmd_by_path(
        \                         g:custom_menu[a:command],
        \                         a:menu_path)
  if empty(l:cmd_obj)
    " cmd object couldn't be identified
    call s:warning_msg("Cannot find object")
    return
  elseif !has_key(l:cmd_obj, "action")
    " there is no action key for cmd object we try to invoke
    call s:warning_msg("Missing action")
    return
  endif
  try
    call s:execute_action(l:cmd_obj["action"], l:cmd_args)
  catch /E11[8|9]/
    echohl WarningMsg
    echomsg "Wrong number of arguments for ".string(l:cmd_obj["action"]).
          \ " call. Arguments passed: ".join(l:cmd_args, ", ")
    echohl None
    return
  endtry
endfunction

" Create commands based on g:custom_menu keys
" This function must be invoked when user modifies g:custom_menu object
" This function is called after initilization (VimEnter event)
function! custom_menu#update_commands()
  for cmd in keys(g:custom_menu)
    execute "command! -nargs=+ -complete=custom,s:menu_completions ".
          \ cmd." call s:menu_action('".cmd."', [<f-args>])"
  endfor
endfunction
