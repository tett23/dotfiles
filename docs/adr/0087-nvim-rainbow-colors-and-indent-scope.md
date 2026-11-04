# ADR 0087: nvim の括弧の色を Monokai にそろえ、インデントの線にも括弧と同じ色を付ける

ステータス: 採択

## 文脈

本人から、vim の rainbow 系のプラグインを尋ねられた。括弧の対応を色で示す rainbow-delimiters.nvim は、すでに入っている
(`nvim/lua/plugins/editor.lua`。旧 `luochen1990/rainbow` を移したもの)。headless の nvim で `editor.lua` を開くと、括弧に 5 色が付いていた。
調べると、次のことが分かった。

- **括弧の色が Monokai になっていない。**
  - 今の色は、rainbow-delimiters の既定の色 (`plugin/rainbow-delimiters.lua`。赤 `#cc241d`・黄 `#d79921`・青 `#458588` などの Gruvbox 風の色) になっている。
  - カラースキームの monokai-pro.nvim は、rainbow-delimiters 用の色を持っている (`theme/plugins/rainbow-delimiters.lua`)。ただし、
    `rainbow-delimiters.setup` のモジュールが読み込まれたときだけ当てる (`theme/plugins/init.lua` の `lazy = { module = "rainbow-delimiters.setup" }`)。
    今の設定は `setup` を呼ばないので、当たらない。
  - headless の nvim で `require("rainbow-delimiters.setup").setup({})` を呼ぶと、Monokai の色 (赤 `#ff6188`・黄 `#ffd866`・青 `#78dce8`・
    橙 `#fc9867`・緑 `#a9dc76`・紫 `#ab9df2`・水色 `#78dce8`) に替わった。monokai-pro は、青と水色に同じ色を当てている。
- **インデントの線を、括弧と同じ色にできる。**
  - indent-blankline.nvim の README の「rainbow-delimiters.nvim integration」の節に、カーソルのある範囲 (scope) のインデントの線を、
    その範囲を囲む括弧と同じ色で描く設定がある。範囲の色の一覧 (`scope.highlight`) を rainbow-delimiters と同じにし、hook
    `hooks.builtin.scope_highlight_from_extmark` を登録する。
  - README の例は、色の名前 (`RainbowRed` など) と色を新しく作っている。rainbow-delimiters の既定の色の名前 (`RainbowDelimiterRed` など。
    `lua/rainbow-delimiters/default.lua` の `highlight`。赤・黄・青・橙・緑・紫・水色の順) をそのまま使えば、新しく作らずに済み、
    色はカラースキームに任せられる。
  - 今の範囲の線の色は、`IblScope` (`#ff6188`) の 1 色。
- 不可視文字 (`listchars` と全角スペース) は緑 (`#76b98e`) にしている ([ADR 0028](0028-nvim-show-invisible-characters.md))。

## 実装すること

- `nvim/lua/plugins/editor.lua`:
  - rainbow-delimiters.nvim の設定で、`require("rainbow-delimiters.setup").setup({})` を呼ぶ (既定の設定のまま。monokai-pro の色が当たる)。
  - indent-blankline.nvim の設定を、`opts = {}` から `config` に変える。`scope.highlight` を rainbow-delimiters の既定の色の名前の一覧
    (`RainbowDelimiterRed`・`Yellow`・`Blue`・`Orange`・`Green`・`Violet`・`Cyan` の順) にし、`require("ibl.hooks")` で
    `SCOPE_HIGHLIGHT` に `scope_highlight_from_extmark` を登録する。色の名前と色は新しく作らない。
  - indent-blankline.nvim が rainbow-delimiters.nvim の後に読み込まれるよう、`dependencies` に書く。
- `docs/specifications.md` の nvim の節に書く。

## 実装しないこと

- 括弧の色を自分で決めること (monokai-pro の色に任せる。青と水色が同じ色になるのも、そのまま)。
- 範囲でないインデントの線 (`IblIndent`) に色を付けること。
- rainbow-delimiters の色を付ける方法 (`strategy`) や、対象の言語の変更。
- ほかの rainbow 系のプラグイン (CSV の列の色分けなど) を入れること。

## テスト設計

先に確かめ方を実行して失敗を確かめてから、実装する。CI に nvim とプラグインが無いので、手元の headless の nvim で確かめる。

- 括弧の色: headless の nvim で `RainbowDelimiterRed` の色が `#ff6188` (monokai-pro の赤) であること。実装の前は `#cc241d`。
- インデントの線: 入れ子の関数を含む Lua のファイルを開き、カーソルを内側の範囲に置いたとき、indent-blankline の extmark (`indent_blankline` の名前空間) の
  `virt_text` の色に `RainbowDelimiter` で始まる名前が含まれること。実装の前は `IblScope` だけ。
- 括弧の色付けが、今と同じく効くこと (rainbow-delimiters の名前空間に extmark があること)。
- `stylua --check` が通ること。
- 本人が確かめる: Ghostty の nvim で、括弧とインデントの線の色が見やすく、不可視文字の緑と見分けられること。

## トレードオフ

- 括弧の色が、今の Gruvbox 風の落ち着いた色から、Monokai の明るい色に変わる。
- monokai-pro は、青と水色に同じ色を当てるので、7 段のうち 2 段が同じ色に見える。
- 範囲の線の色が、範囲ごとに変わる (今は `IblScope` の 1 色)。緑の段 (`#a9dc76`) は、不可視文字の緑 (`#76b98e`) と近い。

## 参考文献

- rainbow-delimiters.nvim の README (`rainbow-delimiters.setup`)、`plugin/rainbow-delimiters.lua`、`lua/rainbow-delimiters/default.lua`
  (手元の `a798325`): https://github.com/HiPhish/rainbow-delimiters.nvim
- indent-blankline.nvim の README の「rainbow-delimiters.nvim integration」(手元の `d28a3f7`): https://github.com/lukas-reineke/indent-blankline.nvim
- monokai-pro.nvim の `lua/monokai-pro/theme/plugins/rainbow-delimiters.lua`・`theme/plugins/init.lua`: https://github.com/loctvl842/monokai-pro.nvim
