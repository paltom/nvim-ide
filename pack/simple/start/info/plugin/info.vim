" Return info section names that are not yet present in Info command arguments
" entered so far.
" - cmd_line starts with Info followed by space-separated section names
function! s:remove_already_entered(info_sections, cmd_line)
  let l:cmd_args = split(matchstr(a:cmd_line, '\vInfo \zs.*\ze'), " ")
  for cmd_arg in l:cmd_args
    let l:index_to_remove = index(a:info_sections, cmd_arg)
    if l:index_to_remove >= 0
      call remove(a:info_sections, l:index_to_remove)
    endif
  endfor
  return a:info_sections
endfunction

" Return available info sections
" - Should return only those that are not yet used
" - Should take candidates defined in user-customizable sections map
function! s:info_complete(arg_lead, cmd_line, cur_pos)
  let l:all_info_sections = map(info#sections_names(), 'tolower(v:val)')
  let l:not_entered_sections = s:remove_already_entered(l:all_info_sections,
        \ a:cmd_line)
  return join(l:not_entered_sections, "\n")
endfunction

" Indent lines using given indentation
" - Space is used as indentation character
let s:indent_char = " "
function! s:indent_lines(lines, indentation)
  for line_index in range(0, len(a:lines) - 1)
    let a:lines[line_index] = repeat(s:indent_char, a:indentation).
          \a:lines[line_index]
  endfor
  return a:lines
endfunction

" Render section and return list of rendered lines
" Indent section using indent_level (2 spaces per level)
" - Content is indented  with respect to section header
function! s:render_section(section, indent_level)
  let l:lines = []
  if type(a:section) == type({})
    let l:lines = add(l:lines, a:section.name)
    if !a:indent_level
      let l:lines = add(l:lines, repeat("=", len(a:section.name)))
    endif
    let l:lines = extend(l:lines,
          \ s:render_section(a:section.content, a:indent_level + 1))
  elseif type(a:section) == type([])
    let l:lines = extend(l:lines, a:section)
  else
    let l:lines = add(l:lines, a:section)
  endif
  if a:indent_level
    let l:lines = s:indent_lines(l:lines, 2)
  endif
  return l:lines
endfunction

" Render sections and return list of rendered lines
function! s:render_sections(sections)
  if empty(a:sections)
    return []
  endif
  let l:lines = [""]
  for rendered_section in map(a:sections, 's:render_section(v:val, 0)')
    let l:lines = extend(l:lines, rendered_section)
    let l:lines = add(l:lines, "")
  endfor
  return s:indent_lines(l:lines, 1)
endfunction

" Display info lines
function! s:display(lines)
  if empty(a:lines)
    return
  endif
  " create temporary buffer
  let l:info_buffer = nvim_create_buf(v:false, v:true)
  call nvim_buf_set_lines(l:info_buffer, 0, -1, v:false, a:lines)
  let l:info_win = nvim_open_win(l:info_buffer, v:false, {
        \ 'relative': 'editor',
        \ 'anchor': 'SE',
        \ 'width': min([max(map(copy(a:lines), 'len(v:val)')) + 1, &columns / 2]),
        \ 'height': min([len(a:lines), &lines * 3 / 4]),
        \ 'row': (&lines - &cmdheight - 1) - 1,
        \ 'col': &columns - 2,
        \ 'focusable': v:false,
        \ 'style': 'minimal',
        \})
  call nvim_win_set_option(l:info_win, 'winblend', 30)
  execute "autocmd CursorMoved * ++once silent call nvim_win_close(".l:info_win.", v:true)"
endfunction

" Convert list of strings in string suitable for passing as function arguments
function! s:list_to_f_args(args_list)
  return join(map(copy(a:args_list), '"\''".v:val."\''"'), ",")
endfunction

" Display info in floating window
" - If called without arguments - display all defined info sections
" - If called with arguments - display only requested info sections in same
"   order as requested
" - Adjust window size to content; window can be later made customizable
" - Up to 20 sections currently allowed: E740
function! s:info(...)
  " Display only requested sections if called with arguments
  if a:0
    let l:sections_string = '['.s:list_to_f_args(a:000).']'
    let l:sections_to_display = filter(info#sections(),
          \ 'index('.l:sections_string.', tolower(v:val.name)) >= 0')
  else
    let l:sections_to_display = info#sections()
  endif
  let l:info_lines = s:render_sections(l:sections_to_display)
  return l:info_lines
endfunction

function! Info(...)
  if a:0
    return join(s:info(eval(s:list_to_f_args(a:000))), "\n")
  else
    return ""
  endif
endfunction

command! -nargs=* -complete=custom,s:info_complete Info call s:display(s:info(<f-args>))
