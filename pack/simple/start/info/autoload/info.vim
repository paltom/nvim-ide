" Info object format:
" - name: (mandatory) Section name to display
"   - name may contain spaces, however for completion and Info() funciton call
"   argument providing purposes, name will be lowercased and spaces will be
"   replaced by underscores
"   - root-level section names will be underlined with '=' characters
" - subsections: (optional) list of nested section objects
" - text: (exactly one of text, function is mandatory) Static text to
"   display as section's content
"   - may be String or List of lines
" - function: (exactly one of text, function is mandatory) Function to call
"   which should return section's content
"   - may be String or List of lines
" - default: (optional) Flag indicating if section should be displayed when
"   not explicitly requested
" Info sections list
" - List contains info objects
let s:info_sections = []

function! s:validate_info_obj(info_obj)
  if type(a:info_obj) != v:t_dict
    return v:false
  endif
  if !has_key(a:info_obj, "name")
    return v:false
  endif
  if has_key(a:info_obj, "text")
    if has_key(a:info_obj, "function")
      return v:false
    endif
    if type(a:info_obj.text) != v:t_string &&
          \ type(a:info_obj.text) != v:t_list
      return v:false
    endif
  elseif has_key(a:info_obj, "function")
    if type(a:info_obj.function) != v:t_func
      return v:false
    endif
  else
    return v:false
  endif
  if has_key(a:info_obj, "subsections")
    if type(a:info_obj.subsections) != v:t_list
      return v:false
    endif
    for subsection in a:info_obj.subsections
      if !s:validate_info_obj(subsection)
        return v:false
      endif
    endfor
  endif
  if has_key(a:info_obj, "default")
    if type(a:info_obj.default) != v:t_bool
      return v:false
    endif
  endif
  return v:true
endfunction

" Add Info section
" - If entry with the same name already exists in sections list, it is
"   overwritten, otherwise info_section is added at the end of list
" - Validates format of added object (with nested subsections if present)
function! info#add_section(info_section)
  if !s:validate_info_obj(a:info_section)
    echohl WarningMsg
    echomsg "Invalid format of Info section object: ".string(a:info_section)
    echohl None
    return
  endif
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
