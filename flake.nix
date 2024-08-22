{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = { self, nixpkgs, flake-utils, treefmt-nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        stdenv = pkgs.stdenv;
        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
        zigpeg = stdenv.mkDerivation {
          pname = "zigpeg";
          version = "dev";

          src = ./.;

          nativeBuildInputs = [
            pkgs.zig_0_13.hook
          ];

          zigBuildFlags = [
            "-Doptimize=Debug"
          ];
        };
      in
      {
        # Use `nix fmt`
        formatter = treefmtEval.config.build.wrapper;

        # Use `nix flake check`
        checks = {
          inherit zigpeg;
          formatting = treefmtEval.config.build.check self;
        };

        # nix build .
        packages = {
          inherit zigpeg;
          default = zigpeg;
        };

        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            # Compiler
            zig_0_13

            # LSP
            zls
            nil
          ];

          shellHook = ''
            export PS1="\n[nix-shell:\w]$ "
          '';
        };
      });
}
