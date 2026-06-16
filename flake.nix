{
  description = "NixOS flake for Burp Suite Professional";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: {
    packages = nixpkgs.lib.genAttrs [
      "x86_64-linux"
    ] (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      burpsuitepro = pkgs.callPackage ./default.nix { };
      default = self.packages.${system}.burpsuitepro;
    });
  };
}
