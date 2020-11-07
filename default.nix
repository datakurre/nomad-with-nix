{ pkgs ? import ./nix {}
, sources ? import ./nix/sources.nix
}:

pkgs.mkShell {
  buildInputs = with pkgs; [
    niv
    nomad_0_12
  ];
  shellHook = ''
    export NOMAD_ADDR=http://127.0.0.1:4646
  '';
}
