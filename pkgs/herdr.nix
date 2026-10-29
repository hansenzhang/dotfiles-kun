{ lib, stdenvNoCC, fetchurl }:

# herdr isn't in nixpkgs. Upstream's Linux release is a static binary, so just install it.
# The Mac gets herdr from Homebrew, which tracks releases; bump version and hash here by hand.
stdenvNoCC.mkDerivation rec {
  pname = "herdr";
  version = "0.9.5";
  src = fetchurl {
    url = "https://github.com/herdrdev/herdr/releases/download/v${version}/herdr-linux-aarch64";
    hash = "sha256-F9dTby2lCFlSNoDvJ53/ysjkojX05G/o2mwuxEFBiXw=";
  };
  dontUnpack = true;
  installPhase = ''
    install -Dm755 $src $out/bin/herdr
  '';
  meta = {
    description = "Agent multiplexer that lives in your terminal";
    homepage = "https://herdr.dev";
    license = lib.licenses.asl20;
    platforms = [ "aarch64-linux" ];
    mainProgram = "herdr";
  };
}
