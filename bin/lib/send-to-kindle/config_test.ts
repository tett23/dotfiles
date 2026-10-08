import { assertEquals } from "jsr:@std/assert@^1";

import { loadConfig } from "./config.ts";

const DOTENV = `EMAIL=me@example.com
SEND_TO_KINDLE_EMAIL=me@kindle.com
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER_NAME=user
SMTP_PASSWORD=secret
`;

const ENV: Record<string, string> = {
  EMAIL: "env@example.com",
  SEND_TO_KINDLE_EMAIL: "env@kindle.com",
  SMTP_HOST: "smtp.env.example.com",
  SMTP_PORT: "465",
  SMTP_USER_NAME: "env-user",
  SMTP_PASSWORD: "env-secret",
};
const fromEnv = (env: Record<string, string>) => (key: string) => env[key];

Deno.test(".env があれば .env の値を使い、環境変数は見ない", () => {
  assertEquals(loadConfig({ path: ".env", text: DOTENV }, fromEnv(ENV)), {
    ok: true,
    source: ".env",
    config: {
      from: "me@example.com",
      to: "me@kindle.com",
      smtp: { host: "smtp.example.com", port: 587, user: "user", pass: "secret" },
    },
  });
});

Deno.test(".env が無ければ環境変数の値を使う", () => {
  assertEquals(loadConfig(undefined, fromEnv(ENV)), {
    ok: true,
    source: "環境変数",
    config: {
      from: "env@example.com",
      to: "env@kindle.com",
      smtp: { host: "smtp.env.example.com", port: 465, user: "env-user", pass: "env-secret" },
    },
  });
});

Deno.test("足りない項目を、読んだ場所とともに列挙してエラーにする", () => {
  const { SMTP_HOST: _host, SMTP_PASSWORD: _pass, ...partial } = ENV;
  assertEquals(loadConfig(undefined, fromEnv(partial)), {
    ok: false,
    error: "環境変数に次の設定がありません: SMTP_HOST, SMTP_PASSWORD",
  });
});

Deno.test("空文字の項目は足りないものとして扱う", () => {
  const text = DOTENV.replace("SMTP_USER_NAME=user", "SMTP_USER_NAME=");
  assertEquals(loadConfig({ path: ".env", text }, fromEnv({})), {
    ok: false,
    error: ".env に次の設定がありません: SMTP_USER_NAME",
  });
});

Deno.test("指定したファイルから読んだときは、そのパスを source とエラーに出す", () => {
  const path = "/conf/kindle.env";
  assertEquals(loadConfig({ path, text: DOTENV }, fromEnv({})).ok && "ok", "ok");
  assertEquals(loadConfig({ path, text: "EMAIL=me@example.com\n" }, fromEnv(ENV)), {
    ok: false,
    error: "/conf/kindle.env に次の設定がありません: SEND_TO_KINDLE_EMAIL, SMTP_HOST, SMTP_PORT, SMTP_USER_NAME, SMTP_PASSWORD",
  });
});

Deno.test("SMTP_PORT が正の整数でなければエラーにする", () => {
  assertEquals(loadConfig(undefined, fromEnv({ ...ENV, SMTP_PORT: "smtp" })), {
    ok: false,
    error: "SMTP_PORT は正の整数で指定してください: smtp",
  });
});
