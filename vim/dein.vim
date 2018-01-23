" dein settings {{{
if &compatible
  set nocompatible
endif

" reset augroup
augroup MyAutoCmd
  autocmd!
augroup END

let s:cache_home = empty($XDG_CACHE_HOME) ? expand('$HOME/.cache') : $XDG_CACHE_HOME
let g:config_home = empty($XDG_CONFIG_HOME) ? expand('$HOME/.config') : $XDG_CONFIG_HOME
let s:dein_dir = s:cache_home . '/dein'

let s:dein_repo_dir = expand('~/dotfiles/dein/plugins/dein.vim')
execute 'set runtimepath+=' . s:dein_repo_dir

" なんかwindowsでpath separatorがおかしくなるので対策
" execute 'set runtimepath=' . expand(&runtimepath)

if dein#load_state(s:dein_dir)
  let g:dein#install_max_processes = 16
  let g:dein#install_progress_type = 'title'
  let g:dein#enable_notification = 1

  let s:toml = expand('~/dotfiles/dein/plugins.toml')
  let s:lazy_toml = expand('~/dotfiles/dein/plugins_lazy.toml')

  call dein#begin(s:dein_dir, [s:toml, s:lazy_toml])
  call dein#load_toml(s:toml, {'lazy': 0})
  call dein#load_toml(s:lazy_toml, {'lazy': 1})
  call dein#end()
  call dein#save_state()
endif

filetype plugin indent on

if has('vim_starting') && dein#check_install()
  call dein#install()
endif
" }}}
