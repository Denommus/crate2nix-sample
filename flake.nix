{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      rust-overlay,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            (import rust-overlay)
          ];
        };

        rustToolchain = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;

        foo = pkgs.callPackage ./Cargo.nix {
          buildRustCrateForPkgs =
            p:
            p.buildRustCrate.override {
              rustc = rustToolchain;
              cargo = rustToolchain;
            };
        };

        shell = pkgs.mkShell {
          inputsFrom = [
            foo.workspaceMembers.bar.build
            foo.workspaceMembers.baz.build
          ];
        };
      in
      {
        packages = {
          default = foo.workspaceMembers.bar.build;
          bar = foo.workspaceMembers.bar.build;
          baz = foo.workspaceMembers.baz.build;
        };

        devShells.default = shell;
      }
    );
}
