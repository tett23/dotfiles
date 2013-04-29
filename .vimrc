source ~/dotfiles/vim/common.vim
source ~/dotfiles/vim/bundle.vim
source ~/dotfiles/vim/colors.vim
source ~/dotfiles/vim/neocomplecache.vim

" eregexの設定
"nnoremap / :M/
"nnoremap ? :M?
"nnoremap ,/ /
"nnoremap ,? ?

let g:rsenseHome = "$RSENSE_HOME"
let g:rsenseUseOmniFunc = 1

" rspecのquickrun
augroup RSpec
  autocmd!
  autocmd BufWinEnter,BufNewFile *_spec.rb set filetype=ruby.rspec
augroup END

let g:quickrun_config = {}
let g:quickrun_config['ruby.rspec'] = {'command': 'rspec'}
let g:quickrun_config['*'] = {'runmode': 'async:remote'}

set incsearch

" syntastic設定
let g:syntastic_enable_signs=1
let g:syntastic_mode_map = { 'mode': 'active',
  \ 'active_filetypes': [],
  \ 'passive_filetypes': ['html'] }
let g:syntastic_auto_loc_list = 1
let g:syntastic_javascript_checker = 'jshint'
