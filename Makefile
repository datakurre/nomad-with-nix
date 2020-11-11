export CONSUL_IP=127.0.0.1
export CONSUL_PORT=8500
export CONSUL_ADDR=http://$(CONSUL_IP):$(CONSUL_PORT)
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
	@echo CONSUL_ADDR: $(CONSUL_ADDR)
	@echo NOMAD_ADDR: $(NOMAD_ADDR)
	@echo NOMAD_HOME: $(NOMAD_HOME)
	@echo NOMAD_NIX: $(NOMAD_NIX)
	@echo NIX_SHELL: $(NIX_SHELL)

.PHONY: app-artifact
app-artifact:
	make -C app

.PHONY: postgres-artifact
postgres-artifact:
	make -C postgres

.PHONY: serve-artifacts
serve-artifacts:
	make -j app-artifact postgres-artifact
	nix-shell -p python3 --run "python3 -m http.server --directory artifacts 8080"

.PHONY: run-haproxy
run-haproxy:
	haproxy -f haproxy.conf

.PHONY: run-consul
run-consul:
	consul agent -dev

.PHONY: run-nomad
run-nomad:
	HOME=$(NOMAD_HOME) NIX_SHELL=$(NIX_SHELL) \
	nomad agent -dev -data-dir=$(NOMAD_HOME)

.PHONY: run-nomad-root
run-nomad-root:
	HOME=$(NOMAD_HOME) \
	sudo $(shell which nomad) agent -dev -data-dir=$(NOMAD_HOME)

.PHONY: run-job
run-job: $(NOMAD_JOB)
	while ! nc -z $(NOMAD_IP) $(NOMAD_PORT); do \
	echo "Waiting for nomad at $(NOMAD_ADDR)"; sleep 2; done
	nomad run $(NOMAD_JOB)

.PHONY: run-artifact-job
run-artifact-job: $(NOMAD_JOB)
	while ! nc -z $(NOMAD_IP) $(NOMAD_PORT); do \
	echo "Waiting for nomad at $(NOMAD_ADDR)"; sleep 2; done
	while ! nc -z 127.0.0.1 8080; do \
	echo "Waiting for artifacts at 127.0.0.1:8080"; sleep 2; done
	levant deploy -var-file ${NOMAD_VARIABLES} $(NOMAD_JOB)

.PHONY: develop
develop:
	make -j run-consul run-nomad run-job

.PHONY: serve
serve:
	make \
	NOMAD_VARIABLES=production.json NOMAD_JOB=production.hcl -j \
	serve-artifacts run-haproxy run-consul run-nomad-root run-artifact-job
