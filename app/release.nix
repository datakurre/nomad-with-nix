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
mkdir -p local/bin
makeWrapper ${bashInteractive}/bin/sh local/bin/sh \
  --set PATH ${coreutils}/bin \
  --prefix PATH : ${netcat}/bin \
  --prefix PATH : ${app}/bin
tar cvhP --xz \
  --hard-dereference \
  --exclude="${env}/*" \
  --files-from=${closure} \
  local > $out || true
''
