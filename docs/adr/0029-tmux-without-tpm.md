# ADR 0029: tmux の TPM をやめ、tmux-nova を Nix で入れ、sensible と yank を tmux.conf に置き換える

ステータス: 採択

## 文脈

tmux のプラグインは TPM (submodule の `tmux/tpm`) で管理し、tmux-sensible・tmux-yank・tmux-nova を入れている。

- TPM はプラグインのバージョンを固定できず (監査の T1)、`prefix + U` を押したときの最新が入る。
  今入っている版は 2022〜2024 年のまま更新されていない。
- `@plugin 'tmux-plugins/tpm'` の指定で、起動に使う submodule とは別の TPM が `~/.tmux/plugins/tpm` にも入っている。
- tmux-sensible のうち、この環境で実際に効いているのは `display-time 4000`・`status-keys emacs`・
  `focus-events on`・`aggressive-resize on` と、既存の割り当てと同じ動きのキー (`prefix + C-p`/`C-n`/`C-q`/`R`) だけ。
  ほかの項目は `tmux.conf` で設定済みのため何もしていない。
- tmux-yank は、コピーモードの `y`・`Y`・マウスでの選択と、`prefix + y`・`prefix + Y` を割り当てている。
  クリップボードへのコピーには `pbcopy` を使っている。
  - `prefix + y` (シェルの入力行のコピー) は、シェルに `C-a` を送って行頭へ移り、コピーモードで行末まで選択してコピーし、
    `C-e` で行末へ戻る。シェルが emacs のキー割り当てであることを前提にしている (`@shell_mode` の既定値)。
  - しかし zsh は `bindkey -v` (vi モード) で、挿入モードの `C-a`・`C-e` は文字の入力 (`self-insert`) になる。
    このため現在の `prefix + y` は、行頭に移らずに制御文字を入力行へ入れてしまう。
- 外部から持ってくる必要があるのは、ステータスライン全体を組み立てる tmux-nova だけ。nixpkgs に
  `tmuxPlugins.tmux-nova` (現在の flake.lock で 1.2.0) がある。

## 実装すること

### Nix (`flake.nix`)

home-manager の `xdg.configFile` で、tmux-nova のディレクトリを `~/.config/tmux/plugins/tmux-nova` にリンクする。

```nix
xdg.configFile = {
  # tmux-nova は Nix で入れる。nova.tmux は自分の置き場所から scripts/ を読むため、ファイル単体ではなくディレクトリをリンクする
  "tmux/plugins/tmux-nova".source = "${pkgs.tmuxPlugins.tmux-nova}/share/tmux-plugins/tmux-nova";
};
```

- バージョンは `flake.lock` の nixpkgs で固定され、`bin/update-nix` で更新される。

### tmux.conf

`@plugin` の 4 行と `run "$DOTFILES/tmux/tpm/tpm"` を外し、次を書く。

```tmux
# tmux-sensible で効いていた設定 (docs/adr/0029)
set -g display-time 4000
set -g status-keys emacs
set -g focus-events on
setw -g aggressive-resize on

# tmux-yank の代わり: y とマウスでの選択はクリップボードへ、Y は入力欄へ貼り付け
bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel pbcopy
bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel pbcopy
bind-key -T copy-mode-vi Y send-keys -X copy-pipe-and-cancel "tmux paste-buffer -p"
# prefix + y: シェルの入力行をクリップボードへ。prefix + Y: ペインのカレントディレクトリのパスをクリップボードへ
bind y run-shell -b "$DOTFILES/tmux/scripts/copy-line"
bind Y run-shell -b "tmux display-message -p '#{pane_current_path}' | tr -d '\n' | pbcopy; tmux display-message 'PWD copied to clipboard!'"

# nova の設定 (@nova-*) は nova.tmux を実行する前に読み込む
source-file "$DOTFILES/tmux/statuses.conf"
# tmux-nova は Nix で入れる (flake.nix の xdg.configFile)
run-shell ~/.config/tmux/plugins/tmux-nova/nova.tmux
```

- `y` についての既存のコメント (「tmux-yank がOS別コマンドを自動選択」) は、`pbcopy` を直接使う旨に直す。

### `prefix + y` のスクリプト (`tmux/scripts/copy-line`)

tmux-yank の `copy_line.sh` を、zsh の vi モードに合わせて再実装する (POSIX sh)。

1. シェルに `Escape` と `0` を送り、ノーマルモードにして行頭へ移る。
2. 少し待ってから (シェルがカーソルを動かすのを待つ) コピーモードに入り、選択を始める。
3. 下へ 150 行進んでから行末・前の単語・次の単語の末尾へ移り、複数行にまたがる入力行の末尾まで選択する
   (`copy_line.sh` と同じ手順)。
4. `copy-pipe-and-cancel pbcopy` でコピーしてコピーモードを抜ける。
5. シェルに `$` と `a` を送り、行末に戻って挿入モードに戻す。
6. `Line copied to clipboard!` と表示する。

- CI の shellcheck の対象に `tmux/scripts/copy-line` を足す。

### 片付け

- submodule の `tmux/tpm` を外す (`git rm tmux/tpm`。`.gitmodules` も消える)。
- `~/.tmux/plugins/` は本人が手で削除する (リポジトリの外のため)。
- `docs/specifications.md` の tmux の節と、README を直す。

## 実装しないこと

- tmux-sensible の割り当てのうち、既存の割り当てと同じ動きのもの (`prefix + C-p`/`C-n`/`C-q`/`R`)。
  `prefix + p`/`n`/`q`/`r` を使う。
- `prefix + y` の、emacs のキー割り当てのシェルへの対応 (nvim の `:terminal` 内の zsh は vi モードにしていないが、対象外とする)。
- `prefix + y` の、ssh・mosh 越しのときに待ち時間を延ばす処理 (`copy_line.sh` にはある)。
- home-manager の `programs.tmux` の利用。`tmux.conf` 自体を生成するため、リポジトリの `tmux.conf` へのリンクとぶつかる。
- `install.sh` の submodule の取得処理の削除。submodule が無くても何もしないだけで害は無く、今後 submodule を足したときに使える。
- tmux の設定ファイルの場所の変更 (`~/.tmux.conf` のまま。監査の L4)。

## テスト設計

- 設定ファイルの変更のため、自動テストは書かない。
- `nix eval --raw .#darwinConfigurations.dione.system.drvPath` が通ることを確かめる (CI の nix-eval と同じ)。
- `sudo darwin-rebuild switch` の後、`~/.config/tmux/plugins/tmux-nova/nova.tmux` と `scripts/` があることを確かめる。
- tmux を再起動し (`~/.tmux/plugins/` を消した状態で)、次を確かめる。
  - `tmux show -gv` で `display-time` が 4000、`status-keys` が emacs、`focus-events` が on、
    `aggressive-resize` (`show -gwv`) が on であること。
  - `tmux list-keys -T copy-mode-vi` で `y`・`Y`・`MouseDragEnd1Pane` が上の割り当てになっていること。
  - `tmux list-keys -T prefix` で `y`・`Y` が上の割り当てになっていること。
  - zsh で入力途中の行に対して `prefix + y` を押し、入力行がクリップボードに入り、入力行が変わらず挿入モードのままであること。
  - `prefix + Y` で、ペインのカレントディレクトリのパスが (末尾の改行なしで) クリップボードに入ること。
  - `tmux show -gv status-left` と `status-right` に nova のセグメント (セッション情報、時刻、`whoami`、LAN の IP) が入っていること。
  - `prefix + I` などの TPM の割り当てが無いこと。
- ステータスラインの見た目と、`y`・マウスでのコピーが従来どおりかは本人が目で確かめる。

## トレードオフ

- tmux のプラグインを足すたびに、nixpkgs の `tmuxPlugins` にあるか確かめ、無ければ Nix のパッケージを書く必要がある。
  `prefix + I` で GitHub から入れる手軽さは無くなる。
- `prefix + C-p`/`C-n`/`C-q`/`R` が使えなくなる。
- `prefix + y` のスクリプトが dotfiles に増える。シェルのキー割り当て (vi モード) を前提にしているため、
  zsh の設定を変えたら合わせて直す必要がある。
- `darwin-rebuild switch` を実行するまで tmux-nova のリンクが無く、その間に tmux を起動するとステータスラインが既定の見た目になる。
  他のマシンで pull した後も同じ。
- 他のマシンでは、pull 後も `tmux/tpm` のディレクトリが中身ごと残ることがある (git は submodule の作業ディレクトリを消さない)。
  手で削除する。
