let g:ale_completion_enabled = 1
" powerlineにlint情報を出すときのフォーマット
let g:ale_statusline_format = ['⨉ %d', '⚠ %d', '']
let g:ale_set_loclist = 0
let g:ale_set_quickfix = 1
let g:ale_lint_on_text_changed = 'never'
let g:ale_fix_on_save = 1
let g:ale_fixers = {
\   'javascript': ['eslint'],
\   'ruby': ['rubocop'],
\}
