let config#vim_home = fnamemodify($MYVIMRC, ":~:h")
let config#ext_plugins_directory = expand(g:config#vim_home."/ext/plugins")

function! config#toggle_trailing_whitespaces_removal()
  let g:remove_trailing_whitespaces = !g:remove_trailing_whitespaces
endfunction
