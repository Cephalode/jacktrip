{
  description = "High-quality system for audio network performances over the Internet";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages = {
          default = self.packages.${system}.jacktrip;

          jacktrip = pkgs.qt6Packages.callPackage ./package.nix {
            inherit (pkgs) libjack2;
          };
        };

        devShells.default = pkgs.mkShell {
          inputsFrom = [ self.packages.${system}.jacktrip ];

          packages = with pkgs; [
            # C++ development
            clang-tools  # clangd, clang-format
            cmake-format

            # Qt development
            qt6.qttools

            # Documentation
            help2man
            doxygen
          ] ++ lib.optionals stdenv.isLinux [
            # Linux-specific development tools
            gdb
            valgrind
          ] ++ lib.optionals (stdenv.isLinux && pkgs ? qt6.qtcreator) [
            # Qt Creator (not always available on all platforms)
            qt6.qtcreator
          ];

          shellHook = ''
            echo "=============================="
            echo "JackTrip Development Shell"
            echo "=============================="
            echo ""
            echo "Quick start:"
            echo "  meson setup builddir -Dqtversion=6 -Djack=enabled -Drtaudio=disabled"
            echo "  meson compile -C builddir"
            echo "  ./builddir/jacktrip --version"
            echo ""
            echo "Installed tools:"
            echo "  - Qt Creator: qtcreator"
            echo "  - Debugger: gdb"
            echo "  - LSP: clangd (for IDE integration)"
            echo ""
          '';
        };

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.jacktrip}/bin/jacktrip";
        };
      });
}
