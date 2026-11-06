# ADR 0084: [ADR 0082](0082-nvim-markdown-autosave-format-and-tsx.md) の参考文献と、prettier の表の整形についての記述を直す

ステータス: 採択

## 文脈

[ADR 0082](0082-nvim-markdown-autosave-format-and-tsx.md) (Markdown を保存のたびに整形しない) をコミットした後に、全体の指示 (`.claude/CLAUDE.md`) と照らし合わせ、
参考文献に、調べるときに実際には読んでいない文献が入っていたことが分かった。全体の指示は「仕様の調査に使った文献は ADR の末尾に含める」としている。
コミットした ADR は変えられないので、この ADR で直す。

[ADR 0082](0082-nvim-markdown-autosave-format-and-tsx.md) の参考文献と、実際に確かめたものは次のとおり。

| [ADR 0082](0082-nvim-markdown-autosave-format-and-tsx.md) の参考文献 | 実際 |
|---|---|
| auto-save.nvim の README (`noautocmd`) | 手元のクローン (`~/.local/share/nvim/lazy/auto-save.nvim/README.md`) で読んだ。正しい |
| conform.nvim の `format_on_save` (関数にできる) | ADR を書いたときは読まず、実装して動かして確かめた。この ADR を書くときに README の設定の表で確かめた (`fun(bufnr: integer): nil\|conform.FormatOpts`) |
| nvim-lint の `linters_by_ft` | 既存の設定と同じ書き方で、README は読んでいない。この ADR を書くときに README で確かめた |
| prettier の Rationale (`https://prettier.io/docs/rationale`。表の列をそろえる) | 読んでいなかった。この ADR を書くときに読むと、Markdown の表の記述は無かった。表がそろうことは、手元で prettier を実行して確かめただけだった |

prettier のソース (`src/language-markdown/print/table.js`。2026-11-04 の `d5d30c1`) を読むと、次のことも分かった。

- prettier は、表の列を、各列のいちばん広いセルの幅にそろえる (区切りの行の `-` も、その幅まで伸ばす)。
- ただし、`proseWrap` が `never` で、そろえた表が行の幅 (`printWidth`) を超えるときだけは、列をそろえない形 (`| a | b |`) で出す。
  そのため、[ADR 0082](0082-nvim-markdown-autosave-format-and-tsx.md) の「実装しないこと」の「prettier には、表をそろえない設定が無い」は正しくない。
  `proseWrap: never` で、行の幅を超える表はそろえない (幅に収まる表はそろえる)。

## 実装すること

- [ADR 0082](0082-nvim-markdown-autosave-format-and-tsx.md) のステータスを「採択→参考文献と、prettier の表の整形についての記述は ADR 0084」にする。
- [ADR 0082](0082-nvim-markdown-autosave-format-and-tsx.md) の参考文献を、次のとおりに読み替える (この ADR の「参考文献」に挙げる)。
  - prettier の Rationale を外し、prettier のソースの `src/language-markdown/print/table.js` にする。
- [ADR 0082](0082-nvim-markdown-autosave-format-and-tsx.md) の「実装しないこと」の「prettier には、表をそろえない設定が無い」を、上の「文脈」のとおりに読み替える。
  実装は変えない (`proseWrap: never` でも、幅に収まる表はそろうので、関係の無い行が差分に入るのは防げない)。

## 実装しないこと

- [ADR 0082](0082-nvim-markdown-autosave-format-and-tsx.md) の本文の書き換え (コミットした ADR は変えられない。ステータスの行だけを変える)。
- nvim の設定の変更。
- prettier の設定 (`proseWrap` など) の追加。

## テスト設計

- 文書の修正のため、自動テストは書かない。次を確かめる。
  - [ADR 0082](0082-nvim-markdown-autosave-format-and-tsx.md) の差分が、ステータスの行だけであること (adr-guard の pre-commit が通ること)。
  - `adr-guard links` と `adr-guard check-status` が何も報告しないこと。
  - 上の prettier の動きを、手元の prettier で確かめる: 幅に収まる表は `--prose-wrap never` でもそろい、行の幅を超える表は
    `--prose-wrap never` ではそろわず、既定 (`preserve`) ではそろうこと。

## トレードオフ

- [ADR 0082](0082-nvim-markdown-autosave-format-and-tsx.md) を読むときに、この ADR も合わせて読む必要がある。

## 参考文献

- auto-save.nvim の README (`noautocmd = false` の既定、conform との組み合わせの説明): https://github.com/okuuva/auto-save.nvim
- conform.nvim の README の設定の表 (`format_on_save` に関数を渡せる): https://github.com/stevearc/conform.nvim
- nvim-lint の README (`linters_by_ft`): https://github.com/mfussenegger/nvim-lint
- prettier の `src/language-markdown/print/table.js` (`d5d30c1`): https://github.com/prettier/prettier/blob/main/src/language-markdown/print/table.js
- prettier の Rationale (読んだが、表の記述は無かった): https://prettier.io/docs/rationale
