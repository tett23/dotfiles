# ADR 0078: 過剰な日本語訳を prh の辞書で見つけ、Claude Code の hook で知らせる

ステータス: 採択

## 文脈

全体の指示 (`.claude/CLAUDE.md`) には「技術用語のカタカナ語や英語は、分野で慣用されている形のまま使い、漢語に置き換えない」とある。
しかし Claude には、どの言葉をカタカナ語のまま使うかの辞書が無く、指示があっても漢語に寄ることがある (この dotfiles の作業でも、
「ウィンドウ」を「窓」と書き、本人が直した。[ADR 0074](0074-usage-hint-fable-from-usage-api.md))。本人から、辞書で検査し、Claude Code の hook で
自動にしたいと要望があった。

- prh は、辞書 (`prh.yml`) の規則で文書の表記を検査・置換する CLI で、mise で入れている ([ADR 0072](0072-inkscape-and-prh.md))。
  `prh --rules <辞書> <ファイル>` は、規則に当たった箇所を `<ファイル>(<行>,<列>): <見つけた表記> → <直した表記>` の形で出し、
  当たっても終了コードは 0 (`--verify` を付けると 1 になるが、スタックトレースも出る)。規則の `pattern` には正規表現 (`/…/`) を書ける。
- Claude Code の hook の `PostToolUse` は、ツール (Write・Edit など) の実行の後に動く。hook が終了コード 2 で終わると、標準エラーの内容が Claude に渡る
  (ツールの実行は取り消されない)。hook は、標準入力に JSON (`tool_input.file_path` など) を受け取る。
- `.claude/settings.json` は `~/.claude/settings.json` にリンクしていて、すべてのリポジトリの Claude Code に効く。今は `PreToolUse` に
  adr-guard の hook がある ([ADR 0032](0032-adr-guard.md), [0064](0064-adr-guard-allow-options.md))。
- hook は Claude Code の環境で動くので、mise の PATH (`~/.local/share/mise/shims`) が無いことがある。
- コミットするスクリプトは Python で書かず、シェルスクリプトにする (全体の指示)。

## 実装すること

- 辞書 `prh/prh.yml` を置く。すべてのリポジトリで共通に使う。最初の規則は次の 1 つにし、本人が使いながら足す。

  | 直した表記 | 見つける表記 | 備考 |
  |---|---|---|
  | ウィンドウ | `窓` (`窓口` を除く。`/窓(?!口)/`) | この dotfiles で実際に取り違えたもの |

- hook のスクリプト `bin/prh-claude-hook` (POSIX sh) を置く。
  - 標準入力の JSON から、`jq` で `tool_input.file_path` を取り出す。拡張子が `.md` で、ファイルがあるときだけ検査する。
  - prh だけでは Markdown の構造を考えられない (prh の README)。コードブロック (` ``` `・`~~~` で囲んだ行) とインラインのコード (`` ` `` で囲んだ部分) は、
    同じ文字数の空白に置き換えた写しを作り、写しを prh に渡す (行と列はそのまま)。報告は元のファイルの名前に直して出す。
  - prh は、PATH か、無ければ mise の shims (`~/.local/share/mise/shims/prh`) から探す。見つからなければ何もしない (終了コード 0)。
  - 辞書は `$DOTFILES/prh/prh.yml` (`DOTFILES` が無ければ `~/dotfiles`)。テストのために、環境変数 `PRH_CLAUDE_RULES` で差し替えられるようにする。
  - prh の出力が空でなければ、直す表記の一覧と、辞書の場所を標準エラーに出し、終了コード 2 で終わる。空なら 0。
- `.claude/settings.json` の `hooks` の `PostToolUse` に、`Write|Edit|MultiEdit` で `bin/prh-claude-hook` を呼ぶ hook を足す
  (`${DOTFILES:-$HOME/dotfiles}/bin/prh-claude-hook`)。
- `docs/specifications.md` の Claude Code の節に書く。手で検査するときのコマンド (`prh --rules ~/dotfiles/prh/prh.yml <ファイル>`) も書く。

## 実装しないこと

- チャットの返答の検査 (hook はファイルだけを見る)。
- prh で自動で置き換えること (`--replace`)。直すのは Claude に任せる (文脈で正しいことがあるため)。
- `.md` 以外のファイル (コードのコメントなど) の検査。
- リポジトリごとの辞書 (`prh.yml` をリポジトリに置くもの) を読むこと。
- textlint の `textlint-rule-prh` を使うこと。
- 最初の規則のほかに、言葉を推測して足すこと (誤検出を避けるため、実際に取り違えたものから足す)。

## テスト設計

先にテストを書いて失敗させてから実装する。

- `zsh/tests/prh-claude-hook.test.zsh` を足す (prh が無い環境、たとえば CI では飛ばす)。作業用の辞書 (`PRH_CLAUDE_RULES`) と、hook の JSON を入力にして確かめる。
  - 規則に当たる表記を含む `.md` のファイル: 終了コード 2 で、標準エラーに `窓 → ウィンドウ` が出ること。
  - `窓口` だけを含む `.md`、当たる表記が無い `.md`: 終了コード 0 で、何も出さないこと。
  - `.md` でないファイル、無いファイル、`file_path` の無い JSON: 終了コード 0 で、何も出さないこと。
  - PATH と mise の shims のどちらにも prh が無いとき: 終了コード 0 で、何も出さないこと。
  - 規則に当たる表記が、コードブロックの中 (` ``` `・`~~~`) と、インラインのコードの中にだけあるとき: 終了コード 0 で、何も出さないこと。
  - コードの部分と本文の両方にあるとき: 本文の箇所だけが、元のファイルの名前と、元の行・列で出ること。
- `prh/prh.yml` が prh で読めること (`prh --rules prh/prh.yml --rules-json` が終了コード 0)。同じテストで、実際の辞書で `窓` が当たることも確かめる。
- `.claude/settings.json` が JSON として読め、`PostToolUse` の hook が上のとおりであること。
- 実装の後に、Claude Code の中で `窓` を含む `.md` を書くと、hook の知らせが Claude に届くことを確かめる (本人の Claude Code を起動し直した後)。
- 既存の zsh のテストと、CI の shellcheck が通ること。

## トレードオフ

- `.md` を書くたびに prh (node) が動くので、書く操作ごとに少し時間がかかる。
- 辞書の規則が雑だと、正しい表記まで知らせが出て、Claude が誤って直すおそれがある。規則は実際に取り違えたものから、除外の条件と一緒に足す。
- 規則に当たっても、書き込みは取り消されない。直すのは知らせを受けた Claude で、直さずに進むこともありうる。
- コードブロックとインラインのコードの判定は簡単なもの (行頭の ` ``` `・`~~~` と、同じ行の中の `` ` `` の組) で、Markdown のすべての書き方には合わない
  (たとえば、字下げだけのコードブロックや、`` ` `` を 2 つ以上使うインラインのコードは、本文として検査する)。

## 参考文献

- prh: https://github.com/prh/prh
- Claude Code の hooks (`PostToolUse`、終了コード 2 の扱い): https://code.claude.com/docs/en/hooks
