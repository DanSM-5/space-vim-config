
let s:mac = 'mac'
let s:windows = 'windows'
let s:linux = 'linux'
let s:wsl = 'wsl'
let g:wsl_host = 0
" if shell is powershell.exe, system calls will be utf16 files with BOM
let s:cleanrgx = '[\xFF\xFE\x01\r\n]'

func! config#before () abort
  " Ensure command
  let g:host_os = s:CallCleanCommand('uname') 

  silent call s:Set_os_specific_before()
  silent call s:SetBufferOptions()
  silent call s:SetConfigurations()
endf

func! config#after () abort
  silent call s:Set_user_bindings()
  silent call s:Set_os_specific_after()
endf

func! s:SetConfigurations () abort
  silent call s:SetRG()
  silent call s:SetCtrlSFM()

  " Define user commands
  command -nargs=1 -complete=shellcmd CallCleanCommand call s:CallCleanCommand(<f-args>)
  command CleanCR call s:CleanCR()
endf

func! s:SetBufferOptions () abort
  augroup userconfiles
    au!
    au BufNewFile,BufRead *.uconfrc,*.uconfgrc,*.ualiasrc,*.ualiasgrc setfiletype sh
  augroup END
endf

func! s:Set_user_bindings () abort
  silent call s:SetVimSystemCopyMaps()
  silent call s:SetCtrlSFMaps()
endf

func! s:Set_os_specific_before () abort
  let os = s:CurrentOS()
  if g:wsl_host
    " We are inside wsl
    silent call s:WSL_conf_before()
  elseif os == s:windows
    silent call s:Windows_conf_before()
  endif
endf

func! s:Set_os_specific_after () abort
  let os = s:CurrentOS()
  if g:wsl_host
    " We are inside wsl
    silent call s:WSL_conf_after()
  elseif os == s:windows
    silent call s:Windows_conf_after()
  endif
endf

function! s:CurrentOS ()
  let os = g:host_os " substitute(system('uname'), '\n', '', '')
  let known_os = 'unknown'
  if has("gui_mac") || os ==? 'Darwin'
    let known_os = s:mac
  elseif has('win32') || has("gui_win32") || os =~? 'cygwin' || os =~? 'MINGW' || os =~? 'MSYS'
    let known_os = s:windows
  elseif os ==? 'Linux'
    let known_os = s:linux
    if system('uname.exe') =~ 'MSYS'
      let g:wsl_host = 1
    endif
  else
    exe "normal \<Esc>"
    throw "unknown OS: " . os
  endif
  return known_os
endfunction

" Windows specific
func! s:Windows_conf_before () abort
  " Set pwsh or powershell
  " exe 'set shell='.fnameescape("pwsh -ExecutionPolicy Bypass")
  " set shellcmdflag=-c
  set shell=cmd
  set shellcmdflag=/c
endf

func! s:Windows_conf_after () abort
  " Set paste command with pwsh core
  let g:system_copy#paste_command = 'pbpaste.exe'
  let g:system_copy#copy_command = 'clip.exe'
endf

" **************  WSL specific ********************
func! s:WSL_conf_before () abort
  let g:rooter_change_directory_for_non_project_files = 'current'
  let g:rooter_patterns = ["!.SpaceVim.d/", ".git/", "/home/".$USER."/.SpaceVim.d"]

  " Prevent changing to .SpaceVim.d directory on /mnt/c/
  let g:spacevim_project_rooter_patterns = ["!.SpaceVim.d/"] + g:spacevim_project_rooter_patterns 
  " Not implemented
  " let g:spacevim_custom_plugins = [
  "   \ ['/home/linuxbrew/.linuxbrew/opt/fzf'],
  "   \ ]
endf

func! s:WSL_conf_after () abort
  " Set copy and paste commands
  let g:system_copy#paste_command = 'pbpaste.exe'
  let g:system_copy#copy_command = 'clip.exe'
endf

func! s:CallCleanCommand (comm) abort
  return substitute(system(a:comm), s:cleanrgx, '', '')
endf

func! s:CleanCR () abort
  %s/\r//g
endf

func! s:SetRG () abort
  if executable('rg')
    " In-built grep functionality
    set grepprg=rg\ --vimgrep\ --no-heading\ --smart-case\ -H\ --hidden\ -g\ '!.git' 
    set grepformat=%f:%l:%c:%m

    " For Ctrl-P plugin
    let g:crtlp_user_command = 'rg %s --files --color=never --glob "!.git"'
    " No need for caching with rg
    let g:ctrlp_use_caching = 0
    
    let g:ctrlp_clear_cache_on_exit = 1 

    " For SpaceVim search options
    let profile = SpaceVim#mapping#search#getprofile('rg')
    let default_opt = profile.default_opts + ['--no-ignore-vcs']
    call SpaceVim#mapping#search#profile({ 'rg': { 'default_opts': default_opt } })

  endif
endf

func! s:SetCtrlSFM () abort
  let g:ctrlsf_default_root = 'cwd'
  let g:ctrlsf_backend = 'rg'
  let g:ctrlsf_extra_backend_args = {
      \ 'rg': '--hidden --glob "!.git"'
      \ }
  let g:ctrlsf_ignore_dir = ['.git', 'node_modules']

  let g:ctrlsf_mapping = {
    \ "open"    : ["<CR>", "o"],
    \ "openb"   : { 'key': "O", 'suffix': "<C-w>p" },
    \ "split"   : "<C-O>",
    \ "vsplit"  : "<C-I>",
    \ "tab"     : "t",
    \ "tabb"    : "T",
    \ "popen"   : "p",
    \ "popenf"  : "P",
    \ "quit"    : "q",
    \ "next"    : "<C-J>",
    \ "prev"    : "<C-K>",
    \ "nfile"   : "<C-D>",
    \ "pfile"   : "<C-U>",
    \ "pquit"   : "q",
    \ "loclist" : "",
    \ "chgmode" : "M",
    \ "stop"    : "<C-C>",
    \ }
endf

func! s:SetVimSystemCopyMaps () abort 
  nmap zy <Plug>SystemCopy
  xmap zy <Plug>SystemCopy
  nmap zY <Plug>SystemCopyLine
  nmap zp <Plug>SystemPaste
  xmap zp <Plug>SystemPaste
  nmap zP <Plug>SystemPasteLine
endf

func! s:SetCtrlSFMaps () abort
  nmap     <C-M>f <Plug>CtrlSFPrompt
  vmap     <C-M>f <Plug>CtrlSFVwordPath
  vmap     <C-M>F <Plug>CtrlSFVwordExec
  nmap     <C-M>m <Plug>CtrlSFCwordPath
  nmap     <C-M>p <Plug>CtrlSFPwordPath
  nnoremap <C-M>o :CtrlSFOpen<CR>
  nnoremap <C-M>t :CtrlSFToggle<CR>
  inoremap <C-M>t <Esc>:CtrlSFToggle<CR>
endf
" func! s:SetVimVisualMulti () abort

" endf

