let config#statusline#parts#sep = " "

function! config#statusline#parts#cwd()
  return pathshorten(path#full(getcwd())).":"
endfunction

function! config#statusline#parts#flags()
  if &modifiable && !&readonly
    if &modified
      return "  \u274b"
    else
      return "   "
    endif
  else
    return "\U1f512"
  endif
endfunction

function! config#statusline#parts#filename()
  " needs to be evaluated every time, because new filename custom handlers may
  " be added any time
  return func#until_result(config#statusline#parts#filename#funcs())(bufname())
endfunction

function! config#statusline#parts#type()
  let l:wininfo = getwininfo(win_getid())[0]
  if nvim_win_get_option(0, "previewwindow") || l:wininfo["quickfix"] || l:wininfo["loclist"]
    return "%(%q%w%)"
  else
    return "%y"
  endif
endfunction

let s:location_indicators_list = [
      \ ["\u2588"],
      \ ["\u2588", " "],
      \ ["\u2588", "\u2584", " "],
      \ ["\u2588", "\u2585", "\u2583", " "],
      \ ["\u2588", "\u2586", "\u2584", "\u2582", " "],
      \ ["\u2588", "\u2586", "\u2585", "\u2583", "\u2582", " "],
      \ ["\u2588", "\u2587", "\u2585", "\u2584", "\u2583", "\u2582", " "],
      \ ["\u2588", "\u2587", "\u2586", "\u2585", "\u2583", "\u2582", "\u2581", " "],
      \ ["\u2588", "\u2587", "\u2586", "\u2585", "\u2584", "\u2583", "\u2582", "\u2581", " "],
      \]
" convert to float number
let s:indicators_count = eval(len(s:location_indicators_list).".0")
function! config#statusline#parts#location()
  let l:current_line = line(".")
  let l:file_lines = line("$")
  if l:file_lines < s:indicators_count
    return s:location_indicators_list[l:file_lines - 1][l:current_line - 1]
  else
    let l:indicator_index = float2nr(floor(s:indicators_count*(l:current_line - 1)/l:file_lines))
    return s:location_indicators_list[-1][l:indicator_index]
  endif
endfunction

function! config#statusline#parts#winnr()
  return "[%{winnr()}]"
endfunction
