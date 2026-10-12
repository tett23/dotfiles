# ADR 0041: ファイル配置の監査 (2026-10-11) の残骸を片付け、tmux のスクリプトを 1 か所にまとめる

ステータス: 採択

## 文脈

ファイル配置の監査 (`docs/audit/2026-10-11-file-layout.md`) で、直しても挙動が変わらない次の項目が見つかった。

- **L13** `.vscode/settings.json` は `"deno.enable": true` だけを書いたファイル。Deno のコード (`bin/send-to-kindle`) は
  [ADR 0031](0031-command-finder-key-and-rust-tools-via-mise.md) で削除し、リポジトリに Deno のコードは無い。
- **L14** ホームに空の `~/.tmux/` が残っている (TPM のプラグインの置き場所。[ADR 0029](0029-tmux-without-tpm.md) で中身を削除した)。
- **L15** `install.sh` に submodule の取得 (`fetch_submodules`) が残っている。[ADR 0029](0029-tmux-without-tpm.md) で、今後 submodule を足したときの
  ために残すと決めたが、submodule は無く、足す予定も無い。README と `docs/specifications.md` のインストールの手順にも、
  submodule の取得が書かれている。
- **L16** tmux のスクリプトが `tmux/segments/` (ステータスラインの表示用。`lan-ip`・`time-local`・`time-utc`) と
  `tmux/scripts/` (キーの割り当て用。`copy-line`) に分かれている。

## 実装すること

- **L13** `.vscode/settings.json` を削除する (中身が `deno.enable` だけのため。`.vscode/` も無くなる)。
- **L14** `~/.tmux/` を削除する (`rmdir`。dotfiles の外だが、空のディレクトリを消すだけ)。
- **L15** submodule に関わる処理と記述を削除する。[ADR 0029](0029-tmux-without-tpm.md) の「`install.sh` の submodule の取得処理を残す」を変える。
  - `install.sh` の `fetch_submodules` 関数とその呼び出し、手順の一覧のコメントの「submodule の取得」、
    `git_https` の説明のコメントの「submodule update」。手順の番号を詰める。
  - README と `docs/specifications.md` のインストールの手順の「submodule の取得」。
- **L16** `tmux/segments/` の 3 つのスクリプトを `tmux/scripts/` に移し (`git mv`)、`tmux/segments/` を無くす。
  - 参照している `tmux/statuses.conf` (nova のセグメントの設定) と CI の shellcheck の対象を直す。
- [ADR 0029](0029-tmux-without-tpm.md) のステータスを「採択→install.sh の submodule の取得処理は[ADR 0041](0041-file-layout-cleanup-2.md)」にする。

## 実装しないこと

- 監査の、直すと挙動が変わる項目 (L3〜L6・L8)。
- `.vscode/` に別の設定 (biome など) を置くこと。

## テスト設計

- 設定ファイルとシェルスクリプトの変更のため、自動テストは書かない。
- shellcheck が `install.sh` と `tmux/scripts/` のスクリプトで通ること。
- `git grep -n -i submodule` が、ADR と監査レポート (変更しない記録) 以外で何も出さないこと。
- `git grep -n 'tmux/segments'` が、ADR と監査レポート以外で何も出さないこと。
- 別の tmux サーバーで `tmux.conf` を読み込み、`tmux/statuses.conf` のセグメントのコマンド (`#(...)`) が新しいパスのスクリプトを
  指し、そのスクリプトが実行できること。
- 移した後に、普段の tmux で `prefix + r` で設定を読み込み直す (読み込み直すまで、ステータスラインの時刻と IP の表示は
  古いパスを指したまま空になる)。本人が確かめる。

## トレードオフ

- tmux のスクリプトを移してから設定を読み込み直すまで (普段の tmux では `prefix + r` まで)、ステータスラインの時刻と
  IP の表示が出ない。
- 今後 submodule を足すときは、`install.sh` に取得の処理を足し直す必要がある。
