# ADR 0058: git で取り込むオブジェクトを検査し、VSCode の古い設定と拡張を整理する

ステータス: 採択

## 文脈

[dotfiles の改善案 (2026-10-13)](../audit/2026-10-13-improvements.md) のうち、[ADR 0057](0057-remaining-improvements-2.md) の後に残った項目から、
本人が G2・O2 を直すことにした。V5 (自動保存のたびの整形と行末の空白の削除) は許容する。I10 (adr-guard) は本人が直した。

- **G2** git は、既定では fetch・clone・push で受け取るオブジェクトの形を検査しない。`transfer.fsckObjects` を有効にすると、
  壊れたオブジェクトや不正なオブジェクト (パスに `..` を含むツリーなど) を受け取ったときに失敗する
  (`fetch.fsckObjects` と `receive.fsckObjects` をまとめて有効にする)。
- **O2** `vscode/settings.json` を、VSCode 1.140.0 に組み込まれた Copilot (copilot-chat 0.68.0。拡張の `package.json` で確かめた)
  と、入っている拡張に照らして調べた。
  - `github.copilot.enable` の `"md"` は言語 ID ではない (Markdown は `"markdown"` で、すでに書いてある)。
    `"mdx"` は、入っている MDX の拡張 (unifiedjs.vscode-mdx) の言語 ID なので正しい (改善案の「言語 ID ではない」は `"md"` だけが正しい)。
  - `github.copilot.editor.enableAutoCompletions` は、今の Copilot に無い設定 (補完は `github.copilot.enable` で有効にしている)。
  - VSCodeVim の割り当てが、今は無いコマンドを呼んでいる。
    - `<Leader> c i g` の `github.copilot.interactiveEditor.generate` (エディタの中で Copilot に指示する機能)。今は VSCode 本体の `inlineChat.start`。
    - `<Leader> c g` の `github.copilot.generate` (補完の候補を一覧で出すパネル)。このパネルは今の Copilot に無い。
  - TOML の整形に使っている `bodil.prettier-toml` (0.1.0) は保守が止まっている。入っている `tamasfe.even-better-toml` (0.21.2) が整形もできる。
  - 拡張は dotfiles で管理していない (`code --list-extensions` で入っているものを確かめた)。

## 実装すること

### dotfiles の設定

| 案 | 変更 |
|---|---|
| G2 | `git/config` に `[transfer] fsckObjects = true` を足す |
| O2 | `github.copilot.enable` から `"md"` を消す (`"mdx"` は残す) |
| O2 | `github.copilot.editor.enableAutoCompletions` を消す |
| O2 | `<Leader> c i g` を `inlineChat.start` にする。`<Leader> c g` の割り当てを消す (置き換える機能が無い) |
| O2 | `[toml]` の `editor.defaultFormatter` を `tamasfe.even-better-toml` にする |

- `docs/specifications.md` の git の節に G2 を書く。

### dotfiles の外の片付け (この端末)

- `code --uninstall-extension bodil.prettier-toml` で、保守の止まった拡張を消す。

## 実装しないこと

- V5 (本人が許容する)。
- 拡張を dotfiles で管理すること (一覧を置くなど)。
- VSCodeVim の `<Leader> c` と `<Leader> c i` が同じコマンド (`editor.action.inlineSuggest.trigger`) を呼んでいることの整理。

## テスト設計

- 設定の値の変更のため、自動テストは書かない。次を確かめる。
  - `git config --get transfer.fsckObjects` が `true` であること。この設定で、dotfiles のリポジトリの `git fetch` が成功すること。
  - `vscode/settings.json` が JSONC として読め、`github.copilot.enable` に `md` が無く、`enableAutoCompletions` が無く、
    `<leader> c i g` が `inlineChat.start`、`<leader> c g` が無く、`[toml]` の整形が `tamasfe.even-better-toml` であること。
  - `code --list-extensions` に `bodil.prettier-toml` が無いこと。
- 本人が VSCode で、TOML のファイルの保存時の整形と、`<Leader> c i g` でエディタの中の Copilot が開くことを確かめる。

## トレードオフ

- G2: 古いリポジトリなどで、過去に入った不正なオブジェクトがあると、fetch・clone が失敗する。そのリポジトリでは
  `git -c transfer.fsckObjects=false fetch` のように一時的に外すか、`fsck.<検査名>` で特定の検査だけを無視する。
- O2: `<Leader> c g` が無くなる (今も動いていない)。TOML の整形の結果が prettier-toml と少し変わることがある。
