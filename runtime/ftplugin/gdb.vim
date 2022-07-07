" Vim filetype plugin file
" Language:	gdb
" Maintainer:	Michaël Peeters <NOSPAMm.vim@noekeon.org>
" Last Changed: 26 Oct 2017

if exists("b:did_ftplugin") | finish | endif
let b:did_ftplugin = 1

let s:cpo_save = &cpo
set cpo&vim

setlocal comments=:#
setlocal commentstring=#%s
setlocal formatoptions-=t
setlocal formatoptions+=croql

" Undo the stuff we changed.
let b:undo_ftplugin = "setlocal com< cms< fo<"

if exists("loaded_matchit") && !exists("b:match_words")
  let s:line_start = '\%(^\s*\)\@<='
  let b:match_words = s:line_start .. '\%(commands\|define\|document\|if\|while\|' ..
	\                             'compi\%[le]\s\+\%(c\%[ode]\|p\%[rint]\)\|' ..
	\                             'exp\%[ression]\s\+\%(c\%[ode]\|p\%[rint]\)\)\>:' ..
	\		s:line_start .. '\%(else\|loop_continue\|loop_break\)\>:' ..
	\	      s:line_start .. 'end\>'
  unlet s:line_start
  let b:undo_ftplugin ..= " | unlet! b:match_words"
endif

if (has("gui_win32") || has("gui_gtk")) && !exists("b:browsefilter")
  let b:browsefilter = "GDB Init Files (.gdbinit gdbinit .gdbearlyinit gdbearlyinit)\t.gdbinit;gdbinit;.gdbearlyinit;gdbearlyinit\n" ..
	\	       "GDB Command Files (*.gdb)\t*.gdb\n" ..
	\	       "All Files (*.*)\t*.*\n"
  let b:undo_ftplugin ..= " | unlet! b:browsefilter"
endif

let &cpo = s:cpo_save
unlet s:cpo_save
