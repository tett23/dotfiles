// send-to-kindle の設定を読む (docs/adr/0021)
// カレントディレクトリに .env があればそこから、無ければ環境変数から読む
import { parse } from "jsr:@std/dotenv@^0.225";

export type Config = {
  from: string;
  to: string;
  smtp: { host: string; port: number; user: string; pass: string };
};

export type ConfigResult =
  | { ok: true; source: ConfigSource; config: Config }
  | { ok: false; error: string };

type ConfigSource = ".env" | "環境変数";

// エラーメッセージでの読んだ場所の書き方 (英字の後には空白を入れる)
const SOURCE_LABEL: Record<ConfigSource, string> = { ".env": ".env ", "環境変数": "環境変数" };

const REQUIRED_KEYS = [
  "EMAIL",
  "SEND_TO_KINDLE_EMAIL",
  "SMTP_HOST",
  "SMTP_PORT",
  "SMTP_USER_NAME",
  "SMTP_PASSWORD",
] as const;

type Values = Record<(typeof REQUIRED_KEYS)[number], string>;

const parsePort = (value: string): number | undefined =>
  /^[1-9][0-9]*$/.test(value) ? Number(value) : undefined;

const toConfig = (values: Values, port: number): Config => ({
  from: values.EMAIL,
  to: values.SEND_TO_KINDLE_EMAIL,
  smtp: {
    host: values.SMTP_HOST,
    port,
    user: values.SMTP_USER_NAME,
    pass: values.SMTP_PASSWORD,
  },
});

/**
 * @param dotenvText .env の中身。.env が無ければ undefined
 * @param getEnv 環境変数を読む関数
 */
export const loadConfig = (
  dotenvText: string | undefined,
  getEnv: (key: string) => string | undefined,
): ConfigResult => {
  const source: ConfigSource = dotenvText === undefined ? "環境変数" : ".env";
  const dotenv = dotenvText === undefined ? undefined : parse(dotenvText);
  const lookup = (key: string) => (dotenv === undefined ? getEnv(key) : dotenv[key]) ?? "";

  const values = Object.fromEntries(REQUIRED_KEYS.map((key) => [key, lookup(key)])) as Values;
  const missing = REQUIRED_KEYS.filter((key) => values[key] === "");
  if (missing.length > 0) {
    return {
      ok: false,
      error: `${SOURCE_LABEL[source]}に次の設定がありません: ${missing.join(", ")}`,
    };
  }

  const port = parsePort(values.SMTP_PORT);
  if (port === undefined) {
    return { ok: false, error: `SMTP_PORT は正の整数で指定してください: ${values.SMTP_PORT}` };
  }

  return { ok: true, source, config: toConfig(values, port) };
};
