{ sources ? import ./sources.nix }:

let

  overlay = _: pkgs: {
  };

  pkgs = import sources.nixpkgs {
    overlays = [ overlay ];
    config = {};
  };

in pkgs
