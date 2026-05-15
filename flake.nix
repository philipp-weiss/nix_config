{
  description = "NixOS Konfiguration für nuc und bastion";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
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

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, flake-parts, disko, agenix, agenix-rekey, nixos-wsl, home-manager, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      imports = [ agenix-rekey.flakeModule ];

      perSystem = { config, pkgs, system, ... }: {
        # Installer-ISO mit r8125 Treiber (für nuc)
        packages.isoImage = (nixpkgs.lib.nixosSystem {
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

        # wsl has no secrets and no SSH host key yet; include it once it does.
        agenix-rekey.nixosConfigurations =
          nixpkgs.lib.filterAttrs (n: _: n != "wsl") self.nixosConfigurations;

        # `nix develop` provides the `agenix` CLI from agenix-rekey
        devShells.default = pkgs.mkShell {
          packages = [ config.agenix-rekey.package ];
        };
      };

      flake.nixosConfigurations =
        let
          system = "x86_64-linux";
          unstable = import nixpkgs-unstable { inherit system; config.allowUnfree = true; };
        in {
          # NUC (Home Assistant, ZFS, restic client)
          nuc = nixpkgs.lib.nixosSystem {
            inherit system;
            modules = [
              disko.nixosModules.disko
              agenix.nixosModules.default
              agenix-rekey.nixosModules.default
              ./modules/common.nix
              ./hosts/nuc
            ];
          };

          # bastion (Hetzner VM: Vaultwarden, restic REST server, headscale)
          bastion = nixpkgs.lib.nixosSystem {
            inherit system;
            modules = [
              agenix.nixosModules.default
              agenix-rekey.nixosModules.default
              ./modules/common.nix
              ./hosts/bastion
            ];
          };

          # wsl (NixOS-WSL dev machine)
          wsl = nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = { inherit unstable; };
            modules = [
              nixos-wsl.nixosModules.default
              home-manager.nixosModules.home-manager
              ./modules/common.nix
              ./hosts/wsl
            ];
          };
        };
    };
}
