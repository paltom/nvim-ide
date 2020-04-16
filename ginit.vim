if exists("g:GuiLoaded")
  call GuiClipboard()
  GuiTabline 0
  GuiPopupmenu 0
  call GuiWindowMaximized(1)
  call GuiMousehide(1)

  nnoremap <F12> <cmd>call GuiWindowFullScreen(!g:GuiWindowFullScreen)<cr>

  if has("unix")
    GuiFont Hack:10
  endif
endif

execute "cd $HOME"
