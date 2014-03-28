if has('vim_starting')
  set nocompatible
  set runtimepath+=~/dotfiles/vim/neobundle.vim/
endif

call neobundle#rc(expand('~/.vim/bundle/'))
NeoBundleFetch 'Shougo/neobundle.vim'

NeoBundle 'itchyny/lightline.vim'
NeoBundle 'tpope/vim-fugitive'
NeoBundle 'airblade/vim-gitgutter'
NeoBundle 'Shougo/neocomplcache'
NeoBundle 'molokai'
NeoBundle 'Zenburn'
"NeoBundle 'othree/eregex.vim'
NeoBundle 'Shougo/unite.vim'
NeoBundle 'Shougo/vimshell'
NeoBundle 'Shougo/vimproc'
NeoBundle 'thinca/vim-ref'
NeoBundle 'thinca/vim-quickrun'
NeoBundle 'mattn/zencoding-vim'
NeoBundle 'vim-scripts/grep.vim'
NeoBundle 'vim-scripts/rails.vim'
NeoBundle 'fuenor/qfixhowm'
"NeoBundle 'vim-ref'
"NeoBundle 'vim-ref-ri'
"NeoBundle 'vim-endwise'
NeoBundle 'ruby-matchit'
NeoBundle 'nathanaelkane/vim-indent-guides'
NeoBundle 'tpope/vim-markdown'
NeoBundle 'scrooloose/syntastic'

" haskell
NeoBundle 'dag/vim2hs'
NeoBundle 'eagletmt/ghcmod-vim'
NeoBundle 'pbrisbin/html-template-syntax'
NeoBundle 'ujihisa/neco-ghc'
NeoBundle 'eagletmt/unite-haddock'

" go
set rtp+=$GOROOT/misc/vim
exe "set rtp+=".globpath($GOPATH, "src/github.com/nsf/gocode/vim")
NeoBundle 'Blackrush/vim-gocode'
NeoBundle 'jnwhiteh/vim-golang'

" javascript
NeoBundle 'jiangmiao/simple-javascript-indenter'
NeoBundleLazy 'jelera/vim-javascript-syntax', {'autoload':{'filetypes':['javascript']}}

" coffee
NeoBundle 'kchmck/vim-coffee-script'
NeoBundle 'claco/jasmine.vim'

filetype plugin indent on

NeoBundleCheck
