set nocompatible
"filetype off                   " (1)

set rtp+=~/.vim/vundle/    " (2)
call vundle#rc()               " (3)

Bundle 'Lokaltog/vim-powerline'
Bundle 'Shougo/neocomplcache'
Bundle 'molokai'
Bundle 'Zenburn'
"Bundle 'othree/eregex.vim'
Bundle 'Shougo/unite.vim'
Bundle 'Shougo/vimshell'
Bundle 'Shougo/vimproc'
Bundle 'thinca/vim-ref'
Bundle 'thinca/vim-quickrun'
Bundle 'mattn/zencoding-vim'
Bundle 'vim-scripts/grep.vim'
Bundle 'vim-scripts/rails.vim'
Bundle 'fuenor/qfixhowm'
"Bundle 'vim-ref'
"Bundle 'vim-ref-ri'
"Bundle 'vim-endwise'
Bundle 'ruby-matchit'
Bundle 'nathanaelkane/vim-indent-guides'
Bundle 'tpope/vim-fugitive'
Bundle 'tpope/vim-markdown'
Bundle 'scrooloose/syntastic'

" haskell
Bundle 'dag/vim2hs'
Bundle 'eagletmt/ghcmod-vim'
Bundle 'pbrisbin/html-template-syntax'
Bundle 'ujihisa/neco-ghc'
Bundle 'eagletmt/unite-haddock'
