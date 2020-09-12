{ pkgs ? import ../nix {}
}:

with pkgs;

python3.withPackages(ps: with ps; [
  fastapi
  uvicorn
])
