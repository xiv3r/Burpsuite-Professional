{
  description = "Nix flake for Burp Suite Professional";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    forEachSystem = nixpkgs.lib.genAttrs supportedSystems;
  in {
    packages = forEachSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      isLinux = nixpkgs.lib.hasSuffix "-linux" system;
      burpsuitepro =
        if isLinux
        then pkgs.callPackage ./default.nix { }
        else pkgs.callPackage ./darwin.nix { };
    in {
      inherit burpsuitepro;
      default = self.packages.${system}.burpsuitepro;
    });
  };
}
