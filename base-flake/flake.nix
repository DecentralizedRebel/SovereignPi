{
  description = "Base flake for setting up essentials";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs = { self, nixpkgs }: let
    system = "aarch64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    defaultPackage.${system} = pkgs.stdenv.mkDerivation {
      name = "base-setup";
      src = ./.;

      buildInputs = [
        pkgs.docker
        pkgs.cryptsetup
        pkgs.btrfs-progs
        pkgs.git  # For version control
        pkgs.curl # Useful for downloading files
        pkgs.vim # Simple text editor, can be swapped for nano or emacs depending on your preferences
        pkgs.networkmanager # Network management tools
        pkgs.openssh # For SSH server/client
      ];

      # Optional shell hooks to inform users when the environment is ready
      shellHook = ''
        echo "Base environment ready with Docker, Cryptsetup, Btrfs, and other essential tools."
      '';
    };

    # Optional devShell configuration for those who prefer using a nix-shell
    devShell.${system} = pkgs.mkShell {
      buildInputs = [
        pkgs.docker
        pkgs.cryptsetup
        pkgs.btrfs-progs
      ];

      shellHook = ''
        echo "You are now in a base development shell with Docker, Cryptsetup, and Btrfs."
      '';
    };

    # A helper function that can be used by other flakes to inherit this base setup
    packages.${system}.baseSetup = self.defaultPackage.${system};
  };
}
