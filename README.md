Service mesh with Nomad and Nix
===============================

With Consul and HAProxy.

This example assumes [Nix](https://nixos.org/download.html) and works best with [Nix and direnv](https://nix.dev/tutorials/declarative-and-reproducible-developer-environments.html#direnv-automatically-activating-the-environment-on-directory-change).

```bash
$ direnv allow
$ make serve
```

Warning: The example above does use sudo to be able to execute Nomad jobs with [exec driver](https://www.nomadproject.io/docs/drivers/exec).
