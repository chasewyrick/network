{ config, lib, pkgs, ... }:
let
  inherit (lib) mkIf mkOption types;
  cfg = config.services.standard;
  secrets = import ../../secrets.nix;
in {
  config = {
    nixpkgs.config.allowUnfree = true;
    services.openssh = {
      enable = true;
      passwordAuthentication = false;
    };

    networking.firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };

    users = {
      mutableUsers = false;
      users = {
        root.openssh.authorizedKeys.keyFiles = [
          secrets.root.keys
        ];

        grahamc = {
          isNormalUser = true;
          uid = 1000;
          extraGroups = [ "wheel" ];
          createHome = true;
          home = "/home/grahamc";
          hashedPassword = secrets.grahamc.password;
          openssh.authorizedKeys.keyFiles = [
            secrets.grahamc.keys
          ];
        };
      };
    };

    nix = {
      useSandbox = true;
      nixPath = [
        # Ruin the config so we don't accidentally run
        # nixos-rebuild switch on the host
        (let
          cfg = pkgs.writeText "configuration.nix"
            ''
              assert builtins.trace "Hey dummy, you're on your server! Use NixOps!" false;
              {}
            '';
         in "nixos-config=${cfg}")

         # Copy the channel version from the deploy host to the target
         "nixpkgs=/run/current-system/nixpkgs"
      ];
    };

    system.extraSystemBuilderCmds = ''
      ln -sv ${pkgs.path} $out/nixpkgs
    '';
    environment.etc.host-nix-channel.source = pkgs.path;
  };
}
