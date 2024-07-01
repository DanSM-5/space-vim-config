
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
let s:fzf_base_options = [ '--multi', '--ansi', '--info=inline', '--bind', 'alt-c:clear-query' ]
let s:fzf_bind_options = s:fzf_base_options + ['--bind', 'ctrl-l:change-preview-window(down|hidden|),ctrl-/:change-preview-window(down|hidden|),alt-up:preview-page-up,alt-down:preview-page-down', '--bind', 'ctrl-s:toggle-sort',
      \                                        '--cycle',
      \                                        '--bind', 'alt-f:first',
      \                                        '--bind', 'alt-l:last',
      \                                        '--bind', 'alt-a:select-all',
      \                                        '--bind', 'alt-d:deselect-all']
let s:fzf_preview_options = ['--layout=reverse', '--preview', 'bat -pp --color=always --style=numbers {}'] + s:fzf_bind_options
let s:fzf_original_default_opts = $FZF_DEFAULT_OPTS
let g:bg_value = ''

" Options with only bind commands
let s:fzf_options_with_binds = { 'options': s:fzf_bind_options }
" let s:preview_options_bang_bind = { 'options': s:fzf_bind_options }

" Options with bindings + preview
let s:fzf_options_with_preview = {'options': s:fzf_preview_options }
" let s:preview_options_bang_preview = { 'options': s:fzf_preview_options }

" Test options for formationg window
" let g:fzf_preview_window = ['right:60%', 'ctrl-/']
" let s:fzf_options_with_binds = { 'window': { 'width': 0.9, 'height': 0.6 } }
" let s:fzf_options_with_binds = { 'window': { 'up': '60%' } }

" Uncomment for debug
" echo 'FZF default opts: ' . $FZF_DEFAULT_OPTS

" INFO: Original values before nvim 0.8.0+
" let s:preview_options = {'options': s:fzf_preview_options }
" let s:fzf_options_with_binds = { 'options': ['--preview-window=right,60%', '--height=80%'] + s:fzf_bind_options }
" let s:fzf_options_with_binds = { 'options': ['--preview-window=up,60%'] + s:fzf_bind_options }
" let s:preview_options_bang_preview = { 'options': ['--preview-window=up,60%'] + s:fzf_preview_options }

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

  " Filter quickfix with :Cfilter :Lfilter
  autocmd QuickFixCmdPost *grep* cwindow
  packadd cfilter

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

func! s:Set_user_keybindings () abort
  silent call s:SetVimSystemCopyMaps()
  silent call s:SetCtrlSFMaps()

  " Quick buffer overview an completion to change
  nnoremap gb :ls<CR>:b<Space>

  " Change to normal mode from terminal mode
  tnoremap <leader><Esc> <C-\><C-n>

  " Clean carriage returns '^M'
  nnoremap <silent> <Leader>r :%s/\r$//g<cr>

  " Paste text override word under the cursor
  nmap <leader>v ciw<C-r>0<ESC>

  " Remove all trailing spaces in current buffer
  nnoremap <silent> <leader>c :%s/\s\+$//e<cr>

  " Move between buffers with tab
  nnoremap <silent> <tab> :bn<cr>
  nnoremap <silent> <s-tab> :bN<cr>

  " vim-asterisk
  let g:asterisk#keeppos = 1
  map *   <Plug>(asterisk-*)
  map #   <Plug>(asterisk-#)
  map g*  <Plug>(asterisk-g*)
  map g#  <Plug>(asterisk-g#)
  map z*  <Plug>(asterisk-z*)
  map gz* <Plug>(asterisk-gz*)
  map z#  <Plug>(asterisk-z#)
  map gz# <Plug>(asterisk-gz#)

  " Set stay behavior by default
  " map *  <Plug>(asterisk-z*)
  " map #  <Plug>(asterisk-z#)
  " map g* <Plug>(asterisk-gz*)
  " map g# <Plug>(asterisk-gz#)

  " Command mode open in buffer ctrl+e
  cnoremap <C-e> <C-f>
  " Command mode open in buffer leader+t+e from normal mode
  nnoremap <Leader>te q:
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
  elseif g:is_linux
    silent call s:Linux_conf_before()
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
  elseif g:is_linux
    silent call s:Linux_conf_after()
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

  let g:bash = substitute(system('where.exe bash | awk "/[Gg]it/ {print}" | tr -d "\r\n"'), '\n', '', '')
  " if has("gui_running") || ! has('nvim')
  "   " Vim and Gvim requires additional escaping on \r\n
  "   let g:bash = substitute(system('where.exe bash | awk '"/[Gg]it/ {print}" | tr -d '"\r\n"'), '\n', '', '')
  "   let g:bash = substitute(system("where.exe bash | awk \"/[Gg]it/ {print}\" | tr -d \"\\r\\n\" "), '\n', '', '')
  " else
  "   let g:bash = substitute(system("where.exe bash | awk \"/[Gg]it/ {print}\" | tr -d \"\r\n\" "), '\n', '', '')
  " endif

  if g:is_gitbash
    let g:fzf_vim.preview_bash = substitute(s:WindowsShortPath(g:bash), '\', '/', 'g')
  else
    let g:fzf_vim.preview_bash = s:WindowsShortPath(g:bash)
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
  if $IS_WSL1 == 'true'
    " Set copy and paste commands
    let g:system_copy#paste_command = 'pbpaste.exe'
    let g:system_copy#copy_command = 'pbcopy.exe'

    call clipboard#set(g:system_copy#copy_command, g:system_copy#paste_command)
  elseif !empty($DISPLAY) && executable('xsel')
    let g:system_copy#copy_command = 'xsel -i -b'
    let g:system_copy#paste_command = 'xsel -o -b'
  elseif !empty($DISPLAY) && executable('xclip')
    let g:system_copy#copy_command = 'xclip -i -selection clipboard'
    let g:system_copy#paste_command = 'xclip -o -selection clipboard'
  elseif !empty($WAYLAND_DISPLAY) && executable('wl-copy') && executable('wl-paste')
    let g:system_copy#copy_command = 'wl-copy --foreground --type text/plain'
    let g:system_copy#paste_command = 'wl-paste --no-newline'
  elseif executable('pbpaste.exe')
    let g:system_copy#paste_command = 'pbpaste.exe'
    let g:system_copy#copy_command = 'pbcopy.exe'

    call clipboard#set(g:system_copy#copy_command, g:system_copy#paste_command)
  else
    let g:system_copy#paste_command = 'pwsh.exe -NoLogo -NonInteractive -NoProfile -Command Get-Clipboard'
    let g:system_copy#copy_command = 'pwsh.exe -NoLogo -NonInteractive -NoProfile -Command Set-Clipboard'
  endif

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

  if has('nvim')
    let g:python3_host_prog = 'python3'
  endif
endf

func! s:Termux_conf_after () abort
  " Set copy and paste commands
  let g:system_copy#paste_command = 'termux-clipboard-get'
  let g:system_copy#copy_command = 'termux-clipboard-set'
  " silent call s:MoveLinesBlockMapsLinux()
endf

" **************  LINUX specific ********************
func! s:Linux_conf_before () abort
  if has('nvim')
    let g:python3_host_prog = 'python3'
  endif

  let g:rooter_change_directory_for_non_project_files = 'current'
endf

func! s:Linux_conf_after () abort
  " Run after
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
"     return s:UpdateFzfDefaultArgs(s:fzf_options_with_preview, a:fullscreen)
"   endif
" endf

" func! s:GetFzfOptionsBind (fullscreen) abort
"   if a:fullscreen
"     return s:UpdateFzfDefaultArgs(s:preview_options_bang_bind, a:fullscreen)
"   else
"     return s:UpdateFzfDefaultArgs(s:fzf_options_with_binds, a:fullscreen)
"   endif
" endf

function! s:Fzf_vim_files(query, options, fullscreen) abort
  let spec = fzf#vim#with_preview({ 'options': [] }, a:fullscreen)
  " Append options after to get better keybindings for 'ctrl-/'
  let spec.options = spec.options + a:options

  try
    call s:UpdateFzfDefaultArgs({}, a:fullscreen)
    call fzf#vim#files(a:query, spec, a:fullscreen)
  finally
    call s:RestoreFzfDefaultArgs({})
  endtry
endfunction

function! s:FzfSelectedList(list) abort
  if len(a:list) == 0
    echo a:list
    return
  else
    if isdirectory(a:list[0])
      " Use first selected directory only!
      call s:Fzf_vim_files(a:list[0], s:fzf_preview_options, 0)
    elseif !empty(glob(a:list[0])) " Is file
      " Open multiple files
      for sfile in a:list
        exec ':e ' . sfile
      endfor
    endif
  endif
endfunction

function! s:WindowsShortPath(path) abort
  " From fzf.vim
  " Changes paths like 'C:/Program Files' that have spaces into C:/PROGRA~1
  " which is nicer as we avoid escaping
  return split(system('for %A in ("'. a:path .'") do @echo %~sA'), "\n")[0]
endfunction

function! FzfChangeProject() abort
  let user_conf_path = substitute($user_conf_path, '\\', '/', 'g')
  let preview = user_conf_path . '/utils/fzf-preview.sh {}'
  let getprojects = user_conf_path . '/utils/getprojects'
  let reload_command = getprojects
  let files_command = "fd --type file --color=always --no-ignore --hidden --exclude node_modules --exclude .git "

  " NOTE: Windows only block
  " The below if handles the function when called from powershell (pwsh)
  " And bash/zsh from MINGW (git bash)
  if g:is_windows
    " Get env.exe from gitbash
    let gitenv = substitute(system('where.exe env | awk "/[Gg]it/ {print}" | tr -d "\r\n"'), '\n', '', '')
    let gitenv = s:WindowsShortPath(gitenv)
    let gitenv = shellescape(substitute(gitenv, '\\', '/', 'g'))
    let bash = substitute(s:WindowsShortPath(g:bash), '\\', '/', 'g')
    let preview = bash . ' ' . preview
    " Hack to run a bash script without adding -l or -i flags (faster)
    let getprojects = ' MSYS=enable_pcon MSYSTEM=MINGW64 enable_pcon=1 SHELL=/usr/bin/bash /usr/bin/bash -c "export PATH=/mingw64/bin:/usr/local/bin:/usr/bin:/bin:$PATH; export user_conf_path=' . user_conf_path . '; ' . getprojects . '"'

    " Subtle differences between git bash and powershell
    if $IS_GITBASH == 'true'
      " Update reload_command (can call script directly)
      let reload_command = 'user_conf_path=' . user_conf_path . ' ' . reload_command
      let getprojects = gitenv . getprojects
    else
      let home = substitute($USERPROFILE, '\\', '/', 'g')
      " Set get getprojects, then update reload_command
      let getprojects = gitenv . ' HOME=' . home . getprojects
      let reload_command = getprojects
      " Use fortward slash (/) as path separator if called from powershell
      " It is not needed for gitbash (it breaks).
      let files_command = files_command . ' --path-separator "/"'
    endif
  endif

  " Notice ctrl-d doesn't work on Windows nvim
  let spec = {
    \   'sinklist': function('s:FzfSelectedList'),
    \   'source': getprojects,
    \   'options': [
    \     '--prompt', 'Projs> ',
    \     '--no-multi', '--ansi',
    \     '--layout=reverse',
    \     '--bind', 'ctrl-f:change-prompt(Files> )+reload(' . files_command . ' . {})+clear-query+change-multi+unbind(ctrl-f)',
    \     '--bind', 'ctrl-r:change-prompt(Projs> )+reload(' . reload_command . ')+rebind(ctrl-f)+clear-query+change-multi(0)',
    \     '--preview', preview]
    \ }

  let spec.options = s:fzf_bind_options + spec.options

  " Hope for the best
  call fzf#run(fzf#wrap(spec))
endfunction

function! s:FzfRgWindows_preview(spec, fullscreen) abort

  let bash_path = shellescape(substitute(g:bash, '\\', '/', 'g'))
  let preview_path = substitute('/c' . $HOMEPATH . '\.SpaceVim.d\utils\preview.sh', '\\', '/', 'g')
  let command_preview = bash_path . ' ' . preview_path . ' {}'

  " Keep for debugging
  " echo command_preview

  if has_key(a:spec, 'options')
    let a:spec.options = a:spec.options + ['--preview',  command_preview] + s:UpdateFzfDefaultArgs(s:fzf_bind_options, a:fullscreen)
  else
    let a:spec.options = s:UpdateFzfDefaultArgs(s:fzf_preview_options, a:fullscreen)
  endif

  return a:spec
endfunction

function! s:FzfRg_bindings(options) abort
  return a:options + s:fzf_bind_options
endfunction

function! RipgrepFzf(query, fullscreen)
  let fzf_rg_args = s:rg_args

  " if g:is_windows
    " let s:rg_args = ' --column --line-number --no-ignore --no-heading --color=always --smart-case --hidden --glob="!.git" --glob="!node_modules" '
    " let fzf_rg_args = ' --glob="!.git" --glob="!node_modules" --column --line-number --no-ignore --no-heading --color=always --smart-case --hidden '
  " endif

  let command_fmt = 'rg' . fzf_rg_args . '-- %s || true'
  let initial_command = printf(command_fmt, fzf#shellescape(a:query))
  let reload_command = printf(command_fmt, '{q}')
  let spec = {
        \     'options': ['--disabled', '--query', a:query,
        \                 '--ansi', '--prompt', 'RG> ',
        \                 '--multi', '--delimiter', ':', '--preview-window', '+{2}-/2',
        \                 '--bind', 'start:reload:'.initial_command,
        \                 '--bind', 'change:reload:'.reload_command]
        \}

  " TODO: From fzf.vim
  " The g:fzf_vim dictionary can be used to alter the behavior of the
  " preview
  " let g:fzf_vim.preview_bash = 'C:\Git\bin\bash.exe' " for setting gitbash
  " let g:fzf_vim.preview_window = ['hidden,right,50%,<70(up,40%)', 'ctrl-/']
  "
  " Consider using this instead of changing FZF_DEFAULT_OPTS environment
  " variable
  " let g:fzf_vim = {}
  " let g:fzf_vim.preview_window = ['right,80%', 'ctrl-/']
  " let g:fzf_vim.preview_bash = g:bash

  if g:is_windows
    let spec = s:FzfRgWindows_preview(spec, a:fullscreen)
  else
    let spec = fzf#vim#with_preview(s:UpdateFzfDefaultArgs(spec, a:fullscreen))
    let spec.options = spec.options + s:fzf_bind_options
  endif

  " fzf.vim examples
  " call fzf#vim#grep2("rg --column --line-number --no-heading --color=always --smart-case -- ", <q-args>, fzf#vim#with_preview(), <bang>0)
  " call fzf#vim#grep2("rg --column --line-number --no-heading --color=always --smart-case -- ", a:query, fzf#vim#with_preview(), a:fullscreen)

  let curr_path = getcwd()
  let gitpath = GitPath()

  try
    " Change path to get relative 'short' paths in the fzf search
    exec 'cd '. gitpath
    " NOTE: the first argument is not needed. It is overriden by the options
    " (third argument)
    call fzf#vim#grep2("echo loading ", a:query, spec, a:fullscreen)
  finally
    exec 'cd '. curr_path
    call s:RestoreFzfDefaultArgs({})
  endtry
endfunction

function! RipgrepFuzzy(query, fullscreen)
  let command_fmt = 'rg' . s:rg_args . '-- %s || true'
  let initial_command = printf(command_fmt, shellescape(a:query))
  " Hide query for now
  " let spec = {'options': ['--query', a:query]}
  let spec = {'options': []}

  " Change path to get relative 'short' paths in the fzf search
  let curr_path = getcwd()
  let gitpath = GitPath()

  try
    exec 'cd '. gitpath

    if g:is_windows
      let spec = s:FzfRgWindows_preview(spec, a:fullscreen)
    else
      " let spec.options = s:FzfRg_bindings(spec.options)
      " call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview(s:UpdateFzfDefaultArgs(spec, a:fullscreen)), a:fullscreen)
      let spec = fzf#vim#with_preview(s:UpdateFzfDefaultArgs(spec, a:fullscreen))
      let spec.options = spec.options + s:fzf_bind_options
    endif

    call fzf#vim#grep(initial_command, spec, a:fullscreen)
  finally
    exec 'cd '. curr_path
    call s:RestoreFzfDefaultArgs({})
  endtry
endfunction

func! s:SetFZF () abort

  " command! -bang -nargs=* Rg
  "   \ call fzf#vim#grep(
  "   \   'rg' . s:rg_args . '-- ' . shellescape(<q-args>) . ' ' . GitPath(), 1,
  "   \   g:is_windows ? s:FzfRgWindows_preview({}, <bang>0) : fzf#vim#with_preview(), <bang>0)

  command! -nargs=* CPrj call FzfChangeProject()
  command! -nargs=* -bang RG call RipgrepFzf(<q-args>, <bang>0)
  command! -nargs=* -bang Rg call RipgrepFuzzy(<q-args>, <bang>0)

  command! -bang -nargs=? -complete=dir Files
    \ call s:Fzf_vim_files(<q-args>, s:fzf_preview_options, <bang>0)

  if g:is_windows

    " command! -nargs=* -bang RG call RipgrepFzf(<q-args>, <bang>0)
    " command! -nargs=* -bang Rg call RipgrepFuzzy(<q-args>, <bang>0)

    command! -bang -nargs=? -complete=dir FzfFiles
      \ call s:Fzf_vim_files(<q-args>, s:fzf_preview_options, <bang>0)
    command! -bang -nargs=? -complete=dir GitFZF
      \ call s:Fzf_vim_files(GitPath(), s:fzf_preview_options, <bang>0)

    if ! has('nvim')
      execute "set <M-p>=\ep"
    endif

  elseif g:is_termux

    " command! -nargs=* -bang Rg call RipgrepFuzzy(<q-args>, <bang>0)

    command! -bang -nargs=? -complete=dir FzfFiles
      \ call s:Fzf_vim_files(<q-args>, s:fzf_preview_options, <bang>0)
    command! -bang -nargs=? -complete=dir GitFZF
      \ call s:Fzf_vim_files(GitPath(), s:fzf_preview_options, <bang>0)

    if ! has('nvim')
      execute "set <M-p>=\ep"
    endif

  elseif g:is_mac

    command! -bang -nargs=? -complete=dir FzfFiles
      \ call s:Fzf_vim_files(<q-args>, s:fzf_bind_options, <bang>0)
    command! -bang -nargs=? -complete=dir GitFZF
      \ call s:Fzf_vim_files(GitPath(), s:fzf_bind_options, <bang>0)

    " command! -bang -nargs=* Rg
    "   \ call fzf#vim#grep(
    "   \   'rg' . s:rg_args . '-- ' . shellescape(<q-args>) . ' ' . GitPath(), 1,
    "   \   fzf#vim#with_preview(s:UpdateFzfDefaultArgs(s:fzf_options_with_binds, <bang>0)), <bang>0)

    if ! has('nvim')
      execute "set <M-p>=π"
    endif

  else
    " Linux
    command! -bang -nargs=? -complete=dir FzfFiles
      \ call s:Fzf_vim_files(<q-args>, s:fzf_bind_options, <bang>0)
    command! -bang -nargs=? -complete=dir GitFZF
      \ call s:Fzf_vim_files(GitPath(), s:fzf_bind_options, <bang>0)

    " command! -bang -nargs=* Rg
    "   \ call fzf#vim#grep(
    "   \   'rg' . s:rg_args . '-- ' . shellescape(<q-args>) . ' ' . GitPath(), 1,
    "   \   fzf#vim#with_preview(s:UpdateFzfDefaultArgs(s:fzf_options_with_binds, <bang>0)), <bang>0)

    if ! has('nvim')
      execute "set <M-p>=\ep"
    endif

    " else
    " command! -bang -nargs=? -complete=dir FzfFiles
    "       \ call fzf#vim#files(<q-args>, <bang>0 ? s:fzf_options_with_binds : s:fzf_options_with_preview, <bang>0)
    " command! -bang -nargs=? -complete=dir GitFZF
    "       \ call fzf#vim#files(GitPath(), fzf#vim#with_preview(<bang>0 ? s:fzf_options_with_binds : s:fzf_options_with_preview), <bang>0)

  endif


  " Set key mappings
  nnoremap <A-p> :GitFZF!<CR>
  nnoremap <C-P> :GitFZF<CR>
  nnoremap <C-o>p :CPrj<CR>
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

  command! SetTab call s:SetTab()
  nnoremap <silent><leader>st :SetTab<CR>
  " NOTE: if needed uncomment next line
  " but I should check if I can force always 2 spaces for indent
  " with SpaceVim built-ins
  " autocmd vimenter * SetTab

  " Use lf to select files to open in vim
  " NOTE: It does not work on nvim
  command! -bar LF call LF()
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
  " TODO: Fix windows falling in this detection
  " Gitbash and Msys zsh does not report ming on first run
  elseif os =~? 'cygwin' || os =~? 'MINGW' || os =~? 'MSYS' || $IS_GITBASH == 'true'
    if $IS_POWERSHELL == 'true' || $IS_CMD == 'true'
      let g:is_gitbash = 0
    else
      let g:is_gitbash = 1
    endif

    let g:is_windows = 1
    let known_os = s:windows
  elseif has('win32') || has("gui_win32")
    let g:is_windows = 1
    let known_os = s:windows
  elseif os ==? 'Linux'
    let known_os = s:linux
    let g:is_linux = 1
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

function s:SetTab ()
  set tabstop=2 softtabstop=2 shiftwidth=2
  set expandtab
  " set number ruler
  " set autoindent smartindent
  " syntax enable
  filetype plugin indent on
endfunction

function! LF()
  if has('nvim')
    echo 'Cannot open in nvim'
    return
  endif
  let temp = tempname()
  exec 'silent !lf -selection-path=' . shellescape(temp)
  if !filereadable(temp)
    redraw!
    return
  endif
  let names = readfile(temp)
  if empty(names)
    redraw!
    return
  endif
  exec 'edit ' . fnameescape(names[0])
  for name in names[1:]
    exec 'argadd ' . fnameescape(name)
  endfor
  redraw!
endfunction

" Ensure command
let g:host_os = g:CurrentOS()

func! config#before () abort
  " Can be used to set different undodir between vim and nvim
  " silent call s:SetUndodir()

  " Fzf configs
  let g:fzf_vim = {}

  silent call s:Set_os_specific_before()
  silent call s:SetBufferOptions()
  silent call s:SetConfigurationsBefore()
endf

func! config#after () abort
  silent call s:Set_user_keybindings()
  silent call s:Set_os_specific_after()
  silent call s:SetConfigurationsAfter()
  " Add to force 2 spaces with tab
  " filetype plugin indent on
  " " On pressing tab, insert 2 spaces
  " set expandtab
  " " show existing tab with 2 spaces width
  " set tabstop=2
  " set softtabstop=2
  " " when indenting with '>', use 2 spaces width
  " set shiftwidth=2
endf

