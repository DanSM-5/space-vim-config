" Add utility clipboard functions

function! s:set_command() abort
  let yank = ''
  let paste = ''

  " the logic is based on nvim's clipboard provider

  " in vim8, system() do not support list argv

  if $IS_WINDOWS == 'true'
    let yank = 'pbcopy.exe'
    let paste = 'pbpaste.exe'
  endif

  return [yank, paste]
endfunction

" yank to system clipboard
function! clipboard#yank() abort
  if !empty(s:yank_cmd)
    call system(s:yank_cmd, s:get_selection_text())
  else
    if has('clipboard')
      let @+ = s:get_selection_text()
    else
    endif
  endif
endfunction


" The mode can be `p` or `P`
function! clipboard#paste(mode) abort
  if !empty(s:paste_cmd)
    let @" = system(s:paste_cmd)
  else
    if has('clipboard')
      let @" = @+
    else
    endif
  endif
  return a:mode
endfunction


function! s:get_selection_text()
  let [begin, end] = [getpos("'<"), getpos("'>")]
  let lastchar = matchstr(getline(end[1])[end[2]-1 :], '.')
  if begin[1] ==# end[1]
    let lines = [getline(begin[1])[begin[2]-1 : end[2]-2]]
  else
    let lines = [getline(begin[1])[begin[2]-1 :]]
          \         + (end[1] - begin[1] <# 2 ? [] : getline(begin[1]+1, end[1]-1))
          \         + [getline(end[1])[: end[2]-2]]
  endif
  return join(lines, "\n") . lastchar . (visualmode() ==# 'V' ? "\n" : '')
endfunction

let [s:yank_cmd, s:paste_cmd] = s:set_command()


function! clipboard#set(yank, past) abort
  let s:yank_cmd = a:yank
  let s:paste_cmd = a:past
endfunction
