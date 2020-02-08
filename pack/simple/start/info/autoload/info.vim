" Info sections list
" - List contains info objects
" - Info object: name, content
" - Info object content may be String or List of lines to display or nested
"   Info object
let s:info_sections = []

" Add Info section
" - Info section object format:
"   name - name of section (header)
"   content - String (single line) or List of lines to display under section
" - If entry with the same name already exists in sections list, it is
"   overwritten, otherwise info_section is added at the end of list
function! info#add_section(info_section)
  let l:info_section_name_index = index(info#sections_names(),
        \ a:info_section.name)
  if l:info_section_name_index >= 0
    let s:info_sections[l:info_section_name_index] = a:info_section
  else
    let s:info_sections = add(s:info_sections, a:info_section)
  endif
endfunction

" Return copy of current info objects list
function! info#sections()
  return copy(s:info_sections)
endfunction

" Return all info sections names
function! info#sections_names()
  return map(info#sections(), 'v:val.name')
endfunction
