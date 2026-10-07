# Claude デスクトップ (nixpkgs に無いため、配布 zip から作る。docs/adr/0012)
# バージョンとハッシュは sources.json (bin/update-nix が更新する)
{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:
let
  source = (lib.importJSON ./sources.json).claude-desktop;
in
stdenvNoCC.mkDerivation {
  pname = "claude-desktop";
  inherit (source) version;

  src = fetchurl { inherit (source) url sha256; };

  nativeBuildInputs = [ unzip ];
  sourceRoot = ".";

  # アプリのコード署名を壊さないよう、展開したものをそのまま置く
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications
    cp -R Claude.app $out/Applications/
    runHook postInstall
  '';

  meta = {
    description = "Claude desktop app";
    homepage = "https://claude.ai/download";
    license = lib.licenses.unfree;
    platforms = lib.platforms.darwin;
  };
}
