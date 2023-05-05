" Test for reset 'scroll' and 'smoothscroll'

source check.vim
source screendump.vim
source mouse.vim

func Test_reset_scroll()
  let scr = &l:scroll

  setlocal scroll=1
  setlocal scroll&
  call assert_equal(scr, &l:scroll)

  setlocal scroll=1
  setlocal scroll=0
  call assert_equal(scr, &l:scroll)

  try
    execute 'setlocal scroll=' . (winheight(0) + 1)
    " not reached
    call assert_false(1)
  catch
    call assert_exception('E49:')
  endtry

  split

  let scr = &l:scroll

  setlocal scroll=1
  setlocal scroll&
  call assert_equal(scr, &l:scroll)

  setlocal scroll=1
  setlocal scroll=0
  call assert_equal(scr, &l:scroll)

  quit!
endfunc

func Test_scolloff_even_line_count()
   new
   resize 6
   setlocal scrolloff=3
   call setline(1, range(20))
   normal 2j
   call assert_equal(1, getwininfo(win_getid())[0].topline)
   normal j
   call assert_equal(1, getwininfo(win_getid())[0].topline)
   normal j
   call assert_equal(2, getwininfo(win_getid())[0].topline)
   normal j
   call assert_equal(3, getwininfo(win_getid())[0].topline)

   bwipe!
endfunc

func Test_CtrlE_CtrlY_stop_at_end()
  enew
  call setline(1, ['one', 'two'])
  set number
  exe "normal \<C-Y>"
  call assert_equal(["  1 one   "], ScreenLines(1, 10))
  exe "normal \<C-E>\<C-E>\<C-E>"
  call assert_equal(["  2 two   "], ScreenLines(1, 10))

  bwipe!
  set nonumber
endfunc

func Test_smoothscroll_CtrlE_CtrlY()
  CheckScreendump

  let lines =<< trim END
      vim9script
      setline(1, [
        'line one',
        'word '->repeat(20),
        'line three',
        'long word '->repeat(7),
        'line',
        'line',
        'line',
      ])
      set smoothscroll
      :5
  END
  call writefile(lines, 'XSmoothScroll', 'D')
  let buf = RunVimInTerminal('-S XSmoothScroll', #{rows: 12, cols: 40})

  call term_sendkeys(buf, "\<C-E>")
  call VerifyScreenDump(buf, 'Test_smoothscroll_1', {})
  call term_sendkeys(buf, "\<C-E>")
  call VerifyScreenDump(buf, 'Test_smoothscroll_2', {})
  call term_sendkeys(buf, "\<C-E>")
  call VerifyScreenDump(buf, 'Test_smoothscroll_3', {})
  call term_sendkeys(buf, "\<C-E>")
  call VerifyScreenDump(buf, 'Test_smoothscroll_4', {})

  call term_sendkeys(buf, "\<C-Y>")
  call VerifyScreenDump(buf, 'Test_smoothscroll_5', {})
  call term_sendkeys(buf, "\<C-Y>")
  call VerifyScreenDump(buf, 'Test_smoothscroll_6', {})
  call term_sendkeys(buf, "\<C-Y>")
  call VerifyScreenDump(buf, 'Test_smoothscroll_7', {})
  call term_sendkeys(buf, "\<C-Y>")
  call VerifyScreenDump(buf, 'Test_smoothscroll_8', {})

  if has('folding')
    call term_sendkeys(buf, ":set foldmethod=indent\<CR>")
    " move the cursor so we can reuse the same dumps
    call term_sendkeys(buf, "5G")
    call term_sendkeys(buf, "\<C-E>")
    call VerifyScreenDump(buf, 'Test_smoothscroll_1', {})
    call term_sendkeys(buf, "\<C-E>")
    call VerifyScreenDump(buf, 'Test_smoothscroll_2', {})
    call term_sendkeys(buf, "7G")
    call term_sendkeys(buf, "\<C-Y>")
    call VerifyScreenDump(buf, 'Test_smoothscroll_7', {})
    call term_sendkeys(buf, "\<C-Y>")
    call VerifyScreenDump(buf, 'Test_smoothscroll_8', {})
  endif

  call StopVimInTerminal(buf)
endfunc

func Test_smoothscroll_number()
  CheckScreendump

  let lines =<< trim END
      vim9script
      setline(1, [
        'one ' .. 'word '->repeat(20),
        'two ' .. 'long word '->repeat(7),
        'line',
        'line',
        'line',
      ])
      set smoothscroll
      set splitkeep=topline
      set number cpo+=n
      :3

      def g:DoRel()
        set number relativenumber scrolloff=0
        :%del
        setline(1, [
          'one',
          'very long text '->repeat(12),
          'three',
        ])
        exe "normal 2Gzt\<C-E>"
      enddef
  END
  call writefile(lines, 'XSmoothNumber', 'D')
  let buf = RunVimInTerminal('-S XSmoothNumber', #{rows: 12, cols: 40})

  call VerifyScreenDump(buf, 'Test_smooth_number_1', {})
  call term_sendkeys(buf, "\<C-E>")
  call VerifyScreenDump(buf, 'Test_smooth_number_2', {})
  call term_sendkeys(buf, "\<C-E>")
  call VerifyScreenDump(buf, 'Test_smooth_number_3', {})

  call term_sendkeys(buf, ":set cpo-=n\<CR>")
  call VerifyScreenDump(buf, 'Test_smooth_number_4', {})
  call term_sendkeys(buf, "\<C-Y>")
  call VerifyScreenDump(buf, 'Test_smooth_number_5', {})
  call term_sendkeys(buf, "\<C-Y>")
  call VerifyScreenDump(buf, 'Test_smooth_number_6', {})

  call term_sendkeys(buf, ":botright split\<CR>gg")
  call VerifyScreenDump(buf, 'Test_smooth_number_7', {})
  call term_sendkeys(buf, "\<C-E>")
  call VerifyScreenDump(buf, 'Test_smooth_number_8', {})
  call term_sendkeys(buf, "\<C-E>")
  call VerifyScreenDump(buf, 'Test_smooth_number_9', {})
  call term_sendkeys(buf, ":close\<CR>")

  call term_sendkeys(buf, ":call DoRel()\<CR>")
  call VerifyScreenDump(buf, 'Test_smooth_number_10', {})

  call StopVimInTerminal(buf)
endfunc

func Test_smoothscroll_list()
  CheckScreendump

  let lines =<< trim END
      vim9script
      set smoothscroll scrolloff=0
      set list
      setline(1, [
        'one',
        'very long text '->repeat(12),
        'three',
      ])
      exe "normal 2Gzt\<C-E>"
  END
  call writefile(lines, 'XSmoothList', 'D')
  let buf = RunVimInTerminal('-S XSmoothList', #{rows: 8, cols: 40})

  call VerifyScreenDump(buf, 'Test_smooth_list_1', {})

  call term_sendkeys(buf, ":set listchars+=precedes:#\<CR>")
  call VerifyScreenDump(buf, 'Test_smooth_list_2', {})

  call StopVimInTerminal(buf)
endfunc

func Test_smoothscroll_diff_mode()
  CheckScreendump

  let lines =<< trim END
      vim9script
      var text = 'just some text here'
      setline(1, text)
      set smoothscroll
      diffthis
      new
      setline(1, text)
      set smoothscroll
      diffthis
  END
  call writefile(lines, 'XSmoothDiff', 'D')
  let buf = RunVimInTerminal('-S XSmoothDiff', #{rows: 8})

  call VerifyScreenDump(buf, 'Test_smooth_diff_1', {})
  call term_sendkeys(buf, "\<C-Y>")
  call VerifyScreenDump(buf, 'Test_smooth_diff_1', {})
  call term_sendkeys(buf, "\<C-E>")
  call VerifyScreenDump(buf, 'Test_smooth_diff_1', {})

  call StopVimInTerminal(buf)
endfunc

func Test_smoothscroll_wrap_scrolloff_zero()
  CheckScreendump

  let lines =<< trim END
      vim9script
      setline(1, ['Line' .. (' with some text'->repeat(7))]->repeat(7))
      set smoothscroll scrolloff=0
      :3
  END
  call writefile(lines, 'XSmoothWrap', 'D')
  let buf = RunVimInTerminal('-S XSmoothWrap', #{rows: 8, cols: 40})

  call VerifyScreenDump(buf, 'Test_smooth_wrap_1', {})

  " moving cursor down - whole bottom line shows
  call term_sendkeys(buf, "j")
  call VerifyScreenDump(buf, 'Test_smooth_wrap_2', {})

  call term_sendkeys(buf, "\<C-E>j")
  call VerifyScreenDump(buf, 'Test_smooth_wrap_3', {})

  call term_sendkeys(buf, "G")
  call VerifyScreenDump(buf, 'Test_smooth_wrap_4', {})

  " moving cursor up right after the >>> marker - no need to show whole line
  call term_sendkeys(buf, "2gj3l2k")
  call VerifyScreenDump(buf, 'Test_smooth_wrap_5', {})

  " moving cursor up where the >>> marker is - whole top line shows
  call term_sendkeys(buf, "2j02k")
  call VerifyScreenDump(buf, 'Test_smooth_wrap_6', {})

  call StopVimInTerminal(buf)
endfunc

func Test_smoothscroll_wrap_long_line()
  CheckScreendump

  let lines =<< trim END
      vim9script
      setline(1, ['one', 'two', 'Line' .. (' with lots of text'->repeat(30)) .. ' end', 'four'])
      set smoothscroll scrolloff=0
      normal 3G10|zt
  END
  call writefile(lines, 'XSmoothWrap', 'D')
  let buf = RunVimInTerminal('-S XSmoothWrap', #{rows: 6, cols: 40})
  call VerifyScreenDump(buf, 'Test_smooth_long_1', {})

  " scrolling up, cursor moves screen line down
  call term_sendkeys(buf, "\<C-E>")
  call VerifyScreenDump(buf, 'Test_smooth_long_2', {})
  call term_sendkeys(buf, "5\<C-E>")
  call VerifyScreenDump(buf, 'Test_smooth_long_3', {})

  " scrolling down, cursor moves screen line up
  call term_sendkeys(buf, "5\<C-Y>")
  call VerifyScreenDump(buf, 'Test_smooth_long_4', {})
  call term_sendkeys(buf, "\<C-Y>")
  call VerifyScreenDump(buf, 'Test_smooth_long_5', {})

  " 'scrolloff' set to 1, scrolling up, cursor moves screen line down
  call term_sendkeys(buf, ":set scrolloff=1\<CR>")
  call term_sendkeys(buf, "10|\<C-E>")
  call VerifyScreenDump(buf, 'Test_smooth_long_6', {})

  " 'scrolloff' set to 1, scrolling down, cursor moves screen line up
  call term_sendkeys(buf, "\<C-E>")
  call term_sendkeys(buf, "gjgj")
  call term_sendkeys(buf, "\<C-Y>")
  call VerifyScreenDump(buf, 'Test_smooth_long_7', {})

  " 'scrolloff' set to 2, scrolling up, cursor moves screen line down
  call term_sendkeys(buf, ":set scrolloff=2\<CR>")
  call term_sendkeys(buf, "10|\<C-E>")
  call VerifyScreenDump(buf, 'Test_smooth_long_8', {})

  " 'scrolloff' set to 2, scrolling down, cursor moves screen line up
  call term_sendkeys(buf, "\<C-E>")
  call term_sendkeys(buf, "gj")
  call term_sendkeys(buf, "\<C-Y>")
  call VerifyScreenDump(buf, 'Test_smooth_long_9', {})

  " 'scrolloff' set to 0, move cursor down one line.
  " Cursor should move properly, and since this is a really long line, it will
  " be put on top of the screen.
  call term_sendkeys(buf, ":set scrolloff=0\<CR>")
  call term_sendkeys(buf, "0j")
  call VerifyScreenDump(buf, 'Test_smooth_long_10', {})

  " Test zt/zz/zb that they work properly when a long line is above it
  call term_sendkeys(buf, "zb")
  call VerifyScreenDump(buf, 'Test_smooth_long_11', {})
  call term_sendkeys(buf, "zz")
  call VerifyScreenDump(buf, 'Test_smooth_long_12', {})
  call term_sendkeys(buf, "zt")
  call VerifyScreenDump(buf, 'Test_smooth_long_13', {})

  " Repeat the step and move the cursor down again.
  " This time, use a shorter long line that is barely long enough to span more
  " than one window. Note that the cursor is at the bottom this time because
  " Vim prefers to do so if we are scrolling a few lines only.
  call term_sendkeys(buf, ":call setline(1, ['one', 'two', 'Line' .. (' with lots of text'->repeat(10)) .. ' end', 'four'])\<CR>")
  call term_sendkeys(buf, "3Gzt")
  call term_sendkeys(buf, "j")
  call VerifyScreenDump(buf, 'Test_smooth_long_14', {})

  " Repeat the step but this time start it when the line is smooth-scrolled by
  " one line. This tests that the offset calculation is still correct and
  " still end up scrolling down to the next line with cursor at bottom of
  " screen.
  call term_sendkeys(buf, "3Gzt")
  call term_sendkeys(buf, "\<C-E>j")
  call VerifyScreenDump(buf, 'Test_smooth_long_15', {})

  call StopVimInTerminal(buf)
endfunc

func Test_smoothscroll_one_long_line()
  CheckScreendump

  let lines =<< trim END
      vim9script
      setline(1, 'with lots of text '->repeat(7))
      set smoothscroll scrolloff=0
  END
  call writefile(lines, 'XSmoothOneLong', 'D')
  let buf = RunVimInTerminal('-S XSmoothOneLong', #{rows: 6, cols: 40})
  call VerifyScreenDump(buf, 'Test_smooth_one_long_1', {})

  call term_sendkeys(buf, "\<C-E>")
  call VerifyScreenDump(buf, 'Test_smooth_one_long_2', {})

  call term_sendkeys(buf, "0")
  call VerifyScreenDump(buf, 'Test_smooth_one_long_1', {})

  call StopVimInTerminal(buf)
endfunc

func Test_smoothscroll_long_line_showbreak()
  CheckScreendump

  let lines =<< trim END
      vim9script
      # a line that spans four screen lines
      setline(1, 'with lots of text in one line '->repeat(6))
      set smoothscroll scrolloff=0 showbreak=+++\ 
  END
  call writefile(lines, 'XSmoothLongShowbreak', 'D')
  let buf = RunVimInTerminal('-S XSmoothLongShowbreak', #{rows: 6, cols: 40})
  call VerifyScreenDump(buf, 'Test_smooth_long_showbreak_1', {})

  call term_sendkeys(buf, "\<C-E>")
  call VerifyScreenDump(buf, 'Test_smooth_long_showbreak_2', {})

  call term_sendkeys(buf, "0")
  call VerifyScreenDump(buf, 'Test_smooth_long_showbreak_1', {})

  call StopVimInTerminal(buf)
endfunc

func s:check_col_calc(win_col, win_line, buf_col)
  call assert_equal(a:win_col, wincol())
  call assert_equal(a:win_line, winline())
  call assert_equal(a:buf_col, col('.'))
endfunc

" Test that if the current cursor is on a smooth scrolled line, we correctly
" reposition it. Also check that we don't miscalculate the values by checking
" the consistency between wincol() and col('.') as they are calculated
" separately in code.
func Test_smoothscroll_cursor_position()
  call NewWindow(10, 20)
  setl smoothscroll wrap
  call setline(1, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")

  call s:check_col_calc(1, 1, 1)
  exe "normal \<C-E>"

  " Move down another line to avoid blocking the <<< display
  call s:check_col_calc(1, 2, 41)
  exe "normal \<C-Y>"
  call s:check_col_calc(1, 3, 41)

  normal gg3l
  exe "normal \<C-E>"

  " Move down only 1 line when we are out of the range of the <<< display
  call s:check_col_calc(4, 1, 24)
  exe "normal \<C-Y>"
  call s:check_col_calc(4, 2, 24)
  normal ggg$
  exe "normal \<C-E>"
  call s:check_col_calc(20, 1, 40)
  exe "normal \<C-Y>"
  call s:check_col_calc(20, 2, 40)
  normal gg

  " Test number, where we have indented lines
  setl number
  call s:check_col_calc(5, 1, 1)
  exe "normal \<C-E>"

  " Move down only 1 line when the <<< display is on the number column
  call s:check_col_calc(5, 1, 17)
  exe "normal \<C-Y>"
  call s:check_col_calc(5, 2, 17)
  normal ggg$
  exe "normal \<C-E>"
  call s:check_col_calc(20, 1, 32)
  exe "normal \<C-Y>"
  call s:check_col_calc(20, 2, 32)
  normal gg

  setl numberwidth=1

  " Move down another line when numberwidth is too short to cover the whole
  " <<< display
  call s:check_col_calc(3, 1, 1)
  exe "normal \<C-E>"
  call s:check_col_calc(3, 2, 37)
  exe "normal \<C-Y>"
  call s:check_col_calc(3, 3, 37)
  normal ggl

  " Only move 1 line down when we are just past the <<< display
  call s:check_col_calc(4, 1, 2)
  exe "normal \<C-E>"
  call s:check_col_calc(4, 1, 20)
  exe "normal \<C-Y>"
  call s:check_col_calc(4, 2, 20)
  normal gg
  setl numberwidth&

  " Test number + showbreak, so test that the additional indentation works
  setl number showbreak=+++
  call s:check_col_calc(5, 1, 1)
  exe "normal \<C-E>"
  call s:check_col_calc(8, 1, 17)
  exe "normal \<C-Y>"
  call s:check_col_calc(8, 2, 17)
  normal gg

  " Test number + cpo+=n mode, where wrapped lines aren't indented
  setl number cpo+=n showbreak=
  call s:check_col_calc(5, 1, 1)
  exe "normal \<C-E>"
  call s:check_col_calc(1, 2, 37)
  exe "normal \<C-Y>"
  call s:check_col_calc(1, 3, 37)
  normal gg

  bwipe!
endfunc

func Test_smoothscroll_cursor_scrolloff()
  call NewWindow(10, 20)
  setl smoothscroll wrap
  setl scrolloff=3

  " 120 chars are 6 screen lines
  call setline(1, "abcdefghijklmnopqrstABCDEFGHIJKLMNOPQRSTabcdefghijklmnopqrstABCDEFGHIJKLMNOPQRSTabcdefghijklmnopqrstABCDEFGHIJKLMNOPQRST")
  call setline(2, "below")

  call s:check_col_calc(1, 1, 1)

  " CTRL-E shows "<<<DEFG...", cursor move four lines down
  exe "normal \<C-E>"
  call s:check_col_calc(1, 4, 81)

  " cursor on start of second line, "gk" moves into first line, skipcol doesn't
  " change
  exe "normal G0gk"
  call s:check_col_calc(1, 5, 101)

  " move cursor left one window width worth, scrolls one screen line
  exe "normal 20h"
  call s:check_col_calc(1, 5, 81)

  " move cursor left one window width worth, scrolls one screen line
  exe "normal 20h"
  call s:check_col_calc(1, 4, 61)

  " cursor on last line, "gk" should not cause a scroll
  set scrolloff=0
  normal G0
  call s:check_col_calc(1, 7, 1)
  normal gk
  call s:check_col_calc(1, 6, 101)

  bwipe!
endfunc


" Test that mouse picking is still accurate when we have smooth scrolled lines
func Test_smoothscroll_mouse_pos()
  CheckNotGui
  CheckUnix

  let save_mouse = &mouse
  let save_term = &term
  let save_ttymouse = &ttymouse
  set mouse=a term=xterm ttymouse=xterm2

  call NewWindow(10, 20)
  setl smoothscroll wrap
  " First line will wrap to 3 physical lines. 2nd/3rd lines are short lines.
  call setline(1, ["abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", "line 2", "line 3"])

  func s:check_mouse_click(row, col, buf_row, buf_col)
    call MouseLeftClick(a:row, a:col)

    call assert_equal(a:col, wincol())
    call assert_equal(a:row, winline())
    call assert_equal(a:buf_row, line('.'))
    call assert_equal(a:buf_col, col('.'))
  endfunc

  " Check that clicking without scroll works first.
  call s:check_mouse_click(3, 5, 1, 45)
  call s:check_mouse_click(4, 1, 2, 1)
  call s:check_mouse_click(4, 6, 2, 6)
  call s:check_mouse_click(5, 1, 3, 1)
  call s:check_mouse_click(5, 6, 3, 6)

  " Smooth scroll, and checks that this didn't mess up mouse clicking
  exe "normal \<C-E>"
  call s:check_mouse_click(2, 5, 1, 45)
  call s:check_mouse_click(3, 1, 2, 1)
  call s:check_mouse_click(3, 6, 2, 6)
  call s:check_mouse_click(4, 1, 3, 1)
  call s:check_mouse_click(4, 6, 3, 6)

  exe "normal \<C-E>"
  call s:check_mouse_click(1, 5, 1, 45)
  call s:check_mouse_click(2, 1, 2, 1)
  call s:check_mouse_click(2, 6, 2, 6)
  call s:check_mouse_click(3, 1, 3, 1)
  call s:check_mouse_click(3, 6, 3, 6)

  " Make a new first line 11 physical lines tall so it's taller than window
  " height, to test overflow calculations with really long lines wrapping.
  normal gg
  call setline(1, "12345678901234567890"->repeat(11))
  exe "normal 6\<C-E>"
  call s:check_mouse_click(5, 1, 1, 201)
  call s:check_mouse_click(6, 1, 2, 1)
  call s:check_mouse_click(7, 1, 3, 1)

  let &mouse = save_mouse
  let &term = save_term
  let &ttymouse = save_ttymouse
endfunc

" this was dividing by zero
func Test_smoothscrol_zero_width()
  CheckScreendump

  let lines =<< trim END
      winsize 0 0
      vsplit
      vsplit
      vsplit
      vsplit
      vsplit
      sil norm H
      set wrap
      set smoothscroll
      set number
  END
  call writefile(lines, 'XSmoothScrollZero', 'D')
  let buf = RunVimInTerminal('-u NONE -i NONE -n -m -X -Z -e -s -S XSmoothScrollZero', #{rows: 6, cols: 60, wait_for_ruler: 0})
  call TermWait(buf, 3000)
  call VerifyScreenDump(buf, 'Test_smoothscroll_zero_1', {})

  call term_sendkeys(buf, ":sil norm \<C-V>\<C-W>\<C-V>\<C-N>\<CR>")
  call VerifyScreenDump(buf, 'Test_smoothscroll_zero_2', {})

  call StopVimInTerminal(buf)
endfunc


" vim: shiftwidth=2 sts=2 expandtab
