{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      imports = [
        inputs.treefmt-nix.flakeModule
      ];
      perSystem =
        { pkgs, ... }:
        let
          zig = pkgs.zig_0_13;
          zigpeg = pkgs.stdenv.mkDerivation {
            pname = "zigpeg";
            version = "dev";

            src = ./.;

            nativeBuildInputs = [
              zig.hook
            ];

            zigBuildFlags = [
              "-Doptimize=Debug"
            ];
          };
        in
        {
          treefmt = {
            projectRootFile = "flake.nix";
            programs.nixfmt.enable = true;
            programs.zig.enable = true;
            programs.actionlint.enable = true;
          };

          checks = {
            inherit zigpeg;
          };

          packages = {
            inherit zigpeg;
            default = zigpeg;
          };

          devShells.default = pkgs.mkShell {
            packages = [
              # Compiler
              zig

              # LSP
              pkgs.zls
              pkgs.nil
            ];

            shellHook = ''
              export PS1="\n[nix-shell:\w]$ "
            '';
          };
        };
    };
}
