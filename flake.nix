{
  description = "dotfiles";

  inputs = {
    # Use `github:NixOS/nixpkgs/nixpkgs-26.05-darwin` to use Nixpkgs 26.05.
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    # The darwin branch above only carries Mac binaries; NixOS hosts build from this one.
    nixos.url = "github:NixOS/nixpkgs/nixos-26.05";
    # Stable lags fast-moving tools by weeks; oci takes only claude-code from here.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Use `github:nix-darwin/nix-darwin/nix-darwin-26.05` to use Nixpkgs 26.05.
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    # Declarative partitioning; nixos-anywhere uses it to format the server at install time.
    disko.url = "github:nix-community/disko/v1.13.0";
    disko.inputs.nixpkgs.follows = "nixos";
  };

  outputs = inputs@{ self, nix-darwin, nix-homebrew, home-manager, nixpkgs, nixos, nixpkgs-unstable, disko }:
    let
      # The one username line to change if this isn't your machine.
      # bootstrap.sh offers to rewrite this for you if your macOS username differs.
      user = "hansen";

      # Shared home.nix plus the platform's layer on top.
      homeManager = platformHome: {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        # Move pre-existing files (e.g. a hand-written ~/.zshrc) to *.backup instead of failing the switch.
        home-manager.backupFileExtension = "backup";
        home-manager.extraSpecialArgs = { inherit user; };
        home-manager.users.${user}.imports = [ ./home.nix platformHome ];
      };
    in
    {
      darwinConfigurations."mac" = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit user; };
        modules = [
          ./configuration.nix
          nix-homebrew.darwinModules.nix-homebrew
          home-manager.darwinModules.home-manager
          (homeManager ./home-darwin.nix)
        ];
      };

      # Oracle Cloud Ampere A1 server. Installed with nixos-anywhere: see docs/oracle-cloud-nixos.md.
      nixosConfigurations."oci" = nixos.lib.nixosSystem {
        specialArgs = { inherit user; };
        modules = [
          disko.nixosModules.disko
          ./hosts/oci/configuration.nix
          ./hosts/oci/hardware.nix
          ./hosts/oci/disk.nix
          {
            nixpkgs.overlays = [
              (final: prev: {
                claude-code = (import nixpkgs-unstable {
                  system = prev.stdenv.hostPlatform.system;
                  config.allowUnfree = true;
                }).claude-code;
              })
            ];
          }
          home-manager.nixosModules.home-manager
          (homeManager ./home-linux.nix)
        ];
      };
    };
}
