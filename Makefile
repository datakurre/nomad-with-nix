export NOMAD_IP=127.0.0.1
export NOMAD_PORT=4646
export NOMAD_ADDR=http://$(NOMAD_IP):$(NOMAD_PORT)
export NOMAD_HOME=$(shell pwd)/.cache
export NOMAD_NIX=$(shell pwd)/nomad.nix
export NOMAD_JOB=development.hcl

export NIX_SHELL=$(shell which nix-shell)

.PHONY: all
all: develop

.PHONY: clean
clean:
	nomad system gc

.PHONY: show
show:
	@echo NOMAD_ADDR: $(NOMAD_ADDR)
	@echo NOMAD_HOME: $(NOMAD_HOME)
	@echo NOMAD_NIX: $(NOMAD_NIX)
	@echo NIX_SHELL: $(NIX_SHELL)

.PHONY: server-artifacts
serve-artifacts:
	make -C app
	nix-shell -p python3 --run "python3 -m http.server --directory artifacts 8080"

.PHONY: run-nomad
run-nomad:
	HOME=$(NOMAD_HOME) NIX_SHELL=$(NIX_SHELL) \
	nomad agent -dev -data-dir=$(NOMAD_HOME)

.PHONY: run-job
run-job: $(NOMAD_JOB)
	while ! nc -z $(NOMAD_IP) $(NOMAD_PORT); do \
	echo "Waiting for nomad at $(NOMAD_ADDR)"; sleep 2; done
	nomad run $(NOMAD_JOB)

.PHONY: develop
develop:
	make -j run-nomad run-job

.PHONY: serve
serve:
	sudo make NOMAD_JOB=production.hcl -j serve-artifacts run-nomad run-job
