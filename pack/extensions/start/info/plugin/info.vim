if exists('g:loaded_info')
  finish
endif
let g:loaded_info = v:true

" Info object format:
" - dictionary
" - keys are used for completing Info command arguments
" - values are dictionary containing following entries:
" - 'name' of the section: string
" - 'text' to display
"   OR
" - 'function' which result to display
" - text or function may be string or list of strings
" - text takes precendence over function
" - optionally, nested 'subsections' (formatted same as values)
if !exists("g:info_sections")
  let g:info_sections = {}
endif

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

" Return available info sections
" - Should return only those that are not yet used
" - Should take candidates defined in user-customizable sections map
function! s:info_complete(arg_lead, cmd_line, cur_pos)
  let l:section_names = keys(g:info_sections)
  let l:not_entered_names = s:remove_already_entered(l:section_names,
        \ a:cmd_line)
  return join(l:not_entered_names, "\n")
endfunction
" }}}

" Public interface {{{
command! -nargs=* -bang -complete=custom,s:info_complete Info call info#show(<bang>v:false, [<f-args>])
" }}}

" vim:foldmethod=marker
