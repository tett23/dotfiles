# ADR 0049: Ghostty で英数字の合字 (リガチャ) を無効にする

ステータス: 採択

## 文脈

Ghostty で `<-`・`->`・`!=`・`==` などの記号の並びが、1 つの記号 (合字・リガチャ) にまとめて表示され、見づらい。

- Ghostty の英数字のフォントは、Ghostty に組み込みの JetBrains Mono (フォントは指定していない。[ADR 0048](0048-ghostty-japanese-font.md))。
  JetBrains Mono は、OpenType の機能 `calt` (文脈に応じた字形の置き換え) で記号の並びを合字にする。
- Ghostty の `font-feature` で、フォントの OpenType の機能を有効・無効にできる (`-<機能>` で無効)。
  Ghostty の説明では、合字を無効にするには `calt`・`liga`・`dlig` を無効にする。

## 実装すること

- `ghostty/config` に次を足し、合字を無効にする。

  ```
  font-feature = -calt
  font-feature = -liga
  font-feature = -dlig
  ```

  | 機能 | 内容 |
  |---|---|
  | `calt` | 文脈に応じた字形の置き換え (JetBrains Mono の合字はこれ) |
  | `liga` | 標準の合字 (`fi` など) |
  | `dlig` | 任意の合字 |

- `docs/specifications.md` の Ghostty の節に書く。

## 実装しないこと

- フォントの変更 (合字の無い別のフォントへの切り替え)。
- 日本語の文字のフォント (BIZ UDゴシック。[ADR 0048](0048-ghostty-japanese-font.md)) の機能の個別の指定 (同じ `font-feature` が効く)。

## テスト設計

- 設定ファイルの変更のため、自動テストは書かない。
- `ghostty +validate-config --config-file=ghostty/config` で、設定にエラーが無いこと。
- 本人が、Ghostty の設定を読み込み直して (`Cmd+Shift+,`)、`<-`・`->`・`!=`・`==`・`>=` などが 1 文字ずつ表示されることを確かめる。

## トレードオフ

- 合字を使う表示 (矢印や比較の記号を 1 つの記号で見せる) はできなくなる。
