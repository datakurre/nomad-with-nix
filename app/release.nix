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
# shell
makeWrapper ${bashInteractive}/bin/sh bin/sh \
  --set PATH ${coreutils}/bin \
  --prefix PATH : ${netcat}/bin \
  --prefix PATH : ${app}/bin

# executables
mkdir -p usr/local/bin
for filename in ${env}/bin/??*; do
  cat > usr/local/bin/$(basename $filename) << EOF
#!/bin/sh
set -e
exec $(basename $filename) "\$@"
EOF
done
chmod a+x usr/local/bin/*

# artifact
tar cvzhP \
  --hard-dereference \
  --exclude="${env}/*" \
  --files-from=${closure} \
  bin usr > $out || true
''
