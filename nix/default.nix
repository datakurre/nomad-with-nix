{ sources ? import ./sources.nix }:

let

  overlay = _: pkgs: {

    levant = pkgs.buildGoPackage rec {
      name = "levant-${version}";
      version = "2020-11-06";
      src = sources.levant;
      goPackagePath = "github.com/hashicorp/levant";
      goDeps = ./levant-deps.nix;
      preBuild = ''
        rm -r go/src/github.com/hashicorp/nomad/vendor/github.com/hashicorp/nomad
      '';
    };

  };

  pkgs = import sources.nixpkgs {
    overlays = [ overlay ];
    config = {};
  };

in pkgs
