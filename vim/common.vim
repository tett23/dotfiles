""" もろもろの設定

set nocompatible "vi非互換モード
set backspace=2
"表示系

" エンコードの設定
set encoding=utf-8
set fileencodings=utf-8,ucs-bom,iso-2022-jp-3,iso-2022-jp,eucjp-ms,euc-jisx0213,euc-jp,sjis,cp932

set ttyfast

set number "行番号表示
set showmode "モード表示
set title "編集中のファイル名を表示
set ruler "ルーラーの表示
set showcmd "入力中のコマンドをステータスに表示する
set showmatch "括弧入力時の対応する括弧を表示
set laststatus=2 "ステータスラインを常に表示
set wildmenu
let &directory = &backupdir
if has('multi_byte_ime') || has('xim') " 日本語入力ON時のカーソルの色を設定
    highlight CursorIM guibg=Purple guifg=NONE
endif
set statusline=%F%M%R%=code:%B%H%W

"プログラミングヘルプ系

syntax on "カラー表示
" 500字以上のときsyntax無効
set synmaxcol=500
let g:indentLine_faster = 1
set smartindent "オートインデント

set tabstop=2
set shiftwidth=2
set expandtab

set ignorecase "検索文字列が小文字の場合は大文字小文字を区別なく検索する
set smartcase "検索文字列に大文字が含まれている場合は区別して検索する

set wrapscan "検索時に最後まで行ったら最初に戻る
set nohlsearch "検索結果文字列の非ハイライト表示

set incsearch

let $VIMRUNTIME = "~/.vim"
set tags=tags

"マッピングとか
map ^? ^H
map! ^? ^H

"キーマッピング
noremap ; :
noremap : ;

"その他
set noerrorbells
set novisualbell

filetype plugin on
filetype indent on
set shellslash
set grepprg=\ -nH\ $*

" コピペ用
imap <F11> <nop>
set pastetoggle=<F11>

" タブと空白の表示
set list listchars=tab:>-,trail:_

" インデント表示
let g:indent_guides_auto_colors=0
let g:indent_guides_start_lebel=1
let g:indent_guides_guide_size=1
let g:indent_guides_enable_on_vim_startup=1

" 保存時にスペースを自動削除
autocmd BufWritePre * :%s/\s\+$//ge

" 自動改行しない
set formatoptions=q

" 最終行の表示
set display+=lastline
