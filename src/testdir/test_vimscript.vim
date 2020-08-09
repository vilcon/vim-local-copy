" Test various aspects of the Vim script language.
" Most of this was formerly in test49.

source check.vim
source shared.vim
source script_util.vim

"-------------------------------------------------------------------------------
" Test environment							    {{{1
"-------------------------------------------------------------------------------

" Append a message to the "messages" file
func Xout(text)
    split messages
    $put =a:text
    wq
endfunc

com! -nargs=1	     Xout     call Xout(<args>)

" Create a new instance of Vim and run the commands in 'test' and then 'verify'
" The commands in 'test' are expected to store the test results in the Xtest.out
" file. If the test passes successfully, then Xtest.out should be empty.
func RunInNewVim(test, verify)
  let init =<< trim END
    source script_util.vim
    XpathINIT
    XloopINIT
  END
  let cleanup =<< trim END
    call writefile(v:errors, 'Xtest.out')
    qall
  END
  call writefile(init, 'Xtest.vim')
  call writefile(a:test, 'Xtest.vim', 'a')
  call writefile(a:verify, 'Xverify.vim')
  call writefile(cleanup, 'Xverify.vim', 'a')
  call RunVim([], [], "-S Xtest.vim -S Xverify.vim")
  call assert_equal([], readfile('Xtest.out'))
  call delete('Xtest.out')
  call delete('Xtest.vim')
  call delete('Xverify.vim')
endfunc

"-------------------------------------------------------------------------------
" Test 1:   :endwhile in function					    {{{1
"
"	    Detect if a broken loop is (incorrectly) reactivated by the
"	    :endwhile.  Use a :return to prevent an endless loop, and make
"	    this test first to get a meaningful result on an error before other
"	    tests will hang.
"-------------------------------------------------------------------------------

func T1_F()
    Xpath 'a'
    let first = 1
    while 1
	Xpath 'b'
	if first
	    Xpath 'c'
	    let first = 0
	    break
	else
	    Xpath 'd'
	    return
	endif
    endwhile
endfunc

func T1_G()
    Xpath 'h'
    let first = 1
    while 1
	Xpath 'i'
	if first
	    Xpath 'j'
	    let first = 0
	    break
	else
	    Xpath 'k'
	    return
	endif
	if 1	" unmatched :if
    endwhile
endfunc

func Test_endwhile_function()
  XpathINIT
  call T1_F()
  Xpath 'F'

  try
    call T1_G()
  catch
    " Catch missing :endif
    call assert_true(v:exception =~ 'E171')
    Xpath 'x'
  endtry
  Xpath 'G'

  call assert_equal('abcFhijxG', g:Xpath)
endfunc

"-------------------------------------------------------------------------------
" Test 2:   :endwhile in script						    {{{1
"
"	    Detect if a broken loop is (incorrectly) reactivated by the
"	    :endwhile.  Use a :finish to prevent an endless loop, and place
"	    this test before others that might hang to get a meaningful result
"	    on an error.
"
"	    This test executes the bodies of the functions T1_F and T1_G from
"	    the previous test as script files (:return replaced by :finish).
"-------------------------------------------------------------------------------

func Test_endwhile_script()
  XpathINIT
  ExecAsScript T1_F
  Xpath 'F'
  call DeleteTheScript()

  try
    ExecAsScript T1_G
  catch
    " Catch missing :endif
    call assert_true(v:exception =~ 'E171')
    Xpath 'x'
  endtry
  Xpath 'G'
  call DeleteTheScript()

  call assert_equal('abcFhijxG', g:Xpath)
endfunc

"-------------------------------------------------------------------------------
" Test 3:   :if, :elseif, :while, :continue, :break			    {{{1
"-------------------------------------------------------------------------------

func Test_if_while()
    XpathINIT
    if 1
	Xpath 'a'
	let loops = 3
	while loops > -1	    " main loop: loops == 3, 2, 1 (which breaks)
	    if loops <= 0
		let break_err = 1
		let loops = -1
	    else
		Xpath 'b' . loops
	    endif
	    if (loops == 2)
		while loops == 2 " dummy loop
		    Xpath 'c' . loops
		    let loops = loops - 1
		    continue    " stop dummy loop
		    Xpath 'd' . loops
		endwhile
		continue	    " continue main loop
		Xpath 'e' . loops
	    elseif (loops == 1)
		let p = 1
		while p	    " dummy loop
		    Xpath 'f' . loops
		    let p = 0
		    break	    " break dummy loop
		    Xpath 'g' . loops
		endwhile
		Xpath 'h' . loops
		unlet p
		break	    " break main loop
		Xpath 'i' . loops
	    endif
	    if (loops > 0)
		Xpath 'j' . loops
	    endif
	    while loops == 3    " dummy loop
		let loops = loops - 1
	    endwhile	    " end dummy loop
	endwhile		    " end main loop
	Xpath 'k'
    else
	Xpath 'l'
    endif
    Xpath 'm'
    if exists("break_err")
	Xpath 'm'
	unlet break_err
    endif

    unlet loops

    call assert_equal('ab3j3b2c2b1f1h1km', g:Xpath)
endfunc

"-------------------------------------------------------------------------------
" Test 4:   :return							    {{{1
"-------------------------------------------------------------------------------

func T4_F()
    if 1
	Xpath 'a'
	let loops = 3
	while loops > 0				"    3:  2:     1:
	    Xpath 'b' . loops
	    if (loops == 2)
		Xpath 'c' . loops
		return
		Xpath 'd' . loops
	    endif
	    Xpath 'e' . loops
	    let loops = loops - 1
	endwhile
	Xpath 'f'
    else
	Xpath 'g'
    endif
endfunc

func Test_return()
    XpathINIT
    call T4_F()
    Xpath '4'

    call assert_equal('ab3e3b2c24', g:Xpath)
endfunc


"-------------------------------------------------------------------------------
" Test 5:   :finish							    {{{1
"
"	    This test executes the body of the function T4_F from the previous
"	    test as a script file (:return replaced by :finish).
"-------------------------------------------------------------------------------

func Test_finish()
    XpathINIT
    ExecAsScript T4_F
    Xpath '5'
    call DeleteTheScript()

    call assert_equal('ab3e3b2c25', g:Xpath)
endfunc



"-------------------------------------------------------------------------------
" Test 6:   Defining functions in :while loops				    {{{1
"
"	     Functions can be defined inside other functions.  An inner function
"	     gets defined when the outer function is executed.  Functions may
"	     also be defined inside while loops.  Expressions in braces for
"	     defining the function name are allowed.
"
"	     The functions are defined when sourcing the script, only the
"	     resulting path is checked in the test function.
"-------------------------------------------------------------------------------

XpathINIT

" The command CALL collects the argument of all its invocations in "calls"
" when used from a function (that is, when the global variable "calls" needs
" the "g:" prefix).  This is to check that the function code is skipped when
" the function is defined.  For inner functions, do so only if the outer
" function is not being executed.
"
let calls = ""
com! -nargs=1 CALL
	    \ if !exists("calls") && !exists("outer") |
	    \ let g:calls = g:calls . <args> |
	    \ endif

let i = 0
while i < 3
    let i = i + 1
    if i == 1
	Xpath 'a'
	function! F1(arg)
	    CALL a:arg
	    let outer = 1

	    let j = 0
	    while j < 1
		Xpath 'b'
		let j = j + 1
		function! G1(arg)
		    CALL a:arg
		endfunction
		Xpath 'c'
	    endwhile
	endfunction
	Xpath 'd'

	continue
    endif

    Xpath 'e' . i
    function! F{i}(i, arg)
	CALL a:arg
	let outer = 1

	if a:i == 3
	    Xpath 'f'
	endif
	let k = 0
	while k < 3
	    Xpath 'g' . k
	    let k = k + 1
	    function! G{a:i}{k}(arg)
		CALL a:arg
	    endfunction
	    Xpath 'h' . k
	endwhile
    endfunction
    Xpath 'i'

endwhile

if exists("*G1")
    Xpath 'j'
endif
if exists("*F1")
    call F1("F1")
    if exists("*G1")
       call G1("G1")
    endif
endif

if exists("G21") || exists("G22") || exists("G23")
    Xpath 'k'
endif
if exists("*F2")
    call F2(2, "F2")
    if exists("*G21")
       call G21("G21")
    endif
    if exists("*G22")
       call G22("G22")
    endif
    if exists("*G23")
       call G23("G23")
    endif
endif

if exists("G31") || exists("G32") || exists("G33")
    Xpath 'l'
endif
if exists("*F3")
    call F3(3, "F3")
    if exists("*G31")
       call G31("G31")
    endif
    if exists("*G32")
       call G32("G32")
    endif
    if exists("*G33")
       call G33("G33")
    endif
endif

Xpath 'm'

let g:test6_result = g:Xpath
let g:test6_calls = calls

unlet calls
delfunction F1
delfunction G1
delfunction F2
delfunction G21
delfunction G22
delfunction G23
delfunction G31
delfunction G32
delfunction G33

func Test_defining_functions()
    call assert_equal('ade2ie3ibcg0h1g1h2g2h3fg0h1g1h2g2h3m', g:test6_result)
    call assert_equal('F1G1F2G21G22G23F3G31G32G33', g:test6_calls)
endfunc

"-------------------------------------------------------------------------------
" Test 7:   Continuing on errors outside functions			    {{{1
"
"	    On an error outside a function, the script processing continues
"	    at the line following the outermost :endif or :endwhile.  When not
"	    inside an :if or :while, the script processing continues at the next
"	    line.
"-------------------------------------------------------------------------------

XpathINIT

if 1
    Xpath 'a'
    while 1
	Xpath 'b'
	asdf
	Xpath 'c'
	break
    endwhile | Xpath 'd'
    Xpath 'e'
endif | Xpath 'f'
Xpath 'g'

while 1
    Xpath 'h'
    if 1
	Xpath 'i'
	asdf
	Xpath 'j'
    endif | Xpath 'k'
    Xpath 'l'
    break
endwhile | Xpath 'm'
Xpath 'n'

asdf
Xpath 'o'

asdf | Xpath 'p'
Xpath 'q'

let g:test7_result = g:Xpath

func Test_error_in_script()
    call assert_equal('abghinoq', g:test7_result)
endfunc

"-------------------------------------------------------------------------------
" Test 8:   Aborting and continuing on errors inside functions		    {{{1
"
"	    On an error inside a function without the "abort" attribute, the
"	    script processing continues at the next line (unless the error was
"	    in a :return command).  On an error inside a function with the
"	    "abort" attribute, the function is aborted and the script processing
"	    continues after the function call; the value -1 is returned then.
"-------------------------------------------------------------------------------

XpathINIT

func T8_F()
    if 1
	Xpath 'a'
	while 1
	    Xpath 'b'
	    asdf
	    Xpath 'c'
	    asdf | Xpath 'd'
	    Xpath 'e'
	    break
	endwhile
	Xpath 'f'
    endif | Xpath 'g'
    Xpath 'h'

    while 1
	Xpath 'i'
	if 1
	    Xpath 'j'
	    asdf
	    Xpath 'k'
	    asdf | Xpath 'l'
	    Xpath 'm'
	endif
	Xpath 'n'
	break
    endwhile | Xpath 'o'
    Xpath 'p'

    return novar		" returns (default return value 0)
    Xpath 'q'
    return 1			" not reached
endfunc

func T8_G() abort
    if 1
	Xpath 'r'
	while 1
	    Xpath 's'
	    asdf		" returns -1
	    Xpath 't'
	    break
	endwhile
	Xpath 'v'
    endif | Xpath 'w'
    Xpath 'x'

    return -4			" not reached
endfunc

func T8_H() abort
    while 1
	Xpath 'A'
	if 1
	    Xpath 'B'
	    asdf		" returns -1
	    Xpath 'C'
	endif
	Xpath 'D'
	break
    endwhile | Xpath 'E'
    Xpath 'F'

    return -4			" not reached
endfunc

" Aborted functions (T8_G and T8_H) return -1.
let g:test8_sum = (T8_F() + 1) - 4 * T8_G() - 8 * T8_H()
Xpath 'X'
let g:test8_result = g:Xpath

func Test_error_in_function()
    call assert_equal(13, g:test8_sum)
    call assert_equal('abcefghijkmnoprsABX', g:test8_result)

    delfunction T8_F
    delfunction T8_G
    delfunction T8_H
endfunc


"-------------------------------------------------------------------------------
" Test 9:   Continuing after aborted functions				    {{{1
"
"	    When a function with the "abort" attribute is aborted due to an
"	    error, the next function back in the call hierarchy without an
"	    "abort" attribute continues; the value -1 is returned then.
"-------------------------------------------------------------------------------

XpathINIT

func F() abort
    Xpath 'a'
    let result = G()	" not aborted
    Xpath 'b'
    if result != 2
	Xpath 'c'
    endif
    return 1
endfunc

func G()		" no abort attribute
    Xpath 'd'
    if H() != -1	" aborted
	Xpath 'e'
    endif
    Xpath 'f'
    return 2
endfunc

func H() abort
    Xpath 'g'
    call I()		" aborted
    Xpath 'h'
    return 4
endfunc

func I() abort
    Xpath 'i'
    asdf		" error
    Xpath 'j'
    return 8
endfunc

if F() != 1
    Xpath 'k'
endif

let g:test9_result = g:Xpath

delfunction F
delfunction G
delfunction H
delfunction I

func Test_func_abort()
    call assert_equal('adgifb', g:test9_result)
endfunc


"-------------------------------------------------------------------------------
" Test 10:  :if, :elseif, :while argument parsing			    {{{1
"
"	    A '"' or '|' in an argument expression must not be mixed up with
"	    a comment or a next command after a bar.  Parsing errors should
"	    be recognized.
"-------------------------------------------------------------------------------

XpathINIT

func MSG(enr, emsg)
    let english = v:lang == "C" || v:lang =~ '^[Ee]n'
    if a:enr == ""
	Xout "TODO: Add message number for:" a:emsg
	let v:errmsg = ":" . v:errmsg
    endif
    let match = 1
    if v:errmsg !~ '^'.a:enr.':' || (english && v:errmsg !~ a:emsg)
	let match = 0
	if v:errmsg == ""
	    Xout "Message missing."
	else
	    let v:errmsg = v:errmsg->escape('"')
	    Xout "Unexpected message:" v:errmsg
	endif
    endif
    return match
endfunc

if 1 || strlen("\"") | Xpath 'a'
    Xpath 'b'
endif
Xpath 'c'

if 0
elseif 1 || strlen("\"") | Xpath 'd'
    Xpath 'e'
endif
Xpath 'f'

while 1 || strlen("\"") | Xpath 'g'
    Xpath 'h'
    break
endwhile
Xpath 'i'

let v:errmsg = ""
if 1 ||| strlen("\"") | Xpath 'j'
    Xpath 'k'
endif
Xpath 'l'
if !MSG('E15', "Invalid expression")
    Xpath 'm'
endif

let v:errmsg = ""
if 0
elseif 1 ||| strlen("\"") | Xpath 'n'
    Xpath 'o'
endif
Xpath 'p'
if !MSG('E15', "Invalid expression")
    Xpath 'q'
endif

let v:errmsg = ""
while 1 ||| strlen("\"") | Xpath 'r'
    Xpath 's'
    break
endwhile
Xpath 't'
if !MSG('E15', "Invalid expression")
    Xpath 'u'
endif

let g:test10_result = g:Xpath
delfunction MSG

func Test_expr_parsing()
    call assert_equal('abcdefghilpt', g:test10_result)
endfunc


"-------------------------------------------------------------------------------
" Test 11:  :if, :elseif, :while argument evaluation after abort	    {{{1
"
"	    When code is skipped over due to an error, the boolean argument to
"	    an :if, :elseif, or :while must not be evaluated.
"-------------------------------------------------------------------------------

XpathINIT

let calls = 0

func P(num)
    let g:calls = g:calls + a:num   " side effect on call
    return 0
endfunc

if 1
    Xpath 'a'
    asdf		" error
    Xpath 'b'
    if P(1)		" should not be called
	Xpath 'c'
    elseif !P(2)	" should not be called
	Xpath 'd'
    else
	Xpath 'e'
    endif
    Xpath 'f'
    while P(4)		" should not be called
	Xpath 'g'
    endwhile
    Xpath 'h'
endif
Xpath 'x'

let g:test11_calls = calls
let g:test11_result = g:Xpath

unlet calls
delfunction P

func Test_arg_abort()
    call assert_equal(0, g:test11_calls)
    call assert_equal('ax', g:test11_result)
endfunc


"-------------------------------------------------------------------------------
" Test 12:  Expressions in braces in skipped code			    {{{1
"
"	    In code skipped over due to an error or inactive conditional,
"	    an expression in braces as part of a variable or function name
"	    should not be evaluated.
"-------------------------------------------------------------------------------

XpathINIT

function! NULL()
    Xpath 'a'
    return 0
endfunction

function! ZERO()
    Xpath 'b'
    return 0
endfunction

function! F0()
    Xpath 'c'
endfunction

function! F1(arg)
    Xpath 'e'
endfunction

let V0 = 1

Xpath 'f'
echo 0 ? F{NULL() + V{ZERO()}}() : 1

Xpath 'g'
if 0
    Xpath 'h'
    call F{NULL() + V{ZERO()}}()
endif

Xpath 'i'
if 1
    asdf		" error
    Xpath 'j'
    call F1(F{NULL() + V{ZERO()}}())
endif

Xpath 'k'
if 1
    asdf		" error
    Xpath 'l'
    call F{NULL() + V{ZERO()}}()
endif

let g:test12_result = g:Xpath

func Test_braces_skipped()
    call assert_equal('fgik', g:test12_result)
endfunc


"-------------------------------------------------------------------------------
" Test 13:  Failure in argument evaluation for :while			    {{{1
"
"	    A failure in the expression evaluation for the condition of a :while
"	    causes the whole :while loop until the matching :endwhile being
"	    ignored.  Continuation is at the next following line.
"-------------------------------------------------------------------------------

XpathINIT

Xpath 'a'
while asdf
    Xpath 'b'
    while 1
	Xpath 'c'
	break
    endwhile
    Xpath 'd'
    break
endwhile
Xpath 'e'

while asdf | Xpath 'f' | endwhile | Xpath 'g'
Xpath 'h'
let g:test13_result = g:Xpath

func Test_while_fail()
    call assert_equal('aeh', g:test13_result)
endfunc


"-------------------------------------------------------------------------------
" Test 14:  Failure in argument evaluation for :if			    {{{1
"
"	    A failure in the expression evaluation for the condition of an :if
"	    does not cause the corresponding :else or :endif being matched to
"	    a previous :if/:elseif.  Neither of both branches of the failed :if
"	    are executed.
"-------------------------------------------------------------------------------

XpathINIT

function! F()
    Xpath 'a'
    let x = 0
    if x		" false
	Xpath 'b'
    elseif !x		" always true
	Xpath 'c'
	let x = 1
	if g:boolvar	" possibly undefined
	    Xpath 'd'
	else
	    Xpath 'e'
	endif
	Xpath 'f'
    elseif x		" never executed
	Xpath 'g'
    endif
    Xpath 'h'
endfunction

let boolvar = 1
call F()
Xpath '-'

unlet boolvar
call F()
let g:test14_result = g:Xpath

delfunction F

func Test_if_fail()
    call assert_equal('acdfh-acfh', g:test14_result)
endfunc


"-------------------------------------------------------------------------------
" Test 15:  Failure in argument evaluation for :if (bar)		    {{{1
"
"	    Like previous test, except that the failing :if ... | ... | :endif
"	    is in a single line.
"-------------------------------------------------------------------------------

XpathINIT

function! F()
    Xpath 'a'
    let x = 0
    if x		" false
	Xpath 'b'
    elseif !x		" always true
	Xpath 'c'
	let x = 1
	if g:boolvar | Xpath 'd' | else | Xpath 'e' | endif
	Xpath 'f'
    elseif x		" never executed
	Xpath 'g'
    endif
    Xpath 'h'
endfunction

let boolvar = 1
call F()
Xpath '-'

unlet boolvar
call F()
let g:test15_result = g:Xpath

delfunction F

func Test_if_bar_fail()
    call assert_equal('acdfh-acfh', g:test15_result)
endfunc

"-------------------------------------------------------------------------------
" Test 16:  Double :else or :elseif after :else				    {{{1
"
"	    Multiple :elses or an :elseif after an :else are forbidden.
"-------------------------------------------------------------------------------

func T16_F() abort
  if 0
    Xpath 'a'
  else
    Xpath 'b'
  else		" aborts function
    Xpath 'c'
  endif
  Xpath 'd'
endfunc

func T16_G() abort
  if 0
    Xpath 'a'
  else
    Xpath 'b'
  elseif 1		" aborts function
    Xpath 'c'
  else
    Xpath 'd'
  endif
  Xpath 'e'
endfunc

func T16_H() abort
  if 0
    Xpath 'a'
  elseif 0
    Xpath 'b'
  else
    Xpath 'c'
  else		" aborts function
    Xpath 'd'
  endif
  Xpath 'e'
endfunc

func T16_I() abort
  if 0
    Xpath 'a'
  elseif 0
    Xpath 'b'
  else
    Xpath 'c'
  elseif 1		" aborts function
    Xpath 'd'
  else
    Xpath 'e'
  endif
  Xpath 'f'
endfunc

func Test_Multi_Else()
  XpathINIT
  try
    call T16_F()
  catch /E583:/
    Xpath 'e'
  endtry
  call assert_equal('be', g:Xpath)

  XpathINIT
  try
    call T16_G()
  catch /E584:/
    Xpath 'f'
  endtry
  call assert_equal('bf', g:Xpath)

  XpathINIT
  try
    call T16_H()
  catch /E583:/
    Xpath 'f'
  endtry
  call assert_equal('cf', g:Xpath)

  XpathINIT
  try
    call T16_I()
  catch /E584:/
    Xpath 'g'
  endtry
  call assert_equal('cg', g:Xpath)
endfunc

"-------------------------------------------------------------------------------
" Test 17:  Nesting of unmatched :if or :endif inside a :while		    {{{1
"
"	    The :while/:endwhile takes precedence in nesting over an unclosed
"	    :if or an unopened :endif.
"-------------------------------------------------------------------------------

" While loops inside a function are continued on error.
func T17_F()
  let loops = 3
  while loops > 0
    let loops -= 1
    Xpath 'a' . loops
    if (loops == 1)
      Xpath 'b' . loops
      continue
    elseif (loops == 0)
      Xpath 'c' . loops
      break
    elseif 1
      Xpath 'd' . loops
    " endif missing!
  endwhile	" :endwhile after :if 1
  Xpath 'e'
endfunc

func T17_G()
  let loops = 2
  while loops > 0
    let loops -= 1
    Xpath 'a' . loops
    if 0
      Xpath 'b' . loops
    " endif missing
  endwhile	" :endwhile after :if 0
endfunc

func T17_H()
  let loops = 2
  while loops > 0
    let loops -= 1
    Xpath 'a' . loops
    " if missing!
    endif	" :endif without :if in while
    Xpath 'b' . loops
  endwhile
endfunc

" Error continuation outside a function is at the outermost :endwhile or :endif.
XpathINIT
let v:errmsg = ''
let loops = 2
while loops > 0
    let loops -= 1
    Xpath 'a' . loops
    if 0
	Xpath 'b' . loops
    " endif missing! Following :endwhile fails.
endwhile | Xpath 'c'
Xpath 'd'
call assert_match('E171:', v:errmsg)
call assert_equal('a1d', g:Xpath)

func Test_unmatched_if_in_while()
  XpathINIT
  call assert_fails('call T17_F()', 'E171:')
  call assert_equal('a2d2a1b1a0c0e', g:Xpath)

  XpathINIT
  call assert_fails('call T17_G()', 'E171:')
  call assert_equal('a1a0', g:Xpath)

  XpathINIT
  call assert_fails('call T17_H()', 'E580:')
  call assert_equal('a1b1a0b0', g:Xpath)
endfunc

"-------------------------------------------------------------------------------
" Test 18:  Interrupt (Ctrl-C pressed)					    {{{1
"
"	    On an interrupt, the script processing is terminated immediately.
"-------------------------------------------------------------------------------

func Test_interrupt_while_if()
  let test =<< trim [CODE]
    try
      if 1
        Xpath 'a'
        while 1
          Xpath 'b'
          if 1
            Xpath 'c'
            call interrupt()
            call assert_report('should not get here')
            break
            finish
          endif | call assert_report('should not get here')
          call assert_report('should not get here')
        endwhile | call assert_report('should not get here')
        call assert_report('should not get here')
      endif | call assert_report('should not get here')
      call assert_report('should not get here')
    catch /^Vim:Interrupt$/
      Xpath 'd'
    endtry | Xpath 'e'
    Xpath 'f'
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('abcdef', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

func Test_interrupt_try()
  let test =<< trim [CODE]
    try
      try
        Xpath 'a'
        call interrupt()
        call assert_report('should not get here')
      endtry | call assert_report('should not get here')
      call assert_report('should not get here')
    catch /^Vim:Interrupt$/
      Xpath 'b'
    endtry | Xpath 'c'
    Xpath 'd'
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('abcd', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

func Test_interrupt_func_while_if()
  let test =<< trim [CODE]
    func F()
      if 1
        Xpath 'a'
        while 1
          Xpath 'b'
          if 1
            Xpath 'c'
            call interrupt()
            call assert_report('should not get here')
            break
            return
          endif | call assert_report('should not get here')
          call assert_report('should not get here')
        endwhile | call assert_report('should not get here')
        call assert_report('should not get here')
      endif | call assert_report('should not get here')
      call assert_report('should not get here')
    endfunc

    Xpath 'd'
    try
      call F() | call assert_report('should not get here')
    catch /^Vim:Interrupt$/
      Xpath 'e'
    endtry | Xpath 'f'
    Xpath 'g'
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('dabcefg', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

func Test_interrupt_func_try()
  let test =<< trim [CODE]
    func G()
      try
        Xpath 'a'
        call interrupt()
        call assert_report('should not get here')
      endtry | call assert_report('should not get here')
      call assert_report('should not get here')
    endfunc

    Xpath 'b'
    try
      call G() | call assert_report('should not get here')
    catch /^Vim:Interrupt$/
      Xpath 'c'
    endtry | Xpath 'd'
    Xpath 'e'
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('bacde', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

"-------------------------------------------------------------------------------
" Test 19:  Aborting on errors inside :try/:endtry			    {{{1
"
"	    An error in a command dynamically enclosed in a :try/:endtry region
"	    aborts script processing immediately.  It does not matter whether
"	    the failing command is outside or inside a function and whether a
"	    function has an "abort" attribute.
"-------------------------------------------------------------------------------

func Test_try_error_abort_1()
  let test =<< trim [CODE]
    func F() abort
      Xpath 'a'
      asdf
      call assert_report('should not get here')
    endfunc

    try
      Xpath 'b'
      call F()
      call assert_report('should not get here')
    endtry | call assert_report('should not get here')
    call assert_report('should not get here')
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('ba', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

func Test_try_error_abort_2()
  let test =<< trim [CODE]
    func G()
      Xpath 'a'
      asdf
      call assert_report('should not get here')
    endfunc

    try
      Xpath 'b'
      call G()
      call assert_report('should not get here')
    endtry | call assert_report('should not get here')
    call assert_report('should not get here')
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('ba', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

func Test_try_error_abort_3()
  let test =<< trim [CODE]
    try
      Xpath 'a'
      asdf
      call assert_report('should not get here')
    endtry | call assert_report('should not get here')
    call assert_report('should not get here')
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('a', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

func Test_try_error_abort_4()
  let test =<< trim [CODE]
    if 1
      try
        Xpath 'a'
        asdf
        call assert_report('should not get here')
      endtry | call assert_report('should not get here')
    endif | call assert_report('should not get here')
    call assert_report('should not get here')
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('a', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

func Test_try_error_abort_5()
  let test =<< trim [CODE]
    let p = 1
    while p
      let p = 0
      try
        Xpath 'a'
        asdf
        call assert_report('should not get here')
      endtry | call assert_report('should not get here')
    endwhile | call assert_report('should not get here')
    call assert_report('should not get here')
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('a', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

func Test_try_error_abort_6()
  let test =<< trim [CODE]
    let p = 1
    Xpath 'a'
    while p
      Xpath 'b'
      let p = 0
      try
        Xpath 'c'
    endwhile | call assert_report('should not get here')
    call assert_report('should not get here')
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('abc', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

"-------------------------------------------------------------------------------
" Test 20:  Aborting on errors after :try/:endtry			    {{{1
"
"	    When an error occurs after the last active :try/:endtry region has
"	    been left, termination behavior is as if no :try/:endtry has been
"	    seen.
"-------------------------------------------------------------------------------

func Test_error_after_try_1()
  let test =<< trim [CODE]
    let p = 1
    while p
      let p = 0
      Xpath 'a'
      try
        Xpath 'b'
      endtry
      asdf
      call assert_report('should not get here')
    endwhile | call assert_report('should not get here')
    Xpath 'c'
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('abc', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

func Test_error_after_try_2()
  let test =<< trim [CODE]
    while 1
      try
        Xpath 'a'
        break
        call assert_report('should not get here')
      endtry
    endwhile
    Xpath 'b'
    asdf
    Xpath 'c'
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('abc', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

func Test_error_after_try_3()
  let test =<< trim [CODE]
    while 1
      try
        Xpath 'a'
        break
        call assert_report('should not get here')
      finally
        Xpath 'b'
      endtry
    endwhile
    Xpath 'c'
    asdf
    Xpath 'd'
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('abcd', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

func Test_error_after_try_4()
  let test =<< trim [CODE]
    while 1
      try
        Xpath 'a'
      finally
        Xpath 'b'
        break
        call assert_report('should not get here')
      endtry
    endwhile
    Xpath 'c'
    asdf
    Xpath 'd'
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('abcd', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

func Test_error_after_try_5()
  let test =<< trim [CODE]
    let p = 1
    while p
      let p = 0
      try
        Xpath 'a'
        continue
        call assert_report('should not get here')
      endtry
    endwhile
    Xpath 'b'
    asdf
    Xpath 'c'
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('abc', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

func Test_error_after_try_6()
  let test =<< trim [CODE]
    let p = 1
    while p
      let p = 0
      try
        Xpath 'a'
        continue
        call assert_report('should not get here')
      finally
        Xpath 'b'
      endtry
    endwhile
    Xpath 'c'
    asdf
    Xpath 'd'
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('abcd', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

func Test_error_after_try_7()
  let test =<< trim [CODE]
    let p = 1
    while p
      let p = 0
      try
        Xpath 'a'
      finally
        Xpath 'b'
        continue
        call assert_report('should not get here')
      endtry
    endwhile
    Xpath 'c'
    asdf
    Xpath 'd'
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('abcd', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

"-------------------------------------------------------------------------------
" Test 21:  :finally for :try after :continue/:break/:return/:finish	    {{{1
"
"	    If a :try conditional stays inactive due to a preceding :continue,
"	    :break, :return, or :finish, its :finally clause should not be
"	    executed.
"-------------------------------------------------------------------------------

func Test_finally_after_loop_ctrl_statement()
  let test =<< trim [CODE]
    func F()
      let loops = 2
      while loops > 0
        XloopNEXT
        let loops = loops - 1
        try
          if loops == 1
            Xloop 'a'
            continue
            call assert_report('should not get here')
          elseif loops == 0
            Xloop 'b'
            break
            call assert_report('should not get here')
          endif

          try		" inactive
            call assert_report('should not get here')
          finally
            call assert_report('should not get here')
          endtry
        finally
          Xloop 'c'
        endtry
        call assert_report('should not get here')
      endwhile

      try
        Xpath 'd'
        return
        call assert_report('should not get here')
        try		    " inactive
          call assert_report('should not get here')
        finally
          call assert_report('should not get here')
        endtry
      finally
        Xpath 'e'
      endtry
      call assert_report('should not get here')
    endfunc

    try
      Xpath 'f'
      call F()
      Xpath 'g'
      finish
      call assert_report('should not get here')
      try		" inactive
        call assert_report('should not get here')
      finally
        call assert_report('should not get here')
      endtry
    finally
      Xpath 'h'
    endtry
    call assert_report('should not get here')
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('fa2c2b3c3degh', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

"-------------------------------------------------------------------------------
" Test 22:  :finally for a :try after an error/interrupt/:throw		    {{{1
"
"	    If a :try conditional stays inactive due to a preceding error or
"	    interrupt or :throw, its :finally clause should not be executed.
"-------------------------------------------------------------------------------

func Test_finally_after_error_in_func()
  let test =<< trim [CODE]
    func Error()
      try
        Xpath 'b'
        asdf    " aborting error, triggering error exception
        call assert_report('should not get here')
      endtry
      call assert_report('should not get here')
    endfunc

    Xpath 'a'
    call Error()
    call assert_report('should not get here')

    if 1	" not active due to error
      try	" not active since :if inactive
        call assert_report('should not get here')
      finally
        call assert_report('should not get here')
      endtry
    endif

    try		" not active due to error
      call assert_report('should not get here')
    finally
      call assert_report('should not get here')
    endtry
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('ab', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

func Test_finally_after_interrupt()
  let test =<< trim [CODE]
    func Interrupt()
      try
        Xpath 'a'
        call interrupt()            " triggering interrupt exception
        call assert_report('should not get here')
      endtry
    endfunc

    Xpath 'b'
    try
      call Interrupt()
    catch /^Vim:Interrupt$/
      Xpath 'c'
      finish
    endtry
    call assert_report('should not get here')

    if 1	" not active due to interrupt
      try	" not active since :if inactive
        call assert_report('should not get here')
      finally
        call assert_report('should not get here')
      endtry
    endif

    try		" not active due to interrupt
      call assert_report('should not get here')
    finally
      call assert_report('should not get here')
    endtry
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('bac', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

func Test_finally_after_throw()
  let test =<< trim [CODE]
    func Throw()
      Xpath 'a'
      throw 'xyz'
    endfunc

    Xpath 'b'
    call Throw()
    call assert_report('should not get here')

    if 1	" not active due to :throw
      try	" not active since :if inactive
        call assert_report('should not get here')
      finally
        call assert_report('should not get here')
      endtry
    endif

    try		" not active due to :throw
      call assert_report('should not get here')
    finally
      call assert_report('should not get here')
    endtry
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('ba', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

"-------------------------------------------------------------------------------
" Test 23:  :catch clauses for a :try after a :throw			    {{{1
"
"	    If a :try conditional stays inactive due to a preceding :throw,
"	    none of its :catch clauses should be executed.
"-------------------------------------------------------------------------------

func Test_catch_after_throw()
  let test =<< trim [CODE]
    try
      Xpath 'a'
      throw "xyz"
      call assert_report('should not get here')

      if 1	" not active due to :throw
        try	" not active since :if inactive
          call assert_report('should not get here')
        catch /xyz/
          call assert_report('should not get here')
        endtry
      endif
    catch /xyz/
      Xpath 'b'
    endtry

    Xpath 'c'
    throw "abc"
    call assert_report('should not get here')

    try		" not active due to :throw
      call assert_report('should not get here')
    catch /abc/
      call assert_report('should not get here')
    endtry
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('abc', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

"-------------------------------------------------------------------------------
" Test 24:  :endtry for a :try after a :throw				    {{{1
"
"	    If a :try conditional stays inactive due to a preceding :throw,
"	    its :endtry should not rethrow the exception to the next surrounding
"	    active :try conditional.
"-------------------------------------------------------------------------------

func Test_endtry_after_throw()
  let test =<< trim [CODE]
    try			" try 1
      try		" try 2
        Xpath 'a'
        throw "xyz"	" makes try 2 inactive
        call assert_report('should not get here')

        try		" try 3
          call assert_report('should not get here')
        endtry	" no rethrow to try 1
      catch /xyz/	" should catch although try 2 inactive
        Xpath 'b'
      endtry
    catch /xyz/		" try 1 active, but exception already caught
      call assert_report('should not get here')
    endtry
    Xpath 'c'
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('abc', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

"-------------------------------------------------------------------------------
" Test 27:  Executing :finally clauses after :return			    {{{1
"
"	    For a :return command dynamically enclosed in a :try/:endtry region,
"	    :finally clauses are executed and the called function is ended.
"-------------------------------------------------------------------------------

func T27_F()
  try
    Xpath 'a'
    try
      Xpath 'b'
      return
      call assert_report('should not get here')
    finally
      Xpath 'c'
    endtry
    Xpath 'd'
  finally
    Xpath 'e'
  endtry
  call assert_report('should not get here')
endfunc

func T27_G()
  try
    Xpath 'f'
    return
    call assert_report('should not get here')
  finally
    Xpath 'g'
    call T27_F()
    Xpath 'h'
  endtry
  call assert_report('should not get here')
endfunc

func T27_H()
  try
    Xpath 'i'
    call T27_G()
    Xpath 'j'
  finally
    Xpath 'k'
    return
    call assert_report('should not get here')
  endtry
  call assert_report('should not get here')
endfunction

func Test_finally_after_return()
  XpathINIT
  try
      Xpath 'l'
      call T27_H()
      Xpath 'm'
  finally
      Xpath 'n'
  endtry
  call assert_equal('lifgabcehjkmn', g:Xpath)
endfunc

"-------------------------------------------------------------------------------
" Test 28:  Executing :finally clauses after :finish			    {{{1
"
"	    For a :finish command dynamically enclosed in a :try/:endtry region,
"	    :finally clauses are executed and the sourced file is finished.
"
"	    This test executes the bodies of the functions F, G, and H from the
"	    previous test as script files (:return replaced by :finish).
"-------------------------------------------------------------------------------

func Test_finally_after_finish()
  XpathINIT

  let scriptF = MakeScript("T27_F")
  let scriptG = MakeScript("T27_G", scriptF)
  let scriptH = MakeScript("T27_H", scriptG)

  try
    Xpath 'A'
    exec "source" scriptH
    Xpath 'B'
  finally
    Xpath 'C'
  endtry
  Xpath 'D'
  call assert_equal('AifgabcehjkBCD', g:Xpath)
  call delete(scriptF)
  call delete(scriptG)
  call delete(scriptH)
endfunc

"-------------------------------------------------------------------------------
" Test 29:  Executing :finally clauses on errors			    {{{1
"
"	    After an error in a command dynamically enclosed in a :try/:endtry
"	    region, :finally clauses are executed and the script processing is
"	    terminated.
"-------------------------------------------------------------------------------

func Test_finally_after_error_1()
  let test =<< trim [CODE]
    func F()
      while 1
        try
          Xpath 'a'
          while 1
            try
              Xpath 'b'
              asdf	    " error
              call assert_report('should not get here')
            finally
              Xpath 'c'
            endtry | call assert_report('should not get here')
            call assert_report('should not get here')
            break
          endwhile
          call assert_report('should not get here')
        finally
          Xpath 'd'
        endtry | call assert_report('should not get here')
        call assert_report('should not get here')
        break
      endwhile
      call assert_report('should not get here')
    endfunc

    while 1
      try
        Xpath 'e'
        while 1
          call F()
          call assert_report('should not get here')
          break
        endwhile  | call assert_report('should not get here')
        call assert_report('should not get here')
      finally
        Xpath 'f'
      endtry | call assert_report('should not get here')
    endwhile | call assert_report('should not get here')
    call assert_report('should not get here')
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('eabcdf', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

func Test_finally_after_error_2()
  let test =<< trim [CODE]
    func G() abort
      if 1
        try
          Xpath 'a'
          asdf	    " error
          call assert_report('should not get here')
        finally
          Xpath 'b'
        endtry | Xpath 'c'
      endif | Xpath 'd'
      call assert_report('should not get here')
    endfunc

    if 1
      try
        Xpath 'e'
        call G()
        call assert_report('should not get here')
      finally
        Xpath 'f'
      endtry | call assert_report('should not get here')
    endif | call assert_report('should not get here')
    call assert_report('should not get here')
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('eabf', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

"-------------------------------------------------------------------------------
" Test 30:  Executing :finally clauses on interrupt			    {{{1
"
"	    After an interrupt in a command dynamically enclosed in
"	    a :try/:endtry region, :finally clauses are executed and the
"	    script processing is terminated.
"-------------------------------------------------------------------------------

func Test_finally_on_interrupt()
  let test =<< trim [CODE]
    func F()
      try
        Xloop 'a'
        call interrupt()
        call assert_report('should not get here')
      finally
        Xloop 'b'
      endtry
      call assert_report('should not get here')
    endfunc

    try
      try
        Xpath 'c'
        try
          Xpath 'd'
          call interrupt()
          call assert_report('should not get here')
        finally
          Xpath 'e'
          try
            Xpath 'f'
            try
              Xpath 'g'
            finally
              Xpath 'h'
              try
                Xpath 'i'
                call interrupt()
                call assert_report('should not get here')
              endtry
              call assert_report('should not get here')
            endtry
            call assert_report('should not get here')
          endtry
          call assert_report('should not get here')
        endtry
        call assert_report('should not get here')
      finally
        Xpath 'j'
        try
          Xpath 'k'
          call F()
          call assert_report('should not get here')
        finally
          Xpath 'l'
          try
            Xpath 'm'
            XloopNEXT
            ExecAsScript F
            call assert_report('should not get here')
          finally
            Xpath 'n'
          endtry
          call assert_report('should not get here')
        endtry
        call assert_report('should not get here')
      endtry
      call assert_report('should not get here')
    catch /^Vim:Interrupt$/
      Xpath 'o'
    endtry
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('cdefghijka1b1lma2b2no', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

"-------------------------------------------------------------------------------
" Test 31:  Executing :finally clauses after :throw			    {{{1
"
"	    After a :throw dynamically enclosed in a :try/:endtry region,
"	    :finally clauses are executed and the script processing is
"	    terminated.
"-------------------------------------------------------------------------------

func Test_finally_after_throw_2()
  let test =<< trim [CODE]
    func F()
      try
        Xloop 'a'
        throw "exception"
        call assert_report('should not get here')
      finally
        Xloop 'b'
      endtry
      call assert_report('should not get here')
    endfunc

    try
      Xpath 'c'
      try
        Xpath 'd'
        throw "exception"
        call assert_report('should not get here')
      finally
        Xpath 'e'
        try
          Xpath 'f'
          try
            Xpath 'g'
          finally
            Xpath 'h'
            try
              Xpath 'i'
              throw "exception"
              call assert_report('should not get here')
            endtry
            call assert_report('should not get here')
          endtry
          call assert_report('should not get here')
        endtry
        call assert_report('should not get here')
      endtry
      call assert_report('should not get here')
    finally
      Xpath 'j'
      try
        Xpath 'k'
        call F()
        call assert_report('should not get here')
      finally
        Xpath 'l'
        try
          Xpath 'm'
          XloopNEXT
          ExecAsScript F
          call assert_report('should not get here')
        finally
          Xpath 'n'
        endtry
        call assert_report('should not get here')
      endtry
      call assert_report('should not get here')
    endtry
    call assert_report('should not get here')
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('cdefghijka1b1lma2b2n', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

"-------------------------------------------------------------------------------
" Test 34:  :finally reason discarded by :continue			    {{{1
"
"	    When a :finally clause is executed due to a :continue, :break,
"	    :return, :finish, error, interrupt or :throw, the jump reason is
"	    discarded by a :continue in the finally clause.
"-------------------------------------------------------------------------------

func Test_finally_after_continue()
  let test =<< trim [CODE]
    func C(jump)
      XloopNEXT
      let loop = 0
      while loop < 2
        let loop = loop + 1
        if loop == 1
          try
            if a:jump == "continue"
              continue
            elseif a:jump == "break"
              break
            elseif a:jump == "return" || a:jump == "finish"
              return
            elseif a:jump == "error"
              asdf
            elseif a:jump == "interrupt"
              call interrupt()
              let dummy = 0
            elseif a:jump == "throw"
              throw "abc"
            endif
          finally
            continue	" discards jump that caused the :finally
            call assert_report('should not get here')
          endtry
          call assert_report('should not get here')
        elseif loop == 2
          Xloop 'a'
        endif
      endwhile
    endfunc

    call C("continue")
    Xpath 'b'
    call C("break")
    Xpath 'c'
    call C("return")
    Xpath 'd'
    let g:jump = "finish"
    ExecAsScript C
    unlet g:jump
    Xpath 'e'
    try
      call C("error")
      Xpath 'f'
    finally
      Xpath 'g'
      try
        call C("interrupt")
        Xpath 'h'
      finally
        Xpath 'i'
        call C("throw")
        Xpath 'j'
      endtry
    endtry
    Xpath 'k'
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('a2ba3ca4da5ea6fga7hia8jk', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

"-------------------------------------------------------------------------------
" Test 35:  :finally reason discarded by :break				    {{{1
"
"	    When a :finally clause is executed due to a :continue, :break,
"	    :return, :finish, error, interrupt or :throw, the jump reason is
"	    discarded by a :break in the finally clause.
"-------------------------------------------------------------------------------

func Test_finally_discard_by_break()
  let test =<< trim [CODE]
    func B(jump)
      XloopNEXT
      let loop = 0
      while loop < 2
        let loop = loop + 1
        if loop == 1
          try
            if a:jump == "continue"
              continue
            elseif a:jump == "break"
              break
            elseif a:jump == "return" || a:jump == "finish"
              return
            elseif a:jump == "error"
              asdf
            elseif a:jump == "interrupt"
              call interrupt()
              let dummy = 0
            elseif a:jump == "throw"
              throw "abc"
            endif
          finally
            break	" discards jump that caused the :finally
            call assert_report('should not get here')
          endtry
        elseif loop == 2
          call assert_report('should not get here')
        endif
      endwhile
      Xloop 'a'
    endfunc

    call B("continue")
    Xpath 'b'
    call B("break")
    Xpath 'c'
    call B("return")
    Xpath 'd'
    let g:jump = "finish"
    ExecAsScript B
    unlet g:jump
    Xpath 'e'
    try
      call B("error")
      Xpath 'f'
    finally
      Xpath 'g'
      try
        call B("interrupt")
        Xpath 'h'
      finally
        Xpath 'i'
        call B("throw")
        Xpath 'j'
      endtry
    endtry
    Xpath 'k'
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('a2ba3ca4da5ea6fga7hia8jk', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

"-------------------------------------------------------------------------------
" Test 36:  :finally reason discarded by :return			    {{{1
"
"	    When a :finally clause is executed due to a :continue, :break,
"	    :return, :finish, error, interrupt or :throw, the jump reason is
"	    discarded by a :return in the finally clause.
"-------------------------------------------------------------------------------

func Test_finally_discard_by_return()
  let test =<< trim [CODE]
    func R(jump, retval) abort
      let loop = 0
      while loop < 2
        let loop = loop + 1
        if loop == 1
          try
            if a:jump == "continue"
              continue
            elseif a:jump == "break"
              break
            elseif a:jump == "return"
              return
            elseif a:jump == "error"
              asdf
            elseif a:jump == "interrupt"
              call interrupt()
              let dummy = 0
            elseif a:jump == "throw"
              throw "abc"
            endif
          finally
            return a:retval	" discards jump that caused the :finally
            call assert_report('should not get here')
          endtry
        elseif loop == 2
          call assert_report('should not get here')
        endif
      endwhile
      call assert_report('should not get here')
    endfunc

    let sum =  -R("continue", -8)
    Xpath 'a'
    let sum = sum - R("break", -16)
    Xpath 'b'
    let sum = sum - R("return", -32)
    Xpath 'c'
    try
      let sum = sum - R("error", -64)
      Xpath 'd'
    finally
      Xpath 'e'
      try
        let sum = sum - R("interrupt", -128)
        Xpath 'f'
      finally
        Xpath 'g'
        let sum = sum - R("throw", -256)
        Xpath 'h'
      endtry
    endtry
    Xpath 'i'

    let expected = 8 + 16 + 32 + 64 + 128 + 256
    call assert_equal(sum, expected)
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('abcdefghi', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

"-------------------------------------------------------------------------------
" Test 37:  :finally reason discarded by :finish			    {{{1
"
"	    When a :finally clause is executed due to a :continue, :break,
"	    :return, :finish, error, interrupt or :throw, the jump reason is
"	    discarded by a :finish in the finally clause.
"-------------------------------------------------------------------------------

func Test_finally_discard_by_finish()
  let test =<< trim [CODE]
    func F(jump)	" not executed as function, transformed to a script
      let loop = 0
      while loop < 2
        let loop = loop + 1
        if loop == 1
          try
            if a:jump == "continue"
              continue
            elseif a:jump == "break"
              break
            elseif a:jump == "finish"
              finish
            elseif a:jump == "error"
              asdf
            elseif a:jump == "interrupt"
              call interrupt()
              let dummy = 0
            elseif a:jump == "throw"
              throw "abc"
            endif
          finally
            finish	" discards jump that caused the :finally
            call assert_report('should not get here')
          endtry
        elseif loop == 2
          call assert_report('should not get here')
        endif
      endwhile
      call assert_report('should not get here')
    endfunc

    let scriptF = MakeScript("F")
    delfunction F

    let g:jump = "continue"
    exec "source" scriptF
    Xpath 'a'
    let g:jump = "break"
    exec "source" scriptF
    Xpath 'b'
    let g:jump = "finish"
    exec "source" scriptF
    Xpath 'c'
    try
      let g:jump = "error"
      exec "source" scriptF
      Xpath 'd'
    finally
      Xpath 'e'
      try
        let g:jump = "interrupt"
        exec "source" scriptF
        Xpath 'f'
      finally
        Xpath 'g'
        try
          let g:jump = "throw"
          exec "source" scriptF
          Xpath 'h'
        finally
          Xpath 'i'
        endtry
      endtry
    endtry
    unlet g:jump
    call delete(scriptF)
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('abcdefghi', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

"-------------------------------------------------------------------------------
" Test 38:  :finally reason discarded by an error			    {{{1
"
"	    When a :finally clause is executed due to a :continue, :break,
"	    :return, :finish, error, interrupt or :throw, the jump reason is
"	    discarded by an error in the finally clause.
"-------------------------------------------------------------------------------

func Test_finally_discard_by_error()
  let test =<< trim [CODE]
    func E(jump)
      let loop = 0
      while loop < 2
        let loop = loop + 1
        if loop == 1
          try
            if a:jump == "continue"
              continue
            elseif a:jump == "break"
              break
            elseif a:jump == "return" || a:jump == "finish"
              return
            elseif a:jump == "error"
              asdf
            elseif a:jump == "interrupt"
              call interrupt()
              let dummy = 0
            elseif a:jump == "throw"
              throw "abc"
            endif
          finally
            asdf	" error; discards jump that caused the :finally
          endtry
        elseif loop == 2
          call assert_report('should not get here')
        endif
      endwhile
      call assert_report('should not get here')
    endfunc

    try
      Xpath 'a'
      call E("continue")
      call assert_report('should not get here')
    finally
      try
        Xpath 'b'
        call E("break")
        call assert_report('should not get here')
      finally
        try
          Xpath 'c'
          call E("return")
          call assert_report('should not get here')
        finally
          try
            Xpath 'd'
            let g:jump = "finish"
            ExecAsScript E
            call assert_report('should not get here')
          finally
            unlet g:jump
            try
              Xpath 'e'
              call E("error")
              call assert_report('should not get here')
            finally
              try
                Xpath 'f'
                call E("interrupt")
                call assert_report('should not get here')
              finally
                try
                  Xpath 'g'
                  call E("throw")
                  call assert_report('should not get here')
                finally
                  Xpath 'h'
                  delfunction E
                endtry
              endtry
            endtry
          endtry
        endtry
      endtry
    endtry
    call assert_report('should not get here')
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('abcdefgh', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

"-------------------------------------------------------------------------------
" Test 39:  :finally reason discarded by an interrupt			    {{{1
"
"	    When a :finally clause is executed due to a :continue, :break,
"	    :return, :finish, error, interrupt or :throw, the jump reason is
"	    discarded by an interrupt in the finally clause.
"-------------------------------------------------------------------------------

func Test_finally_discarded_by_interrupt()
  let test =<< trim [CODE]
    func I(jump)
      let loop = 0
      while loop < 2
        let loop = loop + 1
        if loop == 1
          try
            if a:jump == "continue"
              continue
            elseif a:jump == "break"
              break
            elseif a:jump == "return" || a:jump == "finish"
              return
            elseif a:jump == "error"
              asdf
            elseif a:jump == "interrupt"
              call interrupt()
              let dummy = 0
            elseif a:jump == "throw"
              throw "abc"
            endif
          finally
            call interrupt()
            let dummy = 0
          endtry
        elseif loop == 2
          call assert_report('should not get here')
        endif
      endwhile
      call assert_report('should not get here')
    endfunc

    try
      try
        Xpath 'a'
        call I("continue")
        call assert_report('should not get here')
      finally
        try
          Xpath 'b'
          call I("break")
          call assert_report('should not get here')
        finally
          try
            Xpath 'c'
            call I("return")
            call assert_report('should not get here')
          finally
            try
              Xpath 'd'
              let g:jump = "finish"
              ExecAsScript I
              call assert_report('should not get here')
            finally
              unlet g:jump
              try
                Xpath 'e'
                call I("error")
                call assert_report('should not get here')
              finally
                try
                  Xpath 'f'
                  call I("interrupt")
                  call assert_report('should not get here')
                finally
                  try
                    Xpath 'g'
                    call I("throw")
                    call assert_report('should not get here')
                  finally
                    Xpath 'h'
                    delfunction I
                  endtry
                endtry
              endtry
            endtry
          endtry
        endtry
      endtry
      call assert_report('should not get here')
    catch /^Vim:Interrupt$/
      Xpath 'A'
    endtry
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('abcdefghA', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

"-------------------------------------------------------------------------------
" Test 40:  :finally reason discarded by :throw				    {{{1
"
"	    When a :finally clause is executed due to a :continue, :break,
"	    :return, :finish, error, interrupt or :throw, the jump reason is
"	    discarded by a :throw in the finally clause.
"-------------------------------------------------------------------------------

func Test_finally_discard_by_throw()
  let test =<< trim [CODE]
    func T(jump)
      let loop = 0
      while loop < 2
        let loop = loop + 1
        if loop == 1
          try
            if a:jump == "continue"
              continue
            elseif a:jump == "break"
              break
            elseif a:jump == "return" || a:jump == "finish"
              return
            elseif a:jump == "error"
              asdf
            elseif a:jump == "interrupt"
              call interrupt()
              let dummy = 0
            elseif a:jump == "throw"
              throw "abc"
            endif
          finally
            throw "xyz"	" discards jump that caused the :finally
          endtry
        elseif loop == 2
          call assert_report('should not get here')
        endif
      endwhile
      call assert_report('should not get here')
    endfunc

    try
      Xpath 'a'
      call T("continue")
      call assert_report('should not get here')
    finally
      try
        Xpath 'b'
        call T("break")
        call assert_report('should not get here')
      finally
        try
          Xpath 'c'
          call T("return")
          call assert_report('should not get here')
        finally
          try
            Xpath 'd'
            let g:jump = "finish"
            ExecAsScript T
            call assert_report('should not get here')
          finally
            unlet g:jump
            try
              Xpath 'e'
              call T("error")
              call assert_report('should not get here')
            finally
              try
                Xpath 'f'
                call T("interrupt")
                call assert_report('should not get here')
              finally
                try
                  Xpath 'g'
                  call T("throw")
                  call assert_report('should not get here')
                finally
                  Xpath 'h'
                  delfunction T
                endtry
              endtry
            endtry
          endtry
        endtry
      endtry
    endtry
    call assert_report('should not get here')
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('abcdefgh', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

"-------------------------------------------------------------------------------
" Test 49:  Throwing exceptions across functions			    {{{1
"
"	    When an exception is thrown but not caught inside a function, the
"	    caller is checked for a matching :catch clause.
"-------------------------------------------------------------------------------

func T49_C()
  try
    Xpath 'a'
    throw "arrgh"
    call assert_report('should not get here')
  catch /arrgh/
    Xpath 'b'
  endtry
  Xpath 'c'
endfunc

func T49_T1()
  XloopNEXT
  try
    Xloop 'd'
    throw "arrgh"
    call assert_report('should not get here')
  finally
    Xloop 'e'
  endtry
  Xloop 'f'
endfunc

func T49_T2()
  try
    Xpath 'g'
    call T49_T1()
    call assert_report('should not get here')
  finally
    Xpath 'h'
  endtry
  call assert_report('should not get here')
endfunc

func Test_throw_exception_across_funcs()
  XpathINIT
  XloopINIT
  try
    Xpath 'i'
    call T49_C()            " throw and catch
    Xpath 'j'
  catch /.*/
    call assert_report('should not get here')
  endtry

  try
    Xpath 'k'
    call T49_T1()  " throw, one level
    call assert_report('should not get here')
  catch /arrgh/
    Xpath 'l'
  catch /.*/
    call assert_report('should not get here')
  endtry

  try
    Xpath 'm'
    call T49_T2()	" throw, two levels
    call assert_report('should not get here')
  catch /arrgh/
    Xpath 'n'
  catch /.*/
    call assert_report('should not get here')
  endtry
  Xpath 'o'

  call assert_equal('iabcjkd2e2lmgd3e3hno', g:Xpath)
endfunc

"-------------------------------------------------------------------------------
" Test 50:  Throwing exceptions across script files			    {{{1
"
"	    When an exception is thrown but not caught inside a script file,
"	    the sourcing script or function is checked for a matching :catch
"	    clause.
"
"	    This test executes the bodies of the functions C, T1, and T2 from
"	    the previous test as script files (:return replaced by :finish).
"-------------------------------------------------------------------------------

func T50_F()
  try
    Xpath 'A'
    exec "source" g:scriptC
    Xpath 'B'
  catch /.*/
    call assert_report('should not get here')
  endtry

  try
    Xpath 'C'
    exec "source" g:scriptT1
    call assert_report('should not get here')
  catch /arrgh/
    Xpath 'D'
  catch /.*/
    call assert_report('should not get here')
  endtry
endfunc

func Test_throw_across_script()
  XpathINIT
  XloopINIT
  let g:scriptC = MakeScript("T49_C")
  let g:scriptT1 = MakeScript("T49_T1")
  let scriptT2 = MakeScript("T49_T2", g:scriptT1)

  try
    Xpath 'E'
    call T50_F()
    Xpath 'F'
    exec "source" scriptT2
    call assert_report('should not get here')
  catch /arrgh/
    Xpath 'G'
  catch /.*/
    call assert_report('should not get here')
  endtry
  Xpath 'H'
  call assert_equal('EAabcBCd2e2DFgd3e3hGH', g:Xpath)

  call delete(g:scriptC)
  call delete(g:scriptT1)
  call delete(scriptT2)
  unlet g:scriptC g:scriptT1 scriptT2
endfunc

"-------------------------------------------------------------------------------
" Test 52:  Uncaught exceptions						    {{{1
"
"	    When an exception is thrown but not caught, an error message is
"	    displayed when the script is terminated.  In case of an interrupt
"	    or error exception, the normal interrupt or error message(s) are
"	    displayed.
"-------------------------------------------------------------------------------

func Test_uncaught_exception_1()
  CheckEnglish

  let test =<< trim [CODE]
    Xpath 'a'
    throw "arrgh"
    call assert_report('should not get here')`
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('E605: Exception not caught: arrgh', v:errmsg)
    call assert_equal('a', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

func Test_uncaught_exception_2()
  CheckEnglish

  let test =<< trim [CODE]
    try
      Xpath 'a'
      throw "oops"
      call assert_report('should not get here')`
    catch /arrgh/
      call assert_report('should not get here')`
    endtry
    call assert_report('should not get here')`
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('E605: Exception not caught: oops', v:errmsg)
    call assert_equal('a', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

func Test_uncaught_exception_3()
  CheckEnglish

  let test =<< trim [CODE]
    func T()
      Xpath 'c'
      throw "brrr"
      call assert_report('should not get here')`
    endfunc

    try
      Xpath 'a'
      throw "arrgh"
      call assert_report('should not get here')`
    catch /.*/
      Xpath 'b'
      call T()
      call assert_report('should not get here')`
    endtry
    call assert_report('should not get here')`
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('E605: Exception not caught: brrr', v:errmsg)
    call assert_equal('abc', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

func Test_uncaught_exception_4()
  CheckEnglish

  let test =<< trim [CODE]
    try
      Xpath 'a'
      throw "arrgh"
      call assert_report('should not get here')`
    finally
      Xpath 'b'
      throw "brrr"
      call assert_report('should not get here')`
    endtry
    call assert_report('should not get here')`
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('E605: Exception not caught: brrr', v:errmsg)
    call assert_equal('ab', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

func Test_uncaught_exception_5()
  CheckEnglish

  " Need to catch and handle interrupt, otherwise the test will wait for the
  " user to press <Enter> to continue
  let test =<< trim [CODE]
    try
      try
        Xpath 'a'
        call interrupt()
        call assert_report('should not get here')
      endtry
      call assert_report('should not get here')
    catch /^Vim:Interrupt$/
      Xpath 'b'
    endtry
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('ab', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

func Test_uncaught_exception_6()
  CheckEnglish

  let test =<< trim [CODE]
    try
      Xpath 'a'
      let x = novar	" error E121; exception: E121
    catch /E15:/	" should not catch
      call assert_report('should not get here')
    endtry
    call assert_report('should not get here')
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('a', g:Xpath)
    call assert_equal('E121: Undefined variable: novar', v:errmsg)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

func Test_uncaught_exception_7()
  CheckEnglish

  let test =<< trim [CODE]
    try
      Xpath 'a'
      " error E108/E488; exception: E488
      unlet novar #
    catch /E108:/       " should not catch
      call assert_report('should not get here')
    endtry
    call assert_report('should not get here')
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('a', g:Xpath)
    call assert_equal('E488: Trailing characters: #', v:errmsg)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

"-------------------------------------------------------------------------------
" Test 53:  Nesting errors: :endif/:else/:elseif			    {{{1
"
"	    For nesting errors of :if conditionals the correct error messages
"	    should be given.
"-------------------------------------------------------------------------------

func Test_nested_if_else_errors()
  CheckEnglish

  " :endif without :if
  let code =<< trim END
    endif
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(endif):E580: :endif without :if')

  " :endif without :if
  let code =<< trim END
    while 1
      endif
    endwhile
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(endif):E580: :endif without :if')

  " :endif without :if
  let code =<< trim END
    try
    finally
      endif
    endtry
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(endif):E580: :endif without :if')

  " :endif without :if
  let code =<< trim END
    try
      endif
    endtry
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(endif):E580: :endif without :if')

  " :endif without :if
  let code =<< trim END
    try
      throw "a"
    catch /a/
      endif
    endtry
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(endif):E580: :endif without :if')

  " :else without :if
  let code =<< trim END
    else
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(else):E581: :else without :if')

  " :else without :if
  let code =<< trim END
    while 1
      else
    endwhile
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(else):E581: :else without :if')

  " :else without :if
  let code =<< trim END
    try
    finally
      else
    endtry
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(else):E581: :else without :if')

  " :else without :if
  let code =<< trim END
    try
      else
    endtry
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(else):E581: :else without :if')

  " :else without :if
  let code =<< trim END
    try
      throw "a"
    catch /a/
      else
    endtry
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(else):E581: :else without :if')

  " :elseif without :if
  let code =<< trim END
    elseif
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(elseif):E582: :elseif without :if')

  " :elseif without :if
  let code =<< trim END
    while 1
      elseif
    endwhile
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(elseif):E582: :elseif without :if')

  " :elseif without :if
  let code =<< trim END
    try
    finally
      elseif
    endtry
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(elseif):E582: :elseif without :if')

  " :elseif without :if
  let code =<< trim END
    try
      elseif
    endtry
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(elseif):E582: :elseif without :if')

  " :elseif without :if
  let code =<< trim END
    try
      throw "a"
    catch /a/
      elseif
    endtry
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(elseif):E582: :elseif without :if')

  " multiple :else
  let code =<< trim END
    if 1
    else
    else
    endif
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(else):E583: multiple :else')

  " :elseif after :else
  let code =<< trim END
    if 1
    else
    elseif 1
    endif
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(elseif):E584: :elseif after :else')

  call delete('Xtest')
endfunc

"-------------------------------------------------------------------------------
" Test 54:  Nesting errors: :while/:endwhile				    {{{1
"
"	    For nesting errors of :while conditionals the correct error messages
"	    should be given.
"
"	    This test reuses the function MESSAGES() from the previous test.
"	    This functions checks the messages in g:msgfile.
"-------------------------------------------------------------------------------

func Test_nested_while_error()
  CheckEnglish

  " :endwhile without :while
  let code =<< trim END
    endwhile
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(endwhile):E588: :endwhile without :while')

  " :endwhile without :while
  let code =<< trim END
    if 1
      endwhile
    endif
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(endwhile):E588: :endwhile without :while')

  " Missing :endif
  let code =<< trim END
    while 1
      if 1
    endwhile
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(endwhile):E171: Missing :endif')

  " :endwhile without :while
  let code =<< trim END
    try
    finally
      endwhile
    endtry
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(endwhile):E588: :endwhile without :while')

  " Missing :endtry
  let code =<< trim END
    while 1
      try
      finally
    endwhile
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(endwhile):E600: Missing :endtry')

  " Missing :endtry
  let code =<< trim END
    while 1
      if 1
        try
        finally
    endwhile
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(endwhile):E600: Missing :endtry')

  " Missing :endif
  let code =<< trim END
    while 1
      try
      finally
        if 1
    endwhile
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(endwhile):E171: Missing :endif')

  " :endwhile without :while
  let code =<< trim END
    try
      endwhile
    endtry
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(endwhile):E588: :endwhile without :while')

  " :endwhile without :while
  let code =<< trim END
    while 1
      try
        endwhile
      endtry
    endwhile
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(endwhile):E588: :endwhile without :while')

  " :endwhile without :while
  let code =<< trim END
    try
      throw "a"
    catch /a/
      endwhile
    endtry
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(endwhile):E588: :endwhile without :while')

  " :endwhile without :while
  let code =<< trim END
    while 1
      try
        throw "a"
      catch /a/
        endwhile
      endtry
    endwhile
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(endwhile):E588: :endwhile without :while')

  call delete('Xtest')
endfunc

"-------------------------------------------------------------------------------
" Test 55:  Nesting errors: :continue/:break				    {{{1
"
"	    For nesting errors of :continue and :break commands the correct
"	    error messages should be given.
"
"	    This test reuses the function MESSAGES() from the previous test.
"	    This functions checks the messages in g:msgfile.
"-------------------------------------------------------------------------------

func Test_nested_cont_break_error()
  CheckEnglish

  " :continue without :while
  let code =<< trim END
    continue
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(continue):E586: :continue without :while or :for')

  " :continue without :while
  let code =<< trim END
    if 1
      continue
    endif
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(continue):E586: :continue without :while or :for')

  " :continue without :while
  let code =<< trim END
    try
    finally
      continue
    endtry
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(continue):E586: :continue without :while or :for')

  " :continue without :while
  let code =<< trim END
    try
      continue
    endtry
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(continue):E586: :continue without :while or :for')

  " :continue without :while
  let code =<< trim END
    try
      throw "a"
    catch /a/
      continue
    endtry
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(continue):E586: :continue without :while or :for')

  " :break without :while
  let code =<< trim END
    break
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(break):E587: :break without :while or :for')

  " :break without :while
  let code =<< trim END
    if 1
      break
    endif
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(break):E587: :break without :while or :for')

  " :break without :while
  let code =<< trim END
    try
    finally
      break
    endtry
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(break):E587: :break without :while or :for')

  " :break without :while
  let code =<< trim END
    try
      break
    endtry
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(break):E587: :break without :while or :for')

  " :break without :while
  let code =<< trim END
    try
      throw "a"
    catch /a/
      break
    endtry
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(break):E587: :break without :while or :for')

  call delete('Xtest')
endfunc

"-------------------------------------------------------------------------------
" Test 56:  Nesting errors: :endtry					    {{{1
"
"	    For nesting errors of :try conditionals the correct error messages
"	    should be given.
"
"	    This test reuses the function MESSAGES() from the previous test.
"	    This functions checks the messages in g:msgfile.
"-------------------------------------------------------------------------------

func Test_nested_endtry_error()
  CheckEnglish

  " :endtry without :try
  let code =<< trim END
    endtry
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(endtry):E602: :endtry without :try')

  " :endtry without :try
  let code =<< trim END
    if 1
      endtry
    endif
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(endtry):E602: :endtry without :try')

  " :endtry without :try
  let code =<< trim END
    while 1
      endtry
    endwhile
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(endtry):E602: :endtry without :try')

  " Missing :endif
  let code =<< trim END
    try
        if 1
    endtry
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(endtry):E171: Missing :endif')

  " Missing :endwhile
  let code =<< trim END
    try
      while 1
    endtry
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(endtry):E170: Missing :endwhile')

  " Missing :endif
  let code =<< trim END
    try
    finally
      if 1
    endtry
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(endtry):E171: Missing :endif')

  " Missing :endwhile
  let code =<< trim END
    try
    finally
      while 1
    endtry
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(endtry):E170: Missing :endwhile')

  " Missing :endif
  let code =<< trim END
    try
      throw "a"
    catch /a/
      if 1
    endtry
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(endtry):E171: Missing :endif')

  " Missing :endwhile
  let code =<< trim END
    try
      throw "a"
    catch /a/
      while 1
    endtry
  END
  call writefile(code, 'Xtest')
  call AssertException(['source Xtest'], 'Vim(endtry):E170: Missing :endwhile')

  call delete('Xtest')
endfunc

"-------------------------------------------------------------------------------
" Test 57:  v:exception and v:throwpoint for user exceptions		    {{{1
"
"	    v:exception evaluates to the value of the exception that was caught
"	    most recently and is not finished.  (A caught exception is finished
"	    when the next ":catch", ":finally", or ":endtry" is reached.)
"	    v:throwpoint evaluates to the script/function name and line number
"	    where that exception has been thrown.
"-------------------------------------------------------------------------------

func Test_user_exception_info()
  CheckEnglish

  XpathINIT
  XloopINIT

  func FuncException()
    let g:exception = v:exception
  endfunc

  func FuncThrowpoint()
    let g:throwpoint = v:throwpoint
  endfunc

  let scriptException  = MakeScript("FuncException")
  let scriptThrowPoint = MakeScript("FuncThrowpoint")

  command! CmdException  let g:exception  = v:exception
  command! CmdThrowpoint let g:throwpoint = v:throwpoint

  func T(arg, line)
    if a:line == 2
      throw a:arg		" in line 2
    elseif a:line == 4
      throw a:arg		" in line 4
    elseif a:line == 6
      throw a:arg		" in line 6
    elseif a:line == 8
      throw a:arg		" in line 8
    endif
  endfunc

  func G(arg, line)
    call T(a:arg, a:line)
  endfunc

  func F(arg, line)
    call G(a:arg, a:line)
  endfunc

  let scriptT = MakeScript("T")
  let scriptG = MakeScript("G", scriptT)
  let scriptF = MakeScript("F", scriptG)

  try
    Xpath 'a'
    call F("oops", 2)
  catch /.*/
    Xpath 'b'
    let exception  = v:exception
    let throwpoint = v:throwpoint
    call assert_equal("oops", v:exception)
    call assert_match('\<F\[1]\.\.G\[1]\.\.T\>', v:throwpoint)
    call assert_match('\<2\>', v:throwpoint)

    exec "let exception  = v:exception"
    exec "let throwpoint = v:throwpoint"
    call assert_equal("oops", v:exception)
    call assert_match('\<F\[1]\.\.G\[1]\.\.T\>', v:throwpoint)
    call assert_match('\<2\>', v:throwpoint)

    CmdException
    CmdThrowpoint
    call assert_equal("oops", v:exception)
    call assert_match('\<F\[1]\.\.G\[1]\.\.T\>', v:throwpoint)
    call assert_match('\<2\>', v:throwpoint)

    call FuncException()
    call FuncThrowpoint()
    call assert_equal("oops", v:exception)
    call assert_match('\<F\[1]\.\.G\[1]\.\.T\>', v:throwpoint)
    call assert_match('\<2\>', v:throwpoint)

    exec "source" scriptException
    exec "source" scriptThrowPoint
    call assert_equal("oops", v:exception)
    call assert_match('\<F\[1]\.\.G\[1]\.\.T\>', v:throwpoint)
    call assert_match('\<2\>', v:throwpoint)

    try
      Xpath 'c'
      call G("arrgh", 4)
    catch /.*/
      Xpath 'd'
      let exception  = v:exception
      let throwpoint = v:throwpoint
      call assert_equal("arrgh", v:exception)
      call assert_match('\<G\[1]\.\.T\>', v:throwpoint)
      call assert_match('\<4\>', v:throwpoint)

      try
        Xpath 'e'
        let g:arg = "autsch"
        let g:line = 6
        exec "source" scriptF
      catch /.*/
        Xpath 'f'
        let exception  = v:exception
        let throwpoint = v:throwpoint
        call assert_equal("autsch", v:exception)
        call assert_match(fnamemodify(scriptT, ':t'), v:throwpoint)
        call assert_match('\<6\>', v:throwpoint)
      finally
        Xpath 'g'
        let exception  = v:exception
        let throwpoint = v:throwpoint
        call assert_equal("arrgh", v:exception)
        call assert_match('\<G\[1]\.\.T\>', v:throwpoint)
        call assert_match('\<4\>', v:throwpoint)
        try
          Xpath 'h'
          let g:arg = "brrrr"
          let g:line = 8
          exec "source" scriptG
        catch /.*/
          Xpath 'i'
          let exception  = v:exception
          let throwpoint = v:throwpoint
          " Resolve scriptT for matching it against v:throwpoint.
          call assert_equal("brrrr", v:exception)
          call assert_match(fnamemodify(scriptT, ':t'), v:throwpoint)
          call assert_match('\<8\>', v:throwpoint)
        finally
          Xpath 'j'
          let exception  = v:exception
          let throwpoint = v:throwpoint
          call assert_equal("arrgh", v:exception)
          call assert_match('\<G\[1]\.\.T\>', v:throwpoint)
          call assert_match('\<4\>', v:throwpoint)
        endtry
        Xpath 'k'
        let exception  = v:exception
        let throwpoint = v:throwpoint
        call assert_equal("arrgh", v:exception)
        call assert_match('\<G\[1]\.\.T\>', v:throwpoint)
        call assert_match('\<4\>', v:throwpoint)
      endtry
      Xpath 'l'
      let exception  = v:exception
      let throwpoint = v:throwpoint
      call assert_equal("arrgh", v:exception)
      call assert_match('\<G\[1]\.\.T\>', v:throwpoint)
      call assert_match('\<4\>', v:throwpoint)
    finally
      Xpath 'm'
      let exception  = v:exception
      let throwpoint = v:throwpoint
      call assert_equal("oops", v:exception)
      call assert_match('\<F\[1]\.\.G\[1]\.\.T\>', v:throwpoint)
      call assert_match('\<2\>', v:throwpoint)
    endtry
    Xpath 'n'
    let exception  = v:exception
    let throwpoint = v:throwpoint
    call assert_equal("oops", v:exception)
    call assert_match('\<F\[1]\.\.G\[1]\.\.T\>', v:throwpoint)
    call assert_match('\<2\>', v:throwpoint)
  finally
    Xpath 'o'
    let exception  = v:exception
    let throwpoint = v:throwpoint
    call assert_equal("", v:exception)
    call assert_match('^$', v:throwpoint)
    call assert_match('^$', v:throwpoint)
  endtry

  call assert_equal('abcdefghijklmno', g:Xpath)

  unlet exception throwpoint
  delfunction FuncException
  delfunction FuncThrowpoint
  call delete(scriptException)
  call delete(scriptThrowPoint)
  unlet scriptException scriptThrowPoint
  delcommand CmdException
  delcommand CmdThrowpoint
  delfunction T
  delfunction G
  delfunction F
  call delete(scriptT)
  call delete(scriptG)
  call delete(scriptF)
  unlet scriptT scriptG scriptF
endfunc

"-------------------------------------------------------------------------------
"
" Test 58:  v:exception and v:throwpoint for error/interrupt exceptions	    {{{1
"
"	    v:exception and v:throwpoint work also for error and interrupt
"	    exceptions.
"-------------------------------------------------------------------------------

func Test_execption_info_for_error()
  CheckEnglish

  let test =<< trim [CODE]
    func T(line)
      if a:line == 2
        delfunction T		" error (function in use) in line 2
      elseif a:line == 4
        call interrupt()
      endif
    endfunc

    while 1
      try
        Xpath 'a'
        call T(2)
        call assert_report('should not get here')
      catch /.*/
        Xpath 'b'
        if v:exception !~ 'Vim(delfunction):'
          call assert_report('should not get here')
        endif
        if v:throwpoint !~ '\<T\>'
          call assert_report('should not get here')
        endif
        if v:throwpoint !~ '\<2\>'
          call assert_report('should not get here')
        endif
      finally
        Xpath 'c'
        if v:exception != ""
          call assert_report('should not get here')
        endif
        if v:throwpoint != ""
          call assert_report('should not get here')
        endif
        break
      endtry
    endwhile

    Xpath 'd'
    if v:exception != ""
      call assert_report('should not get here')
    endif
    if v:throwpoint != ""
      call assert_report('should not get here')
    endif

    while 1
      try
        Xpath 'e'
        call T(4)
        call assert_report('should not get here')
      catch /.*/
        Xpath 'f'
        if v:exception != 'Vim:Interrupt'
          call assert_report('should not get here')
        endif
        if v:throwpoint !~ 'function T'
          call assert_report('should not get here')
        endif
        if v:throwpoint !~ '\<4\>'
          call assert_report('should not get here')
        endif
      finally
        Xpath 'g'
        if v:exception != ""
          call assert_report('should not get here')
        endif
        if v:throwpoint != ""
          call assert_report('should not get here')
        endif
        break
      endtry
    endwhile

    Xpath 'h'
    if v:exception != ""
      call assert_report('should not get here')
    endif
    if v:throwpoint != ""
      call assert_report('should not get here')
    endif
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('abcdefgh', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

"-------------------------------------------------------------------------------
" Test 61:  Catching interrupt exceptions				    {{{1
"
"	    When an interrupt occurs inside a :try/:endtry region, an
"	    interrupt exception is thrown and can be caught.  Its value is
"	    "Vim:Interrupt".  If the interrupt occurs after an error or a :throw
"	    but before a matching :catch is reached, all following :catches of
"	    that try block are ignored, but the interrupt exception can be
"	    caught by the next surrounding try conditional.  An interrupt is
"	    ignored when there is a previous interrupt that has not been caught
"	    or causes a :finally clause to be executed.
"-------------------------------------------------------------------------------

func Test_catch_intr_exception()
  let test =<< trim [CODE]
    while 1
      try
        try
          Xpath 'a'
          call interrupt()
          call assert_report('should not get here')
        catch /^Vim:Interrupt$/
          Xpath 'b'
        finally
          Xpath 'c'
        endtry
      catch /.*/
        call assert_report('should not get here')
      finally
        Xpath 'd'
        break
      endtry
    endwhile

    while 1
      try
        try
          try
            Xpath 'e'
            asdf
            call assert_report('should not get here')
          catch /do_not_catch/
            call assert_report('should not get here')
          catch /.*/
            Xpath 'f'
            call interrupt()
            call assert_report('should not get here')
          catch /.*/
            call assert_report('should not get here')
          finally
            Xpath 'g'
            call interrupt()
            call assert_report('should not get here')
          endtry
        catch /^Vim:Interrupt$/
          Xpath 'h'
        finally
          Xpath 'i'
        endtry
      catch /.*/
        call assert_report('should not get here')
      finally
        Xpath 'j'
        break
      endtry
    endwhile

    while 1
      try
        try
          try
            Xpath 'k'
            throw "x"
            call assert_report('should not get here')
          catch /do_not_catch/
            call assert_report('should not get here')
          catch /x/
            Xpath 'l'
            call interrupt()
            call assert_report('should not get here')
          catch /.*/
            call assert_report('should not get here')
          endtry
        catch /^Vim:Interrupt$/
          Xpath 'm'
        finally
          Xpath 'n'
        endtry
      catch /.*/
        call assert_report('should not get here')
      finally
        Xpath 'o'
        break
      endtry
    endwhile

    while 1
      try
        try
          Xpath 'p'
          call interrupt()
          call assert_report('should not get here')
        catch /do_not_catch/
          call interrupt()
          call assert_report('should not get here')
        catch /^Vim:Interrupt$/
          Xpath 'q'
        finally
          Xpath 'r'
        endtry
      catch /.*/
        call assert_report('should not get here')
      finally
        Xpath 's'
        break
      endtry
    endwhile

    Xpath 't'
  [CODE]
  let verify =<< trim [CODE]
    call assert_equal('abcdefghijklmnopqrst', g:Xpath)
  [CODE]
  call RunInNewVim(test, verify)
endfunc

"-------------------------------------------------------------------------------
" Test 65:  Errors in the /pattern/ argument of a :catch		    {{{1
"
"	    On an error in the /pattern/ argument of a :catch, the :catch does
"	    not match.  Any following :catches of the same :try/:endtry don't
"	    match either.  Finally clauses are executed.
"-------------------------------------------------------------------------------

func Test_catch_pattern_error()
  CheckEnglish
  XpathINIT

  try
    try
      Xpath 'a'
      throw "oops"
    catch /^oops$/
      Xpath 'b'
    catch /\)/		" not checked; exception has already been caught
      call assert_report('should not get here')
    endtry
    Xpath 'c'
  catch /.*/
    call assert_report('should not get here')
  endtry
  call assert_equal('abc', g:Xpath)

  XpathINIT
  func F()
    try
      try
        try
          Xpath 'a'
          throw "ab"
        catch /abc/	" does not catch
          call assert_report('should not get here')
        catch /\)/	" error; discards exception
          call assert_report('should not get here')
        catch /.*/	" not checked
          call assert_report('should not get here')
        finally
          Xpath 'b'
        endtry
        call assert_report('should not get here')
      catch /^ab$/	" checked, but original exception is discarded
        call assert_report('should not get here')
      catch /^Vim(catch):/
        Xpath 'c'
        call assert_match('Vim(catch):E475: Invalid argument:', v:exception)
      finally
        Xpath 'd'
      endtry
      Xpath 'e'
    catch /.*/
      call assert_report('should not get here')
    endtry
    Xpath 'f'
  endfunc

  call F()
  call assert_equal('abcdef', g:Xpath)

  delfunc F
endfunc

"-------------------------------------------------------------------------------
" Test 87   using (expr) ? funcref : funcref				    {{{1
"
"	    Vim needs to correctly parse the funcref and even when it does
"	    not execute the funcref, it needs to consume the trailing ()
"-------------------------------------------------------------------------------

func Add2(x1, x2)
  return a:x1 + a:x2
endfu

func GetStr()
  return "abcdefghijklmnopqrstuvwxyp"
endfu

func Test_funcref_with_condexpr()
  call assert_equal(5, function('Add2')(2,3))

  call assert_equal(3, 1 ? function('Add2')(1,2) : function('Add2')(2,3))
  call assert_equal(5, 0 ? function('Add2')(1,2) : function('Add2')(2,3))
  " Make sure, GetStr() still works.
  call assert_equal('abcdefghijk', GetStr()[0:10])
endfunc

" Test 90:  Recognizing {} in variable name.			    {{{1
"-------------------------------------------------------------------------------

func Test_curlies()
    let s:var = 66
    let ns = 's'
    call assert_equal(66, {ns}:var)

    let g:a = {}
    let g:b = 't'
    let g:a[g:b] = 77
    call assert_equal(77, g:a['t'])
endfunc

"-------------------------------------------------------------------------------
" Test 91:  using type().					    {{{1
"-------------------------------------------------------------------------------

func Test_type()
    call assert_equal(0, type(0))
    call assert_equal(1, type(""))
    call assert_equal(2, type(function("tr")))
    call assert_equal(2, type(function("tr", [8])))
    call assert_equal(3, type([]))
    call assert_equal(4, type({}))
    if has('float')
      call assert_equal(5, type(0.0))
    endif
    call assert_equal(6, type(v:false))
    call assert_equal(6, type(v:true))
    call assert_equal(7, type(v:none))
    call assert_equal(7, type(v:null))
    call assert_equal(8, v:t_job)
    call assert_equal(9, v:t_channel)
    call assert_equal(v:t_number, type(0))
    call assert_equal(v:t_string, type(""))
    call assert_equal(v:t_func, type(function("tr")))
    call assert_equal(v:t_func, type(function("tr", [8])))
    call assert_equal(v:t_list, type([]))
    call assert_equal(v:t_dict, type({}))
    if has('float')
      call assert_equal(v:t_float, type(0.0))
    endif
    call assert_equal(v:t_bool, type(v:false))
    call assert_equal(v:t_bool, type(v:true))
    call assert_equal(v:t_none, type(v:none))
    call assert_equal(v:t_none, type(v:null))
    call assert_equal(v:t_string, type(test_null_string()))
    call assert_equal(v:t_func, type(test_null_function()))
    call assert_equal(v:t_func, type(test_null_partial()))
    call assert_equal(v:t_list, type(test_null_list()))
    call assert_equal(v:t_dict, type(test_null_dict()))
    if has('job')
      call assert_equal(v:t_job, type(test_null_job()))
    endif
    if has('channel')
      call assert_equal(v:t_channel, type(test_null_channel()))
    endif
    call assert_equal(v:t_blob, type(test_null_blob()))

    call assert_fails("call type(test_void())", 'E685:')
    call assert_fails("call type(test_unknown())", 'E685:')

    call assert_equal(0, 0 + v:false)
    call assert_equal(1, 0 + v:true)
    call assert_equal(0, 0 + v:none)
    call assert_equal(0, 0 + v:null)

    call assert_equal('v:false', '' . v:false)
    call assert_equal('v:true', '' . v:true)
    call assert_equal('v:none', '' . v:none)
    call assert_equal('v:null', '' . v:null)

    call assert_true(v:false == 0)
    call assert_false(v:false != 0)
    call assert_true(v:true == 1)
    call assert_false(v:true != 1)
    call assert_false(v:true == v:false)
    call assert_true(v:true != v:false)

    call assert_true(v:null == 0)
    call assert_false(v:null != 0)
    call assert_true(v:none == 0)
    call assert_false(v:none != 0)

    call assert_true(!v:true is v:false)
    call assert_true(!v:false is v:true)

    call assert_true(v:false is v:false)
    call assert_true(v:true is v:true)
    call assert_true(v:none is v:none)
    call assert_true(v:null is v:null)

    call assert_false(v:false isnot v:false)
    call assert_false(v:true isnot v:true)
    call assert_false(v:none isnot v:none)
    call assert_false(v:null isnot v:null)

    call assert_false(v:false is 0)
    call assert_false(v:true is 1)
    call assert_false(v:true is v:false)
    call assert_false(v:none is 0)
    call assert_false(v:null is 0)
    call assert_false(v:null is v:none)

    call assert_true(v:false isnot 0)
    call assert_true(v:true isnot 1)
    call assert_true(v:true isnot v:false)
    call assert_true(v:none isnot 0)
    call assert_true(v:null isnot 0)
    call assert_true(v:null isnot v:none)

    call assert_equal(v:false, eval(string(v:false)))
    call assert_equal(v:true, eval(string(v:true)))
    call assert_equal(v:none, eval(string(v:none)))
    call assert_equal(v:null, eval(string(v:null)))

    call assert_equal(v:false, copy(v:false))
    call assert_equal(v:true, copy(v:true))
    call assert_equal(v:none, copy(v:none))
    call assert_equal(v:null, copy(v:null))

    call assert_equal([v:false], deepcopy([v:false]))
    call assert_equal([v:true], deepcopy([v:true]))
    call assert_equal([v:none], deepcopy([v:none]))
    call assert_equal([v:null], deepcopy([v:null]))

    call assert_true(empty(v:false))
    call assert_false(empty(v:true))
    call assert_true(empty(v:null))
    call assert_true(empty(v:none))

    func ChangeYourMind()
	try
	    return v:true
	finally
	    return 'something else'
	endtry
    endfunc

    call ChangeYourMind()
endfunc

"-------------------------------------------------------------------------------
" Test 92:  skipping code					    {{{1
"-------------------------------------------------------------------------------

func Test_skip()
    let Fn = function('Test_type')
    call assert_false(0 && Fn[1])
    call assert_false(0 && string(Fn))
    call assert_false(0 && len(Fn))
    let l = []
    call assert_false(0 && l[1])
    call assert_false(0 && string(l))
    call assert_false(0 && len(l))
    let f = 1.0
    call assert_false(0 && f[1])
    call assert_false(0 && string(f))
    call assert_false(0 && len(f))
    let sp = v:null
    call assert_false(0 && sp[1])
    call assert_false(0 && string(sp))
    call assert_false(0 && len(sp))

endfunc

"-------------------------------------------------------------------------------
" Test 93:  :echo and string()					    {{{1
"-------------------------------------------------------------------------------

func Test_echo_and_string()
    " String
    let a = 'foo bar'
    redir => result
    echo a
    echo string(a)
    redir END
    let l = split(result, "\n")
    call assert_equal(["foo bar",
		     \ "'foo bar'"], l)

    " Float
    if has('float')
	let a = -1.2e0
	redir => result
	echo a
	echo string(a)
	redir END
	let l = split(result, "\n")
	call assert_equal(["-1.2",
			 \ "-1.2"], l)
    endif

    " Funcref
    redir => result
    echo function('string')
    echo string(function('string'))
    redir END
    let l = split(result, "\n")
    call assert_equal(["string",
		     \ "function('string')"], l)

    " Recursive dictionary
    let a = {}
    let a["a"] = a
    redir => result
    echo a
    echo string(a)
    redir END
    let l = split(result, "\n")
    call assert_equal(["{'a': {...}}",
		     \ "{'a': {...}}"], l)

    " Recursive list
    let a = [0]
    let a[0] = a
    redir => result
    echo a
    echo string(a)
    redir END
    let l = split(result, "\n")
    call assert_equal(["[[...]]",
		     \ "[[...]]"], l)

    " Empty dictionaries in a list
    let a = {}
    redir => result
    echo [a, a, a]
    echo string([a, a, a])
    redir END
    let l = split(result, "\n")
    call assert_equal(["[{}, {}, {}]",
		     \ "[{}, {}, {}]"], l)

    " Empty dictionaries in a dictionary
    let a = {}
    let b = {"a": a, "b": a}
    redir => result
    echo b
    echo string(b)
    redir END
    let l = split(result, "\n")
    call assert_equal(["{'a': {}, 'b': {}}",
		     \ "{'a': {}, 'b': {}}"], l)

    " Empty lists in a list
    let a = []
    redir => result
    echo [a, a, a]
    echo string([a, a, a])
    redir END
    let l = split(result, "\n")
    call assert_equal(["[[], [], []]",
		     \ "[[], [], []]"], l)

    " Empty lists in a dictionary
    let a = []
    let b = {"a": a, "b": a}
    redir => result
    echo b
    echo string(b)
    redir END
    let l = split(result, "\n")
    call assert_equal(["{'a': [], 'b': []}",
		     \ "{'a': [], 'b': []}"], l)

    " Dictionaries in a list
    let a = {"one": "yes", "two": "yes", "three": "yes"}
    redir => result
    echo [a, a, a]
    echo string([a, a, a])
    redir END
    let l = split(result, "\n")
    call assert_equal(["[{'one': 'yes', 'two': 'yes', 'three': 'yes'}, {...}, {...}]",
		     \ "[{'one': 'yes', 'two': 'yes', 'three': 'yes'}, {'one': 'yes', 'two': 'yes', 'three': 'yes'}, {'one': 'yes', 'two': 'yes', 'three': 'yes'}]"], l)

    " Dictionaries in a dictionary
    let a = {"one": "yes", "two": "yes", "three": "yes"}
    let b = {"a": a, "b": a}
    redir => result
    echo b
    echo string(b)
    redir END
    let l = split(result, "\n")
    call assert_equal(["{'a': {'one': 'yes', 'two': 'yes', 'three': 'yes'}, 'b': {...}}",
		     \ "{'a': {'one': 'yes', 'two': 'yes', 'three': 'yes'}, 'b': {'one': 'yes', 'two': 'yes', 'three': 'yes'}}"], l)

    " Lists in a list
    let a = [1, 2, 3]
    redir => result
    echo [a, a, a]
    echo string([a, a, a])
    redir END
    let l = split(result, "\n")
    call assert_equal(["[[1, 2, 3], [...], [...]]",
		     \ "[[1, 2, 3], [1, 2, 3], [1, 2, 3]]"], l)

    " Lists in a dictionary
    let a = [1, 2, 3]
    let b = {"a": a, "b": a}
    redir => result
    echo b
    echo string(b)
    redir END
    let l = split(result, "\n")
    call assert_equal(["{'a': [1, 2, 3], 'b': [...]}",
		     \ "{'a': [1, 2, 3], 'b': [1, 2, 3]}"], l)

    call assert_fails('echo &:', 'E112:')
    call assert_fails('echo &g:', 'E112:')
    call assert_fails('echo &l:', 'E112:')

endfunc

"-------------------------------------------------------------------------------
" Test 94:  64-bit Numbers					    {{{1
"-------------------------------------------------------------------------------

func Test_num64()
    call assert_notequal( 4294967296, 0)
    call assert_notequal(-4294967296, 0)
    call assert_equal( 4294967296,  0xFFFFffff + 1)
    call assert_equal(-4294967296, -0xFFFFffff - 1)

    call assert_equal( 9223372036854775807,  1 / 0)
    call assert_equal(-9223372036854775807, -1 / 0)
    call assert_equal(-9223372036854775807 - 1,  0 / 0)

    if has('float')
      call assert_equal( 0x7FFFffffFFFFffff, float2nr( 1.0e150))
      call assert_equal(-0x7FFFffffFFFFffff, float2nr(-1.0e150))
    endif

    let rng = range(0xFFFFffff, 0x100000001)
    call assert_equal([0xFFFFffff, 0x100000000, 0x100000001], rng)
    call assert_equal(0x100000001, max(rng))
    call assert_equal(0xFFFFffff, min(rng))
    call assert_equal(rng, sort(range(0x100000001, 0xFFFFffff, -1), 'N'))
endfunc

"-------------------------------------------------------------------------------
" Test 95:  lines of :append, :change, :insert			    {{{1
"-------------------------------------------------------------------------------

function! DefineFunction(name, body)
    let func = join(['function! ' . a:name . '()'] + a:body + ['endfunction'], "\n")
    exec func
endfunction

func Test_script_lines()
    " :append
    try
	call DefineFunction('T_Append', [
		    \ 'append',
		    \ 'py <<EOS',
		    \ '.',
		    \ ])
    catch
	call assert_report("Can't define function")
    endtry
    try
	call DefineFunction('T_Append', [
		    \ 'append',
		    \ 'abc',
		    \ ])
	call assert_report("Shouldn't be able to define function")
    catch
	call assert_exception('Vim(function):E126: Missing :endfunction')
    endtry

    " :change
    try
	call DefineFunction('T_Change', [
		    \ 'change',
		    \ 'py <<EOS',
		    \ '.',
		    \ ])
    catch
	call assert_report("Can't define function")
    endtry
    try
	call DefineFunction('T_Change', [
		    \ 'change',
		    \ 'abc',
		    \ ])
	call assert_report("Shouldn't be able to define function")
    catch
	call assert_exception('Vim(function):E126: Missing :endfunction')
    endtry

    " :insert
    try
	call DefineFunction('T_Insert', [
		    \ 'insert',
		    \ 'py <<EOS',
		    \ '.',
		    \ ])
    catch
	call assert_report("Can't define function")
    endtry
    try
	call DefineFunction('T_Insert', [
		    \ 'insert',
		    \ 'abc',
		    \ ])
	call assert_report("Shouldn't be able to define function")
    catch
	call assert_exception('Vim(function):E126: Missing :endfunction')
    endtry
endfunc

"-------------------------------------------------------------------------------
" Test 96:  line continuation						    {{{1
"
"	    Undefined behavior was detected by ubsan with line continuation
"	    after an empty line.
"-------------------------------------------------------------------------------
func Test_script_emty_line_continuation()

    \
endfunc

"-------------------------------------------------------------------------------
" Test 97:  bitwise functions						    {{{1
"-------------------------------------------------------------------------------
func Test_bitwise_functions()
    " and
    call assert_equal(127, and(127, 127))
    call assert_equal(16, and(127, 16))
    eval 127->and(16)->assert_equal(16)
    call assert_equal(0, and(127, 128))
    call assert_fails("call and([], 1)", 'E745:')
    call assert_fails("call and({}, 1)", 'E728:')
    if has('float')
      call assert_fails("call and(1.0, 1)", 'E805:')
      call assert_fails("call and(1, 1.0)", 'E805:')
    endif
    call assert_fails("call and(1, [])", 'E745:')
    call assert_fails("call and(1, {})", 'E728:')
    " or
    call assert_equal(23, or(16, 7))
    call assert_equal(15, or(8, 7))
    eval 8->or(7)->assert_equal(15)
    call assert_equal(123, or(0, 123))
    call assert_fails("call or([], 1)", 'E745:')
    call assert_fails("call or({}, 1)", 'E728:')
    if has('float')
      call assert_fails("call or(1.0, 1)", 'E805:')
      call assert_fails("call or(1, 1.0)", 'E805:')
    endif
    call assert_fails("call or(1, [])", 'E745:')
    call assert_fails("call or(1, {})", 'E728:')
    " xor
    call assert_equal(0, xor(127, 127))
    call assert_equal(111, xor(127, 16))
    eval 127->xor(16)->assert_equal(111)
    call assert_equal(255, xor(127, 128))
    if has('float')
      call assert_fails("call xor(1.0, 1)", 'E805:')
      call assert_fails("call xor(1, 1.0)", 'E805:')
    endif
    call assert_fails("call xor([], 1)", 'E745:')
    call assert_fails("call xor({}, 1)", 'E728:')
    call assert_fails("call xor(1, [])", 'E745:')
    call assert_fails("call xor(1, {})", 'E728:')
    " invert
    call assert_equal(65408, and(invert(127), 65535))
    eval 127->invert()->and(65535)->assert_equal(65408)
    call assert_equal(65519, and(invert(16), 65535))
    call assert_equal(65407, and(invert(128), 65535))
    if has('float')
      call assert_fails("call invert(1.0)", 'E805:')
    endif
    call assert_fails("call invert([])", 'E745:')
    call assert_fails("call invert({})", 'E728:')
endfunc

" Test using bang after user command				    {{{1
func Test_user_command_with_bang()
    command -bang Nieuw let nieuw = 1
    Ni!
    call assert_equal(1, nieuw)
    unlet nieuw
    delcommand Nieuw
endfunc

func Test_script_expand_sfile()
  let lines =<< trim END
    func s:snr()
      return expand('<sfile>')
    endfunc
    let g:result = s:snr()
  END
  call writefile(lines, 'Xexpand')
  source Xexpand
  call assert_match('<SNR>\d\+_snr', g:result)
  source Xexpand
  call assert_match('<SNR>\d\+_snr', g:result)

  call delete('Xexpand')
  unlet g:result
endfunc

func Test_compound_assignment_operators()
    " Test for number
    let x = 1
    let x += 10
    call assert_equal(11, x)
    let x -= 5
    call assert_equal(6, x)
    let x *= 4
    call assert_equal(24, x)
    let x /= 3
    call assert_equal(8, x)
    let x %= 3
    call assert_equal(2, x)
    let x .= 'n'
    call assert_equal('2n', x)

    " Test special cases: division or modulus with 0.
    let x = 1
    let x /= 0
    call assert_equal(0x7FFFFFFFFFFFFFFF, x)

    let x = -1
    let x /= 0
    call assert_equal(-0x7FFFFFFFFFFFFFFF, x)

    let x = 0
    let x /= 0
    call assert_equal(-0x7FFFFFFFFFFFFFFF - 1, x)

    let x = 1
    let x %= 0
    call assert_equal(0, x)

    let x = -1
    let x %= 0
    call assert_equal(0, x)

    let x = 0
    let x %= 0
    call assert_equal(0, x)

    " Test for string
    let x = 'str'
    let x .= 'ing'
    call assert_equal('string', x)
    let x += 1
    call assert_equal(1, x)

    if has('float')
      " Test for float
      let x -= 1.5
      call assert_equal(-0.5, x)
      let x = 0.5
      let x += 4.5
      call assert_equal(5.0, x)
      let x -= 1.5
      call assert_equal(3.5, x)
      let x *= 3.0
      call assert_equal(10.5, x)
      let x /= 2.5
      call assert_equal(4.2, x)
      call assert_fails('let x %= 0.5', 'E734')
      call assert_fails('let x .= "f"', 'E734')
      let x = !3.14
      call assert_equal(0.0, x)

      " integer and float operations
      let x = 1
      let x *= 2.1
      call assert_equal(2.1, x)
      let x = 1
      let x /= 0.25
      call assert_equal(4.0, x)
      let x = 1
      call assert_fails('let x %= 0.25', 'E734:')
      let x = 1
      call assert_fails('let x .= 0.25', 'E734:')
      let x = 1.0
      call assert_fails('let x += [1.1]', 'E734:')
    endif

    " Test for environment variable
    let $FOO = 1
    call assert_fails('let $FOO += 1', 'E734')
    call assert_fails('let $FOO -= 1', 'E734')
    call assert_fails('let $FOO *= 1', 'E734')
    call assert_fails('let $FOO /= 1', 'E734')
    call assert_fails('let $FOO %= 1', 'E734')
    let $FOO .= 's'
    call assert_equal('1s', $FOO)
    unlet $FOO

    " Test for option variable (type: number)
    let &scrolljump = 1
    let &scrolljump += 5
    call assert_equal(6, &scrolljump)
    let &scrolljump -= 2
    call assert_equal(4, &scrolljump)
    let &scrolljump *= 3
    call assert_equal(12, &scrolljump)
    let &scrolljump /= 2
    call assert_equal(6, &scrolljump)
    let &scrolljump %= 5
    call assert_equal(1, &scrolljump)
    call assert_fails('let &scrolljump .= "j"', 'E734')
    set scrolljump&vim

    " Test for register
    let @/ = 1
    call assert_fails('let @/ += 1', 'E734')
    call assert_fails('let @/ -= 1', 'E734')
    call assert_fails('let @/ *= 1', 'E734')
    call assert_fails('let @/ /= 1', 'E734')
    call assert_fails('let @/ %= 1', 'E734')
    let @/ .= 's'
    call assert_equal('1s', @/)
    let @/ = ''
endfunc

func Test_unlet_env()
  let $TESTVAR = 'yes'
  call assert_equal('yes', $TESTVAR)
  call assert_fails('lockvar $TESTVAR', 'E940')
  call assert_fails('unlockvar $TESTVAR', 'E940')
  call assert_equal('yes', $TESTVAR)
  if 0
    unlet $TESTVAR
  endif
  call assert_equal('yes', $TESTVAR)
  unlet $TESTVAR
  call assert_equal('', $TESTVAR)
endfunc

func Test_refcount()
    " Immediate values
    call assert_equal(-1, test_refcount(1))
    call assert_equal(-1, test_refcount('s'))
    call assert_equal(-1, test_refcount(v:true))
    call assert_equal(0, test_refcount([]))
    call assert_equal(0, test_refcount({}))
    call assert_equal(0, test_refcount(0zff))
    call assert_equal(0, test_refcount({-> line('.')}))
    if has('float')
        call assert_equal(-1, test_refcount(0.1))
    endif
    if has('job')
        call assert_equal(0, test_refcount(job_start([&shell, &shellcmdflag, 'echo .'])))
    endif

    " No refcount types
    let x = 1
    call assert_equal(-1, test_refcount(x))
    let x = 's'
    call assert_equal(-1, test_refcount(x))
    let x = v:true
    call assert_equal(-1, test_refcount(x))
    if has('float')
        let x = 0.1
        call assert_equal(-1, test_refcount(x))
    endif

    " Check refcount
    let x = []
    call assert_equal(1, test_refcount(x))

    let x = {}
    call assert_equal(1, x->test_refcount())

    let x = 0zff
    call assert_equal(1, test_refcount(x))

    let X = {-> line('.')}
    call assert_equal(1, test_refcount(X))
    let Y = X
    call assert_equal(2, test_refcount(X))

    if has('job')
        let job = job_start([&shell, &shellcmdflag, 'echo .'])
        call assert_equal(1, test_refcount(job))
        call assert_equal(1, test_refcount(job_getchannel(job)))
        call assert_equal(1, test_refcount(job))
    endif

    " Function arguments, copying and unassigning
    func ExprCheck(x, i)
        let i = a:i + 1
        call assert_equal(i, test_refcount(a:x))
        let Y = a:x
        call assert_equal(i + 1, test_refcount(a:x))
        call assert_equal(test_refcount(a:x), test_refcount(Y))
        let Y = 0
        call assert_equal(i, test_refcount(a:x))
    endfunc
    call ExprCheck([], 0)
    call ExprCheck({}, 0)
    call ExprCheck(0zff, 0)
    call ExprCheck({-> line('.')}, 0)
    if has('job')
	call ExprCheck(job, 1)
	call ExprCheck(job_getchannel(job), 1)
	call job_stop(job)
    endif
    delfunc ExprCheck

    " Regarding function
    func Func(x) abort
        call assert_equal(2, test_refcount(function('Func')))
        call assert_equal(0, test_refcount(funcref('Func')))
    endfunc
    call assert_equal(1, test_refcount(function('Func')))
    call assert_equal(0, test_refcount(function('Func', [1])))
    call assert_equal(0, test_refcount(funcref('Func')))
    call assert_equal(0, test_refcount(funcref('Func', [1])))
    let X = function('Func')
    let Y = X
    call assert_equal(1, test_refcount(X))
    let X = function('Func', [1])
    let Y = X
    call assert_equal(2, test_refcount(X))
    let X = funcref('Func')
    let Y = X
    call assert_equal(2, test_refcount(X))
    let X = funcref('Func', [1])
    let Y = X
    call assert_equal(2, test_refcount(X))
    unlet X
    unlet Y
    call Func(1)
    delfunc Func

    " Function with dict
    func DictFunc() dict
        call assert_equal(3, test_refcount(self))
    endfunc
    let d = {'Func': function('DictFunc')}
    call assert_equal(1, test_refcount(d))
    call assert_equal(0, test_refcount(d.Func))
    call d.Func()
    unlet d
    delfunc DictFunc
endfunc

" Test for missing :endif, :endfor, :endwhile and :endtry           {{{1
func Test_missing_end()
  call writefile(['if 2 > 1', 'echo ">"'], 'Xscript')
  call assert_fails('source Xscript', 'E171:')
  call writefile(['for i in range(5)', 'echo i'], 'Xscript')
  call assert_fails('source Xscript', 'E170:')
  call writefile(['while v:true', 'echo "."'], 'Xscript')
  call assert_fails('source Xscript', 'E170:')
  call writefile(['try', 'echo "."'], 'Xscript')
  call assert_fails('source Xscript', 'E600:')
  call delete('Xscript')

  " Using endfor with :while
  let caught_e732 = 0
  try
    while v:true
    endfor
  catch /E732:/
    let caught_e732 = 1
  endtry
  call assert_equal(1, caught_e732)

  " Using endwhile with :for
  let caught_e733 = 0
  try
    for i in range(1)
    endwhile
  catch /E733:/
    let caught_e733 = 1
  endtry
  call assert_equal(1, caught_e733)

  " Using endfunc with :if
  call assert_fails('exe "if 1 | endfunc | endif"', 'E193:')

  " Missing 'in' in a :for statement
  call assert_fails('for i range(1) | endfor', 'E690:')

  " Incorrect number of variables in for
  call assert_fails('for [i,] in range(3) | endfor', 'E475:')
endfunc

" Test for deep nesting of if/for/while/try statements              {{{1
func Test_deep_nest()
  CheckRunVimInTerminal

  let lines =<< trim [SCRIPT]
    " Deep nesting of if ... endif
    func Test1()
      let @a = join(repeat(['if v:true'], 51), "\n")
      let @a ..= "\n"
      let @a ..= join(repeat(['endif'], 51), "\n")
      @a
      let @a = ''
    endfunc

    " Deep nesting of for ... endfor
    func Test2()
      let @a = join(repeat(['for i in [1]'], 51), "\n")
      let @a ..= "\n"
      let @a ..= join(repeat(['endfor'], 51), "\n")
      @a
      let @a = ''
    endfunc

    " Deep nesting of while ... endwhile
    func Test3()
      let @a = join(repeat(['while v:true'], 51), "\n")
      let @a ..= "\n"
      let @a ..= join(repeat(['endwhile'], 51), "\n")
      @a
      let @a = ''
    endfunc

    " Deep nesting of try ... endtry
    func Test4()
      let @a = join(repeat(['try'], 51), "\n")
      let @a ..= "\necho v:true\n"
      let @a ..= join(repeat(['endtry'], 51), "\n")
      @a
      let @a = ''
    endfunc

    " Deep nesting of function ... endfunction
    func Test5()
      let @a = join(repeat(['function X()'], 51), "\n")
      let @a ..= "\necho v:true\n"
      let @a ..= join(repeat(['endfunction'], 51), "\n")
      @a
      let @a = ''
    endfunc
  [SCRIPT]
  call writefile(lines, 'Xscript')

  let buf = RunVimInTerminal('-S Xscript', {'rows': 6})

  " Deep nesting of if ... endif
  call term_sendkeys(buf, ":call Test1()\n")
  call TermWait(buf)
  call WaitForAssert({-> assert_match('^E579:', term_getline(buf, 5))})

  " Deep nesting of for ... endfor
  call term_sendkeys(buf, ":call Test2()\n")
  call TermWait(buf)
  call WaitForAssert({-> assert_match('^E585:', term_getline(buf, 5))})

  " Deep nesting of while ... endwhile
  call term_sendkeys(buf, ":call Test3()\n")
  call TermWait(buf)
  call WaitForAssert({-> assert_match('^E585:', term_getline(buf, 5))})

  " Deep nesting of try ... endtry
  call term_sendkeys(buf, ":call Test4()\n")
  call TermWait(buf)
  call WaitForAssert({-> assert_match('^E601:', term_getline(buf, 5))})

  " Deep nesting of function ... endfunction
  call term_sendkeys(buf, ":call Test5()\n")
  call TermWait(buf)
  call WaitForAssert({-> assert_match('^E1058:', term_getline(buf, 4))})
  call term_sendkeys(buf, "\<C-C>\n")
  call TermWait(buf)

  "let l = ''
  "for i in range(1, 6)
  "  let l ..= term_getline(buf, i) . "\n"
  "endfor
  "call assert_report(l)

  call StopVimInTerminal(buf)
  call delete('Xscript')
endfunc

" Test for errors in converting to float from various types         {{{1
func Test_float_conversion_errors()
  if has('float')
    call assert_fails('let x = 4.0 % 2.0', 'E804')
    call assert_fails('echo 1.1[0]', 'E806')
    call assert_fails('echo sort([function("min"), 1], "f")', 'E891:')
    call assert_fails('echo 3.2 == "vim"', 'E892:')
    call assert_fails('echo sort([[], 1], "f")', 'E893:')
    call assert_fails('echo sort([{}, 1], "f")', 'E894:')
    call assert_fails('echo 3.2 == v:true', 'E362:')
    call assert_fails('echo 3.2 == v:none', 'E907:')
  endif
endfunc

" invalid function names               {{{1
func Test_invalid_function_names()
  " function name not starting with capital
  let caught_e128 = 0
  try
    func! g:test()
      echo "test"
    endfunc
  catch /E128:/
    let caught_e128 = 1
  endtry
  call assert_equal(1, caught_e128)

  " function name includes a colon
  let caught_e884 = 0
  try
    func! b:test()
      echo "test"
    endfunc
  catch /E884:/
    let caught_e884 = 1
  endtry
  call assert_equal(1, caught_e884)

  " function name folowed by #
  let caught_e128 = 0
  try
    func! test2() "#
      echo "test2"
    endfunc
  catch /E128:/
    let caught_e128 = 1
  endtry
  call assert_equal(1, caught_e128)

  " function name starting with/without "g:", buffer-local funcref.
  function! g:Foo(n)
    return 'called Foo(' . a:n . ')'
  endfunction
  let b:my_func = function('Foo')
  call assert_equal('called Foo(1)', b:my_func(1))
  call assert_equal('called Foo(2)', g:Foo(2))
  call assert_equal('called Foo(3)', Foo(3))
  delfunc g:Foo

  " script-local function used in Funcref must exist.
  let lines =<< trim END
    func s:Testje()
      return "foo"
    endfunc
    let Bar = function('s:Testje')
    call assert_equal(0, exists('s:Testje'))
    call assert_equal(1, exists('*s:Testje'))
    call assert_equal(1, exists('Bar'))
    call assert_equal(1, exists('*Bar'))
  END
  call writefile(lines, 'Xscript')
  source Xscript
  call delete('Xscript')
endfunc

" substring and variable name              {{{1
func Test_substring_var()
  let str = 'abcdef'
  let n = 3
  call assert_equal('def', str[n:])
  call assert_equal('abcd', str[:n])
  call assert_equal('d', str[n:n])
  unlet n
  let nn = 3
  call assert_equal('def', str[nn:])
  call assert_equal('abcd', str[:nn])
  call assert_equal('d', str[nn:nn])
  unlet nn
  let b:nn = 4
  call assert_equal('ef', str[b:nn:])
  call assert_equal('abcde', str[:b:nn])
  call assert_equal('e', str[b:nn:b:nn])
  unlet b:nn
endfunc

" Test using s: with a typed command              {{{1
func Test_typed_script_var()
  CheckRunVimInTerminal

  let buf = RunVimInTerminal('', {'rows': 6})

  " Deep nesting of if ... endif
  call term_sendkeys(buf, ":echo get(s:, 'foo', 'x')\n")
  call TermWait(buf)
  call WaitForAssert({-> assert_match('^E116:', term_getline(buf, 5))})

  call StopVimInTerminal(buf)
endfunc

"-------------------------------------------------------------------------------
" Modelines								    {{{1
" vim: ts=8 sw=2 sts=2 expandtab tw=80 fdm=marker
"-------------------------------------------------------------------------------
