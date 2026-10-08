import { assertEquals } from "jsr:@std/assert@^1";

import type { Config } from "./config.ts";
import { buildMail } from "./mail.ts";

const CONFIG: Config = {
  from: "me@example.com",
  to: "me@kindle.com",
  smtp: { host: "smtp.example.com", port: 587, user: "user", pass: "secret" },
};

Deno.test("送信元・送信先・件名・本文と、ファイルの添付を組み立てる", () => {
  assertEquals(buildMail(CONFIG, "books/novel.epub", "/home/me"), {
    from: "me@example.com",
    to: "me@kindle.com",
    subject: "変換",
    text: "book",
    attachments: [{ filename: "novel.epub", path: "/home/me/books/novel.epub" }],
  });
});

Deno.test("絶対パスのファイルはカレントディレクトリと結合しない", () => {
  assertEquals(
    buildMail(CONFIG, "/tmp/novel.epub", "/home/me").attachments,
    [{ filename: "novel.epub", path: "/tmp/novel.epub" }],
  );
});
