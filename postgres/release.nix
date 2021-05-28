{ pkgs ? import ../nix { nixpkgs = sources.nixpkgs-unstable; }
, sources ? import ../nix/sources.nix
, name ? "artifact"
}:

with pkgs;

let

  env = buildEnv {
    name = "env";
    paths = [
      bashInteractive
      coreutils
      postgresql
    ];
  };

  closure = (writeReferencesToFile env);

in

runCommand name {
  buildInputs = [ makeWrapper ];
} ''
# shell
makeWrapper ${bashInteractive}/bin/sh bin/sh \
  --prefix PATH : ${coreutils}/bin \
  --prefix PATH : ${postgresql}/bin

# artifact
tar cvzhP \
  --hard-dereference \
  --exclude="${env}" \
  --exclude="*ncurses*/ncurses*/ncurses*" \
  --files-from=${closure} \
  bin > $out || true
''
