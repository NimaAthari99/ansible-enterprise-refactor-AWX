# Local development

Create a virtual environment and install pinned development tooling:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt
make deps
```

Validate before committing:

```bash
make validate
```

Useful targeted runs:

```bash
make baseline ARGS='--check --diff --limit nginx-server-1'
make docker ARGS='--check --diff --limit tools-server-1'
make nginx ARGS='--check --diff --limit nginx-server-1'
```

`playbooks/network.yml` intentionally requires `target_hosts` and rejects `all` because network changes can remove the controller's own path to a host.
