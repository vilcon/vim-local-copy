" Tests for the swap feature

" Tests for 'directory' option.
func Test_swap_directory()
  if !has("unix")
    return
  endif
  let content = ['start of testfile',
	      \ 'line 2 Abcdefghij',
	      \ 'line 3 Abcdefghij',
	      \ 'end of testfile']
  call writefile(content, 'Xtest1')

  "  '.', swap file in the same directory as file
  set dir=.,~

  " Verify that the swap file doesn't exist in the current directory
  call assert_equal([], glob(".Xtest1*.swp", 1, 1, 1))
  edit Xtest1
  let swfname = split(execute("swapname"))[0]
  call assert_equal([swfname], glob(swfname, 1, 1, 1))

  " './dir', swap file in a directory relative to the file
  set dir=./Xtest2,.,~

  call mkdir("Xtest2")
  edit Xtest1
  call assert_equal([], glob(swfname, 1, 1, 1))
  let swfname = "Xtest2/Xtest1.swp"
  call assert_equal(swfname, split(execute("swapname"))[0])
  call assert_equal([swfname], glob("Xtest2/*", 1, 1, 1))

  " 'dir', swap file in directory relative to the current dir
  set dir=Xtest.je,~

  call mkdir("Xtest.je")
  call writefile(content, 'Xtest2/Xtest3')
  edit Xtest2/Xtest3
  call assert_equal(["Xtest2/Xtest3"], glob("Xtest2/*", 1, 1, 1))
  let swfname = "Xtest.je/Xtest3.swp"
  call assert_equal(swfname, split(execute("swapname"))[0])
  call assert_equal([swfname], glob("Xtest.je/*", 1, 1, 1))

  set dir&
  call delete("Xtest1")
  call delete("Xtest2", "rf")
  call delete("Xtest.je", "rf")
endfunc

func Test_swap_group()
  if !has("unix")
    return
  endif
  let groups = split(system('groups'))
  if len(groups) <= 1
    throw 'Skipped: need at least two groups, got ' . string(groups)
  endif

  try
    call delete('Xtest')
    split Xtest
    call setline(1, 'just some text')
    wq
    if system('ls -l Xtest') !~ ' ' . groups[0] . ' \d'
      throw 'Skipped: test file does not have the first group'
    else
      silent !chmod 640 Xtest
      call system('chgrp ' . groups[1] . ' Xtest')
      if system('ls -l Xtest') !~ ' ' . groups[1] . ' \d'
	throw 'Skipped: cannot set second group on test file'
      else
	split Xtest
	let swapname = substitute(execute('swapname'), '[[:space:]]', '', 'g')
	call assert_match('Xtest', swapname)
	" Group of swapfile must now match original file.
	call assert_match(' ' . groups[1] . ' \d', system('ls -l ' . swapname))

	bwipe!
      endif
    endif
  finally
    call delete('Xtest')
  endtry
endfunc

func Test_missing_dir()
  call mkdir('Xswapdir')
  exe 'set directory=' . getcwd() . '/Xswapdir'

  call assert_equal('', glob('foo'))
  call assert_equal('', glob('bar'))
  edit foo/x.txt
  " This should not give a warning for an existing swap file.
  split bar/x.txt
  only

  set directory&
  call delete('Xswapdir', 'rf')
endfunc

func Test_swapinfo()
  new Xswapinfo
  call setline(1, ['one', 'two', 'three'])
  w
  let fname = trim(execute('swapname'))
  call assert_match('Xswapinfo', fname)
  let info = swapinfo(fname)

  let ver = printf('VIM %d.%d', v:version / 100, v:version % 100)
  call assert_equal(ver, info.version)

  call assert_match('\w', info.user)
  " host name is truncated to 39 bytes in the swap file
  call assert_equal(hostname()[:38], info.host)
  call assert_match('Xswapinfo', info.fname)
  call assert_match(0, info.dirty)
  call assert_equal(getpid(), info.pid)
  call assert_match('^\d*$', info.mtime)
  if has_key(info, 'inode')
    call assert_match('\d', info.inode)
  endif
  bwipe!
  call delete(fname)
  call delete('Xswapinfo')

  let info = swapinfo('doesnotexist')
  call assert_equal('Cannot open file', info.error)

  call writefile(['burp'], 'Xnotaswapfile')
  let info = swapinfo('Xnotaswapfile')
  call assert_equal('Cannot read file', info.error)
  call delete('Xnotaswapfile')

  call writefile([repeat('x', 10000)], 'Xnotaswapfile')
  let info = swapinfo('Xnotaswapfile')
  call assert_equal('Not a swap file', info.error)
  call delete('Xnotaswapfile')
endfunc
