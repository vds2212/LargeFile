" LargeFile: Sets up an autocmd to make editing large files work with celerity
"   Author:     Charles E. Campbell
"   Date:       Nov 25, 2013
"   Version:    5
"   Copyright:  see :help LargeFile-copyright
" GetLatestVimScripts: 1506 1 :AutoInstall: LargeFile.vim
"DechoRemOn

" ---------------------------------------------------------------------
" Load Once: {{{1
if exists("g:loaded_LargeFile") || &cp
  finish
endif
let g:loaded_LargeFile = "v6"
let s:keepcpo          = &cpo
let g:LargeFile_undo   = 1
set cpo&vim

" ---------------------------------------------------------------------
" Commands: {{{1
command! Unlarge      call s:Unlarge()
command! -bang Large  call s:LargeFile(<bang>0, expand("%"))

" ---------------------------------------------------------------------
"  Options: {{{1
if !exists("g:LargeFile")
  let g:LargeFile = 20  " in megabytes
endif

" ---------------------------------------------------------------------
"  LargeFile Autocmd: {{{1
" for large files: turns undo, syntax highlighting, undo off etc
" (based on vimtip#611)
augroup LargeFile
  autocmd!
  autocmd BufReadPre * call <SID>LargeFile(0, expand("<afile>"))
  " autocmd BufReadPost * call <SID>LargeFilePost()
augroup END

" ---------------------------------------------------------------------
" s:LargeFile: {{{2
fun! s:LargeFile(force, fname)
  " call Dfunc("s:LargeFile(force=".a:force." fname<".a:fname.">) buf#".bufnr("%")."<".bufname("%")."> g:LargeFile=".g:LargeFile)
  let fsz = getfsize(a:fname)
  " call Decho("fsz=".fsz)
  if a:force || fsz >= g:LargeFile*1024.0*1024.0 || fsz <= -2
    silent! call s:ParenMatchOff()
    syntax clear
    let b:LF_bhkeep      = &l:bufhidden
    let b:LF_bkkeep      = &l:backup
    let b:LF_cptkeep     = &complete
    let b:LF_eikeep      = &eventignore
    let b:LF_fdmkeep     = &l:foldmethod
    let b:LF_fenkeep     = &l:foldenable
    let b:LF_swfkeep     = &l:swapfile

    if g:LargeFile_undo
      if v:version < 704 || (v:version == 704 && !has("patch073"))
        let b:LF_ulkeep    = &undolevels
      else
        let b:LF_ulkeep    = &l:undolevels
      endif
    endif

    let b:LF_wbkeep      = &l:writebackup

    set eventignore=FileType
    setlocal noswapfile bufhidden=unload foldmethod=manual nofoldenable complete-=wbuU nobackup nowritebackup

    if g:LargeFile_undo
      if v:version < 704 || (v:version == 704 && !has("patch073"))
        set undolevels=-1
      else
        setlocal undolevels=-1
      endif
    endif

    augroup LargeFileAU
      autocmd LargeFile BufEnter <buffer> call s:LargeFileEnter()
      autocmd LargeFile BufLeave <buffer> call s:LargeFileLeave()
      autocmd LargeFile BufUnload <buffer> augroup LargeFileAU | autocmd! BufEnter,BufLeave <buffer> | augroup END
    augroup END
    let b:LargeFile_mode = 1
    " call Decho("turning  b:LargeFile_mode to ".b:LargeFile_mode)
    echomsg "***note*** handling a large file"
  endif
  " call Dret("s:LargeFile")
endfun

" ---------------------------------------------------------------------
" s:LargeFilePost: determines if the file is large enough to warrant LargeFile treatment.  Called via a BufReadPost event.  {{{2
fun! s:LargeFilePost()
  " call Dfunc("s:LargeFilePost() ".line2byte(line("$")+1)."bytes g:LargeFile=".g:LargeFile.(exists("b:LargeFile_mode")? " b:LargeFile_mode=".b:LargeFile_mode : ""))
  if line2byte(line("$")+1) >= g:LargeFile*1024.0*1024.0
    if !exists("b:LargeFile_mode") || b:LargeFile_mode == 0
      call s:LargeFile(1, expand("<afile>"))
    endif
  endif
  " call Dret("s:LargeFilePost")
endfun

" ---------------------------------------------------------------------
" s:ParenMatchOff: {{{2
fun! s:ParenMatchOff()
  " call Dfunc("s:ParenMatchOff()")
  redir => matchparen_enabled
  command NoMatchParen
  redir END
  if matchparen_enabled =~ 'g:loaded_matchparen'
    let b:LF_nmpkeep = 1
    NoMatchParen
  endif
  " call Dret("s:ParenMatchOff")
endfun

" ---------------------------------------------------------------------
" s:Unlarge: this function will undo what the LargeFile autocmd does {{{2
fun! s:Unlarge()
  " call Dfunc("s:Unlarge()")
  let b:LargeFile_mode= 0
  " call Decho("turning  b:LargeFile_mode to ".b:LargeFile_mode)
  if exists("b:LF_bhkeep") |let &l:bufhidden   = b:LF_bhkeep |unlet b:LF_bhkeep |endif
  if exists("b:LF_bkkeep") |let &l:backup      = b:LF_bkkeep |unlet b:LF_bkkeep |endif
  if exists("b:LF_cptkeep")|let &complete      = b:LF_cptkeep|unlet b:LF_cptkeep|endif
  if exists("b:LF_eikeep") |let &eventignore   = b:LF_eikeep |unlet b:LF_eikeep |endif
  if exists("b:LF_fdmkeep")|let &l:foldmethod  = b:LF_fdmkeep|unlet b:LF_fdmkeep|endif
  if exists("b:LF_fenkeep")|let &l:foldenable  = b:LF_fenkeep|unlet b:LF_fenkeep|endif
  if exists("b:LF_swfkeep")|let &l:swapfile    = b:LF_swfkeep|unlet b:LF_swfkeep|endif

  if g:LargeFile_undo
    if exists("b:LF_ulkeep") |let &undolevels    = b:LF_ulkeep |unlet b:LF_ulkeep |endif
  endif

  if exists("b:LF_wbkeep") |let &l:writebackup = b:LF_wbkeep |unlet b:LF_wbkeep |endif

  if exists("b:LF_nmpkeep")
    DoMatchParen
    unlet b:LF_nmpkeep
  endif

  syntax on

  doautocmd FileType

  augroup LargeFileAU
    autocmd! BufEnter,BufLeave <buffer>
  augroup END

  call s:LargeFileLeave()
  echomsg "***note*** stopped large-file handling"
  " call Dret("s:Unlarge")
endfun

" ---------------------------------------------------------------------
" s:LargeFileEnter: {{{2
fun! s:LargeFileEnter()
  " call Dfunc("s:LargeFileEnter() buf#".bufnr("%")."<".bufname("%").">")
  if !g:LargeFile_undo
    return
  endif

  if v:version < 704 || (v:version == 704 && !has("patch073"))
    if has("persistent_undo")
      "   call Decho("(s:LargeFileEnter) handling persistent undo: write undo history")
      " Write all undo history:
      "   Turn off all events/autocmds.
      "   Split the buffer so bufdo will always work (i.e. won't abandon the current buffer)
      "   Use bufdo
      "   Restorre
      let eikeep = &eventignore
      set eventignore=all
      1split
      bufdo exe "wundo! ".fnameescape(undofile(bufname("%")))
      quit!
      let &eventignore = eikeep
    endif
    set undolevels=-1
  else
    setlocal undolevels=-1
  endif
  " call Dret("s:LargeFileEnter")
endfun

" ---------------------------------------------------------------------
" s:LargeFileLeave: when leaving a LargeFile, turn undo back on {{{2
"                   This routine is useful for having a LargeFile still open,
"                   but one has changed windows/tabs to edit a different file.
fun! s:LargeFileLeave()
  " call Dfunc("s:LargeFileLeave() buf#".bufnr("%")."<".bufname("%").">")
  " restore undo trees
  if v:version < 704 || (v:version == 704 && !has("patch073"))
    if g:LargeFile_undo && has("persistent_undo")
      "   call Decho("(s:LargeFileLeave) handling persistent undo: restoring undo history")
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
  endif

  " restore event handling
  if exists("b:LF_eikeep")
    let &eventignore = b:LF_eikeep
  endif

  " restore undo level
  if g:LargeFile_undo && exists("b:LF_ulkeep")
    if v:version < 704 || (v:version == 704 && !has("patch073"))
      let &undolevels = b:LF_ulkeep
    else
      let &l:undolevels = b:LF_ulkeep
    endif
  endif
  " call Dret("s:LargeFileLeave")
endfun

" ---------------------------------------------------------------------
"  Restore: {{{1
let &cpo= s:keepcpo
unlet s:keepcpo
" vim: ts=4 fdm=marker
