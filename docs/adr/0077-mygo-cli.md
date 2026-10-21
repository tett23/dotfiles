# ADR 0077: MyGo の CLI (mygo) を mise で入れる

ステータス: 破棄

## 文脈

本人から、MyGo (https://github.com/egoist/mygo) を依存の一覧に足したいと要望があった。

- MyGo は、Go でデスクトップアプリを作るためのライブラリと CLI (MIT。最新は 0.6.2、2026-10-21)。アプリはライブラリとして使い (`go.mod`)、
  CLI の `mygo` で、プロジェクトの作成 (`init`)・開発用の起動 (`dev`)・TypeScript のクライアントの生成 (`generate`)・パッケージ化などを行う。
- README の入れ方は次の 2 つ。どちらも全体には入れない。
  - Web のフロントエンドを使うアプリ: `bunx mygo-cli init my-app` (Go 1.27 以降と Bun が要る)。
  - ネイティブの UI のアプリ: `go run github.com/egoist/mygo/cmd/mygo@latest init …`。作った後は、プロジェクトの `go tool mygo` を使う
    (プロジェクトの `go.mod` で版が決まる)。
- GitHub のリリースには、CLI のバイナリは付いていない。npm の `mygo-cli` は、プラットフォームごとのビルド済みのバイナリ
  (`@egoist/mygo-cli-darwin-arm64` など) を入れ、`mygo` のコマンドからそれを起動する。手元で `npx mygo-cli@0.6.2 --version` が `mygo 0.6.2` を出した。
- mise では、npm バックエンド (`npm:mygo-cli`) か、go バックエンド (`go:github.com/egoist/mygo/cmd/mygo`。手元でソースからビルドする) で入る。
  go バックエンドは、mise の `minimum_release_age` で新しい版が隠れていた (0.5.5 まで)。
- Go (mise。1.27.2) と Bun (mise) は既に入っている。npm バックエンドのツールは TypeScript・prh も同じ入れ方 ([ADR 0062](0062-typescript-7-via-mise.md), [0072](0072-inkscape-and-prh.md))。
- 再実装はしない (アプリのフレームワークの CLI で、ライブラリと一緒に使うもののため)。

## 実装すること

- `dependencies.md` の mise の「Install tools」に `mygo` を足し、npm バックエンド (`npm:mygo-cli`。コマンドは `mygo`) で入れることを書く。
- `mise/config.toml` に `"npm:mygo-cli" = "latest"` を足す。
- sync-deps の名前の対応表に `mygo`(mise) → `"npm:mygo-cli"` を書く。
- `mise install` で入れる。

## 実装しないこと

- go バックエンドで、ソースからビルドして入れること (ビルドに時間がかかり、新しい版が `minimum_release_age` で遅れる)。
- MyGo のライブラリや、アプリのひな形を dotfiles に置くこと。
- プロジェクトごとの `go tool mygo` の代わりに、全体の `mygo` を使うよう決めること (版を合わせたいプロジェクトでは `go tool mygo` を使う)。

## テスト設計

- 依存の追加のため、自動テストは書かない。次を確かめる。
  - `mise install` の後に、新しい zsh で `command -v mygo` が mise の場所を指し、`mygo --version` が版を出すこと。
  - 作業用のディレクトリで `mygo init` でプロジェクトを作れること (作ったものは消す)。
  - sync-deps の対応表と `dependencies.md`・`mise/config.toml` が食い違わないこと。

## トレードオフ

- 全体の `mygo` は `latest` なので、プロジェクトの `go.mod` の MyGo の版と食い違うことがある。プロジェクトの中では `go tool mygo` を使うほうが確実。
- npm のパッケージを通すので、`mygo` は node (または bun) からビルド済みのバイナリを起動する (起動が少し遅い)。
- MyGo は 0.x で、CLI の使い方が変わりやすい。

## 参考文献

- MyGo: https://github.com/egoist/mygo (README の「Getting started」)
- mygo-cli (npm): https://www.npmjs.com/package/mygo-cli
- mise の npm バックエンド: https://mise.jdx.dev/dev-tools/backends/npm.html
