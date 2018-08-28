let g:ale_completion_enabled = 1
" powerlineにlint情報を出すときのフォーマット
let g:ale_statusline_format = ['⨉ %d', '⚠ %d', '']
let g:ale_sign_error = '!!'
let g:ale_sign_warning = '=='
let g:ale_set_loclist = 0
let g:ale_set_quickfix = 1
let g:ale_open_list = 1
let g:ale_lint_on_text_changed = 'never'
let g:ale_fix_on_save = 1
let g:ale_echo_msg_format = '[%linter%] [%severity%] %s'
let g:ale_linters = {
\   'txt': ['textlint'],
\   'markdown': ['prettier'],
\   'json': ['prettier'],
\   'javascript': ['eslint'],
\   'typescript': ['tslint', 'tsserver'],
\   'ruby': ['rubocop'],
\   'go': ['gometalinter'],
\}
let g:ale_fixers = {
\   'json': ['prettier'],
\   'markdown': ['prettier'],
\   'javascript': ['eslint'],
\   'typescript': ['tslint'],
\   'ruby': ['rubocop'],
\}

" js
let g:ale_javascript_prettier_use_local_config = 1
