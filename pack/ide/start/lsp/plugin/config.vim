let s:guard = "g:loaded_ide_lsp"
if exists(s:guard)
  finish
endif
let {s:guard} = v:true

inoremap <c-space> <c-x><c-o>

call config#ext_plugins#load(
      \ "asyncomplete.vim",
      \ "asyncomplete-omni.vim",
      \)
call asyncomplete#register_source(asyncomplete#sources#omni#get_source_options({
      \ "name": "omni",
      \ "whitelist": ["*"],
      \ "completor": function("asyncomplete#sources#omni#completor"),
      \}))
