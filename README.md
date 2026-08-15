# Ansible Galaxy + AWX Platform Automation

This repository is an AWX-ready monorepo with a real Ansible Galaxy collection embedded beside thin control-plane playbooks and inventories.


> **AWX dependency model:** third-party collections are baked into the Execution Environment from `collections/requirements-ee.yml`. This repository intentionally has no `collections/requirements.yml`, so an AWX Project Sync does not contact Galaxy.

## Layout

```text
.
├── collections/
│   ├── requirements.yml
│   └── ansible_collections/nima/platform/   # reusable Galaxy collection
├── inventories/
│   ├── lab/hosts.yml
│   ├── staging/hosts.yml
│   └── production/hosts.yml
├── playbooks/                               # thin orchestration only
├── awx/                                     # AWX credential examples/runbook
├── docs/
├── execution-environment.yml
├── ansible.cfg
└── Makefile
```

The collection exposes these FQCN roles:

- `nima.platform.linux_baseline`
- `nima.platform.privileged_access`
- `nima.platform.ssh_bootstrap`
- `nima.platform.linux_network`
- `nima.platform.docker_engine`
- `nima.platform.nginx_setup`
- `nima.platform.observability_agent`

## Local workflow

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt
make deps
make validate
make site ARGS='--check --diff --limit nginx-server-1'
```

Build the reusable collection with `make build-collection` and the Execution Environment with `make build-ee`.

## AWX workflow

AWX resources are now converged as code with `playbooks/awx-controller.yml` and `awx/controller.yml`. Only bootstrap API authentication and encrypted secret inputs stay outside Git. See `docs/05-awx.md`.

## Security notice

The uploaded source archive contained plaintext credentials. They were removed from this refactor and are not present in the generated repository. Treat those original values as compromised and rotate them before using this project. Deleting a secret from the current tree does not remove it from an existing Git history.


### Controller API proxy bypass

The AWX controller API is an internal endpoint. `awx/controller.yml` defines `awx_controller_no_proxy`, and the bootstrap/reconcile playbooks export both `NO_PROXY` and `no_proxy`. Their preflight `uri` request also uses `use_proxy: false` and is forced to run in check mode, so `make awx-plan` validates the real TLS/API path instead of silently skipping it.
