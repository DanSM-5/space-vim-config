
let s:mac = 'mac'
let s:windows = 'windows'
let s:linux = 'linux'
let s:termux = 'termux'
let s:wsl = 'wsl'
" if shell is powershell.exe, system calls will be utf16 files with BOM
let s:cleanrgx = '[\xFF\xFE\x01\r\n]'

let g:bash = '/usr/bin/bash'
let g:is_linux = 0
let g:is_wsl = 0
let g:is_gitbash = 0
let g:is_windows = 0
let g:is_mac = 0
let g:is_termux = 0

let g:host_os = 'unknown'


" General options
let s:rg_args = ' --column --line-number --no-ignore --no-heading --color=always --smart-case --hidden --glob "!.git" --glob "!node_modules" '
let s:bind_opts = ['--bind', 'ctrl-l:change-preview-window(down|hidden|),alt-up:preview-page-up,alt-down:preview-page-down']
let s:preview_opts = ['--layout=reverse', '--info=inline', '--preview', 'bat --color=always {}'] + s:bind_opts
let s:fzf_original_default_opts = $FZF_DEFAULT_OPTS
let g:bg_value = ''

" Options with only bind commands
let s:preview_options_bind = { 'options': s:bind_opts }
" let s:preview_options_bang_bind = { 'options': s:bind_opts }

" Options with bindings + preview
let s:preview_options_preview = {'options': s:preview_opts }
" let s:preview_options_bang_preview = { 'options': s:preview_opts }

" Test options for formationg window
" let g:fzf_preview_window = ['right:60%', 'ctrl-/']
" let s:preview_options_bind = { 'window': { 'width': 0.9, 'height': 0.6 } }
" let s:preview_options_bind = { 'window': { 'up': '60%' } }

" Uncomment for debug
" echo 'FZF default opts: ' . $FZF_DEFAULT_OPTS

" INFO: Original values before nvim 0.8.0+
" let s:preview_options = {'options': s:preview_opts }
" let s:preview_options_bind = { 'options': ['--preview-window=right,60%', '--height=80%'] + s:bind_opts }
" let s:preview_options_bind = { 'options': ['--preview-window=up,60%'] + s:bind_opts }
" let s:preview_options_bang_preview = { 'options': ['--preview-window=up,60%'] + s:preview_opts }

" WARNING: Error on nvim from 0.8.0+ with fzf and space vim
"
" Issue is related to set status line which fails if fzf args
" contain a '%' (e.g. '--preview-window=right,60%' or '--height=80%')
"
" The issue shows a the message 'Illegal character <'>'
" It fails first on SpaceVim#layers#core#statusline#get
" in shell.vim (see snippet below)
"
" function! s:on_term_open() abort
"   startinsert
"   let &l:statusline = SpaceVim#layers#core#statusline#get(1)
" endfunction
"
" If omitted, the error will occur in two places in fzf.vim (s:execute_term)
"
" First on 'call termopen(command, fzf)'
" Second on 'setf fzf'
"
" The parsing of '%' is somehow escaping one single quote (') breaking
" the string.
"
" The error is not present on windows (powershel, pwsh, gitbash)
" Error is reproducible in termux, linux, steamdeck, wsl and mac
" if both SapceVim and Fzf are used in neovim 0.8.0+
" It won't happen with an empty config
"
" Current workaound is to modify FZF_DEFAULT_OPTS when executing the commands
" as those will be applied by fzf itself and are not parsed by neovim

func! s:SetConfigurationsBefore () abort
  silent call s:SetCamelCaseMotion()
  silent call s:SetRG()
  silent call s:SetCtrlSFM()
  silent call s:DefineCommands()
endf

func! s:SetConfigurationsAfter () abort
  " Configure FZF
  silent call s:SetFZF()

  " Change cursor.
  if ! has('nvim') && ! has('gui_mac') && ! has('gui_win32')

    " Set up vertical vs block cursor for insert/normal mode
    if &term =~ "screen."
      let &t_ti.="\eP\e[1 q\e\\"
      let &t_SI.="\eP\e[5 q\e\\"
      let &t_EI.="\eP\e[1 q\e\\"
      let &t_te.="\eP\e[0 q\e\\"
    else
      let &t_ti.="\<Esc>[1 q"
      let &t_SI.="\<Esc>[5 q"
      let &t_EI.="\<Esc>[1 q"
      let &t_te.="\<Esc>[0 q"
    endif
  endif
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

  " Quick buffer overview an completion to change
  nnoremap gb :ls<CR>:b<Space>

  " Change to normal mode from terminal mode
  tnoremap <leader><Esc> <C-\><C-n>

  " Paste text override word under the cursor
  nmap <leader>v ciw<C-r>0<ESC>

  " Remove all trailing spaces in current buffer
  nnoremap <silent> <leader>c :%s/\s\+$//e<cr>

  " Move between buffers with tab
  nnoremap <silent> <tab> :bn<cr>
  nnoremap <silent> <s-tab> :bN<cr>
endf

func! s:FixCursorShapeOnExitNvim () abort
    augroup RestoreCursorShapeOnExit
      autocmd!
      autocmd VimLeave * set guicursor=a:ver100
    augroup END
endf

func! s:FixCursorShapeOnExitVim () abort
  " let &t_ti .= \e[2 q"
  " let &t_te .= \e[4 q"
  autocmd VimLeave * let &t_te="\e[?1049l\e[23;0;0t"
  autocmd VimLeave * let &t_ti="\e[?1049h\e[22;0;0t"
  autocmd VimLeave * silent !echo -ne "\e[5 q"
  " autocmd VimLeave * silent !echo -ne \033]112\007"
  " autocmd VimLeave * :!touch /tmp/vimleave
endf

func! s:Set_os_specific_before () abort
  let os = g:host_os
  if g:is_wsl
    " We are inside wsl
    silent call s:WSL_conf_before()
  elseif g:is_termux
    silent call s:Termux_conf_before()
  elseif os == s:windows
    silent call s:Windows_conf_before()
  elseif os == s:mac
    " silent call s:Mac_conf_before()
  endif
endf

func! s:Set_os_specific_after () abort
  let os = g:host_os
  if g:is_wsl
    " We are inside wsl
    silent call s:WSL_conf_after()
  elseif g:is_termux
    silent call s:Termux_conf_after()
  elseif os == s:windows
    silent call s:Windows_conf_after()
  elseif os == s:mac
    silent call s:Mac_conf_after()
  endif
endf

" **************  WINDOWS specific ********************
func! s:Windows_conf_before () abort
  " Set pwsh or powershell
  " exe 'set shell='.fnameescape("pwsh -ExecutionPolicy Bypass")
  " set shellcmdflag=-c
  set shell=cmd
  set shellcmdflag=/c

  if has("gui_running") || ! has('nvim')
    " Vim and Gvim requires additional escaping on \r\n
    let g:bash = substitute(system("where.exe bash | awk \"/[Gg]it/ {print}\" | tr -d \"\\r\\n\" "), '\n', '', '')
  else
    let g:bash = substitute(system("where.exe bash | awk \"/[Gg]it/ {print}\" | tr -d \"\r\n\" "), '\n', '', '')
  endif

  let g:python3_host_prog = '~/AppData/local/Programs/Python/Python3*/python.exe'
  " let g:python3_host_prog = '$HOME\AppData\Local\Programs\Python\Python*\python.exe'
endf

func! s:Windows_conf_after () abort
  " Set paste command with pwsh core
  let g:system_copy#paste_command = 'pbpaste.exe'
  let g:system_copy#copy_command = 'pbcopy.exe'

  if executable('tldr')
    set keywordprg=tldr
  endif

  if has("gui_win32")
    silent call s:MoveLinesBlockMapsGvim()
  else
    silent call s:MoveLinesBlockMapsWin()
  endif

  " Windows version of neovim won't set back the cursor shape
  if has('nvim')
    silent call s:FixCursorShapeOnExitNvim()
  endif
endf

" **************  WSL specific ********************
func! s:WSL_conf_before () abort
  if has('nvim')
    let g:python3_host_prog = 'python3'
  endif

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
  let g:system_copy#copy_command = 'pbcopy.exe'

  call clipboard#set(g:system_copy#copy_command, g:system_copy#paste_command)

  silent call s:MoveLinesBlockMapsLinux()

  if ! has('nvim') && ! has('gui_mac') && ! has('gui_win32')
    silent call s:FixCursorShapeOnExitVim()
  endif
endf

" **************  TERMUX specific ********************
func! s:Termux_conf_before () abort
  let g:rooter_change_directory_for_non_project_files = 'current'
  " let g:rooter_patterns = ["!.SpaceVim.d/", '".git/", '"/home/".$USER."/.SpaceVim.d"]

  " Prevent changing to .SpaceVim.d directory on /mnt/c/
  let g:spacevim_project_rooter_patterns = ["!.SpaceVim.d/"] + g:spacevim_project_rooter_patterns
  " Not implemented
  " let g:spacevim_custom_plugins = [
  "   \ ['/home/linuxbrew/.linuxbrew/opt/fzf'],
  "   \ ]
endf

func! s:Termux_conf_after () abort
  " Set copy and paste commands
  let g:system_copy#paste_command = 'termux-clipboard-get'
  let g:system_copy#copy_command = 'termux-clipboard-set'
  " silent call s:MoveLinesBlockMapsLinux()
endf

" **************  MAC specific ********************
func! s:Mac_conf_before () abort
  " Run before
endf

func! s:Mac_conf_after () abort
  if $TERM_PROGRAM =~? 'iTerm.app'
    " do not remap
  else
    silent call s:MoveLinesBlockMapsMac()
  endif
endf

func! s:CallCleanCommand (comm) abort
  return substitute(system(a:comm), '\', 'g', '\\')
endf

func! s:CleanCR () abort
  %s/\r//g
endf

func! s:SetCamelCaseMotion () abort
  let g:camelcasemotion_key = '<leader>'
endf

func! s:SetRG () abort
  if executable('rg')
    " In-built grep functionality
    set grepprg=rg\ --vimgrep\ --no-heading\ --smart-case\ --no-ignore\ --hidden\ -g\ '!.git'\ -g\ '!node_modules'
    set grepformat=%f:%l:%c:%m

    " For Ctrl-P plugin
    let g:crtlp_user_command = 'rg %s --no-ignore --hidden --files --color=never --glob "!.git" --glob "!node_modules" --follow'

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
      \ 'rg': '--hidden --glob "!.git" --glob "!node_modules"'
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

func! GetCurrentBufferPath () abort
  " NOTE: Git Bash and Git Zsh
  " fzf#vim#grep command will fail if '\' is not escaped
  " fzf#vim#files command will fail if '\' is escaped
  " Both functions work if '\' is replaced by '/'
  return substitute(trim(expand('%:p:h')), '\', '/', 'g')
  " return trim(expand('%:p:h'))
  " return trim(shellescape(expand('%:p:h')))
endf

func! GitPath () abort
  let gitpath = trim(system('cd '.shellescape(expand('%:p:h')).' && git rev-parse --show-toplevel'))
  " exe 'FZF ' . path
  " For debug
  " echohl String | echon 'Path: ' . gitpath | echohl None
  if isdirectory(gitpath)
    return gitpath
  else
    return GetCurrentBufferPath()
  endif
endf

func! s:RestoreFzfDefaultArgs (config) abort
  let $FZF_DEFAULT_OPTS = s:fzf_original_default_opts
  return a:config
endf

func! s:UpdateFzfDefaultArgs (config, set_up) abort
  if a:set_up
    let $FZF_DEFAULT_OPTS = s:fzf_original_default_opts . " --preview-window=up,60%"
  else
    let $FZF_DEFAULT_OPTS = s:fzf_original_default_opts . " --preview-window=right,60%"
  endif

  return a:config
endf

" func! s:GetFzfOptionsPreview (fullscreen) abort
"   if a:fullscreen
"     return s:UpdateFzfDefaultArgs(s:preview_options_bang_preview, a:fullscreen)
"   else
"     return s:UpdateFzfDefaultArgs(s:preview_options_preview, a:fullscreen)
"   endif
" endf

" func! s:GetFzfOptionsBind (fullscreen) abort
"   if a:fullscreen
"     return s:UpdateFzfDefaultArgs(s:preview_options_bang_bind, a:fullscreen)
"   else
"     return s:UpdateFzfDefaultArgs(s:preview_options_bind, a:fullscreen)
"   endif
" endf

function! s:FzfRgWindows_preview(spec, fullscreen) abort

  let bash_path = shellescape(substitute(g:bash, '\\', '/', 'g'))
  let preview_path = substitute('/c' . $HOMEPATH . '\.SpaceVim.d\utils\preview.sh', '\\', '/', 'g')
  let command_preview = bash_path . ' ' . preview_path . ' {}'

  " Keep for debugging
  " echo command_preview

  if has_key(a:spec, 'options')
    let a:spec.options = a:spec.options + ['--preview',  command_preview] + s:UpdateFzfDefaultArgs(s:bind_opts, a:fullscreen)
  else
    let a:spec.options = s:UpdateFzfDefaultArgs(s:preview_opts, a:fullscreen)
  endif

  return a:spec
endfunction

function! s:FzfRg_bindings(options) abort
  return a:options + s:bind_opts
endfunction

function! RipgrepFzf(query, fullscreen)
  let command_fmt = 'rg' . s:rg_args . '-- %s ' . GitPath() . ' || true'
  let initial_command = printf(command_fmt, shellescape(a:query))
  let reload_command = printf(command_fmt, '{q}')
  let spec = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command]}

  if g:is_windows
    let command_with_preview = s:FzfRgWindows_preview(spec, a:fullscreen)
  else
    let spec.options = s:FzfRg_bindings(spec.options)
    let command_with_preview = fzf#vim#with_preview(s:UpdateFzfDefaultArgs(spec, a:fullscreen))
  endif

  call fzf#vim#grep(initial_command, 1, command_with_preview, a:fullscreen)
endfunction

function! RipgrepFuzzy(query, fullscreen)
  let command_fmt = 'rg' . s:rg_args . '-- %s ' . GitPath()
  let initial_command = printf(command_fmt, shellescape(a:query))
  let reload_command = printf(command_fmt, '{q}')
  let spec = {'options': ['--query', a:query]}

  if g:is_windows
    call fzf#vim#grep(initial_command, 1, s:FzfRgWindows_preview(spec, a:fullscreen), a:fullscreen)
  else
    let spec.options = s:FzfRg_bindings(spec.options)
    call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview(s:UpdateFzfDefaultArgs(spec, a:fullscreen)), a:fullscreen)
  endif
endfunction

func! s:SetFZF () abort

  " command! -bang -nargs=* Rg
  "   \ call fzf#vim#grep(
  "   \   'rg' . s:rg_args . '-- ' . shellescape(<q-args>) . ' ' . GitPath(), 1,
  "   \   g:is_windows ? s:FzfRgWindows_preview({}, <bang>0) : fzf#vim#with_preview(), <bang>0)

  command! -nargs=* -bang RG call RipgrepFzf(<q-args>, <bang>0)

  command! -bang -nargs=? -complete=dir Files
    \ call fzf#vim#files(<q-args>, s:UpdateFzfDefaultArgs(s:preview_options_preview, <bang>0), <bang>0)

  if g:is_windows

    " command! -nargs=* -bang RG call RipgrepFzf(<q-args>, <bang>0)
    command! -nargs=* -bang Rg call RipgrepFuzzy(<q-args>, <bang>0)

    command! -bang -nargs=? -complete=dir FzfFiles
      \ call fzf#vim#files(<q-args>, s:UpdateFzfDefaultArgs(s:preview_options_preview, <bang>0), <bang>0)
    command! -bang -nargs=? -complete=dir GitFZF
      \ call fzf#vim#files(GitPath(), s:UpdateFzfDefaultArgs(s:preview_options_preview, <bang>0), <bang>0)

    if ! has('nvim')
      execute "set <M-p>=\ep"
    endif

  elseif g:is_termux

    command! -nargs=* -bang Rg call RipgrepFuzzy(<q-args>, <bang>0)

    command! -bang -nargs=? -complete=dir FzfFiles
      \ call fzf#vim#files(<q-args>, s:UpdateFzfDefaultArgs(s:preview_options_preview, <bang>0), <bang>0)
    command! -bang -nargs=? -complete=dir GitFZF
      \ call fzf#vim#files(GitPath(), s:UpdateFzfDefaultArgs(s:preview_options_preview, <bang>0), <bang>0)

    if ! has('nvim')
      execute "set <M-p>=\ep"
    endif

  elseif g:is_mac

    command! -bang -nargs=? -complete=dir FzfFiles
      \ call fzf#vim#files(<q-args>, fzf#vim#with_preview(s:UpdateFzfDefaultArgs(s:preview_options_bind, <bang>0)), <bang>0)
    command! -bang -nargs=? -complete=dir GitFZF
      \ call fzf#vim#files(GitPath(), fzf#vim#with_preview(s:UpdateFzfDefaultArgs(s:preview_options_bind, <bang>0)), <bang>0)

    command! -bang -nargs=* Rg
      \ call fzf#vim#grep(
      \   'rg' . s:rg_args . '-- ' . shellescape(<q-args>) . ' ' . GitPath(), 1,
      \   fzf#vim#with_preview(s:UpdateFzfDefaultArgs(s:preview_options_bind, <bang>0)), <bang>0)

    if ! has('nvim')
      execute "set <M-p>=π"
    endif

  else
    " Linux
    command! -bang -nargs=? -complete=dir FzfFiles
      \ call fzf#vim#files(<q-args>, fzf#vim#with_preview(s:UpdateFzfDefaultArgs(s:preview_options_bind, <bang>0)), <bang>0)
    command! -bang -nargs=? -complete=dir GitFZF
      \ call fzf#vim#files(GitPath(), fzf#vim#with_preview(s:UpdateFzfDefaultArgs(s:preview_options_bind, <bang>0)), <bang>0)

    command! -bang -nargs=* Rg
      \ call fzf#vim#grep(
      \   'rg' . s:rg_args . '-- ' . shellescape(<q-args>) . ' ' . GitPath(), 1,
      \   fzf#vim#with_preview(s:UpdateFzfDefaultArgs(s:preview_options_bind, <bang>0)), <bang>0)

    if ! has('nvim')
      execute "set <M-p>=\ep"
    endif

    " else
    " command! -bang -nargs=? -complete=dir FzfFiles
    "       \ call fzf#vim#files(<q-args>, <bang>0 ? s:preview_options_bind : s:preview_options_preview, <bang>0)
    " command! -bang -nargs=? -complete=dir GitFZF
    "       \ call fzf#vim#files(GitPath(), fzf#vim#with_preview(<bang>0 ? s:preview_options_bind : s:preview_options_preview), <bang>0)

  endif


  " Set key mappings
  nnoremap <A-p> :GitFZF!<CR>
  nnoremap <C-P> :GitFZF<CR>
endf

func! s:SetVimSystemCopyMaps () abort
  source ~/.SpaceVim.d/utils/system-copy-maps.vim
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

func! s:DefineCommands () abort
  " Define user commands
  command! -nargs=1 -complete=shellcmd CallCleanCommand call s:CallCleanCommand(<f-args>)
  command! CleanCR call s:CleanCR()

  " Set toggle background to transparent by default and mapping and function
  " to toggle it.
  command! ToggleBg call s:ToggleBg()
  nnoremap <silent><leader>tb :ToggleBg<CR>
  autocmd vimenter * let g:bg_value = substitute(trim(execute("hi Normal")), 'xxx', '', 'g')
  autocmd vimenter * ToggleBg
endf

func! s:RemapAltUpDownNormal () abort
  " move selected lines up one line
  xnoremap <silent><A-Up> :m-2<CR>gv=gv

  " move selected lines down one line
  xnoremap <silent><A-Down> :m'>+<CR>gv=gv

  " move current line up one line
  noremap <silent><A-Up> :<C-u>m-2<CR>==

  " move current line down one line
  nnoremap <silent><A-Down> :<C-u>m+<CR>==

  " move current line up in insert mode
  inoremap <silent><A-Up> <Esc>:m .-2<CR>==gi

  " move current line down in insert mode
  inoremap <silent><A-Down> <Esc>:m .+1<CR>==gi
endf

func! s:RemapAltUpDownSpecial () abort
  " move selected lines up one line
  xnoremap <silent><Esc>[1;3A :m-2<CR>gv=gv

  " move selected lines down one line
  xnoremap <silent><Esc>[1;3B :m'>+<CR>gv=gv

  " move current line up one line
  nnoremap <silent><Esc>[1;3A :<C-u>m-2<CR>==

  " move current line down one line
  nnoremap <silent><Esc>[1;3B :<C-u>m+<CR>==

  " move current line up in insert mode
  inoremap <silent><Esc>[1;3A <Esc>:m .-2<CR>==gi

  " move current line down in insert mode
  inoremap <silent><Esc>[1;3B <Esc>:m .+1<CR>==gi
endf

func! s:RemapAltUpDownJK () abort
  " move selected lines up one line
  xnoremap <silent><C-K> :m-2<CR>gv=gv

  " move selected lines down one line
  xnoremap <silent><C-J> :m'>+<CR>gv=gv

  " move current line up one line
  nnoremap <silent><C-K> :<C-u>m-2<CR>==

  " move current line down one line
  nnoremap <silent><C-J> :<C-u>m+<CR>==

  " move current line up in insert mode
  inoremap <silent><C-K> <Esc>:m .-2<CR>==gi

  " move current line down in insert mode
  inoremap <silent><C-J> <Esc>:m .+1<CR>==gi
endf

func! s:RemapVisualMultiUpDown () abort
  " Map usual <C-Up> <C-Down> to <C-y> and <C-h> for use in vim windows
  nmap <C-y> <Plug>(VM-Select-Cursor-Up)
  nmap <C-h> <Plug>(VM-Select-Cursor-Down)

  " Other ways to remap
  " let g:VM_custom_remaps = { '<C-h>': 'Up', '<C-H>': 'Down' }
  " let g:VM_maps = { 'Select Cursor Down': '<C-h>', 'Select Cursor Up': '<C-y>' }
  " let g:VM_maps["Select Cursor Down"] = '<C-h>'
  " let g:VM_maps["Select Cursor Up"]   = '<C-H>'
endf

func! s:MoveLinesBlockMapsWin () abort
  if has('nvim')
    silent call s:RemapAltUpDownNormal()

    Repeatable nnoremap <silent>mlu :<C-U>m-2<CR>==
    Repeatable nnoremap <silent>mld :<C-U>m+<CR>==
  else
    silent call s:RemapAltUpDownJK()
    silent call s:RemapVisualMultiUpDown()

    " TODO: Verify unreachable block below
    if ! g:host_os ==? s:windows
      Repeatable nnoremap <silent>mlu :<C-U>m-2<CR>==
      Repeatable nnoremap <silent>mld :<C-U>m+<CR>==
    endif
  endif

endf

func! s:MoveLinesBlockMapsLinux () abort
  " Allow motion mlu/d
  Repeatable nnoremap <silent>mlu :<C-U>m-2<CR>==
  Repeatable nnoremap <silent>mld :<C-U>m+<CR>==

  " <A-UP> | <Esc>[1;3A
  " <A-Down> | <Esc>[1;3B
  if has('nvim')
    silent call s:RemapAltUpDownNormal()
  else
    silent call s:RemapAltUpDownSpecial()
  endif
endf

func! s:MoveLinesBlockMapsGvim () abort
  " Allow motion mlu/d
  Repeatable nnoremap <silent>mlu :<C-U>m-2<CR>==
  Repeatable nnoremap <silent>mld :<C-U>m+<CR>==

  silent call s:RemapAltUpDownNormal()
endf

func! s:MoveLinesBlockMapsMac () abort
  " Allow motion mlu/d
  Repeatable nnoremap <silent>mlu :<C-U>m-2<CR>==
  Repeatable nnoremap <silent>mld :<C-U>m+<CR>==

  " Not needed remap on regular vim
  if has('nvim')
    silent call s:RemapAltUpDownNormal()
  endif
endf

func s:SetUndodir () abort
  if has('nvim')
    set undodir=~/.config/nvim/undodir
  else
    set undodir=~/.vim/undodir
  endif
endf

function! g:CurrentOS ()
  if has('win32')
    set shell=cmd
    set shellcmdflag=/c
  endif

  let os = substitute(system('uname'), '\n', '', '')
  let known_os = 'unknown'

  " Remove annoying error log for MSYS bash and zsh on start (uname not
  " available)
  " echo ''
  if has("gui_mac") || os ==? 'Darwin'
    let g:is_mac = 1
    let known_os = s:mac
  " Gitbash and Msys zsh does not report ming on first run
  elseif os =~? 'cygwin' || os =~? 'MINGW' || os =~? 'MSYS' || $IS_GITBASH == 'true'
    let g:is_windows = 1
    let g:is_gitbash = 1
    let known_os = s:windows
  elseif has('win32') || has("gui_win32")
    let g:is_windows = 1
    let known_os = s:windows
  elseif os ==? 'Linux'
    let known_os = s:linux
    if has('wsl') || system('cat /proc/version') =~ '[Mm]icrosoft'
      let g:is_wsl = 1
    elseif $IS_TERMUX =~ 'true'
      " Don't want to relay on config settings but it will do for now
      " untested way: command -v termux-setup-storage &> /dev/null
      " the termux-setup-storage should only exist on termux
      let g:is_termux = 1
    endif
  else
    exe "normal \<Esc>"
    throw "unknown OS: " . os
  endif

  return known_os
endfunction

func! s:ToggleBg ()
  let highlight_value = execute('hi Normal')
  let ctermbg_value = matchstr(highlight_value, 'ctermbg=\zs\S*')
  let guibg_value = matchstr(highlight_value, 'guibg=\zs\S*')

  if ctermbg_value == '' && guibg_value ==? ''
    silent execute('hi ' . g:bg_value)
  else
    silent execute('hi Normal guibg=NONE ctermbg=NONE')
  endif
endfunction

" Ensure command
let g:host_os = g:CurrentOS()

func! config#before () abort
  " Can be used to set different undodir between vim and nvim
  " silent call s:SetUndodir()
  silent call s:Set_os_specific_before()
  silent call s:SetBufferOptions()
  silent call s:SetConfigurationsBefore()
endf

func! config#after () abort
  silent call s:Set_user_bindings()
  silent call s:Set_os_specific_after()
  silent call s:SetConfigurationsAfter()
endf
