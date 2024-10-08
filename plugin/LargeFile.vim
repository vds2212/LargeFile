" LargeFile: Sets up an autocmd to make editing large files work with celerity
"   Author:     Charles E. Campbell
"   Date:       Nov 25, 2013
"   Version:    6
"   Copyright:  see :help LargeFile-copyright
" GetLatestVimScripts: 1506 1 :AutoInstall: LargeFile.vim
"DechoRemOn

" ---------------------------------------------------------------------
" Load Once: {{{1
if exists("g:LargeFile_loaded") || &cp
  finish
endif
let g:LargeFile_loaded = "v6"

let s:keepcpo = &cpoptions
set cpoptions&vim

if !exists("g:LargeFile_do")
  let g:LargeFile_do = ["syntax", "unload", "backup", "complete", "fold", "swapfile", "match", "filetype", "undo"]
endif

if exists("g:LargeFile_dont")
  for dont in g:LargeFile_dont
    for id in range(len(g:LargeFile_do))
      if dont ==# g:LargeFile_do[id]
        call remove(g:LargeFile_do, id)
        break
      endif
    endfor
  endfor
endif

let g:LargeFile_disables = {}
for disable in g:LargeFile_do
  let g:LargeFile_disables[disable] = 1
endfor

function s:Disable(disable)
  return has_key(g:LargeFile_disables, a:disable)
endfunction

function s:HasBufferUndoLevel()
  return v:version > 704 || (v:version == 704 && has("patch073"))
endfunction

" ---------------------------------------------------------------------
" Commands: {{{1
command! Unlarge call s:Unlarge()
command! -bang Large call s:LargeFile(<bang>0, expand("%"))

" ---------------------------------------------------------------------
"  Options: {{{1
if !exists("g:LargeFile")
  let g:LargeFile = 20  " in megabytes
endif

" ---------------------------------------------------------------------
" LargeFile Autocmd: {{{1
" For large files: turns undo, syntax highlighting, undo off etc.
" (based on vimtip#611)
augroup LargeFile
  autocmd!

  " Disable feature in case the file exceed the limit:
  autocmd BufReadPre * call <SID>LargeFile(0, expand("<afile>"))

  " In case the buffer size exceed the limit after being loaded:
  autocmd BufReadPost * call <SID>LargeFilePost()
augroup END

" ---------------------------------------------------------------------
" s:LargeFile: {{{2
function! s:LargeFile(force, fname)
  " call Dfunc("s:LargeFile(force=".a:force." fname<".a:fname.">) buf#".bufnr("%")."<".bufname("%")."> g:LargeFile=".g:LargeFile)
  let fsz = getfsize(a:fname)
  " call Decho("fsz=".fsz)
  if a:force || fsz >= g:LargeFile * 1024.0 * 1024.0 || fsz <= -2
    if s:Disable("syntax")
      syntax clear
    endif

    if s:Disable("unload")
      let b:LF_bhkeep = &l:bufhidden
      setlocal bufhidden=unload
    endif

    if s:Disable("backup")
      let b:LF_bkkeep = &l:backup
      let b:LF_wbkeep = &l:writebackup
      setlocal nobackup nowritebackup
    endif

    if s:Disable("complete")
      let b:LF_cptkeep = &complete
      setlocal complete-=wbuU
    endif

    if s:Disable("fold")
      let b:LF_fdmkeep = &l:foldmethod
      let b:LF_fenkeep = &l:foldenable
      setlocal foldmethod=manual nofoldenable
    endif

    if s:Disable("swapfile")
      let b:LF_swfkeep = &l:swapfile
      setlocal noswapfile
    endif

    if s:Disable("match")
      silent! call s:ParenMatchOff()
    endif

    if s:Disable("filetype")
      let b:LF_eikeep = &eventignore
      set eventignore=FileType
    endif

    if s:Disable("undo")
      if !s:HasBufferUndoLevel()
        let b:LF_ulkeep = &undolevels
        setlocal undolevels=-1
      else
        let b:LF_ulkeep = &l:undolevels
        setlocal undolevels=-1
      endif
    endif

    " Not necessary since:
    " - This function is triggered at BufReadPost
    " - BufEnter will trigger s:LargeFileEnter()
    " call s:LargeFileEnter()

    augroup LargeFileAU
      autocmd LargeFile BufEnter <buffer> call s:LargeFileEnter()
      autocmd LargeFile BufLeave <buffer> call s:LargeFileLeave()

      " Kill the triggers when the buffer will be unloaded:
      autocmd LargeFile BufUnload <buffer> augroup LargeFileAU | autocmd! BufEnter,BufLeave <buffer> | augroup END
    augroup END

    let b:LargeFile_mode = 1
    " call Decho("turning  b:LargeFile_mode to ".b:LargeFile_mode)
    echomsg "***note*** handling a large file"
  endif
  " call Dret("s:LargeFile")
endfunction

" ---------------------------------------------------------------------
" s:LargeFilePost: determines if the file is large enough to warrant LargeFile treatment.  Called via a BufReadPost event.  {{{2
function! s:LargeFilePost()
  " call Dfunc("s:LargeFilePost() ".line2byte(line("$")+1)."bytes g:LargeFile=".g:LargeFile.(exists("b:LargeFile_mode")? " b:LargeFile_mode=".b:LargeFile_mode : ""))
  let fsz = line2byte(line("$") + 1)
  if fsz >= g:LargeFile * 1024.0 * 1024.0
    " If after the buffer has been loaded the buffer size exceed the limit:
    if !exists("b:LargeFile_mode") || b:LargeFile_mode == 0
      call s:LargeFile(1, expand("<afile>"))
    endif
  endif
  " call Dret("s:LargeFilePost")
endfunction

" ---------------------------------------------------------------------
" s:ParenMatchOff: {{{2
function! s:ParenMatchOff()
  " call Dfunc("s:ParenMatchOff()")
  redir => matchparen_enabled
  command NoMatchParen
  redir END
  if matchparen_enabled =~ 'g:loaded_matchparen'
    let b:LF_nmpkeep = 1
    NoMatchParen
  endif
  " call Dret("s:ParenMatchOff")
endfunction

" ---------------------------------------------------------------------
" s:Unlarge: this function will undo what the LargeFile autocmd does {{{2
function! s:Unlarge()
  " call Dfunc("s:Unlarge()")
  let b:LargeFile_mode = 0
  " call Decho("turning  b:LargeFile_mode to ".b:LargeFile_mode)

  if s:Disable("syntax")
    syntax on
  endif

  if s:Disable("unload")
    if exists("b:LF_bhkeep")
      let &l:bufhidden   = b:LF_bhkeep
      unlet b:LF_bhkeep
    endif
  endif

  if s:Disable("backup")
    if exists("b:LF_bkkeep")
      let &l:backup = b:LF_bkkeep
      unlet b:LF_bkkeep
    endif
    if exists("b:LF_wbkeep")
      let &l:writebackup = b:LF_wbkeep
      unlet b:LF_wbkeep
    endif
  endif

  if s:Disable("complete")
    if exists("b:LF_cptkeep")
      let &complete      = b:LF_cptkeep
      unlet b:LF_cptkeep
    endif
  endif

  if s:Disable("fold")
    if exists("b:LF_fdmkeep")
      let &l:foldmethod = b:LF_fdmkeep
      unlet b:LF_fdmkeep
    endif
    if exists("b:LF_fenkeep")
      let &l:foldenable = b:LF_fenkeep
      unlet b:LF_fenkeep
    endif
  endif

  if s:Disable("swapfile")
    if exists("b:LF_swfkeep")
      let &l:swapfile = b:LF_swfkeep
      unlet b:LF_swfkeep
    endif
  endif

  if s:Disable("match")
    if exists("b:LF_nmpkeep")
      DoMatchParen
      unlet b:LF_nmpkeep
    endif
  endif

  if s:Disable("filetype")
    if exists("b:LF_eikeep")
      let &eventignore = b:LF_eikeep
      unlet b:LF_eikeep
    endif
    doautocmd FileType
  endif

  if s:Disable("undo")
    if exists("b:LF_ulkeep")
      if !s:HasBufferUndoLevel()
        let &undolevels = b:LF_ulkeep
        unlet b:LF_ulkeep
      else
        let &l:undolevels = b:LF_ulkeep
        unlet b:LF_ulkeep
      endif
    endif
  endif

  call s:LargeFileLeave()

  augroup LargeFileAU
    autocmd! BufEnter,BufLeave <buffer>
  augroup END

  echomsg "***note*** stopped large-file handling"
  " call Dret("s:Unlarge")
endfunction

" ---------------------------------------------------------------------
" s:LargeFileEnter: {{{2
function! s:LargeFileEnter()
  " call Dfunc("s:LargeFileEnter() buf#".bufnr("%")."<".bufname("%").">")

  " Set the global settings when entering the buffer:

  if s:Disable("match")
    NoMatchParen
  endif

  " Not necessary since the FileType is usually triggered at BufRead
  " that comes after BufReadPre

  " if s:Disable("filetype")
  "   set eventignore = FileType
  " endif

  if s:Disable("undo")
    if !s:HasBufferUndoLevel()
      " Backup undo tree before setting undolevels to -1
      if has("persistent_undo")
        " call Decho("(s:LargeFileEnter) handling persistent undo: write undo history")
        " Write all undo history:
        "   Turn off all events/autocmds.
        "   Split the buffer so bufdo will always work (i.e. won't abandon the current buffer)
        "   Use bufdo
        "   Restore
        let eikeep = &eventignore
        set eventignore=all
        1split
        bufdo exe "wundo! ".fnameescape(undofile(bufname("%")))
        quit!
        let &eventignore = eikeep
      endif
      set undolevels=-1
    endif
  endif
  " call Dret("s:LargeFileEnter")
endfunction

" ---------------------------------------------------------------------
" s:LargeFileLeave: {{{2
" When leaving a LargeFile, turn undo back on
" This routine is useful for having a LargeFile still open,
" but one has changed windows/tabs to edit a different file.
function! s:LargeFileLeave()
  " call Dfunc("s:LargeFileLeave() buf#".bufnr("%")."<".bufname("%").">")

  " Restore the global settings when leaving the buffer:

  if s:Disable("match")
    if exists("b:LF_nmpkeep")
      DoMatchParen
    endif
  endif

  " Restore event handling
  if s:Disable("filetype")
    if exists("b:LF_eikeep")
      let &eventignore = b:LF_eikeep
    endif
  endif

  " Restore undo trees
  if s:Disable("undo")
    if !s:HasBufferUndoLevel()
      if has("persistent_undo")
        " call Decho("(s:LargeFileLeave) handling persistent undo: restoring undo history")
        " Read all undo history:
        "   Turn off all events/autocmds.
        "   Split the buffer so bufdo will always work (i.e. won't abandon the current buffer)
        "   Use bufdo
        "   Restore
        let eikeep = &eventignore
        set eventignore=all
        1split
        bufdo exe "silent! rundo ".fnameescape(undofile(bufname("%")))|call delete(undofile(bufname("%")))
        quit!
        let &eventignore= eikeep
      endif
      if exists("b:LF_ulkeep")
        let &undolevels = b:LF_ulkeep
      endif
    endif
  endif

  " call Dret("s:LargeFileLeave")
endfunction

" ---------------------------------------------------------------------
"  Restore: {{{1
let &cpoptions = s:keepcpo
unlet s:keepcpo
" vim: ts=2 fdm=marker
