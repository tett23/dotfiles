// send-to-kindle の引数を解釈する (docs/adr/0022)
import { parseArgs } from "node:util";

export type CliArgs =
  | { ok: true; file: string; envFile: string | undefined }
  | { ok: false; error: string };

const USAGE = "使い方: send-to-kindle [--env-file <パス>] <ファイル>";

export const parseCliArgs = (args: string[]): CliArgs => {
  try {
    const { values, positionals } = parseArgs({
      args,
      allowPositionals: true,
      strict: true,
      options: { "env-file": { type: "string", short: "e" } },
    });
    return positionals.length === 1
      ? { ok: true, file: positionals[0], envFile: values["env-file"] }
      : { ok: false, error: USAGE };
  } catch (error) {
    // 知らないオプションや、値の無い --env-file
    return { ok: false, error: `${error instanceof Error ? error.message : String(error)}\n${USAGE}` };
  }
};
