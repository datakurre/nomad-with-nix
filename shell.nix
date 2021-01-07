{ pkgs ? import ./nix {}
, pkgs_nomad ? import ./nix { nixpkgs = sources.nixpkgs-unstable; }
, sources ? import ./nix/sources.nix
}:

pkgs.mkShell {
  buildInputs = with pkgs; [
    gnumake
    dnsutils
    netcat
    consul
    niv
    pkgs_nomad.nomad_1_0
    cni-plugins
  ];
  shellHook = ''
    export NOMAD_ADDR=http://127.0.0.1:4646
    echo ln -s "${pkgs.cni-plugins}"/bin /opt/cni/bin
  '';
}
