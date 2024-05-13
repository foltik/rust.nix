{
  description = "Rust development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, rust-overlay }:
    let
      system = "x86_64-linux";
      overlays = [ rust-overlay.overlays.default ];
      pkgs = import nixpkgs { inherit system overlays; };

      rust = pkgs.rust-bin.nightly.latest.default.override {
        targets = [ "x86_64-unknown-linux-musl" ];
        extensions = [ "rust-src" ];
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell.override {
        # Use the mold linker globally
        stdenv = pkgs.stdenvAdapters.useMoldLinker pkgs.clangStdenv;
      } {
        shellHook = "cargo --version";
        packages = with pkgs; [
          rust
          rust-analyzer

          cargo-edit

          bacon

          mold
        ];

        # Help rust-analyzer find the stdlib sources under nix
        RUST_SRC_PATH = "${rust}/lib/rustlib/src/rust/library";

        # Tell rustc to use the mold linker, it doesn't pick up the global C linker flags
        CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER = "${pkgs.llvmPackages.clangUseLLVM}/bin/clang";
        RUSTFLAGS = "-Clink-arg=-fuse-ld=${pkgs.mold}/bin/mold -Zshare-generics=y";
      };
    };
}
