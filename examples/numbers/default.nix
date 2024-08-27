{ pkgs ? import (builtins.fetchTarball "https://github.com/NixOS/nixpkgs/archive/ae815cee91b417be55d43781eb4b73ae1ecc396c.tar.gz") { } }:

let
  stdenv = pkgs.stdenv;
in
stdenv.mkDerivation {
  pname = "zigpeg-example-numbers";
  version = "dev";

  src = ./.;

  nativeBuildInputs = [
    pkgs.zig_0_13.hook
  ];

  zigBuildFlags = [
    "-Doptimize=Debug"
  ];
}
