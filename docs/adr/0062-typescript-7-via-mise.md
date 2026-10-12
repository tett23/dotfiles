# ADR 0062: TypeScript 7 を mise で入れ、usage-hint の型検査に使う

ステータス: 採択

## 文脈

mod `usage-hint` の型検査は、[ADR 0061](0061-usage-hint-type-check.md) で、mod のディレクトリで `npx -y -p typescript@5 tsc --noEmit -p .`
を実行することにした。TypeScript は dotfiles で入れず、手元の `tsc` (`/usr/local/bin/tsc`。2021 年に npm で入れた 4.3.4) は、
生成された型定義を読めない。本人から、TypeScript 7 に上げ、型検査をすべて通るようにしたいと要望があった。

調べた結果は次のとおり。

- TypeScript 7 (Go で書き直した版) は 7.0.2 が npm の `latest` になっている (`typescript` パッケージ。コマンドは従来どおり `tsc`)。
- usage-hint は、TypeScript 7.0.2 で `tsc --noEmit -p .` がエラー 0 で終わる (TypeScript 5.9.3 でも 0)。`tsconfig.json`
  (Claude Code が生成する `.claude-plugin/types/tsconfig.json` を継承する) の設定で、TypeScript 7 で使えないものは無い。
  リポジトリの TypeScript は usage-hint だけ。
- mise の登録簿には `typescript` が無いが、npm バックエンド (`npm:typescript`) で入れられ、7.0.2 を選べる。
  言語・ツールは mise で `latest` を入れる方針 (`dependencies.md`)。
- `/usr/local/bin/tsc` は、Homebrew を使っていたころの npm の全体のインストール (`/usr/local/lib/node_modules`) の残り。
  PATH では mise が先なので、mise で入れればそちらが使われる。

## 実装すること

- `dependencies.md` の mise の「Install tools」に `typescript` を足し、npm バックエンドで入れることを書く。
- `mise/config.toml` に `"npm:typescript" = "latest"` を足す。sync-deps の名前の対応表に `typescript` → `npm:typescript` を書く。
- `mise install` で入れる。
- usage-hint の型検査のコマンドを、mod のディレクトリでの `tsc --noEmit -p .` にする (`docs/specifications.md`・`README.md`)。
  TypeScript 7 が要ることも書く。

## 実装しないこと

- 型検査を CI に入れること (型定義が git の管理外で、CI では生成できない。ADR 0061 と同じ)。
- `tsconfig.json` を厳しくすること (今の設定で `strict` と `noUncheckedIndexedAccess` が有効)。
- `/usr/local/lib/node_modules` の古い全体のインストール (typescript・expo-cli など) の片付け (本人がこの ADR のレビューのときに消した)。
- mod ごとに `package.json` を置いて TypeScript を固定すること。

## テスト設計

- 型の変更は無いので、新しい自動テストは書かない。次を確かめる。
  - 新しい zsh で `tsc --version` が 7 系で、`command -v tsc` が mise の場所であること。
  - `.claude/mods/usage-hint` で `tsc --noEmit -p .` がエラー 0 (終了コード 0) で終わること。
  - `claude plugin test .claude/mods/usage-hint` がすべて通ること。

## トレードオフ

- `latest` なので、TypeScript の次のメジャー版が出ると、`bin/update-mise` の後に型検査の結果が変わることがある。
- TypeScript 7 では、型定義が TypeScript 5 向けの新しい書き方を使っても読めるが、逆に TypeScript 7 だけの機能を型定義が使うと、
  ほかの版では読めなくなる。手元では mise の 1 つの版だけを使う。
- 全体に `tsc` が入るので、ほかのプロジェクトでプロジェクトの `node_modules` の `tsc` ではなく、mise の `tsc` を誤って使うことがある
  (`npx tsc` やパッケージのスクリプトは、プロジェクトのものを優先する)。
