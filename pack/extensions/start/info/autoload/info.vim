" Indent result of `render_func`
function! s:indent(render_func, level)
  let l:lines = []
  let l:lines = extend(l:lines, a:render_func(a:level))
  if a:level > 0
    " indent if level is greater than 0
    " nested sections will be indented multiple times (as many as nesting
    " level)
    let l:lines = map(l:lines, { _, line -> "  ".line})
  endif
  return l:lines
endfunction

" Display section name
" If it is main section (level is equal to 0) - underline it
function! s:render_name(name, level)
  let l:lines = []
  let l:lines = add(l:lines, a:name)
  if a:level == 0
    let l:lines = add(l:lines, repeat("=", len(a:name)))
  endif
  return l:lines
endfunction

" Display static text element
function! s:render_text(text, level)
  let l:lines = []
  " text may be single string or list of strings (lines)
  if type(a:text) == v:t_list
    let l:lines = extend(l:lines, a:text)
  else
    let l:lines = add(l:lines, a:text)
  endif
  return l:lines
endfunction

" Display result of function element
function! s:render_function(funcref, level)
  let l:lines = []
  let l:result = a:funcref()
  " function call result may be single string or list of strings (lines)
  if type(l:result) == v:t_list
    let l:lines = extend(l:lines, l:result)
  else
    let l:lines = add(l:lines, l:result)
  endif
  return l:lines
endfunction

" Display whole section
" This will display all elements in section
function! s:render_section(section, level)
  let l:lines = []
  let l:lines = extend(l:lines, s:render_name(a:section.name, a:level))
  " text element has precedence over function call
  if has_key(a:section, "text")
    let l:lines = extend(l:lines,
          \ s:indent(function("s:render_text", [a:section.text]),
          \                     a:level + 1)
          \)
  elseif has_key(a:section, "function")
    let l:lines = extend(l:lines,
          \ s:indent(function("s:render_function", [a:section.function]),
          \                     a:level + 1)
          \)
  endif
  if has_key(a:section, "subsections")
    for subsec in a:section.subsections
      let l:lines = extend(l:lines,
            \ s:indent(function("s:render_section", [subsec]),
            \                     a:level + 1)
            \)
    endfor
  endif
  return l:lines
endfunction

" Format (render and indent) all requested top-level sections
function! s:format(sections)
  if empty(g:info_sections)
    return []
  endif
  if empty(a:sections)
    " if no sections were requested explicitly - display all sections
    let l:sections_to_format = g:info_sections
  else
    " display only explicitly requested sections
    let l:sections_to_format = filter(copy(g:info_sections),
          \ { key, _ -> index(a:sections, key) >= 0}
          \)
  endif
  if empty(l:sections_to_format)
    return []
  endif
  " This is for top border
  let l:lines = ['']
  for sec in keys(l:sections_to_format)
    let l:section = g:info_sections[sec]
    let l:lines = extend(l:lines,
          \ s:indent(function("s:render_section", [l:section]), 0))
    " last line will serve as bottom border
    let l:lines = add(l:lines, "")
  endfor
  " add left border
  return map(l:lines, { _, line -> " ".line})
endfunction

" Echo formatted sections to cmdline
function! s:print(lines)
  echo join(a:lines, "\n")
endfunction

" Display formatted section in floating window
function! s:display(lines)
  if empty(a:lines)
    return
  endif
  " create temporary buffer
  let l:info_buffer = nvim_create_buf(v:false, v:true)
  call nvim_buf_set_lines(l:info_buffer, 0, -1, v:false, a:lines)
  " create floating window
  " maximum width = half of screen width
  " maximum height = 75% of screen height
  " put window in right bottom corner
  " automatically go into window if lines do not fit inside window
  let l:max_win_width = &columns / 2
  let l:max_win_height = &lines * 3 / 4
  " +1 is for right border
  let l:max_line_width = max(map(copy(a:lines), { _, line -> len(line)})) + 1
  let l:lines_count = len(a:lines)
  let l:will_fit = l:max_line_width < l:max_win_width &&
        \ l:lines_count < l:max_win_height
  let l:info_win = nvim_open_win(l:info_buffer, !l:will_fit, {
        \ 'relative': 'editor',
        \ 'anchor': 'SE',
        \ 'width': min([l:max_line_width, l:max_win_width]),
        \ 'height': min([l:lines_count, l:max_win_height]),
        \ 'row': (&lines - &cmdheight - 1) - 1,
        \ 'col': &columns - 2,
        \ 'focusable': !l:will_fit,
        \ 'style': 'minimal',
        \})
  call nvim_win_set_option(l:info_win, 'winblend', 30)
  " TODO make buffer nomodifiable
  if l:will_fit
    execute "autocmd CursorMoved * ++once silent call nvim_win_close(".l:info_win.", v:true)"
  else
    call nvim_buf_set_keymap(l:info_buffer, "n", "<left>", "col('.') == 1 ? '<c-w>p' : '<left>'", {"expr": v:true})
    call nvim_buf_set_keymap(l:info_buffer, "n", "h", "col('.') == 1 ? '<c-w>p' : 'h'", {"expr": v:true})
    call nvim_buf_set_keymap(l:info_buffer, "n", "<up>", "line('.') == 1 ? '<c-w>p' : '<up>'", {"expr": v:true})
    call nvim_buf_set_keymap(l:info_buffer, "n", "k", "line('.') == 1 ? '<c-w>p' : 'k'", {"expr": v:true})
    execute "autocmd WinLeave <buffer=".l:info_buffer."> ++once silent quit!"
  endif
  " TODO wipeout buffer
endfunction

" Show info
" `echo_flag` determines if output should be echoed to cmdline output or
" displayed in floating window
" `sections` is list of explicitly requested info sections to display; may be
" empty, in which case, all info sections are shown
function! info#show(echo_flag, sections)
  let l:lines = s:format(a:sections)
  if a:echo_flag
    call s:print(l:lines)
  else
    call s:display(l:lines)
  endif
endfunction
