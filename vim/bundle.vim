if has('vim_starting')
  set nocompatible
  set runtimepath+=~/dotfiles/vim/neobundle.vim/
endif

call neobundle#begin(expand('~/.vim/bundle/'))
NeoBundleFetch 'Shougo/neobundle.vim'

NeoBundle 'Shougo/vimproc', {
  \ 'build' : {
  \     'windows' : 'tools\\update-dll-mingw',
  \     'cygwin' : 'make -f make_cygwin.mak',
  \     'mac' : 'make -f make_mac.mak',
  \     'unix' : 'make -f make_unix.mak',
  \    },
  \ }
NeoBundle 'itchyny/lightline.vim'
NeoBundle 'tpope/vim-fugitive'
NeoBundle 'airblade/vim-gitgutter'
NeoBundle 'Shougo/neocomplcache'
"NeoBundle 'othree/eregex.vim'
NeoBundle 'Shougo/unite.vim'
NeoBundle 'Shougo/vimshell'
NeoBundle 'thinca/vim-ref'
NeoBundle 'thinca/vim-quickrun'
NeoBundle 'mattn/emmet-vim'
NeoBundle 'vim-scripts/grep.vim'
NeoBundle 'vim-scripts/rails.vim'
"NeoBundle 'vim-ref'
"NeoBundle 'vim-ref-ri'
"NeoBundle 'vim-endwise'
NeoBundle 'ruby-matchit'
NeoBundle 'nathanaelkane/vim-indent-guides'
NeoBundle 'tpope/vim-markdown'
NeoBundle 'scrooloose/syntastic'
NeoBundle 'Shougo/vimfiler'
NeoBundle 'kien/ctrlp.vim'
" NeoBundle 'todesking/ruby_hl_lvar.vim'
NeoBundle 'godlygeek/tabular'

NeoBundle 'fencview.vim'

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

" jade
NeoBundle 'digitaltoad/vim-jade'

" stylus
NeoBundle 'wavded/vim-stylus'

" c++
NeoBundle 'osyo-manga/vim-marching'
NeoBundle 'msanders/cocoa.vim'

" colors
NeoBundle 'tomasr/molokai'
NeoBundle 'jnurmine/Zenburn'
NeoBundle 'w0ng/vim-hybrid'
NeoBundle 'jonathanfilip/vim-lucius'

call neobundle#end()

filetype plugin indent on

NeoBundleCheck
