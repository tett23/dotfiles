# ADR 0083: zsh のプラグインを新しいコミットに上げ、コマンドの所要時間の表示を自前で書く

ステータス: 採択

## 文脈

本人から、zsh の改善点を尋ねられ、今のプラグインの手入れをするよう要望があった。プラグインと zinit 本体は、コミットに固定している
([ADR 0010](0010-fix-zsh-fzf-audit.md)、[0046](0046-fix-audit-non-breaking.md))。2026-11-05 に、固定したコミットと上流の既定のブランチを比べた。

| プラグイン | スター | 固定したコミット (日付) | 上流の先頭 (日付) | 遅れ | 主な変更 |
|---|---|---|---|---|---|
| zinit 本体 | 4.9k | `d05a530` (v3.13.1 の 11 コミット後) | `cb49681` (2026-10-27。v3.17.1 の 10 コミット後) | 191 | 不具合の修正、ドキュメント。`ver` の ice は、コミットのハッシュなら今までどおり clone の後に checkout する。checkout に失敗するとエラーで止まる |
| zsh-completions | 7.9k | `7a884c7` (2024-06-26) | `989b232` (2026-10-16) | 602 | 補完の定義の追加・更新 (node など) |
| zsh-autosuggestions | 36k | `c3d4e57` (2023-09-07) | `85919cd` (2025-06-24) | 20 | v0.7.1 と、ドキュメントの修正 |
| fast-syntax-highlighting | 1.8k | `cf318e0` (2023-07-05) | `4672ad5` (2026-08-31) | 6 | ssh・make・perl・podman の色付けの修正 |
| fzf-tab | 5.0k | `24105b1` (2026-06-04) | 同じ | 0 | なし |
| zsh-command-time | 216 | `803d26e` (2020-11-15) | (2026-02 に push があるが、固定から 10 コミット) | 10 | — |

- zsh-command-time は、スターが少なく、コードは 40 行ほど。全体の方針 (ライセンスに問題が無く、書き直しやすいものは依存にせず書き直す) に従い、
  書き直す。dotfiles は、その設定の変数 (`ZSH_COMMAND_TIME_*`) を使っておらず、既定の動きだけを使っている。
  - 既定の動き: 端末 (`$TTY` がある) で、実行に 3 秒以上かかったコマンドの後に、`Time: 0h:00m:05s` の形の行を白で出す。
    空の行で Enter を押したとき (コマンドを実行しないとき) は出さない。時間は `$SECONDS` (秒の整数) で測る。
  - ほかに、`ZSH_COMMAND_TIME` という環境変数を export するが、dotfiles では使っていない。
- zsh のテストは `zsh/tests/*.test.zsh` で、CI で実行している。

## 実装すること

- `zsh/plugins.sh` の固定するコミットを、上の表の「上流の先頭」にする (zinit 本体の `_zinit_rev` と、各プラグインの `ver`)。
- `zsh/lib/command-time.zsh` を足し、zsh-command-time の既定の動きを書き直す。
  - 純粋な関数 `command_time_format <秒>` が `0h:00m:05s` の形の文字列を返す。
  - `preexec` で開始の時刻 (`$SECONDS`) を覚え、`precmd` で、覚えた時刻があり、`$TTY` があり、3 秒以上かかったときに
    `Time: <command_time_format の結果>` を白 (`%F{white}`) で出し、覚えた時刻を消す。`add-zsh-hook` で登録する。
  - 変数は `_command_time_` で始まる名前にし、環境変数にはしない。設定の変数 (除外するコマンド・しきい値・文言・色) は作らない。
- `zsh/plugins.sh` の `zinit light popstas/zsh-command-time` を消し、`zsh/zshrc` で `zsh/lib/command-time.zsh` を読む。
- 今のマシンに残る zsh-command-time のクローン (`~/.local/share/zinit/plugins/popstas---zsh-command-time`) は、zinit の `zinit delete` で消す
  (本人が実行するか、本人の了承を得て実行する)。
- `docs/specifications.md` の zsh の節に、プラグインを固定するコミットを上げたことと、所要時間の表示を自前で行うことを書く。

## 実装しないこと

- プラグインの追加 (zoxide・zsh-vi-mode など。別の ADR で扱う)。
- zinit をほかのプラグインマネージャーに替えること。
- zsh-command-time の設定の変数 (`ZSH_COMMAND_TIME_EXCLUDE` など) と、環境変数 `ZSH_COMMAND_TIME` の書き直し (使っていない)。
- 所要時間を、秒より細かく (`$EPOCHREALTIME`) 測ること。
- プラグインを定期的に上げる仕組み。

## テスト設計

先にテストを書いて失敗させてから実装する。

- `zsh/tests/command-time.test.zsh` を足す。
  - `command_time_format`: 0 → `0h:00m:00s`、5 → `0h:00m:05s`、65 → `0h:01m:05s`、3725 → `1h:02m:05s`。
  - `preexec` の後に `$SECONDS` を進めて (`SECONDS` に値を入れる) `precmd` を呼ぶ。`TTY` があり 3 秒以上なら `Time: 0h:00m:03s` を出す。
    2 秒なら何も出さない。`TTY` が空なら何も出さない。
  - `preexec` を呼ばずに `precmd` を呼ぶ (空の行で Enter を押したとき) と、何も出さない。2 回目の `precmd` (覚えた時刻を消した後) も何も出さない。
  - `zsh/lib/command-time.zsh` を読み込むと、`preexec_functions`・`precmd_functions` に登録され、2 回読み込んでも 1 回だけであること。
- プラグインを上げた後に、次を確かめる (自動テストにはしない)。
  - 新しい zsh (`zsh -i -c exit`) が、エラーを出さずに起動すること。プロンプトの後に遅延読み込みするプラグインを含めて、
    tmux の新しいウィンドウで起動し、補完 (`git <Tab>`)・候補の表示・色付けが効くこと。
  - 各プラグインのクローンの `git rev-parse HEAD` が、固定したコミットであること。
  - `sleep 3` の後に `Time: 0h:00m:03s` が出て、`true` の後には出ないこと。
- 既存の zsh のテストと、CI の shellcheck が通ること。

## トレードオフ

- 上流の変更で、補完・色付けの動きが少し変わることがある (ドキュメントと修正が主で、壊す変更は見当たらなかった)。
- 所要時間の表示の設定 (除外・しきい値など) を変えたくなったら、自分で書き足す。

## 参考文献

- zinit: https://github.com/zdharma-continuum/zinit (`ver` の ice の修正は d7f990e0)
- zsh-completions: https://github.com/zsh-users/zsh-completions
- zsh-autosuggestions: https://github.com/zsh-users/zsh-autosuggestions
- fast-syntax-highlighting: https://github.com/zdharma-continuum/fast-syntax-highlighting
- fzf-tab: https://github.com/Aloxaf/fzf-tab
- zsh-command-time: https://github.com/popstas/zsh-command-time
- zshmisc(1) の Hook Functions (`preexec`・`precmd`)、zshcontrib(1) の `add-zsh-hook`、zshparam(1) の `SECONDS`
