function! ext#plugins#load(plugins)
  for plugin in a:plugins
    let l:first_after_directory_index = match(split(&runtimepath, ","), '\v[\\/]after$')
    call s:insert_into_rtp(g:config#ext_plugins_directory."/".plugin."/after", l:first_after_directory_index)
    call s:insert_into_rtp(g:config#ext_plugins_directory."/".plugin, 1)
    call s:load_plugin(plugin)
  endfor
endfunction

function! s:insert_into_rtp(path_element, index)
  let l:rtp_list = split(&runtimepath, ",")
  " insert only if path_element is not present
  if index(l:rtp_list, a:path_element) < 0
    let l:rtp_list = insert(l:rtp_list, a:path_element, a:index)
  endif
  let &runtimepath = join(l:rtp_list, ",")
endfunction

function! s:load_plugin(plugin)
  " Add plugins directory for manual loading
  call s:insert_into_rtp(g:config#ext_plugins_directory, 0)
  " Load plugin
  execute "runtime! ".a:plugin."/ftdetect/**/*.vim"
  execute "runtime! ".a:plugin."/plugin/**/*.vim"
  " Generate help tags for loaded plugins
  let l:plugin_doc_directory = expand(g:config#ext_plugins_directory."/".a:plugin."/doc")
  if isdirectory(l:plugin_doc_directory)
    execute "helptags ".l:plugin_doc_directory
  endif
  " Remove plugins directory from runtimepath
  let &runtimepath = join(split(&runtimepath, ",")[1:], ",")
endfunction
