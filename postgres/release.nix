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

# entrypoint
mkdir -p usr/local/bin
cat > usr/local/bin/entrypoint << EOF
#!/bin/sh
set -e
if [ ! -d \$PGDATA ]; then
  initdb -U postgres
  echo "unix_socket_directories='\$PGDATA'" >> \$PGDATA/postgresql.conf
fi
exec postgres
EOF
chmod a+x usr/local/bin/entrypoint

# artifact
tar cvzhP \
  --hard-dereference \
  --exclude="${env}" \
  --exclude="*ncurses*/ncurses*/ncurses*" \
  --files-from=${closure} \
  bin usr > $out || true
''
