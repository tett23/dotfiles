// send-to-kindle の設定を読む (docs/adr/0021, 0022)
// .env (--env-file で指定したファイル、または カレントディレクトリの .env) があればそこから、無ければ環境変数から読む
import { parse } from "jsr:@std/dotenv@^0.225";

export type Config = {
  from: string;
  to: string;
  smtp: { host: string; port: number; user: string; pass: string };
};

export type ConfigResult =
  | { ok: true; source: ConfigSource; config: Config }
  | { ok: false; error: string };

// 読んだ場所: .env のパス、または "環境変数"
type ConfigSource = string;

const ENV_SOURCE = "環境変数";

// エラーメッセージでの読んだ場所の書き方 (パスの後には空白を入れる)
const sourceLabel = (source: ConfigSource): string =>
  source === ENV_SOURCE ? ENV_SOURCE : `${source} `;

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
 * @param dotenv 読んだ .env のパスと中身。.env が無ければ undefined (環境変数を使う)
 * @param getEnv 環境変数を読む関数
 */
export const loadConfig = (
  dotenv: { path: string; text: string } | undefined,
  getEnv: (key: string) => string | undefined,
): ConfigResult => {
  const source: ConfigSource = dotenv === undefined ? ENV_SOURCE : dotenv.path;
  const values = readValues(dotenv === undefined ? undefined : parse(dotenv.text), getEnv);
  return validate(values, source);
};

const readValues = (
  dotenv: Record<string, string> | undefined,
  getEnv: (key: string) => string | undefined,
): Values => {
  const lookup = (key: string) => (dotenv === undefined ? getEnv(key) : dotenv[key]) ?? "";
  return Object.fromEntries(REQUIRED_KEYS.map((key) => [key, lookup(key)])) as Values;
};

const validate = (values: Values, source: ConfigSource): ConfigResult => {
  const missing = REQUIRED_KEYS.filter((key) => values[key] === "");
  if (missing.length > 0) {
    return {
      ok: false,
      error: `${sourceLabel(source)}に次の設定がありません: ${missing.join(", ")}`,
    };
  }

  const port = parsePort(values.SMTP_PORT);
  if (port === undefined) {
    return { ok: false, error: `SMTP_PORT は正の整数で指定してください: ${values.SMTP_PORT}` };
  }

  return { ok: true, source, config: toConfig(values, port) };
};
