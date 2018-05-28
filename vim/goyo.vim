let t:goyo_disabled_lightline=0

function! s:goyo_enter()
  let s:tmp_lightline = g:lightline

  call lightline#disable()

  let g:lightline = {
  \ 'colorscheme': 'wombat',
  \ 'mode_map': {'c': 'NORMAL'},
  \ 'active': {
  \   'left': [
  \     ['mode', 'paste'],
  \     ['filename'],
  \   ],
  \   'right': [
  \     ['character_count', 'line_count'],
  \   ]
  \ },
  \ 'component_function': {
  \   'filename': 'MyFilename',
  \   'mode': 'MyMode',
  \   'character_count': 'MyCharacterCount',
  \   'line_count': 'MyLineCount',
  \ },
  \ 'separator': {'left': '', 'right': ''},
  \ 'subseparator': {'left': '|', 'right': '|'}
  \ }

  call lightline#init()
  call lightline#enable()
endfunction

function! s:goyo_leave()
  call lightline#disable()

  let g:lightline = s:tmp_lightline

  call lightline#init()
  call lightline#enable()
endfunction

autocmd! User GoyoEnter nested call <SID>goyo_enter()
autocmd! User GoyoLeave nested call <SID>goyo_leave()
