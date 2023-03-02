# nix-iso
Builder for nix installer iso that automates the nixOS install using my .nix-config.

## Instructions
1. Run `./build_iso.sh` to build the installer iso
2. Write to usb (The iso is generated in result/iso/)
3. Boot usb and type `install.sh` to start installation


#### References
- https://nixos.wiki/wiki/Creating_a_NixOS_live_CD
- https://nixos.org/manual/nixos/stable/index.html#sec-installation
- https://gist.github.com/nuxeh/35fb0eca2af4b305052ca11fe2521159
