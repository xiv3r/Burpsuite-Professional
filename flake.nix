{
  description = "A nixos flake for burpsuite pro";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    systems = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    forAllSystems = nixpkgs.lib.genAttrs systems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in {
        burpsuitepro = pkgs.callPackage ./default.nix { };
        default = self.packages.${system}.burpsuitepro;
      }
    );
  in {
    packages = forAllSystems;
  };
}
