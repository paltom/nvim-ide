" Rendering functions {{{
function! s:render_and_indent(render_func, indent_level)
  let l:lines = []
  let l:lines = extend(l:lines, a:render_func(a:indent_level))
  if a:indent_level > 0
    let l:lines = map(l:lines, '"  ".v:val')
  endif
  return l:lines
endfunction

function! s:render_name(name, indent_level)
  let l:lines = []
  let l:lines = add(l:lines, a:name)
  if a:indent_level == 0
    let l:lines = add(l:lines, repeat("=", len(a:name)))
  endif
  return l:lines
endfunction

function! s:render_text(text, indent_level)
  let l:lines = []
  if type(a:text) == v:t_list
    let l:lines = extend(l:lines, a:text)
  else
    let l:lines = add(l:lines, a:text)
  endif
  return l:lines
endfunction

function! s:render_function(funcref, indent_level)
  let l:lines = []
  let l:result = a:funcref()
  if type(l:result) == v:t_list
    let l:lines = extend(l:lines, l:result)
  else
    let l:lines = add(l:lines, l:result)
  endif
  return l:lines
endfunction

function! s:render_section(section, indent_level)
  let l:lines = []
  let l:lines = extend(l:lines,
        \ s:render_and_indent(function('s:render_name',
        \                              [a:section.name]),
        \                     a:indent_level))
  if has_key(a:section, "text")
    let l:lines = extend(l:lines,
          \ s:render_and_indent(function('s:render_text',
          \                              [a:section.text]),
          \                     a:indent_level))
  elseif has_key(a:section, "function")
    let l:lines = extend(l:lines,
          \ s:render_and_indent(function('s:render_function',
          \                              [a:section.function]),
          \                     a:indent_level))
  endif
  if has_key(a:section, "subsections")
    for subsection in a:section.subsections
      let l:lines = extend(l:lines,
            \ s:render_and_indent(function('s:render_section',
            \                              [subsection]),
            \                     a:indent_level + 1))
    endfor
  endif
  return l:lines
endfunction

" Render sections and return list of rendered lines
function! s:render_sections(sections)
  if empty(a:sections)
    return []
  endif
  let l:lines = [""]
  for section in a:sections
    let l:lines = extend(l:lines,
          \              s:render_and_indent(function('s:render_section',
          \                                  [section]), 0))
    let l:lines = add(l:lines, "")
  endfor
  return map(l:lines, '" ".v:val')
endfunction
" }}}

" Utility functions {{{
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

" Convert list of strings in string suitable for passing as function arguments
function! s:list_to_f_args(args_list)
  return join(map(copy(a:args_list), '"\''".v:val."\''"'), ",")
endfunction

" Return available info sections
" - Should return only those that are not yet used
" - Should take candidates defined in user-customizable sections map
function! s:info_complete(arg_lead, cmd_line, cur_pos)
  let l:section_names = map(info#sections_names(), 's:cmd_arg_escaping(v:val)')
  let l:not_entered_names = s:remove_already_entered(l:section_names,
        \ a:cmd_line)
  return join(l:not_entered_names, "\n")
endfunction

function! s:cmd_arg_escaping(name)
  return tolower(substitute(a:name, " ", "_", "g"))
endfunction
" }}}

" Entrypoint {{{
function! s:info(...)
  " Display requested sections only if called with arguments
  if a:0
    let l:sections_string = '['.s:list_to_f_args(a:000).']'
    let l:sections_to_display = filter(info#sections(),
          \ 'index('.l:sections_string.', s:cmd_arg_escaping(v:val.name)) >= 0')
  else
    let l:sections_to_display = filter(info#sections(),
          \ 'has_key(v:val, "default")')
  endif
  let l:info_lines = s:render_sections(l:sections_to_display)
  return l:info_lines
endfunction
" }}}

" Output handler {{{
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
" }}}

" Public interface {{{
function! Info(...)
  if a:0
    return join(s:info(eval(s:list_to_f_args(a:000))), "\n")
  else
    return ""
  endif
endfunction

command! -nargs=* -complete=custom,s:info_complete Info call s:display(s:info(<f-args>))
" }}}

" vim:foldmethod=marker
