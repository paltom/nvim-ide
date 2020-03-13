" Statusline {{{
" Statusline colors {{{
function! s:update_statusline_colors()
  " Function updating highlight groups used for statusline parts
  function! s:get_highlight_color(highlight_name, attribute)
    " Helper function to get color of given attribute of given highlight group
    function! s:follow_links(highlight_name)
      let l:output = execute("highlight ".a:highlight_name)
      if l:output =~# " links to "
        let l:linked_highlight = matchstr(l:output, '\v\w*$')
        return s:follow_links(l:linked_highlight)
      else
        return split(l:output)
      endif
    endfunction
    let l:raw_attributes = filter(s:follow_links(a:highlight_name),
          \ { _, output_part -> output_part =~ "="}
          \)
    let l:attribute_entries = map(l:raw_attributes,
          \ { _, raw_attribute -> split(raw_attribute, "=")}
          \)
    let l:attribute_entry = filter(l:attribute_entries,
          \ { _, attribute_entry -> attribute_entry[0] ==? a:attribute}
          \)
    if empty(l:attribute_entry)
      return ""
    else
      return l:attribute_entry[0][1]
    endif
  endfunction
  let l:stl_guibg = s:get_highlight_color("StatusLine", "guibg")
  let l:stl_flags_guifg = s:get_highlight_color("Search", "guibg")
  let l:stl_loc_guibg = s:get_highlight_color("Directory", "guifg")
  let l:stl_cwd_guifg = s:get_highlight_color("String", "guifg")
  " STLFlags is used for file status flags
  execute "highlight STLFlags guibg=".l:stl_guibg." guifg=".l:stl_flags_guifg
  " STLLocation is used for location in file marker
  execute "highlight STLLocation guifg=".l:stl_guibg." guibg=".l:stl_loc_guibg
  " STLCWD is used for current working directory part
  execute "highlight STLCWD guifg=".l:stl_cwd_guifg." gui=inverse,bold"
  " STLEmpty is used for separator in active window's statusline
  highlight STLEmpty gui=inverse
  " STLWinnr is used for window number part
  highlight STLWinnr gui=bold
endfunction
augroup config_statusline_colors
  autocmd!
  " Create statusline colors when starting Vim
  autocmd VimEnter * call s:update_statusline_colors()
  " Make sure that statusline highlights are available after changing
  " colorscheme
  autocmd ColorScheme * call s:update_statusline_colors()
augroup end
" }}}

" Utility functions {{{
function! s:sid()
  return matchstr(expand("<sfile>"), '<SNR>\zs\d\+\ze_SID$')
endfun
function! s:highlight_stl_part(part, highlight_group)
  " Helper function for highlighting statusline part
  return "%#".a:highlight_group."#".a:part."%#StatusLine#"
endfunction
" }}}

" Statusline parts {{{
" Statusline parts separator
let s:stl_sep = " "

" Statusline current working directory part
" Current working directory path is relative to home directory when possible
" Current working directory path is shortened up to last directory (exclusive)
function! s:stl_cwd()
  return "%{pathshorten(fnamemodify(getcwd(), ':~'))}:"
endfunction

" Statusline file status flags part
" When file is not modifiable or readonly, display lockpad character
" When file is modified, display centered asterisk character
function! s:stl_file_flags(winid)
  let l:bufnr = winbufnr(a:winid)
  let l:modifiable = getbufvar(l:bufnr, "&modifiable")
  let l:readonly = getbufvar(l:bufnr, "&readonly")
  if l:modifiable && !l:readonly
    let l:modified = getbufvar(l:bufnr, "&modified")
    if l:modified
      let l:flag = " \u274b"
    else
      let l:flag = ""
    endif
  else
    let l:flag = "\U1f512"
  endif
  if empty(l:flag)
    let l:flags = "  "
  else
    let l:flags = l:flag
  endif
  return l:flags
endfunction

" Filename part functions {{{
function! s:stl_filename_set_cwd_context(context)
  " Store cwd context of current active window
  let a:context["original_cwd"] = getcwd()
  " Is it locally-set directory?
  if haslocaldir()
    let a:context["cwd_type"] = "l"
  elseif haslocaldir(-1)
    let a:context["cwd_type"] = "t"
  else
    let a:context["cwd_type"] = ""
  endif
  " Set local working directory to window for which stl is drawn
  " This is for correct context of filename-modifiers
  silent execute "lcd ".getcwd(a:context["winid"])
endfunction
function! s:stl_filename_restore_cwd_context(context)
  " Restore original cwd of current active window
  silent execute a:context["cwd_type"]."cd ".a:context["original_cwd"]
endfunction
" Special cases for filename stl part
" Filetypes that should display custom file name
" See call#first_if for object structure
let g:statusline_filename_special_filetypes = []
let g:statusline_filename_special_filetypes = add(
      \ g:statusline_filename_special_filetypes,
      \ {
      \   "if": { c -> getbufvar(c["bufnr"], "&filetype") == "help" },
      \   "call": { c -> fnamemodify(c["bufname"], ":t") }
      \ }
      \)
" List of handlers for patterns in bufname (full)
" See call#first_if for object structure
let g:statusline_filename_special_patterns = []
" Empty filename handling (buffer not written to disk)
function! s:filename_no_name(context)
  if empty(a:context["bufname"])
    call call#set_result(a:context, "[No Name]")
  endif
endfunction
" Regular filename handling
" Shorten path relatively to current working directory
" Leave full name of directory containing file
function! s:filename_shorten_relative_path(context)
  let l:head_dir = fnamemodify(a:context["bufname"], ":.:h")
  if l:head_dir == "."
    " If file is in current working directory, do not display cwd
    call call#set_result(a:context, fnamemodify(a:context["bufname"], ":t"))
  else
    call call#set_result(a:context,
          \ pathshorten(l:head_dir).
          \ expand("/").
          \ fnamemodify(a:context["bufname"], ":t")
          \)
  endif
endfunction
" Simple filename
function! s:filename_simple(context)
  let l:filename = fnamemodify(a:context["bufname"], ":t")
  call call#set_result(a:context, l:filename)
endfunction
" Which functions and in which order (precedence) determine filename part
let s:stl_filename_funcs = [
      \ { c -> call#first_if_set_result(g:statusline_filename_special_filetypes, c) },
      \ function("s:filename_no_name"),
      \ { c -> call#first_if_set_result(g:statusline_filename_special_patterns, c) },
      \ function("s:filename_shorten_relative_path"),
      \]
function! s:stl_filename(winid)
  let l:bufnr = winbufnr(a:winid)
  " Store context of window for which statusline is drawn
  let l:context  = {
        \ "original_cwd": "",
        \ "cwd_type": "",
        \ "bufnr": l:bufnr,
        \ "bufname": bufname(l:bufnr),
        \ "winid": a:winid,
        \ "has_result": 0,
        \ "filename": "",
        \}
  " Set correct working directory context (for window for which statusline is
  " drawn, not active window)
  call s:stl_filename_set_cwd_context(l:context)
  let l:filename = call#until_result(s:stl_filename_funcs, l:context)
  " Restore window's original current working directory
  call s:stl_filename_restore_cwd_context(l:context)
  return l:filename
endfunction
" }}}

" Filetype statusline part
function! s:stl_type()
  return "%(%y%q%w%)"
endfunction

" Location if file statusline part
function! s:stl_location()
  let l:location_indicators_list = [
        \ ["\u2588"],
        \ ["\u2588", " "],
        \ ["\u2588", "\u2584", " "],
        \ ["\u2588", "\u2585", "\u2583", " "],
        \ ["\u2588", "\u2586", "\u2584", "\u2582", " "],
        \ ["\u2588", "\u2586", "\u2585", "\u2583", "\u2582", " "],
        \ ["\u2588", "\u2587", "\u2585", "\u2584", "\u2583", "\u2582", " "],
        \ ["\u2588", "\u2587", "\u2586", "\u2585", "\u2583", "\u2582", "\u2581", " "],
        \ ["\u2588", "\u2587", "\u2586", "\u2585", "\u2584", "\u2583", "\u2582", "\u2581", " "],
        \]
  let l:curline = line(".")
  let l:file_lines = line("$")
  " Make count a float number to enable floating-point arithmetics
  let l:indicators_count = eval(len(l:location_indicators_list).".0")
  if l:file_lines < l:indicators_count
    return l:location_indicators_list[l:file_lines - 1][l:curline - 1]
  else
    let l:indicator_index = float2nr(floor(l:indicators_count*(l:curline - 1)/l:file_lines))
    return l:location_indicators_list[-1][l:indicator_index]
  endif
endfunction

" Display window id statusline part
function! s:stl_win_nr()
  return "[%{winnr()}]"
endfunction
" }}}

" Active window statusline drawing
function! s:stl(winid)
  let l:stl = ""
  let l:stl .= s:highlight_stl_part(s:stl_cwd(), "STLCWD")
  let l:stl .= s:highlight_stl_part(s:stl_file_flags(a:winid), "STLFlags")
  let l:stl .= s:stl_sep
  let l:stl .= "%<"
  let l:stl .= s:stl_filename(a:winid)
  let l:stl .= s:stl_sep
  let l:stl .= s:highlight_stl_part("%=", "STLEmpty")
  let l:stl .= s:stl_sep
  let l:stl .= s:stl_type()
  let l:stl .= s:stl_sep
  let l:stl .= s:highlight_stl_part(s:stl_location(), "STLLocation")
  let l:stl .= s:stl_sep
  let l:stl .= s:highlight_stl_part(s:stl_win_nr(), "STLWinnr")
  return l:stl
endfunction

" Inactive windows statusline drawing
function! s:stlnc(winid)
  let l:stl = ""
  let l:stl .= s:stl_cwd()
  let l:stl .= s:highlight_stl_part(s:stl_file_flags(a:winid), "STLFlags")
  let l:stl .= s:stl_sep
  let l:stl .= "%<"
  let l:stl .= s:stl_filename(a:winid)
  let l:stl .= "%="
  let l:stl .= s:stl_win_nr()
  return l:stl
endfunction

execute "setlocal statusline=%!<snr>".s:sid()."_stl(".win_getid().")"
augroup config_statusline_update
  autocmd!
  " Set correct statusline functions for all windows in tabpage when changing
  " windows
  autocmd WinEnter,BufWinEnter *
        \ for n in range(1, winnr("$"))|
        \   if n == winnr()|
        \     call setwinvar(n, "&statusline", "%!<snr>".s:sid()."_stl(".win_getid(n).")")|
        \   else|
        \     call setwinvar(n, "&statusline", "%!<snr>".s:sid()."_stlnc(".win_getid(n).")")|
        \   endif|
        \ endfor
augroup end
" }}}

" Tabline {{{
" Display tabline when there are at least two tabpages
set showtabline=1
" Do not use GUI external tabline
set guioptions-=e

" Tabline parts separator
let s:tbl_sep = " "

" Filename tabline part
let s:tbl_filename_funcs = [
      \ function("s:filename_no_name"),
      \ function("s:filename_simple"),
      \]
function! s:tbl_filename(tabpagenr)
  let l:tabpage_curwin = tabpagewinnr(a:tabpagenr)
  let l:curwin_bufnr = tabpagebuflist(a:tabpagenr)[l:tabpage_curwin - 1]
  let l:bufname = bufname(l:curwin_bufnr)
  let l:context = {
        \ "bufname": l:bufname,
        \ "has_result": 0,
        \ "filename": "",
        \}
  return call#until_result(s:tbl_filename_funcs, l:context)
endfunction

" If any window in tabpage is modified
function! s:tbl_modified(tabpagenr)
  for winnr in range(1, tabpagewinnr(a:tabpagenr, "$"))
    if gettabwinvar(a:tabpagenr, winnr, "&modified")
      return "*"
    endif
  endfor
  return " "
endfunction

" All tabpages tabline drawing (:help setting-tabline)
function! s:tbl()
  let l:tbl = ""
  for tpi in range(1, tabpagenr("$"))
    if tpi == tabpagenr()
      " Active tabpage
      let l:tbl .= "%#TablineSel#"
    else
      " Inactive tabpage
      let l:tbl .= "%#Tabline#"
    endif
    let l:tbl .= "%".tpi."T"
    let l:tbl .= s:tbl_sep
    let l:tbl .= s:tbl_modified(tpi)
    let l:tbl .= s:tbl_sep
    let l:tbl .= s:tbl_filename(tpi)
    let l:tbl .= s:tbl_sep
    let l:tbl .= "[".tpi."]"
  endfor
  let l:tbl .= "%#TablineFill#"
  let l:tbl .= "%="
  return l:tbl
endfunction
execute "set tabline=%!<snr>".s:sid()."_tbl()"
" }}}

" vim:foldmethod=marker
