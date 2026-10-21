# ADR 0074: usage-hint の Fable の使用率を、使用量の API から取る

ステータス: 採択

## 文脈

本人から、usage-hint の Fable の使用率が `--` のまま更新されないと報告があった。

usage-hint は、レートリミットのウィンドウを `session.measure` と `$.session.usage()` から受け取り ([ADR 0004](0004-usage-hint-mod.md),
[0063](0063-usage-hint-periodic-refresh.md))、Fable の項目には `kind` に `fable` を含むウィンドウか、`seven_day_overage_included` のウィンドウを使う (`fableLimit`)。
調べた結果は次のとおり。

- mod の型定義 (`SessionRateLimit`) は、ウィンドウの種類を `five_hour`・`seven_day`・(ゲートウェイの) `spend_limit` と説明している。
  `/usage-hint` で受け取ったウィンドウを出すと、`five_hour` と `seven_day` だけだった。API の応答のヘッダーから作る値なので、
  Fable のウィンドウは、そのセッションで Fable にリクエストしたときしか入らないとみられる。
- Claude Code (2.1.294) の実行ファイルの中で、`seven_day_overage_included` は「Fable limit」と表示されている
  (`seven_day_overage_included:"Fable limit"`)。`fableLimit` の対応づけ自体は正しい。`seven_day_omelette` は表示に使われていない。
- Claude Code の `/usage` は、`https://api.anthropic.com/api/oauth/usage` から使用量を取る。実行ファイルの中の、SDK に返す形の定義によると、
  ウィンドウごとの `{ utilization, resets_at }` (`five_hour`・`seven_day`・`seven_day_opus`・`seven_day_sonnet` など) と、
  モデルごとの週のウィンドウ (`model_scoped`。応答の `limits[]` のうち `scope.model.display_name` が `Fable` などのもの。`percent`・`resets_at`) がある。
  応答そのものの形は公開されておらず、実行ファイルから読み取ったもの。
- mod は、`$.session.authorize()` でセッションの Anthropic の認証情報の handle を受け取り、`$.http.fetch(url, { auth: handle })` で
  first-party の host に送れる。秘密の値は mod に渡らない。`CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` があると拒否される。
  API キー・ゲートウェイ・ログインしていないときは handle が `null`。
- Claude Code 本体は、使用量の API の結果を 5 分ほど使い回しているとみられる (実行ファイルの中の 300000 ms の値)。

## 実装すること

- usage-hint に、使用量の API から Fable の週のウィンドウを取る処理を足す。
  - `$.session.authorize()` の handle で `https://api.anthropic.com/api/oauth/usage` を `GET` する。handle が `null`・失敗・形が違うときは何もしない
    (今の表示を残す)。
  - 応答から Fable のウィンドウを取り出す純粋な関数を作る。`limits[]` の `scope.model.display_name` が `Fable` (大文字・小文字を区別しない) のものの
    `percent`・`resets_at` を使い、無ければ `seven_day_overage_included` の `utilization`・`resets_at` を使う。どちらも無ければ無し。
  - 取り出したウィンドウは `kind: 'seven_day_overage_included'` の `Limit` として、表示のウィンドウに入れる (同じ種類のウィンドウがあれば置き換える)。
    リセット時刻を過ぎたら 0% にする扱い (`restoreLimits`) と、保存 (`$.store`) は今のウィンドウと同じにする。
- 問い合わせるのは、セッションを開いたときと、その後 5 分ごと (表示中のセッションだけ。[ADR 0063](0063-usage-hint-periodic-refresh.md) の 1 分ごとの更新の 5 回に 1 回)。
- `docs/specifications.md` の usage-hint の節に書く。

## 実装しないこと

- 5 時間・7 日のウィンドウを使用量の API から取ること (今どおり `session.measure`・`$.session.usage()` から取る)。
- Opus・Sonnet などのほかのモデルのウィンドウを出すこと。
- 認証情報を mod が自分で読むこと (handle だけを使う)。

## テスト設計

先にテストを書いて失敗させてから実装する。

- `tests/format.test.ts`: 応答から Fable のウィンドウを取り出す関数が、`limits[]` の `Fable` を優先すること、大文字・小文字を区別しないこと、
  無ければ `seven_day_overage_included` を使うこと、どちらも無い・形が違う (数でない値・配列でない `limits` など) ときは無しを返すこと。
- `tests/start.test.tsx`・`tests/refresh.test.tsx`: `session.authorize`・`http.fetch` の hook で応答を返し、開始時に Fable の値が表示に出ること、
  5 分ごとに更新されること (1 分では問い合わせないこと)、handle が `null`・`http.fetch` の失敗のときは今の表示が残ること、
  リクエストに handle が付き、URL が上のものであること。
- 既存のテストがすべて通り、`tsc --noEmit -p .` がエラー 0 で終わること。
- 実際の値は、本人が Claude Code を起動し直して、Fable の項目に値が出ることと、`/usage` の Fable の値と合うことを確かめる。

## トレードオフ

- 公開されていない API の、実行ファイルから読み取った形に頼る。形が変わると、Fable の項目はまた `--` になる (ほかの項目には影響しない)。
- 表示中のセッションごとに、5 分に 1 回、Anthropic の API に問い合わせる。
- Fable の値は最大 5 分遅れる。

## 参考文献

- Claude Code の mod の型定義 (`.claude/mods/usage-hint/.claude-plugin/types/claude-code/index.d.ts`): `SessionRateLimit`・`$.session.authorize`・`$.http.fetch`
- Claude Code 2.1.294 の実行ファイル (`~/.local/share/claude/versions/2.1.294`) の中の、使用量の API (`/api/oauth/usage`) と、その結果の形の定義
