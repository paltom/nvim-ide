let config#statusline#highlight# = {}

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
          \ { _, a -> !g:list#.contains(["background", "foreground"], a) })
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

function! config#statusline#highlight#.update_colors()
  let l:stl_bg = s:get_hl_attr("StatusLine", "background")
  let l:stl_flags_fg = s:get_hl_attr("Search", "background")
  let l:stl_loc_bg = s:get_hl_attr("Directory", "foreground")
  let l:stl_cwd_fg = s:get_hl_attr("String", "foreground")
  call s:add_hl("STLFlags", {"foreground": l:stl_flags_fg, "background": l:stl_bg})
  call s:add_hl("STLLocation", {"foreground": l:stl_bg, "background": l:stl_loc_bg})
  call s:add_hl("STLCWD", {"foreground": l:stl_cwd_fg, "inverse": 1, "bold": 1})
  call s:add_hl("STLEmpty", {"inverse": 1})
  call s:add_hl("STLWinnr", {"bold": 1})
endfunction

function! config#statusline#highlight#.part(highlight, part)
  return "%#".a:highlight."#".a:part."%#StatusLine#"
endfunction
