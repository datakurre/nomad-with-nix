{ pkgs ? import ../nix {}
}:

with pkgs;
with python3Packages;

buildPythonPackage {
  pname = "app";
  version = "1.0";
  src = lib.cleanSource ./.;
  propagatedBuildInputs = [
    databases
    fastapi
    uvicorn
  ];
}
