{ pkgs ? import ./nix {}
}:

pkgs.mkShell {
  buildInputs = with pkgs; [
    gnumake
    dnsutils
    (haproxy.overrideAttrs(old: {
      # fixes: https://github.com/haproxy/haproxy/issues/791
      version = "2.2.4";
      src = fetchurl {
        url = "https://www.haproxy.org/download/2.2}/src/haproxy-2.2.4.tar.gz";
        sha256 = "1qhvaixns0xgxgd095kvqid0pi6jxsld9ghvnr60khwdzzadk947";
      };
    }))
    netcat
    consul
    niv
    nomad_0_12
    levant
  ];
  shellHook = ''
    export NOMAD_ADDR=http://127.0.0.1:4646
  '';
}
