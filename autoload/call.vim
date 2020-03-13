" Return result of first function from `functions` objects list for which
" condition is met.
" Conditional function object has following keys:
" - if: condition function receiving context and returning boolean
" - call: result-returning function receiving context
" Result-returning function is called only if associated condition function
" returns true. First result-returning function is called and its result is
" returned. Condition functions may modify context object passing additional
" information for subsequent condition functions and result function.
" Throw a "No condition met" exception if no condition function returns true.
function! call#first_if(functions, context)
  for func_obj in a:functions
    if !has_key(func_obj, "if")
      echohl WarningMsg
      echomsg "Missing condition function in ".string(func_obj)
      echohl None
      return
    endif
    if func_obj["if"](a:context)
      if !has_key(func_obj, "call")
        echohl WarningMsg
        echomsg "Missing result-returning function in ".string(func_obj)
        echohl None
        return
      endif
      return func_obj["call"](a:context)
    endif
  endfor
  throw "No condition met"
endfunction

" Call functions in given list one by one until one of them sets result.
" Functions are called with given context argument. To mark that result was
" set, function must invoke call#set_result function passing context and
" result value. Return value of functions is discarded. Functions may modify
" context object, however, "_result_" key is reserved.
" If no function set result, "No result" exception is thrown.
let s:result_key = "_result_"
function! call#until_result(functions, context)
  for Fn in a:functions
    call Fn(a:context)
    if has_key(a:context, s:result_key)
      return a:context[s:result_key]
    endif
  endfor
  throw "No result"
endfunction

function! call#set_result(context, result)
  let a:context[s:result_key] = a:result
endfunction

" Helper function for setting result if any condition function in `functions`
" returned true. If no condition function returned true, don't set result. No
" exception is thrown in this case.
function! call#first_if_set_result(functions, context)
  try
    let l:result = call#first_if(
          \ a:functions,
          \ a:context
          \)
    call call#set_result(a:context, l:result)
  catch /No condition met/
  endtry
endfunction
