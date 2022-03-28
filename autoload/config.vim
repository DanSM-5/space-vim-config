
let s:mac = 'mac'
let s:windows = 'windows'
let s:linux = 'linux'

func! config#before() abort
  augroup userconfiles
    au!
    au BufNewFile,BufRead *.uconfrc,*.uconfgrc,*.ualiasrc,*.ualiasgrc setfiletype sh
  augroup END
  silent call s:Set_os_specific_before()
endf

func! config#after() abort
  silent call s:Set_user_bindings()
  silent call s:Set_os_specific_after()
endf

func! s:Set_user_bindings() abort
  nmap zy <Plug>SystemCopy
  xmap zy <Plug>SystemCopy
  nmap zY <Plug>SystemCopyLine
  nmap zp <Plug>SystemPaste
  xmap zp <Plug>SystemPaste
  nmap zP <Plug>SystemPasteLine
endf

func! s:Set_os_specific_before() abort
  let os = s:CurrentOS()
  if os == s:linux && system('pwsh.exe -nolo -nopro -nonin -c uname') =~ 'MSYS'
    " We are inside wsl
    silent call s:WSL_conf_before()
  elseif os == s:windows
    silent call s:Windows_conf_before()
  endif
endf

func! s:Set_os_specific_after() abort
  let os = s:CurrentOS()
  if os == s:linux && system('pwsh.exe -nolo -nopro -nonin -c uname') =~ 'MSYS'
    " We are inside wsl
    silent call s:WSL_conf_after()
  elseif os == s:windows
    silent call s:Windows_conf_after()
  endif
endf

function! s:CurrentOS()
  let os = substitute(system('uname'), '\n', '', '')
  let known_os = 'unknown'
  if has("gui_mac") || os ==? 'Darwin'
    let known_os = s:mac
  elseif has("gui_win32") || os =~? 'cygwin' || os =~? 'MINGW'
    let known_os = s:windows
  elseif os ==? 'Linux'
    let known_os = s:linux
  else
    exe "normal \<Esc>"
    throw "unknown OS: " . os
  endif
  return known_os
endfunction

func! s:Windows_conf_before() abort
  " Not implemented
endf

func! s:WSL_conf_before() abort
  " Not implemented
  " let g:spacevim_custom_plugins = [
  "   \ ['/home/linuxbrew/.linuxbrew/opt/fzf'],
  "   \ ]
endf

func! s:Windows_conf_after() abort
  " Set paste command with pwsh core
  let g:system_copy#paste_command = 'pwsh.exe -nolo -nopro -nonin -c "gcb"'
endf

func! s:WSL_conf_after() abort
  " Set copy and paste commands
  let g:system_copy#paste_command = 'pwsh.exe -nolo -nopro -nonin -c "gcb"'
  let g:system_copy#copy_command = 'pwsh.exe -nolo -nopro -nonin -c "clip"'
endf
