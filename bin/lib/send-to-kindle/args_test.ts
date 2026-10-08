import { assertEquals } from "jsr:@std/assert@^1";

import { parseCliArgs } from "./args.ts";

Deno.test("ファイルだけを指定する", () => {
  assertEquals(parseCliArgs(["book.epub"]), { ok: true, file: "book.epub", envFile: undefined });
});

Deno.test("--env-file で .env のパスを指定する", () => {
  assertEquals(parseCliArgs(["--env-file", "/conf/kindle.env", "book.epub"]), {
    ok: true,
    file: "book.epub",
    envFile: "/conf/kindle.env",
  });
});

Deno.test("--env-file=<パス> の形でも指定できる", () => {
  assertEquals(parseCliArgs(["book.epub", "--env-file=/conf/kindle.env"]), {
    ok: true,
    file: "book.epub",
    envFile: "/conf/kindle.env",
  });
});

Deno.test("短縮形 -e でも指定できる", () => {
  assertEquals(parseCliArgs(["-e", "kindle.env", "book.epub"]), {
    ok: true,
    file: "book.epub",
    envFile: "kindle.env",
  });
});

Deno.test("ファイルが無ければエラーにする", () => {
  assertEquals(parseCliArgs(["--env-file", "kindle.env"]), { ok: false, error: USAGE });
});

Deno.test("ファイルを 2 つ以上渡したらエラーにする", () => {
  assertEquals(parseCliArgs(["a.epub", "b.epub"]), { ok: false, error: USAGE });
});

Deno.test("--env-file の値が無ければエラーにする", () => {
  assertEquals(parseCliArgs(["book.epub", "--env-file"]).ok, false);
});

Deno.test("知らないオプションはエラーにする", () => {
  assertEquals(parseCliArgs(["--unknown", "book.epub"]).ok, false);
});

const USAGE = "使い方: send-to-kindle [--env-file <パス>] <ファイル>";
