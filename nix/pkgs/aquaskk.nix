# AquaSKK (nixpkgs に無いため、配布 pkg から作る。docs/adr/0012)
# 入力メソッドは実体として /Library/Input Methods に置く必要があるので、
# flake.nix のアクティベーションでそこへコピーする。
# バージョンとハッシュは sources.json (bin/update-nix が更新する)
{
  lib,
  stdenvNoCC,
  fetchurl,
  xar,
  cpio,
}:
let
  source = (lib.importJSON ./sources.json).aquaskk;
in
stdenvNoCC.mkDerivation {
  pname = "aquaskk";
  inherit (source) version;

  src = fetchurl { inherit (source) url sha256; };

  nativeBuildInputs = [
    xar
    cpio
  ];

  # pkg (xar アーカイブ) の中の Payload (gzip 圧縮の cpio) を展開する
  unpackPhase = ''
    runHook preUnpack
    xar -xf $src
    gzip -dc aquaskk-pkg.pkg/Payload | cpio -idm --quiet
    runHook postUnpack
  '';

  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/Library/Input Methods"
    cp -R "Library/Input Methods/AquaSKK.app" "$out/Library/Input Methods/"
    runHook postInstall
  '';

  meta = {
    description = "SKK input method for macOS";
    homepage = "https://github.com/codefirst/aquaskk";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.darwin;
  };
}
