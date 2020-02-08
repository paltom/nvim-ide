" Info sections list
" - List contains info objects
" - Info object: name, content
" - Info object content may be String or List of lines to display
let s:info_sections = [
      \ {
      \   "name": "test-line",
      \   "content": "Test line",
      \ },
      \ {
      \   "name": "test-lines",
      \   "content": [
      \     "Test line 1",
      \     "Test line 2",
      \   ],
      \ }
      \]

" Add Info section
" - Info section object format:
"   name - name of section (header)
"   content - String (single line) or List of lines to display under section
" - If entry with the same name already exists in sections list, it is
"   overwritten, otherwise info_section is added at the end of list
function! Info_add_section(info_section)
  let l:sections_names = map(copy(s:info_sections), 'v:val.name')
  let l:info_section_name_index = index(l:sections_names, a:info_section.name)
  if l:info_section_name_index >= 0
    let s:info_sections[l:info_section_name_index] = a:info_section
  else
    let s:info_sections = add(s:info_sections, a:info_section)
  endif
endfunction

" Return all info sections names
function! s:info_sections_names()
  return map(copy(s:info_sections), 'v:val.name')
endfunction

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
  let l:all_info_sections = s:info_sections_names()
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
  let l:lines = [""]
  for rendered_section in map(a:sections, 's:render_section(v:val, 0)')
    let l:lines = extend(l:lines, rendered_section)
    let l:lines = add(l:lines, "")
  endfor
  return s:indent_lines(l:lines, 1)
endfunction

" Display info in floating window
" - If called without arguments - display all defined info sections
" - If called with arguments - display only requested info sections in same
"   order as requested
" - Adjust window size to content; window can be later made customizable
" - Up to 20 arguments currently allowed: E740
function! s:info(...)
  " Display only requested sections if called with arguments
  if a:0
    let l:sections_to_display = filter(copy(s:info_sections),
          \ 'index('.a:000.', v:val.name) >= 0')
  else
    let l:sections_to_display = s:info_sections
  endif
  echo join(s:render_sections(l:sections_to_display), "\n")
endfunction

command! -nargs=* -complete=custom,s:info_complete Info call s:info(<f-args>)
