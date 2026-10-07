# 監査の未対応項目のうち、直すと挙動が変わるもの (2026-10-07)

docs/audit/2026-10-07-best-practices.md の未対応項目のうち、直すと何かが壊れる・変わるものをまとめる。
挙動を変えずに直せるものは ADR 0014 で対応済み。ここに挙げたもののうち、直したものは各項目の「状況」に書いた。

各項目は「何が壊れる・変わるか」「直し方」「判断のポイント」の順に書く。数値は 2026-10-07 時点の実測。

## Z5: 旧ツールのディレクトリ (volta / rbenv / pyenv / bun / deno / pnpm)

- **状況**: ✅ 対応済み — 旧ツールのディレクトリを日付付きでゴミ箱に移し、nvim の rubocop を mason 版に切り替えた (ADR 0015)。

- **何が壊れる・変わるか**
  - 削除すると、そこに入っているグローバルなコマンドが使えなくなる。
    - `~/.volta` (2.5 GB): Node 14〜22 の 11 版と、`prettier`・`vivliostyle`・`vsce`・`yo` などのグローバルパッケージ
    - `~/.deno` (100 MB): `asset-build`・`book-builder`・`supreme-octo-bassoon` などの自作コマンド
    - `~/.bun` (302 MB)、`~/Library/pnpm` (130 MB)
    - `~/.rbenv` (752 MB): Ruby 2.6.10 / 2.7.6 / 3.0.4
    - `~/.pyenv` (2.5 GB): Python 2.7.1 / 3.7.1 / 3.8.6 / 3.9.9
  - nvim の rubocop は今 rbenv の shims 経由でしか見つからないので、使えなくなる。
  - 古い Node / Ruby / Python の版を前提にしたプロジェクトが動かなくなる (mise は latest のみ)。
- **直し方**: 必要なグローバルコマンドを mise (`npm:` / `pipx:` などのバックエンド) か Nix に移し、
  nvim の rubocop を mason の対象に戻してから (Ruby は mise 版 4.0.7 で直っている)、ディレクトリを削除する。
- **判断のポイント**: 古い版を使うプロジェクトが残っているか。合計で約 6.3 GB 空く。

## B5 の残り: bin/send-to-kindle の権限と .env

- **状況**: ⬜ 未対応

- **何が壊れる・変わるか**
  - `-A` (全権限) を必要な権限だけに絞ると、nodemailer が使う権限 (環境変数・ネットワーク・ファイル読み取りなど) を
    取りこぼしたときに送信が失敗する。実際にメールを送らないと確認できない。
  - `.env` をカレントディレクトリ以外 (例: `~/.config/send-to-kindle/.env`) から読むようにすると、
    今の「.env のあるディレクトリで実行する」使い方ができなくなる。
- **直し方**: `--allow-read --allow-net --allow-env` などに絞り、テスト用の宛先で送信して確かめる。
- **判断のポイント**: 実際に送信して確かめられるか。

## B6: bin/orch のモデル ID

- **状況**: ⬜ 未対応

- **何が壊れる・変わるか**: 別名の既定値を新しいモデルに変えると、委譲先が使うモデルが変わる
  (出力の傾向とコストが変わる)。今の既定値は `opus` → `claude-opus-4-8`、`fable` → `claude-fable-5`、
  `sonnet` → `claude-sonnet-5`、`sol` → `gpt-5.6-sol` (推定値)。
- **直し方**: 既定値を現行のモデル (例: `claude-opus-5-5`、`claude-fable-5-1`) に更新する。
  環境変数 `ORCH_MODEL_*` で個別に上書きもできる。
- **判断のポイント**: どのモデルに委譲したいか。

## I4: dotfiles とパッケージの二重管理

- **状況**: ✅ 対応済み — リンクを home-manager (mkOutOfStoreSymlink) に移し、setup/install.sh と単体の home-manager を廃止した (ADR 0015)。反映には `sudo darwin-rebuild switch` が必要。

- **何が壊れる・変わるか**
  - dotfiles のリンクを `setup/install.sh` から home-manager (`home.file`) に移すと、既存のリンクやファイルがある場所で
    home-manager が上書きを拒否し、`darwin-rebuild switch` が失敗する (`backupFileExtension` の設定が要る)。
  - 単体の home-manager の環境 (`~/.nix-profile`) を廃止すると、PATH の先頭にあるそのディレクトリのコマンドが
    使えなくなる (nix-darwin 側の home-manager と内容が重なっているが、同一ではない)。
  - sync-deps スキルの「CLI だけの変更は単体の `home-manager switch` で適用する」という手順も変える必要がある
    (以後は sudo が要る `darwin-rebuild switch` に一本化)。
- **直し方**: home-manager に `backupFileExtension` を設定してリンクを移し、`setup/install.sh` を縮小する。
  単体の home-manager の世代を削除し、スキルの手順を直す。
- **判断のポイント**: CLI の追加に sudo が要るようになってもよいか。

## C1: claude/settings.json の autoMode.environment

- **状況**: ⬜ 未対応

- **何が壊れる・変わるか**: 全リポジトリ共通の設定に、別リポジトリ (golem) 向けの「リモートの無い非公開リポジトリ」という
  説明が入っている。直すと Claude Code の auto mode の判断材料が変わり、許可・拒否される操作が変わる
  (公開リポジトリでの操作が今より慎重に扱われるなど)。
- **直し方**: リポジトリ固有の記述 (Repository visibility、Trusted repo) を外し、共通の記述だけにする。
  リポジトリ固有の内容は各リポジトリの `.claude/settings.json` に移す。
- **判断のポイント**: auto mode の振る舞いが変わってよいか (Claude Code のセキュリティに関わる設定なので本人が判断する)。

## C2: statusLine と usage-hint の表示の重複

- **状況**: ⬜ 未対応

- **何が壊れる・変わるか**: statusLine からコンテキスト使用率を外すと、ステータスラインの表示が変わる。
- **直し方**: statusLine の `ctx` 部分を削除する (usage-hint mod が同じ値を出している)。
- **判断のポイント**: どちらの表示を残したいか。

## C3 の残り: usage-hint mod の型定義

- **状況**: ⬜ 未対応

- **何が壊れる・変わるか**: mod の `tsconfig.json` が継承する型定義 (`.claude-plugin/types/`) は Claude Code が生成するもので、
  git の対象外。コミットすると約 1 万 4 千行のファイルが増え、Claude Code の更新のたびに差分が出る。
  コミットしない今は、新しく clone した環境でエディタの型チェックが効かない (動作には影響しない)。
- **直し方**: 型定義をコミットするか、README に生成手順 (`/plugin-types`) を書く。
- **判断のポイント**: 型定義をリポジトリに含めたいか。

## O1: rubocop.yml の TargetRubyVersion 2.5

- **状況**: ✅ 対応済み — TargetRubyVersion の指定を削除した (ADR 0015)。

- **何が壊れる・変わるか**: `~/.rubocop.yml` は、自前の設定を持たないプロジェクトで使われる。
  対象バージョンを上げると、新しい構文を前提にした指摘が増え、既存のコードに警告が出る。
- **直し方**: `TargetRubyVersion` を現行 (例: 3.4) に上げるか、指定を消してプロジェクトの `.ruby-version` に任せる。
- **判断のポイント**: Ruby 2.5 のコードを扱うプロジェクトが残っているか。

## O2 の残り: VSCode の既定フォーマッタ

- **状況**: ⬜ 未対応

- **何が壊れる・変わるか**: 既定のフォーマッタが deno (`denoland.vscode-deno`) になっている。prettier などに変えると、
  保存時の整形結果が変わる (deno のプロジェクトでも prettier で整形されるようになる)。
- **直し方**: 既定は prettier にし、deno のプロジェクトはワークスペースの設定で deno にする。
- **判断のポイント**: 普段 deno と Node のどちらのプロジェクトが多いか。

## M1: /opt/homebrew の残骸 (275 MB)

- **状況**: ✅ 対応済み — 本人が手動で削除した。

- **何が壊れる・変わるか**
  - 削除には sudo が要る (`sudo rm -rf /opt/homebrew`)。
  - mise の古い Ruby 4.0.5 が `/opt/homebrew/opt/gmp` にリンクしている (既に壊れており、
    mise が約 1 日後に自動で削除する予定)。それ以外に `/opt/homebrew` を参照しているものは見つからなかった。
- **直し方**: `mise prune` で Ruby 4.0.5 を消してから `/opt/homebrew` を削除する。
- **判断のポイント**: ほぼ影響なし。sudo での削除を本人が行う。

## M2: 手動で入れた VSCode

- **状況**: ✅ 対応済み — 手動版をゴミ箱に移し、/usr/local/bin/code を削除した (ADR 0015)。

- **何が壊れる・変わるか**: `/Applications/Visual Studio Code.app` (1.138) を削除すると、
  それを指している `/usr/local/bin/code` がリンク切れになる。`code` コマンドは Nix 版
  (`/run/current-system/sw/bin/code`) が先に見つかるので、PATH の順序次第ではそのまま使える。
  拡張機能と設定 (`~/.vscode`、`~/Library/Application Support/Code`) は Nix 版と共有なので失われない。
- **直し方**: Nix 版が動くことを確かめてから、アプリをゴミ箱に移し、`/usr/local/bin/code` を削除する (sudo が要る場合がある)。
- **判断のポイント**: ほぼ影響なし。Spotlight などで手動版を起動している場合は Nix 版に切り替える。
