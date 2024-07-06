" Vim filetype plugin
" Language:     M3U Playlist
" Maintainer:	AvidSeeker <avidseeker7@protonmail.com>
" Last Change:  2024-07-06
"

if exists("b:did_ftplugin")
  finish
endif
let g:did_ftplugin = 1

setlocal commentstring=#%s

function! M3UFold() abort
  let line = getline(v:lnum)
  if line =~# '^#EXTGRP'
    return ">1"
  endif
  return "="
endfunction

function! M3UFoldText() abort
  let start_line = getline(v:foldstart)
  let title = substitute(start_line, '^#EXTGRP:*', '', '')
  let foldsize = (v:foldend - v:foldstart + 1)
  let linecount = '['.foldsize.' lines]'
  return title.' '.linecount
endfunction

if has("folding")
  setlocal foldexpr=M3UFold()
  setlocal foldmethod=expr
  setlocal foldtext=M3UFoldText()
endif
