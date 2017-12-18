" Tests for the jumplist functionality

" Tests for the getjumplist() function
func Test_getjumplist()
  if !has("jumplist")
    return
  endif

  %bwipe
  clearjumps
  call assert_equal([[], 0], getjumplist(1, 1))

  let lines = []
  for i in range(1, 100)
    call add(lines, "Line " . i)
  endfor
  call writefile(lines, "Xtest")

  " Jump around and create a jump list
  edit Xtest
  let bnr = bufnr('%')
  normal 50%
  normal G
  normal gg

  call assert_equal([[
	      \ {'lnum': 1, 'bufnr': bnr, 'col': 0, 'coladd': 0},
	      \ {'lnum': 1, 'bufnr': bnr, 'col': 0, 'coladd': 0},
	      \ {'lnum': 50, 'bufnr': bnr, 'col': 0, 'coladd': 0},
	      \ {'lnum': 100, 'bufnr': bnr, 'col': 0, 'coladd': 0}], 4],
	      \ getjumplist(1, 1))

  " Traverse the jump list and verify the results
  5
  exe "normal \<C-O>"
  call assert_equal(2, getjumplist(1, 1)[1])
  exe "normal 2\<C-O>"
  call assert_equal(0, getjumplist(1, 1)[1])
  exe "normal 3\<C-I>"
  call assert_equal(3, getjumplist(1, 1)[1])
  exe "normal \<C-O>"
  normal 20%
  call assert_equal([[
	      \ {'lnum': 1, 'bufnr': bnr, 'col': 0, 'coladd': 0},
	      \ {'lnum': 50, 'bufnr': bnr, 'col': 0, 'coladd': 0},
	      \ {'lnum': 100, 'bufnr': bnr, 'col': 0, 'coladd': 0},
	      \ {'lnum': 5, 'bufnr': bnr, 'col': 0, 'coladd': 0},
	      \ {'lnum': 100, 'bufnr': bnr, 'col': 0, 'coladd': 0}], 5],
	      \ getjumplist(1, 1))

  let l = getjumplist(1, 1)
  call test_garbagecollect_now()
  call assert_equal(5, l[1])
  clearjumps
  call test_garbagecollect_now()
  call assert_equal(5, l[1])

  call delete("Xtest")
endfunc
