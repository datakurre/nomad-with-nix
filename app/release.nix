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

# entrypoint
mkdir -p usr/local/bin
cat > usr/local/bin/entrypoint << EOF
#!/bin/sh
set -e
exec uvicorn main:app --host 0.0.0.0 --port \$HTTP_PORT
EOF
chmod a+x usr/local/bin/entrypoint

# artifact
tar cvzhP \
  --hard-dereference \
  --exclude="${env}/*" \
  --files-from=${closure} \
  bin usr > $out || true
''
