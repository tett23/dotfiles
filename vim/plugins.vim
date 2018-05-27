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

" linter
Plug 'w0rp/ale'

" powerline
" なんかALEのlint情報をlightlineに出すのに必要らしい
Plug 'delphinus/lightline-delphinus'
Plug 'itchyny/lightline.vim'

" general utilities
Plug 'thinca/vim-quickrun'
" toggle comment out
Plug 'tyru/caw.vim'
" fuzzy finder
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'

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

" language plugins
"" ruby
Plug 'vim-scripts/rails.vim'
Plug 'vim-scripts/ruby-matchit'
Plug 'tpope/vim-endwise'
Plug 'uplus/deoplete-solargraph'

"" HAML
Plug 'tpope/vim-haml'

"" markdown
Plug 'tpope/vim-markdown'

"" go
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
Plug 'jnwhiteh/vim-golang'
Plug 'zchee/deoplete-go', { 'do': 'make'}

"" javascript
Plug 'jiangmiao/simple-javascript-indenter'
Plug 'othree/yajs.vim'

"" html
Plug 'mattn/emmet-vim'

call plug#end()
