# ADR 0047: Ghostty の効いていない `macos-option-as-alt` を外し、仕様の記述を事実に合わせる

ステータス: 採択

## 文脈

[ADR 0044](0044-ghostty-conveniences.md) で、zsh の `Alt-c`・`Alt-p`・`Alt-n` を使うために、Ghostty に `macos-option-as-alt = left` (左の Option キーを Alt として送る)
を入れた。しかし、Karabiner-Elements の選択中のプロファイル (`Default profile`) が左の Option キーを Escape に置き換えている
(`left_option → escape`) ため、Ghostty には Option キーとして届かず、この設定は効いていない。

- 左の Option を Escape にしているのは本人の意図で、今の挙動を維持する。
- 右の Option は置き換えられておらず、今は特殊な文字 (`å` など) を入力する。これも変えない。
- 左の Option (= Escape) を押してから続けてキーを押すと、端末には `Esc` に続けてそのキーが送られ、Alt を押しながらと同じ入力になる。
  zsh は vi モードのため、`KEYTIMEOUT` (既定 0.4 秒) より遅く押すと、ノーマルモードに入ってからキーとして扱われる。
- `docs/specifications.md` の Ghostty の節は「左の Option キーを Alt として送る」としていて、事実と違う。
- [ADR 0044](0044-ghostty-conveniences.md) は採択して実装したが、コミットした [ADR 0044](0044-ghostty-conveniences.md) のステータスの行が「提案」のままになっている。

## 実装すること

- `ghostty/config` から `macos-option-as-alt = left` とそのコメントを外す (効いていないので、挙動は変わらない)。
- `docs/specifications.md` の Ghostty の節を、事実に合わせる。
  - Option キーは Alt として送らない (Ghostty の既定)。左の Option は Karabiner-Elements で Escape に置き換えている
    (Karabiner-Elements は dotfiles で管理しないもの。`dependencies.md`)。
  - 左の Option (= Escape) を押してから素早く続けてキーを押すと、`Alt-c` などと同じ入力になる。
- [ADR 0044](0044-ghostty-conveniences.md) のステータスを「採択→macos-option-as-alt は[ADR 0047](0047-ghostty-option-as-alt-removed.md)」にする。

## 実装しないこと

- Karabiner-Elements の設定の変更 (左の Option を Escape にするのは本人の意図)。
- 右の Option を Alt にすること (右の Option での特殊な文字の入力は変えない)。
- zsh の `Alt-c` などの割り当ての変更。

## テスト設計

- 設定ファイルとドキュメントの変更のため、自動テストは書かない。
- `ghostty +validate-config --config-file=ghostty/config` で、設定にエラーが無いこと。
- `ghostty +show-config` で、`macos-option-as-alt` が既定 (空) になっていること。
- adr-guard の pre-commit hook で、[ADR 0044](0044-ghostty-conveniences.md) のステータスの行だけの変更が通ること。

## トレードオフ

- 左の Option で Alt の入力をするには、今までどおり Escape に続けて素早くキーを押す必要がある (vi モードでは、遅いとノーマルモードに入る)。
