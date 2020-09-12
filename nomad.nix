{ pkgs ? import ./nix {}
, app ? import ./app { inherit pkgs; }
}:

pkgs.mkShell {
  buildInputs = with pkgs; [
    app
  ];
}
