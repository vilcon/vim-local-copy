" Tests for 'listchars' display with 'list' and :list

func GetScreenCharsForLine(lnum)
  return join(map(range(1, virtcol('$')),
        \ 'nr2char(screenchar(a:lnum, v:val))'), '')
endfunc

func Test_listchars()
  enew!
  set ff=unix
  set list

  set listchars+=tab:>-,space:.,trail:<
  call append(0, [
	      \ '	aa	',
	      \ '  bb	  ',
	      \ '   cccc	 ',
	      \ 'dd        ee  	',
	      \ ' '
	      \ ])
  let expected = [
	      \ '>-------aa>-----$',
	      \ '..bb>---<<$',
	      \ '...cccc><$',
	      \ 'dd........ee<<>-$',
	      \ '<$'
	      \ ]
  redraw!
  for i in range(1, 5)
    call cursor(i, 1)
    call assert_equal(expected[i - 1], GetScreenCharsForLine(i))
  endfor

  set listchars-=trail:<
  let expected = [
	      \ '>-------aa>-----$',
	      \ '..bb>---..$',
	      \ '...cccc>.$',
	      \ 'dd........ee..>-$',
	      \ '.$'
	      \ ]
  redraw!
  for i in range(1, 5)
    call cursor(i, 1)
    call assert_equal(expected[i - 1], GetScreenCharsForLine(i))
  endfor

  set listchars+=trail:<
  set nolist
  normal ggdG
  call append(0, [
	      \ '  fff	  ',
	      \ '	gg	',
	      \ '     h	',
	      \ 'iii    	  ',
	      \ ])
  let l = split(execute("%list"), "\n")
  call assert_equal([
	      \ '..fff>--<<$',
	      \ '>-------gg>-----$',
	      \ '.....h>-$',
	      \ 'iii<<<<><<$', '$'], l)

  enew!
  set listchars& ff&
endfunc
