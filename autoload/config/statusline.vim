function! s:get_hl_attr(highlight, attribute)
  return get(nvim_get_hl_by_name(a:highlight, &termguicolors), a:attribute)
endfunction

function! s:add_hl(highlight, options)
  if &termguicolors || has("gui_running")
    let l:modifier = "gui"
  else
    let l:modifier = "cterm"
  endif
  function! s:make_color_attr(option_name) closure
    if !has_key(a:options, a:option_name)
      return ""
    endif
    return l:modifier.a:option_name[0]."g=#".printf("%x", a:options[a:option_name])
  endfunction
  function! s:make_other_attrs() closure
    let l:other_attrs = filter(keys(a:options),
          \ { _, a -> !list#contains(["background", "foreground"], a) })
    if empty(l:other_attrs)
      return ""
    endif
    return l:modifier."=".join(l:other_attrs, ",")
  endfunction
  let l:hl_def = [
        \ "highlight",
        \ a:highlight,
        \ s:make_color_attr("background"),
        \ s:make_color_attr("foreground"),
        \ s:make_other_attrs(),
        \]
  execute join(l:hl_def, " ")
endfunction

function! s:update_colors()
  let l:stl_bg = s:get_hl_attr("StatusLine", "background")
  let l:stl_flags_fg = s:get_hl_attr("Search", "background")
  let l:stl_loc_bg = s:get_hl_attr("Directory", "foreground")
  let l:stl_cwd_bg = s:get_hl_attr("String", "foreground")
  let l:stl_cwd_fg = s:get_hl_attr("Normal", "background")
  call s:add_hl("STLFlags", {"foreground": l:stl_flags_fg, "background": l:stl_bg})
  call s:add_hl("STLLocation", {"foreground": l:stl_bg, "background": l:stl_loc_bg})
  call s:add_hl("STLCWD", {"background": l:stl_cwd_bg, "foreground": l:stl_cwd_fg, "bold": 1})
  call s:add_hl("STLEmpty", {"inverse": 1})
  call s:add_hl("STLWinnr", {"bold": 1})
endfunction

call s:update_colors()
augroup config_statusline_update_colors
  autocmd!
  autocmd VimEnter,ColorScheme * call s:update_colors()
augroup end

function! s:highlight(highlight, part)
  return "%#".a:highlight."#".a:part."%#StatusLine#"
endfunction

function! s:evaluate_part(partname)
  return "%{g:config#statusline#parts#".a:partname."()}"
endfunction

function! config#statusline#active()
  let l:stl = [
        \ s:highlight("STLCWD", s:evaluate_part("cwd")),
        \ s:highlight("STLFlags", s:evaluate_part("flags")),
        \ g:config#statusline#parts#sep,
        \ "%<".s:evaluate_part("filename"),
        \ g:config#statusline#parts#sep,
        \ s:highlight("STLEmpty", "%="),
        \ "%(".g:config#statusline#parts#sep.s:evaluate_part("type")."%)",
        \ g:config#statusline#parts#sep,
        \ s:highlight("STLLocation", s:evaluate_part("location")),
        \ g:config#statusline#parts#sep,
        \ s:highlight("STLWinnr", s:evaluate_part("winnr")),
        \]
  return join(l:stl, "")
endfunction

function! config#statusline#inactive()
  let l:stl = [
        \ s:evaluate_part("cwd"),
        \ s:highlight("STLFlags", s:evaluate_part("flags")),
        \ g:config#statusline#parts#sep,
        \ "%<".s:evaluate_part("filename"),
        \ "%=",
        \ s:evaluate_part("winnr"),
        \]
  return join(l:stl, "")
endfunction

function! config#statusline#custom_filename_handler(handler)
  return config#statusline#parts#filename#add_handler(a:handler)
endfunction
