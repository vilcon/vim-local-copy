" Test to verify that the three function lists,
"
"   global_functions[] in src/evalfunc.c
"   *functions* in runtime/doc/eval.txt
"   *function-list* in runtime/doc/usr_41.txt
"
" contain the same functions and that the global_functions and ":help
" functions" lists are in ASCII order.

func Test_function_lists()

  " Delete any files left over from an earlier run of this test.

  call delete("Xglobal_functions.diff")
  call delete("Xfunctions.diff")
  call delete("Xfunction-list.diff")

  " Create a file of the functions in evalfunc.c:global_functions[].

  new!
  read ../evalfunc.c
  1,/^static funcentry_T global_functions\[\] =$/d
  call search('^};$')
  .,$d
  v/^    {/d
  %s/^    {"//
  %s/".*//
  w! Xglobal_functions

  " Verify that those functions are in ASCII order.

  sort u
  w! Xsorted_global_functions
  let l:unequal = assert_equalfile("Xsorted_global_functions", "Xglobal_functions",
      \ "global_functions[] not sorted")
  if l:unequal && executable("diff")
    call system("diff -u Xsorted_global_functions Xglobal_functions > Xglobal_functions.diff")
  endif

  " Create a file of the functions in evalfunc.c:global_functions[] that are
  " not obsolete, sorted in ASCII order.

  new!
  read ../evalfunc.c
  1,/^static funcentry_T global_functions\[\] =$/d
  call search('^};$')
  .,$d
  v/^    {/d
  g/\/\/ obsolete$/d
  %s/^    {"//
  %s/".*//
  sort u
  w! ++ff=unix Xsorted_current_global_functions

  " Verify that the ":help functions" list is complete and in ASCII order.

  new!
  if filereadable('../../doc/eval.txt')
    " unpacked MS-Windows zip archive
    read ../../doc/eval.txt
  else
    read ../../runtime/doc/eval.txt
  endif
  call search('\*functions\*$')
  call search('^USAGE')
  1,.d
  call search('\*\K\k*()\*$')
  .,$d
  v/^\S/d
  %s/(.*//
  let l:lines = getline(1, '$')
  call uniq(l:lines)
  call writefile(l:lines, "Xfunctions")
  let l:unequal = assert_equalfile("Xsorted_current_global_functions", "Xfunctions",
      \ "\":help functions\" not sorted or incomplete")
  if l:unequal && executable("diff")
    call system("diff -u Xsorted_current_global_functions Xfunctions > Xfunctions.diff")
  endif

  " Verify that the ":help function-list" list is complete.

  new!
  if filereadable('../../doc/usr_41.txt')
    " unpacked MS-Windows zip archive
    read ../../doc/usr_41.txt
  else
    read ../../runtime/doc/usr_41.txt
  endif
  call search('\*function-list\*$')
  1,.d
  call search('^==*$')
  .,$d
  v/^\t\S/d
  %s/(.*//
  %left
  sort u
  w! ++ff=unix Xfunction-list
  let l:unequal = assert_equalfile("Xsorted_current_global_functions", "Xfunction-list",
      \ "\":help function-list\" incomplete")
  if l:unequal && executable("diff")
    call system("diff -u Xsorted_current_global_functions Xfunction-list > Xfunction-list.diff")
  endif

  " Clean up.
  call delete("Xglobal_functions")
  call delete("Xsorted_global_functions")
  call delete("Xsorted_current_global_functions")
  call delete("Xfunctions")
  call delete("Xfunction-list")
  new!

endfunc

" vim: shiftwidth=2 sts=2 expandtab
