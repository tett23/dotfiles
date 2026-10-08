# ADR 0025: send-to-kindle を 1 ファイルにまとめる

- Status: Accepted
- Date: 2026-10-09

## Context

ADR 0021, 0022 で、send-to-kindle の引数の解釈・設定の読み込み・送信内容の組み立てを
`bin/lib/send-to-kindle/` の別ファイル (`args.ts`、`config.ts`、`mail.ts` とそれぞれのテスト) に分けた。
しかし、スクリプトを単体でコピーして使えないなど、ファイルが分かれていると困る。
手で読み書きすることはほぼないため、見通しより 1 ファイルであることを優先する。

## Decision

- `bin/lib/send-to-kindle/` の実装とテストをすべて `bin/send-to-kindle` に移し、ディレクトリは削除する。
- テストは同じファイルに `Deno.test` で書く。`deno run` では `Deno.test` は何もしないため、通常の実行には影響しない。
  テストは `deno test --ext=ts bin/send-to-kindle` で実行する (CI も同様に変える)。
- 送信などの副作用のある処理は `if (import.meta.main)` の中に置き、`deno test` で読み込んだときには実行しない。
- 挙動 (引数、設定の読み込み順、エラーメッセージ) は ADR 0021, 0022 のまま変えない。

## Consequences

- `bin/send-to-kindle` だけをコピーすれば動く。
- 実行時にもテスト用の `jsr:@std/assert` を読み込む (初回にダウンロードされる)。
