# This module defines a small NixOS installation CD.  It does not
# contain any graphical stuff.
{ config, pkgs, stdenv, ... }:
let
  install_script = pkgs.writeShellScriptBin "install.sh" ''
    NIX_CONFIG_DIR=${nix-config}
    ${builtins.readFile ./install.sh}
    '';
  nix-config = pkgs.stdenv.mkDerivation {
    name = "nix-config";
    src = ./nix-config;
    installPhase = "cp -r $src $out";
  };
in
{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>

    # Provide an initial copy of the NixOS channel so that the user
    # doesn't need to run "nix-channel --update" first.
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
  ];


  environment.systemPackages = [ nix-config install_script pkgs.git ];
}

