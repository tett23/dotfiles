# ADR 0061: usage-hint の型検査を、今の Claude Code の型定義に合わせる

ステータス: 採択

## 文脈

mod `usage-hint` (`.claude/mods/usage-hint/`) の型定義 (`.claude-plugin/types/`。git の管理外) は、Claude Code が mod を
読み込んだときに生成する ([ADR 0046](0046-fix-audit-non-breaking.md))。Claude Code の更新で型定義が変わり、mod のディレクトリで
`npx -y -p typescript@5 tsc --noEmit -p .` を実行すると、10 個のエラーが出る。どれも [ADR 0060](0060-usage-hint-danger-color.md) より前からある。
テスト (`claude plugin test .claude/mods/usage-hint`) は通っており、動作には問題がない。

- `hooks/register.tsx`
  - `Engine` が `claude-code` から export されなくなった。hook の `$` の型は `EngineInterface` になっている
    (`Engine` は `claude-code/testing` のテスト用の型として残っている)。
  - そのため `$.session.usage(...)` の戻り値が決まらず、`.then(({ context: estimated }) => ...)` の `estimated` が暗黙の `any` になる。
  - `toText` の引数の型を `(props: TextProps & { children?: unknown }) => RenderElement` と手で書いているが、`$.ui.resolve(e)` の
    `Text` は `ElementConstructor<TextProps>` (`children` が `RenderChildren`) で、`unknown` を渡せる型に代入できない。
- `tests/register.test.tsx`・`tests/start.test.tsx`
  - `AbovePrompt` の props に、`scroll: SiteScroll` (`{ offset, bodyRows }`) と `view: SiteView` (`{ agentId? }`) が必須で加わった。
    テストの `BAND_PROPS` (と、それを広げた `hasSurvey: true` の props) にこの 2 つが無い。
  - `ui.mount` に渡す、`PromptHint` と `AbovePrompt` を三項演算子で切り替える対象が `MountTarget` に代入できないエラーも、
    原因は同じ (`AbovePrompt` の props に `scroll`・`view` が無い)。

また、手元の `npx tsc` は TypeScript 4.3.4 で、生成された型定義を構文から読めない。型検査には TypeScript 5 が要るが、
そのことはどこにも書いていない。

## 実装すること

- `hooks/register.tsx`
  - `Engine` の import をやめ、`EngineInterface` を import して `initialSnapshot` の引数の型にする。
  - `toText` の引数の型を、`ElementConstructor<TextProps>` (import する) にする。
  - `estimated` は、上の変更で型が決まるので、注釈は足さない。
- `tests/register.test.tsx`・`tests/start.test.tsx` の `BAND_PROPS` に、`scroll: { offset: 0, bodyRows: 10 }` と `view: {}` を足す。
  `bodyRows` は `maxRows` (10) と同じにする (帯の木が 1 行なので、スクロールは起きない)。`view: {}` は本会話の表示を表す。
- `docs/specifications.md` の usage-hint の節に、型検査の方法 (mod のディレクトリで `npx -y -p typescript@5 tsc --noEmit -p .`。
  型定義は Claude Code が mod を読み込んだときに生成する。TypeScript 5 が要る) を書く。
- `README.md` のテストの表の下に、同じ型検査のコマンドを書く。
- 振る舞いは変えない。

## 実装しないこと

- 型検査を CI に入れること。型定義が git の管理外で、CI では生成できない ([ADR 0046](0046-fix-audit-non-breaking.md) で mod のテストを CI に入れないのと同じ理由)。
- TypeScript 5 を `dependencies.md` (Nix・mise) に入れること。型検査は型定義が変わったときにだけ行うので、`npx -y -p typescript@5` で足りる。
- テストを増やすこと。型だけの変更で、振る舞いは変わらない。
- 型定義に合わせるための `as` や `any` による抑え込み。

## テスト設計

型の変更なので、新しい自動テストは書かない。次を実装の前後で確かめる。

- 実装の前: mod のディレクトリで `npx -y -p typescript@5 tsc --noEmit -p .` が上の 10 個のエラーを出す。
- 実装の後: 同じコマンドがエラーを出さずに終わる (終了コード 0)。
- 実装の後: `claude plugin test .claude/mods/usage-hint` がすべて通る (件数は実装の前と同じ)。

(提案の時点で、上の変更を試しに当てて、tsc がエラー 0、テストが [ADR 0060](0060-usage-hint-danger-color.md) を含まない状態で 19 件すべて通ることを確かめ、元に戻した。)

## トレードオフ

- `BAND_PROPS` の `scroll`・`view` は、テストの中では使わない値を型のためだけに足すことになる。ただし実際の
  Claude Code は必ず渡すので、テストの props が実物に近くなる利点もある。
- 型定義は Claude Code の更新でまた変わりうる。型検査を CI に入れない以上、壊れたことには手で tsc を実行するまで気づかない。
  仕様と README にコマンドを書いておくことで、気づいたときに直せるようにする。
- [ADR 0060](0060-usage-hint-danger-color.md) (未コミット) も `hooks/register.tsx`・`tests/register.test.tsx` を変えるので、先に入ったほうに合わせてもう一方を直す必要がある。
