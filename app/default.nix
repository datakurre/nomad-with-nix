{ pkgs ? import ../nix {}
}:

with pkgs;
with python3Packages;

buildPythonPackage {
  pname = "app";
  version = "1.0";
  src = lib.cleanSource ./.;
  buildInputs = [
    mypy
  ];
  propagatedBuildInputs = [
    asyncpg
    databases
    fastapi
    psycopg2
    uvicorn
  ];
}
