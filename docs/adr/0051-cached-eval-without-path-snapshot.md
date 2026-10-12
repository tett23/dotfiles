# ADR 0051: `eval` の結果のキャッシュに、作った時点の PATH を残さない

ステータス: 採択

## 文脈

zsh の起動を速くするため、`mise activate zsh` などシェル統合のスクリプトを出力するコマンドの結果をキャッシュして読み込んでいる
(`zsh/lib/cached-eval.zsh` の `__cached_eval`。[ADR 0011](0011-speed-up-zsh-startup.md))。キャッシュは、呼び出すパス・実体のパス・実体の更新日時・引数をキーにし、
変わったら作り直す。

[ADR 0050](0050-ghc-cabal-via-ghcup.md) で `~/.ghcup/bin` を PATH に足したところ、新しいシェルで PATH に入らなかった。原因は次のとおり。

- `mise activate zsh` の出力の先頭には、出力した時点の PATH をそのまま書き込んだ行がある。

  ```zsh
  export __MISE_ORIG_PATH='<出力した時点の PATH>'
  export PATH='<mise の shims>:<出力した時点の PATH>'
  ```

- キャッシュは mise の版などが変わらない限り作り直されない (今のキャッシュは 2026-10-07 に作ったもの) ので、毎回この古い PATH で
  上書きされる。その後で zsh の設定に足した PATH (`~/.ghcup/bin`) は消え、外したはずの PATH が残る。
- mise の PATH の組み立て (`hook-env`) は `__MISE_ORIG_PATH` を元にするので、この値も古いままになる。
- 出力の後のほうには、`__MISE_ORIG_PATH` が無いときに今の PATH から設定する行 (`if [ -z "${__MISE_ORIG_PATH:-}" ]; then
  export __MISE_ORIG_PATH="$PATH"; fi`) があり、先頭の 2 行を除けば、読み込んだ時点の PATH で正しく動く。
- `mise activate zsh` をキャッシュせずに毎回実行すると、起動が 10ms ほど遅くなる。
- 古いキャッシュとして、Homebrew をやめた ([ADR 0012](0012-remove-homebrew.md)) 後の `brew-shellenv.zsh` も `~/.cache/zsh/` に残っている (使われていない)。

## 実装すること

- `__cached_eval` がキャッシュを作るときに、出力から「PATH をその時点の値に固定する行」を取り除く。
  - 対象は、行の頭が `export PATH=` または `export __MISE_ORIG_PATH=` の行 (ほかのコマンドの出力にも、PATH を固定する行は
    書くべきではないので、mise に限らず取り除く)。
  - 取り除いたことが分かるよう、キャッシュの 2 行目に取り除いた行の数をコメントで書く。
- キャッシュの形式が変わるので、キーに形式の版 (`v2`) を足し、今あるキャッシュを作り直させる。
- 使われていない `~/.cache/zsh/brew-shellenv.zsh` を削除する (dotfiles の外。キャッシュなので消しても害は無い)。
- `zsh/tests/cached-eval.test.zsh` にテストを足す (先に書いて失敗させてから直す)。

## 実装しないこと

- `mise activate zsh` をキャッシュの対象から外すこと (起動が遅くなるため)。
- キャッシュのキーに PATH を含めること (tmux の中など、PATH が少しずつ違うシェルで作り直しが頻繁に起きるため)。
- `~/.nix-profile/bin` が PATH に入っている件 (キャッシュを作り直した後も残っていて、別の出どころがある。必要なら別に調べる)。

## テスト設計

- `zsh/tests/cached-eval.test.zsh` (先にテストを書く):
  - 出力に `export PATH='...'` と `export __MISE_ORIG_PATH='...'` の行があるコマンドをキャッシュして読み込むと、
    読み込む前の PATH が変わらず、その 2 行以外 (ほかの export や関数の定義) は効くこと。
  - 行の途中に `PATH=` を含む行 (`if` の中の `export __MISE_ORIG_PATH="$PATH"` など、字下げのある行) は残ること。
  - 形式の版が違う古いキャッシュは作り直されること。
- 新しいシェルで、`~/.ghcup/bin` が PATH に入り、mise で入れたツールの PATH も入っていること (`mise activate` の結果が効いていること)。
- zsh の起動の時間が、キャッシュを使わない場合より短いままであること。

## トレードオフ

- `__cached_eval` が、出力の中身 (PATH を固定する行) を一部書き換える。シェル統合のスクリプトの形式が変わって、PATH を固定する
  別の書き方になった場合は、この取り除きでは防げない。
