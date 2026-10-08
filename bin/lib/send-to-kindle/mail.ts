// send-to-kindle が送るメールを組み立てる (docs/adr/0021)
import { basename, resolve } from "node:path";

import type { Config } from "./config.ts";

export type Mail = {
  from: string;
  to: string;
  subject: string;
  text: string;
  attachments: { filename: string; path: string }[];
};

/**
 * @param file 送るファイル。相対パスなら cwd を基準に解決する
 * @param cwd カレントディレクトリ
 */
export const buildMail = (config: Config, file: string, cwd: string): Mail => ({
  from: config.from,
  to: config.to,
  // Kindle のメールアドレスは件名が「変換」だと、送ったファイルを Kindle の形式に変換する
  subject: "変換",
  text: "book",
  attachments: [{ filename: basename(file), path: resolve(cwd, file) }],
});
