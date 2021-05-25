{ pkgs ? import ../nix {}
, app ? import ./. { inherit pkgs; }
, name ? "artifact"
}:

with pkgs;

let

  env = buildEnv {
    name = "env";
    paths = [
      bashInteractive
      coreutils
      netcat
      app
    ];
  };

  closure = (writeReferencesToFile env);

in

runCommand name {
  buildInputs = [ makeWrapper ];
} ''
mkdir -p bin
makeWrapper ${bashInteractive}/bin/sh bin/sh \
  --set PATH ${coreutils}/bin \
  --prefix PATH : ${netcat}/bin \
  --prefix PATH : ${app}/bin
tar cvzhP \
  --hard-dereference \
  --exclude="${env}/*" \
  --files-from=${closure} \
  bin > $out || true
''
