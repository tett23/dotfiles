; Alloy (文法 vincentlu/tree-sitter-alloy) のインデント。文法に indents.scm が無いので dotfiles で書く。
; { ... } の中を 1 段下げ、} の行は開いた行に戻す (docs/adr/0107)
[
  (sig_decl)
  (enum_decl)
  (block_expression)
  (set_comprehension)
] @indent.begin

(sig_decl
  "}" @indent.branch @indent.end)

(enum_decl
  "}" @indent.branch @indent.end)

(block_expression
  "}" @indent.branch @indent.end)

(set_comprehension
  "}" @indent.branch @indent.end)

(block_comment) @indent.auto

; シグネチャの制約 (sig A { ... } { ... } の後ろの { ... }) は、sig_decl と合わせて 2 段にならないよう 1 段戻す。
; 行の終わりの | の次の行 (all x: A | や let y = A | の本体) を 1 段下げる (docs/adr/0108)
(sig_decl
  (block_expression) @indent.dedent)

[
  (quantified_expression)
  (let_expression)
] @indent.begin
