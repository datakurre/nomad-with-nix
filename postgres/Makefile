ARTIFACT_NAME = postgresql
ARTIFACT_VERSION ?= 11.9-0
ARTIFACT_FULLNAME ?= ../artifacts/$(ARTIFACT_NAME)-$(ARTIFACT_VERSION).tar.gz

SOURCES := $(shell find . -name "*.py")

.PHONY: all
all: ${ARTIFACT_FULLNAME}

${ARTIFACT_FULLNAME}: $(SOURCES)
	nix-build release.nix --no-out-link --argstr name $(ARTIFACT_FULLNAME)|\
	xargs -Iresult cp -aL result $(ARTIFACT_FULLNAME)
	chmod u+w $(ARTIFACT_FULLNAME)
