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
        \     ['gitbranch'],
        \     ['readonly', 'file_path', 'modified'],
        \     ['character_count', 'line_count'],
        \   ],
        \   'right': [
        \     ['linter_checking', 'linter_errors', 'linter_warnings', 'linter_ok'],
        \     ['gitgutter'],
        \   ]
        \ },
        \ 'inactive': {
        \   'left': [
        \     ['full_path', 'modified']
        \   ],
        \   'right': [
        \     ['gitgutter'],
        \   ]
        \ },
        \ 'component_function': {
        \   'modified': 'MyModified',
        \   'readonly': 'MyReadonly',
        \   'gitbranch': 'fugitive#head',
        \   'file_path': 'MyFilePath',
        \   'full_path': 'MyFullPath',
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

function! MyReadonly()
  return &ro ? 'RO' : ''
endfunction

function! MyModified()
  return &modified ? '+' : ''
endfunction

function! MyParentPath() abort
  let l:path = expand('%:h')

  if l:path ==# ''
    return ''
  endif
  if l:path ==# '.'
    return ''
  endif

  let l:path_string = substitute(expand('%:h'), $HOME, '~', '')
  if match(l:path_string, '^/') ==# 0
    return l:path_string
  endif

  let l:path_items = split(l:path_string, '/')
  if len(l:path_string) < 20
    return l:path_string
  endif
  if len(l:path_items) < 3
    return l:path_string
  endif

  let l:short = []
  for item in l:path_items
    call add(l:short, item[0])
  endfor

  return join(l:short, '/')
endfunction

function! MyFilename() abort
  let l:filetype = &filetype
  let l:buftype = &buftype
  if l:buftype ==# 'terminal'
    return b:term_title . ' (' . b:terminal_job_pid . ')'
  endif

  if l:buftype ==# 'nerdtree'
    return 'NERDTree'
  endif

  if l:filetype ==# 'unite'
    return unite#get_status_string()
  end

  if l:filetype ==# 'denite'
    return denite#get_status_sources()
  endif

  return expand('%:t') ==# '' ? '[No Name]' : expand('%:t')
endfunction

function! MyFilePath() abort
  let l:parent = MyParentPath()
  let l:filename = MyFilename()
  if l:parent ==# ''
    return l:filename
  endif

  return l:parent . '/' . l:filename
endfunction

function! MyFullPath() abort
  let l:parent = expand('%:h')
  let l:filename = MyFilename()
  if l:parent ==# ''
    return l:filename
  endif

  return l:parent . '/' . l:filename
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
