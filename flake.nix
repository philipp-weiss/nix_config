{
  description = "NixOS Konfiguration für nuc und testy";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, agenix, ... }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
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
        ./hosts/nuc
      ];
    };

    # testy (Hetzner VM: Vaultwarden, restic REST server)
    nixosConfigurations.testy = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        agenix.nixosModules.default
        ./hosts/testy
      ];
    };
  };
}
