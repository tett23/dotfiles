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
        \     ['fugitive', 'gitgutter', 'filename'],
        \   ],
        \   'right': [
        \     ['lineinfo', 'ale'],
        \     ['percent', 'line_character_counter'],
        \     ['charcode', 'fileformat', 'fileencoding', 'filetype'],
        \   ]
        \ },
        \ 'component_function': {
        \   'modified': 'MyModified',
        \   'readonly': 'MyReadonly',
        \   'fugitive': 'MyFugitive',
        \   'filename': 'MyFilename',
        \   'fileformat': 'MyFileformat',
        \   'filetype': 'MyFiletype',
        \   'fileencoding': 'MyFileencoding',
        \   'mode': 'MyMode',
        \   'syntastic': 'SyntasticStatuslineFlag',
        \   'charcode': 'MyCharCode',
        \   'gitgutter': 'MyGitGutter',
        \   'line_character_counter': 'MyLineCharacterCount',
        \   'ale': 'ALEStatus',
        \ },
        \ 'component': {},
        \ 'separator': {'left': '⮀', 'right': '⮂'},
        \ 'subseparator': {'left': '⮁', 'right': '⮃'}
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

function! MyCharacterCount()
  let buffer_characters = MyCharacterCounterOnCurrentBuffer()
  let line_characters = MyCharacterCounterOnCurrentBufferLine()
  let figures = strlen('' . buffer_characters)
  let format = "%".figures."d / %".figures."d"

  return printf(format, buffer_characters, line_characters)
endfunction

function! MyLineCount()
  let line_count = line('$')
  let current_line = line('.')
  let figures = strlen('' . line_count)
  let format = "%".figures."d / %".figures."d"

  return printf(format, line_count, current_line)
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

function! MyFugitive()
  try
    if &ft !~? 'vimfiler\|gundo' && exists('*fugitive#head')
      let _ = fugitive#head()
      return strlen(_) ? '<U+2B60> '._ : ''
    endif
  catch
  endtry
  return ''
endfunction

function! MyFilename()
return ('' != MyReadonly() ? MyReadonly() . ' ' : '') .
\ (&ft == 'vimfiler' ? vimfiler#get_status_string() :
\  &ft == 'unite' ? unite#get_status_string() :
\  &ft == 'vimshell' ? substitute(b:vimshell.current_dir,expand('~'),'~','') :
\ '' != @% ? @% : '[No Name]') .
\ ('' != MyModified() ? ' ' . MyModified() : '')
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
