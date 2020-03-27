let s:script_suites = {}

function! vut#test_script_file(path)
  let l:full_script_path = fnamemodify(findfile(a:path, &runtimepath), ":~")
  let l:script_sid = util#sid(l:full_script_path)
  let l:script_snr = "<snr>".l:script_sid."_"
  let s:script_suites[l:full_script_path] = {
        \ "call_local": function("s:call_local", [l:script_snr])
        \}
  return s:script_suites[l:full_script_path]
endfunction

function! s:call_local(snr, func_name, args)
  return call(a:snr.a:func_name, a:args)
endfunction
