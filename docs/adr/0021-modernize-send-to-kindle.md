# ADR 0021: bin/send-to-kindle を最新化し、.env が無ければ環境変数を使う

- Status: Accepted
- Date: 2026-10-09

## Context

`bin/send-to-kindle` (Deno) は、ファイルを Kindle のメールアドレスへ添付して送るスクリプト。次の問題がある。

- 設定 (SMTP の接続先・認証、送信元・送信先) をカレントディレクトリの `.env` からしか読めず、`.env` が無いと例外で終わる。
- 送信に失敗しても、エラーを表示せずに正常終了する (失敗に気づけない)。
- ファイルを `join(カレントディレクトリ, 引数)` で組み立てるため、絶対パスを渡すと誤ったパスになる。
- SMTP のポート番号を文字列のまま渡している。
- 依存が古い (nodemailer 6。最新は 10)。不要な `@types/node` の import と、使っていない `-f` オプションがある。
- テストが無い。

## Decision

- 設定は、カレントディレクトリに `.env` があればそこから、無ければ環境変数から読む。
  必要な項目は従来と同じ (`EMAIL`、`SEND_TO_KINDLE_EMAIL`、`SMTP_HOST`、`SMTP_PORT`、`SMTP_USER_NAME`、`SMTP_PASSWORD`)。
  足りない項目は、読んだ場所とともに列挙してエラーにする。`SMTP_PORT` は数値として検証する。
- 設定の読み込み (`config.ts`) と送信内容の組み立て (`mail.ts`) を純粋な関数として `bin/lib/send-to-kindle/` に分け、
  `deno test` でテストする。`bin/send-to-kindle` は入出力 (引数・ファイル・送信) だけを受け持つ。
- 送信の失敗、ファイルが無い、引数が無い場合は、メッセージを表示して終了コード 1 で終わる。
- ファイルのパスは、カレントディレクトリを基準に解決する (絶対パスはそのまま)。
- nodemailer を 10 に上げ、型は `@types/nodemailer` を使う。不要な import と `-f` オプションを削除する。
- 権限 (`-A`) は変えない (絞ると送信を実際に試さないと確かめられないため。docs/audit/2026-10-07-breaking-changes.md の B5)。
- CI に `deno test` を追加する。

## Consequences

- `.env` を置かなくても、環境変数で設定して使える。`.env` がある場合の挙動は従来どおり。
- 送信の失敗が終了コードで分かる。
