call plug#begin('~/.vim/plugged')

Plug 'roxma/nvim-yarp'
Plug 'roxma/vim-hug-neovim-rpc'

Plug 'Shougo/unite.vim'
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }

" colors
Plug 'tomasr/molokai'

" linter
Plug 'w0rp/ale'

" powerline
" なんかALEのlint情報をlightlineに出すのに必要らしい
Plug 'delphinus/lightline-delphinus'
Plug 'itchyny/lightline.vim'

" util
Plug 'kien/ctrlp.vim'

" general utilities
Plug 'thinca/vim-quickrun'

Plug 'jiangmiao/auto-pairs'

" file encoding plugin
Plug 'vim-scripts/fencview.vim'
Plug 'othree/eregex.vim'
Plug 'vim-scripts/grep.vim'
Plug 'nathanaelkane/vim-indent-guides'

" git
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

" language plugins
"" ruby
Plug 'vim-scripts/rails.vim'
Plug 'vim-scripts/ruby-matchit'

"" markdown
Plug 'tpope/vim-markdown'

"" go
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
Plug 'jnwhiteh/vim-golang'
Plug 'Shougo/deoplete.nvim'
Plug 'zchee/deoplete-go', { 'do': 'make'}

"" javascript
Plug 'jiangmiao/simple-javascript-indenter'
Plug 'othree/yajs.vim'

"" coffee
Plug 'kchmck/vim-coffee-script'

"" html
Plug 'mattn/emmet-vim'

"" jade
Plug 'digitaltoad/vim-jade'

"" stylus
Plug 'wavded/vim-stylus'

"" c++
Plug 'osyo-manga/vim-marching'

call plug#end()
