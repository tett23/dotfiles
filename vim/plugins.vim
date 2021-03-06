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

" LSP
Plug 'autozimu/LanguageClient-neovim', {
  \ 'branch': 'next',
  \ 'do': 'bash install.sh',
  \ }

" colors
Plug 'tomasr/molokai'
Plug 'luochen1990/rainbow'

" linter
Plug 'w0rp/ale'

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

" zen editor
Plug 'junegunn/goyo.vim'

" file encoding plugin
Plug 'vim-scripts/fencview.vim'
Plug 'othree/eregex.vim'
Plug 'nathanaelkane/vim-indent-guides'

" git
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'

" language plugins
"" ruby
Plug 'vim-scripts/rails.vim'
Plug 'vim-scripts/ruby-matchit'
Plug 'tpope/vim-endwise'
Plug 'fishbullet/deoplete-ruby'

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
Plug 'prettier/vim-prettier', {
  \ 'do': 'yarn install',
  \ 'for': ['javascript', 'typescript', 'css', 'less', 'scss', 'json', 'graphql', 'markdown', 'vue'] }

"" html
Plug 'mattn/emmet-vim'

" skk
Plug 'tyru/eskk.vim'

call plug#end()
