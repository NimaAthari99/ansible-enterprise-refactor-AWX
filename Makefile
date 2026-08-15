CONTROLLER_NO_PROXY ?= localhost,127.0.0.1,awx.nima.local,.nima.local,awx-server-1

SHELL := /bin/bash
COLLECTION_DIR := collections/ansible_collections/nima/platform
INVENTORY ?= inventories/lab/hosts.yml
EE_IMAGE ?= nima-platform-ee:1.0.0
PROJECT_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
CONTROLLER_ENV := ANSIBLE_CONFIG=$(PROJECT_ROOT)/ansible.cfg ANSIBLE_COLLECTIONS_PATH=$(PROJECT_ROOT)/collections ANSIBLE_COLLECTIONS_SCAN_SYS_PATH=false \
	NO_PROXY=$(CONTROLLER_NO_PROXY) \
	no_proxy=$(CONTROLLER_NO_PROXY)

.PHONY: deps controller-deps controller-version controller-doctor static inventory lint yaml-lint syntax controller-syntax validate build-collection ee-vendor ee-vendor-check build-ee awx-plan awx-apply site bootstrap baseline docker nginx observability clean

deps:
	ansible-galaxy collection install -r collections/requirements-ee.yml --force

controller-deps:
	rm -rf $(PROJECT_ROOT)/collections/ansible_collections/awx/awx
	ANSIBLE_COLLECTIONS_PATH=$(PROJECT_ROOT)/collections ansible-galaxy collection install -r $(PROJECT_ROOT)/collections/requirements-controller.yml -p $(PROJECT_ROOT)/collections --force

controller-version:
	ansible-galaxy collection list awx.awx

controller-doctor:
	$(CONTROLLER_ENV) python3 $(PROJECT_ROOT)/scripts/controller_doctor.py

static:
	python3 scripts/validate_structure.py

inventory:
	ansible-inventory -i $(INVENTORY) --graph

lint:
	ansible-lint playbooks $(COLLECTION_DIR)

yaml-lint:
	yamllint playbooks inventories collections/requirements-ee.yml collections/requirements-ee-offline.yml collections/requirements-controller.yml $(COLLECTION_DIR) execution-environment.yml

syntax:
	@for f in playbooks/*.yml; do \
		if [[ "$$f" == "playbooks/awx-controller.yml" ]]; then continue; fi; \
		echo "==> $$f"; \
		ansible-playbook -i $(INVENTORY) --syntax-check "$$f" || exit 1; \
	done

controller-syntax:
	ansible-playbook --syntax-check playbooks/awx-controller.yml

validate: static inventory yaml-lint lint syntax

build-collection:
	mkdir -p artifacts/collections
	ansible-galaxy collection build $(COLLECTION_DIR) --force --output-path artifacts/collections

ee-vendor:
	./scripts/vendor_ee_collections.sh

ee-vendor-check:
	@test -f collections/vendor/community-general-13.3.0.tar.gz || (echo "Missing vendored community.general artifact; run make ee-vendor"; exit 2)
	@test -f collections/vendor/ansible-posix-2.2.2.tar.gz || (echo "Missing vendored ansible.posix artifact; run make ee-vendor"; exit 2)
	@test -f collections/vendor/awx-awx-0.0.1-devel.tar.gz || (echo "Missing vendored awx.awx artifact; run make ee-vendor"; exit 2)

build-ee: ee-vendor-check
	ansible-builder build -f execution-environment.yml -t $(EE_IMAGE)

awx-plan: controller-doctor
	$(CONTROLLER_ENV) ansible-playbook --check $(PROJECT_ROOT)/playbooks/awx-controller.yml $(ARGS)

awx-apply: controller-doctor
	$(CONTROLLER_ENV) ansible-playbook $(PROJECT_ROOT)/playbooks/awx-controller.yml $(ARGS)

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

.PHONY: awx-bootstrap awx-reconcile
awx-bootstrap:
	$(CONTROLLER_ENV) ansible-playbook $(PROJECT_ROOT)/playbooks/awx-bootstrap.yml $(ARGS)

awx-reconcile:
	$(CONTROLLER_ENV) ansible-playbook $(PROJECT_ROOT)/playbooks/awx-controller.yml $(ARGS)
