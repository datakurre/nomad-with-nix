{ sources ? import ./sources.nix
, nixpkgs ? sources.nixpkgs
}:

let

  overlay = _: pkgs: {};

  pkgs = import nixpkgs {
    overlays = [ overlay ];
    config = {};
  };

in pkgs
