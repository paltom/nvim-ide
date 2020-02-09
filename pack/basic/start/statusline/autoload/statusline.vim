let s:file_name_special_filetypes = []

function! statusline#register_filename_for_ft(filetype, filename_funcref)
  let s:file_name_special_filetypes = add(s:file_name_special_filetypes,
        \ {"filetype": a:filetype, "filename_function":  a:filename_funcref})
endfunction

function! statusline#file_name_special_filetypes()
  return copy(s:file_name_special_filetypes)
endfunction
