{
  description = "NixOS + home-manager для Ark-by";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
  let
    system = "x86_64-linux";
  in {
    # ── Этап 1: standalone home-manager на Arch (без переустановки) ──────────
    # Запуск: nix run home-manager/master -- switch --flake ./nixos#ark@arch
    homeConfigurations."ark@arch" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.${system};
      modules = [ ./home-arch.nix ];
      extraSpecialArgs = { inherit inputs; };
    };

    # ── Этап 2: полноценный NixOS ───────────────────────────────────────────
    nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
      inherit system;

      modules = [
        ./configuration.nix

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "bak";
          home-manager.users.ark = import ./home.nix;
          home-manager.extraSpecialArgs = { inherit inputs; };
        }
      ];
    };
  };
}
