# Execution Environment

`execution-environment.yml` uses Ansible Builder schema version 3. Third-party runtime dependencies are installed from `collections/requirements-ee.yml` **at image build time**.

This is deliberate: AWX Project Sync should only update the Git checkout. It must not depend on public Galaxy being reachable on every sync. The project therefore does **not** contain `collections/requirements.yml`, because AWX treats that exact filename as a trigger to run `ansible-galaxy collection install` during Project Update.

Build locally:

```bash
make build-ee EE_IMAGE=registry.example.invalid/automation/nima-platform-ee:1.0.0
```

Push the image to the registry used by AWX, then register it under **Administration > Execution Environments** and select it on the Job Templates.

The EE contains:

- pinned `ansible-core`
- `community.general`
- `ansible.posix`
- the AWX controller collection required by the controller-as-code playbooks
- Python and system dependencies from `requirements-ee.txt` and `bindep.txt`

The local `nima.platform` collection is intentionally not baked into the image in this monorepo phase. It travels with the AWX Project checkout under `collections/ansible_collections/nima/platform`, so a Git revision and the local automation code remain aligned.

## Why there is no `collections/requirements.yml`

AWX automatically executes `ansible-galaxy collection install` during Project Update when `collections/requirements.yml` exists. That makes every source sync depend on Galaxy networking, proxy behavior, and the `ansible-galaxy` response cache. For this repository, external runtime dependencies belong in the immutable Execution Environment instead.

If `nima.platform` later becomes an independently published collection, add its pinned release to `collections/requirements-ee.yml` and remove the project-adjacent source copy.
