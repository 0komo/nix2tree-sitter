{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flakelight.url = "github:nix-community/flakelight";
  };

  outputs =
    { self, flakelight, ... }@inputs:
    flakelight ./. {
      inherit inputs;

      formatters =
        pkgs: with pkgs; {
          "*.nix" = "${nixfmt-rfc-style}/bin/nixfmt";
        };

      devShell = {
        packages =
          { nixdoc, nix-unit, ... }:
          [
            nixdoc
            nix-unit
          ];
      };

      lib = import ./.;
    };
}
