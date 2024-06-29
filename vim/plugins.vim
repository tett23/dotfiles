call plug#begin('~/.vim/plugged')

Plug 'Shougo/unite.vim'
if has('nvim')
  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
else
  Plug 'Shougo/deoplete.nvim'
  Plug 'roxma/nvim-yarp'
  Plug 'roxma/vim-hug-neovim-rpc'
endif
Plug 'Shougo/neosnippet-snippets'

" colors
Plug 'tomasr/molokai'
Plug 'luochen1990/rainbow'

" powerline
Plug 'itchyny/lightline.vim'
Plug 'maximbaz/lightline-ale'

" general utilities
Plug 'thinca/vim-quickrun'
Plug 'qpkorr/vim-bufkill'
" toggle comment out
Plug 'tyru/caw.vim'
" fuzzy finder
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'

" language settings
Plug 'sheerun/vim-polyglot'

" tree view
Plug 'scrooloose/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'

Plug 'jiangmiao/auto-pairs'

" file encoding plugin
Plug 'vim-scripts/fencview.vim'
Plug 'othree/eregex.vim'
Plug 'nathanaelkane/vim-indent-guides'

" git
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'

" skk
Plug 'tyru/eskk.vim'

Plug 'neoclide/coc.nvim', {'branch': 'release'}

call plug#end()

