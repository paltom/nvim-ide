let s:test_suites = {}

function! s:normalize_path(file)
  return fnamemodify(a:file, ":~")
endfunction

function! s:sid(script_path)
  let l:scriptnames = split(
        \ execute("scriptnames"),
        \ "\n",
        \)
  let l:matching_names = filter(
        \ l:scriptnames,
        \ { _, name -> name =~# a:script_path },
        \)
  let l:scriptname = trim(l:matching_names[0])
  let l:sid = matchstr(
        \ l:scriptname,
        \ '\v^\s*\zs\d+\ze:',
        \)
  return l:sid
endfunction

function! s:create_suite(
      \ script_file,
      \)
  let s:test_suites[a:script_file] = {}
  return s:test_suites[a:script_file]
endfunction!

function! test#register(script_file)
  let l:script_path = s:normalize_path(a:script_file)
  return s:create_suite(l:script_path)
endfunction

function! test#execute(script_file)
  let l:script_path = s:normalize_path(a:script_file)
  let l:script_suite = get(
        \ s:test_suites,
        \ l:script_path,
        \ {},
        \)
  let v:errors = []
  for func_name in keys(l:script_suite)
    call l:script_suite[func_name]()
  endfor
  echo v:errors
endfunction

let s:tests = test#register(expand("<sfile>"))

function! s:tests.abc()
  echomsg "abc"
endfunction

" vim:fdm=indent
