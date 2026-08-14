SHELL := /bin/bash
COLLECTION_DIR := collections/ansible_collections/nima/platform
INVENTORY ?= inventories/lab/hosts.yml
EE_IMAGE ?= nima-platform-ee:1.0.0

.PHONY: deps static inventory lint yaml-lint syntax validate build-collection build-ee site bootstrap baseline docker nginx observability clean

deps:
	ansible-galaxy collection install -r collections/requirements.yml --force

static:
	python3 scripts/validate_structure.py

inventory:
	ansible-inventory -i $(INVENTORY) --graph

lint:
	ansible-lint playbooks $(COLLECTION_DIR)

yaml-lint:
	yamllint playbooks inventories collections/requirements.yml $(COLLECTION_DIR) execution-environment.yml

syntax:
	@for f in playbooks/*.yml; do \
		echo "==> $$f"; \
		ansible-playbook -i $(INVENTORY) --syntax-check "$$f" || exit 1; \
	done

validate: static inventory yaml-lint lint syntax

build-collection:
	mkdir -p artifacts/collections
	ansible-galaxy collection build $(COLLECTION_DIR) --force --output-path artifacts/collections

build-ee:
	ansible-builder build -f execution-environment.yml -t $(EE_IMAGE)

site:
	ansible-playbook -i $(INVENTORY) playbooks/site.yml $(ARGS)

bootstrap:
	ansible-playbook -i $(INVENTORY) playbooks/bootstrap.yml $(ARGS)

baseline:
	ansible-playbook -i $(INVENTORY) playbooks/baseline.yml $(ARGS)

docker:
	ansible-playbook -i $(INVENTORY) playbooks/docker.yml $(ARGS)

nginx:
	ansible-playbook -i $(INVENTORY) playbooks/nginx.yml $(ARGS)

observability:
	ansible-playbook -i $(INVENTORY) playbooks/observability.yml $(ARGS)

clean:
	rm -rf artifacts context
