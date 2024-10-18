{
  description = "Nix developer tooling for elvish-tap";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };
        in
        {
          devShells =
            let
              inherit (pkgs) bashInteractive elvish yq mkShell;
              ci-packages =
                [
                  elvish
                  yq
                ];
            in
            {
              default = mkShell { buildInputs = ci-packages ++ [ bashInteractive ]; };

              ci = mkShell { buildInputs = ci-packages; };
            };
        }
      );
}
