" vim-gitgutter
let g:gitgutter_sign_added = '✚'
let g:gitgutter_sign_modified = '➜'
let g:gitgutter_sign_removed = '✘'

let g:lightline = {
        \ 'colorscheme': 'wombat',
        \ 'mode_map': {'c': 'NORMAL'},
        \ 'active': {
        \   'left': [
        \     ['mode', 'paste'],
        \     ['gitbranch', 'gitgutter', 'filepath'],
        \     ['character_count', 'line_count'],
        \   ],
        \   'right': [
        \     ['lineinfo'],
        \     ['percent'],
        \     ['linter_checking', 'linter_errors', 'linter_warnings', 'linter_ok'],
        \     ['charcode', 'fileformat', 'fileencoding', 'filetype'],
        \   ]
        \ },
        \ 'component_function': {
        \   'modified': 'MyModified',
        \   'readonly': 'MyReadonly',
        \   'filepath': 'MyFilepath',
        \   'filename': 'MyFilename',
        \   'fileformat': 'MyFileformat',
        \   'filetype': 'MyFiletype',
        \   'fileencoding': 'MyFileencoding',
        \   'mode': 'MyMode',
        \   'charcode': 'MyCharCode',
        \   'gitgutter': 'MyGitGutter',
        \   'character_count': 'MyCharacterCount',
        \   'line_count': 'MyLineCount',
        \ },
        \ 'component': { },
        \ 'component_expand': {
        \   'linter_checking': 'lightline#ale#checking',
        \   'linter_warnings': 'lightline#ale#warnings',
        \   'linter_errors': 'lightline#ale#errors',
        \   'linter_ok': 'lightline#ale#ok',
        \ },
        \ 'component_type': {
        \   'linter_checking': 'left',
        \   'linter_warnings': 'warning',
        \   'linter_errors': 'error',
        \   'linter_ok': 'left',
        \ },
        \ 'separator': {'left': '', 'right': ''},
        \ 'subseparator': {'left': '|', 'right': '|'}
        \ }

function! MyCharacterCounterOnCurrentBuffer()
  let result = 0
  for linenum in range(0, line('$'))
    let line = getline(linenum)
    let result += strlen(substitute(line, '.', 'x', 'g'))
  endfor

  return result
endfunction

function! MyCharacterCounterOnCurrentBufferLine()
  let current_line = getline(line('.'))
  let result = strlen(substitute(current_line, '.', 'x', 'g'))

  return result
endfunction

let s:textFileType = ['text', 'markdown']
function! s:isTextFile()
  let l:filetype = &filetype

  return index(s:textFileType, l:filetype) >= 0
endfunction

function! MyCharacterCount()
  if !s:isTextFile()
    return ''
  endif

  let buffer_characters = MyCharacterCounterOnCurrentBuffer()
  let line_characters = MyCharacterCounterOnCurrentBufferLine()
  let figures = strlen('' . buffer_characters)
  let format = "C %".figures."d / %".figures."d"

  return printf(format, line_characters, buffer_characters)
endfunction

function! MyLineCount()
  if !s:isTextFile()
    return ''
  endif

  let line_count = line('$')
  let current_line = line('.')
  let figures = strlen('' . line_count)
  let format = "L %".figures."d / %".figures."d"

  return printf(format, current_line, line_count)
endfunction

function! MyLineCharacterCount()
  return MyLineCount() . ' : ' . MyCharacterCount()
endfunction

augroup character_counter
  autocmd!
  autocmd BufCreate,BufEnter * call MyCharacterCount()
  autocmd BufNew,BufEnter,BufWrite,InsertLeave * call MyCharacterCount()
augroup END

function! MyModified()
return &ft =~ 'help\|vimfiler\|gundo' ? '' : &modified ? '+' : &modifiable ? '' : '-'
endfunction

function! MyReadonly()
return &ft !~? 'help\|vimfiler\|gundo' && &ro ? '⭤' : ''
endfunction

function! MyFilepath()
  return ('' != MyReadonly() ? MyReadonly() . ' ' : '') .
  \ (&ft == 'vimfiler' ? vimfiler#get_status_string() :
  \  &ft == 'unite' ? unite#get_status_string() :
  \  &ft == 'vimshell' ? substitute(b:vimshell.current_dir,expand('~'),'~','') :
  \ '' != @% ? @% : '[No Name]') .
  \ ('' != MyModified() ? ' ' . MyModified() : '')
endfunction

function! MyFilename()
  return expand('%:t')
endfunction

function! MyFileformat()
  return winwidth('.') > 70 ? &fileformat : ''
endfunction

function! MyFiletype()
  return winwidth('.') > 70 ? (strlen(&filetype) ? &filetype : 'no ft') : ''
endfunction

function! MyFileencoding()
  return winwidth('.') > 70 ? (strlen(&fenc) ? &fenc : &enc) : ''
endfunction

function! MyMode()
  return winwidth('.') > 60 ? lightline#mode() : ''
endfunction

function! MyGitGutter()
  if ! exists('*GitGutterGetHunkSummary')
  \ || ! get(g:, 'gitgutter_enabled', 0)
  \ || winwidth('.') <= 90
  return ''
  endif
  let symbols = [
  \ g:gitgutter_sign_added . ' ',
  \ g:gitgutter_sign_modified . ' ',
  \ g:gitgutter_sign_removed . ' '
  \ ]
  let hunks = GitGutterGetHunkSummary()
  let ret = []
  for i in [0, 1, 2]
  if hunks[i] > 0
  call add(ret, symbols[i] . hunks[i])
  endif
  endfor
  return join(ret, ' ')
endfunction

" https://github.com/Lokaltog/vim-powerline/blob/develop/autoload/Powerline/Functions.vim
function! MyCharCode()
  if winwidth('.') <= 70
  return ''
  endif

  "Get the output of :ascii
  redir => ascii
  silent! ascii
  redir END

  if match(ascii, 'NUL') != -1
  return 'NUL'
  endif

  " Zero pad hex values
  let nrformat = '0x%02x'

  let encoding = (&fenc == '' ? &enc : &fenc)

  if encoding == 'utf-8'
    " Zero pad with 4 zeroes in unicode files
    let nrformat = '0x%04x'
  endif
  " Get the character and the numeric value from the return value of :ascii
  " This matches the two first pieces of the return value, e.g.
  ""<F>  70" => char: 'F', nr: '70'
  let [str, char, nr; rest] = matchlist(ascii, '\v\<(.{-1,})\>\s*([0-9]+)')

  " Format the numeric value
  let nr = printf(nrformat, nr)

  return "'". char ."' ". nr
endfunction
