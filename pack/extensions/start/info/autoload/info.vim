function! s:render_and_indent(render_func, level)
  let l:lines = []
  let l:lines = extend(l:lines, a:render_func(a:level))
  if a:level > 0
    let l:lines = map(l:lines, { _, line -> "  ".line})
  endif
  return l:lines
endfunction

function! s:render_name(name, level)
  let l:lines = []
  let l:lines = add(l:lines, a:name)
  if a:level == 0
    let l:lines = add(l:lines, repeat("=", len(a:name)))
  endif
  return l:lines
endfunction

function! s:render_text(text, level)
  let l:lines = []
  if type(a:text) == v:t_list
    let l:lines = extend(l:lines, a:text)
  else
    let l:lines = add(l:lines, a:text)
  endif
  return l:lines
endfunction

function! s:render_function(funcref, level)
  let l:lines = []
  let l:result = a:funcref()
  if type(l:result) == v:t_list
    let l:lines = extend(l:lines, l:result)
  else
    let l:lines = add(l:lines, l:result)
  endif
  return l:lines
endfunction

function! s:render_section(section, level)
  let l:lines = []
  let l:lines = extend(l:lines, s:render_name(a:section.name, a:level))
  if has_key(a:section, "text")
    let l:lines = extend(l:lines,
          \ s:render_and_indent(function("s:render_text", [a:section.text]),
          \                     a:level + 1)
          \)
  elseif has_key(a:section, "function")
    let l:lines = extend(l:lines,
          \ s:render_and_indent(function("s:render_function", [a:section.function]),
          \                     a:level + 1)
          \)
  endif
  if has_key(a:section, "subsections")
    for subsec in keys(a:section.subsections)
      let l:subsection = get(a:section.subsections, subsec)
      let l:lines = extend(l:lines,
            \ s:render_and_indent(function("s:render_section", [l:subsection]),
            \                     a:level + 1)
            \)
    endfor
  endif
  return l:lines
endfunction

function! s:format(sections)
  if empty(g:info_sections)
    return []
  endif
  if empty(a:sections)
    let l:sections_to_format = g:info_sections
  else
    let l:sections_to_format = filter(copy(g:info_sections),
          \ { key, _ -> index(a:sections, key) >= 0}
          \)
  endif
  if empty(l:sections_to_format)
    return []
  endif
  let l:lines = ['']
  for sec in keys(l:sections_to_format)
    let l:section = get(g:info_sections, sec)
    let l:lines = extend(l:lines,
          \ s:render_and_indent(function("s:render_section", [l:section]), 0))
    let l:lines = add(l:lines, "")
  endfor
  return map(l:lines, { _, line -> " ".line})
endfunction

function! s:print(lines)
  return join(a:lines, "\n")
endfunction

function! s:display(lines)
  if empty(a:lines)
    return
  endif
  let l:info_buffer = nvim_create_buf(v:false, v:true)
  call nvim_buf_set_lines(l:info_buffer, 0, -1, v:false, a:lines)
  let l:info_win = nvim_open_win(l:info_buffer, v:false, {
        \ 'relative': 'editor',
        \ 'anchor': 'SE',
        \ 'width': min([max(map(copy(a:lines), { _, line -> len(line)})) + 1,
        \               &columns / 2]),
        \ 'height': min([len(a:lines), &lines * 3 / 4]),
        \ 'row': (&lines - &cmdheight - 1) - 1,
        \ 'col': &columns - 2,
        \ 'focusable': v:false,
        \ 'style': 'minimal',
        \})
  call nvim_win_set_option(l:info_win, 'winblend', 30)
  execute "autocmd CursorMoved * ++once silent call nvim_win_close(".l:info_win.", v:true)"
endfunction

function! info#show(echo_flag, sections)
  let l:lines = s:format(a:sections)
  if a:echo_flag
    echo s:print(l:lines)
  else
    call s:display(l:lines)
  endif
endfunction
