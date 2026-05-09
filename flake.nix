{
  description = "NixOS Konfiguration für nuc und testy";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix-rekey = {
      url = "github:oddlama/agenix-rekey";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, disko, agenix, agenix-rekey, nixos-wsl, home-manager, ... }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      overlays = [ agenix-rekey.overlays.default ];
    };
    unstable = import nixpkgs-unstable { inherit system; config.allowUnfree = true; };
  in
  {
    # Installer-ISO mit r8125 Treiber (für nuc)
    packages.${system}.isoImage = (nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        {
          boot.extraModulePackages = [ pkgs.linuxPackages.r8125 ];
          boot.supportedFilesystems = [ "zfs" ];

          # Konfiguration ist auf der ISO vorinstalliert
          environment.etc."nixos-config".source = ./.;

          environment.systemPackages = with pkgs; [ git ];
        }
      ];
    }).config.system.build.isoImage;

    # NUC (Home Assistant, ZFS, restic client)
    nixosConfigurations.nuc = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        disko.nixosModules.disko
        agenix.nixosModules.default
        agenix-rekey.nixosModules.default
        ./modules/common.nix
        ./hosts/nuc
      ];
    };

    # testy (Hetzner VM: Vaultwarden, restic REST server)
    nixosConfigurations.testy = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        agenix.nixosModules.default
        agenix-rekey.nixosModules.default
        ./modules/common.nix
        ./hosts/testy
      ];
    };

    # wsl (NixOS-WSL dev machine)
    nixosConfigurations.wsl = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit unstable; };
      modules = [
        nixos-wsl.nixosModules.default
        home-manager.nixosModules.home-manager
        ./modules/common.nix
        ./hosts/wsl
      ];
    };

    # agenix-rekey CLI entry points (`nix run .#agenix-rekey.<system>.<app>`)
    agenix-rekey = agenix-rekey.configure {
      userFlake = self;
      nixosConfigurations = self.nixosConfigurations;
      darwinConfigurations = self.darwinConfigurations or { };
    };

    # `nix develop` provides the `agenix` CLI from agenix-rekey
    devShells.${system}.default = pkgs.mkShell {
      packages = [ pkgs.agenix-rekey ];
    };
  };
}
