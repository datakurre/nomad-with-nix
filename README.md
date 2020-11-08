Service mesh with Nomad and Nix
===============================

(Not to forget Consul and HAProxy for the "mesh" part.)

This complete example demonstrates how Nix could be used to package fully self-contained application archives for Nomad's [Isolated Fork/Exec Driver](https://www.nomadproject.io/docs/drivers/exec).

This example assumes [Nix](https://nixos.org/download.html) and works best with [Nix and direnv](https://nix.dev/tutorials/declarative-and-reproducible-developer-environments.html#direnv-automatically-activating-the-environment-on-directory-change).

```bash
$ direnv allow
$ make serve
```

or

```bash
$ nix-shell
$ make serve
```

Warning: The example above does use sudo to be able to execute Nomad jobs with [exec driver](https://www.nomadproject.io/docs/drivers/exec).

All components, which are orchestrated with Nomad, have random port allocations, which are visible at Nomad's UI at [http://localhost:4646](http://localhost:4646). HAProxy is run outside Nomad end serves the example application at [http://localhost:8800](http://localhost:8800).

In addition, this examples contains [Raw Fork/Exec Driver](https://www.nomadproject.io/docs/drivers/raw_exec) based development mode, where Nomad could be run without sudo, and application is executed directly from the project directory without any isolation:

```bash
$ nix-shell
$ make development
```
