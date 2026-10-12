# ADR 0048: Ghostty の日本語の文字を BIZ UDゴシックで表示する

ステータス: 採択

## 文脈

nvim などで、日本語の文字が明朝体で表示されて読みにくい。

- nvim は Ghostty の中で動いていて、表示のフォントは Ghostty が決める。
- Ghostty にはフォントを指定していない (`font-family` が空。英数字は Ghostty に組み込みの JetBrains Mono)。
  日本語の文字は JetBrains Mono に無いので、macOS が選んだ代わりのフォントで表示され、それが明朝体になっている。
  以前どのフォントで表示されていたか、いつ明朝体になったかは分からない。
- Ghostty で使える日本語の等幅フォントは、macOS に付いている `BIZ UDGothic`・`BIZ UDMincho`・`Osaka` の 3 つ
  (`ghostty +list-fonts`)。ヒラギノ角ゴシックは等幅ではないので一覧に出ない。
- Ghostty の `font-codepoint-map` で、指定した Unicode の範囲だけを別のフォントで表示できる。英数字のフォントは変わらない。
- フォントは何でもよい ([ADR 0044](0044-ghostty-conveniences.md) の検討での本人の判断) ので、英数字のフォントは指定しないままにする。

## 実装すること

- `ghostty/config` に、日本語で使う Unicode の範囲を `BIZ UDGothic` (等幅のゴシック体) で表示する設定を足す。

  ```
  font-codepoint-map = U+3000-U+303F,U+3040-U+309F,U+30A0-U+30FF,U+31F0-U+31FF,U+3400-U+4DBF,U+4E00-U+9FFF,U+F900-U+FAFF,U+FF00-U+FFEF=BIZ UDGothic
  ```

  | 範囲 | 内容 |
  |---|---|
  | `U+3000-U+303F` | 和文の記号と句読点 (全角スペース・「」・、。など) |
  | `U+3040-U+309F` | ひらがな |
  | `U+30A0-U+30FF`・`U+31F0-U+31FF` | カタカナ (拡張を含む) |
  | `U+3400-U+4DBF`・`U+4E00-U+9FFF`・`U+F900-U+FAFF` | 漢字 (拡張 A・互換漢字を含む) |
  | `U+FF00-U+FFEF` | 全角の英数字・記号と半角カタカナ |

- `docs/specifications.md` の Ghostty の節に書く。

## 実装しないこと

- 英数字のフォント (`font-family`) とフォントの大きさの指定。
- 罫線などの記号 (`U+2500` 台など) のフォントの変更 (JetBrains Mono に含まれる)。
- 漢字の拡張 B 以降 (`U+20000` 以降) のフォントの変更 (使うことがほぼ無い)。

## テスト設計

- 設定ファイルの変更のため、自動テストは書かない。
- `ghostty +validate-config --config-file=ghostty/config` で、設定にエラーが無いこと。
- 本人が、Ghostty の設定を読み込み直して (`Cmd+Shift+,`)、nvim とシェルで日本語 (ひらがな・カタカナ・漢字・全角の記号) が
  ゴシック体で表示され、英数字は従来どおりであることを確かめる。

## トレードオフ

- 日本語の文字と英数字で、字の形の雰囲気が違う (別のフォントのため)。
- BIZ UDゴシックは macOS に付いているフォントなので、別のマシンでも使える。macOS から無くなった場合は、代わりのフォントに戻る。
