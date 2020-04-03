let config#ext_plugins# = {}

let config#ext_plugins#.directory = path#.join(config#.vim_home, "ext_plugins")

function! s:update_rtp(plugin)
  let l:rtpaths = split(&runtimepath, ",")
  " insert plugin directories just before first "after" entry
  let l:plugin_path = g:path#.join(g:config#ext_plugins#.directory, a:plugin)
  let l:plugin_after_path = g:path#.join(l:plugin_path, "after")
  let l:first_after_dir_index = match(l:rtpaths, '\v'.escape(g:path#.sep, '\').'after$')
  let l:rtpaths = g:list#.unique_insert(l:rtpaths, l:plugin_after_path, l:first_after_dir_index)
  let l:rtpaths = g:list#.unique_insert(l:rtpaths, l:plugin_path, l:first_after_dir_index)
  let &runtimepath = join(l:rtpaths, ",")
endfunction

function! s:load_plugin(plugin)
  " store runtimepath
  let l:runtimepath = &runtimepath
  " add plugins directory for runtime
  let &runtimepath = join([g:config#ext_plugins#.directory, &runtimepath], ",")
  execute "runtime! ".g:path#.join(a:plugin, "ftdetect", "**", "*.vim")
  execute "runtime! ".g:path#.join(a:plugin, "plugin", "**", "*.vim")
  let l:plugin_doc_dir = g:path#.join(g:config#ext_plugins#.directory, a:plugin, "doc")
  if isdirectory(l:plugin_doc_dir)
    execute "helptags ".l:plugin_doc_dir
  endif
  " restore original runtimepath
  let &runtimepath = l:runtimepath
endfunction

function! config#ext_plugins#.load(plugins)
  for plugin in a:plugins
    call g:func#.call_all(funcref("s:update_rtp"), funcref("s:load_plugin"))(plugin)
  endfor
endfunction
