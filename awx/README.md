# AWX Controller as Code

This repository separates bootstrap secrets from the controller's normal desired state.

## Why Basic Auth is used here

The AWX server currently deployed for this project is a development build based on
commit `c0aedc6e3`. Its API does not expose `/api/v2/tokens/`. The released
`awx.awx==24.6.1` collection is therefore incompatible when username/password are
used because that old collection tries to create a temporary OAuth token first.

`collections/requirements-controller.yml` pins `awx.awx` to the matching AWX source
commit. That collection authenticates username/password directly with HTTP Basic Auth
against `/api/v2/me/` and sends Basic Auth on subsequent API requests.

## 1. Install the matching controller collection

```bash
make controller-deps
ansible-galaxy collection list awx.awx
```

Expected collection version for the source build is `0.0.1-devel`.

## 2. Bootstrap from a trusted shell/CI runner

`playbooks/awx-bootstrap.yml` runs outside AWX. Keep the real bootstrap secret file
outside the Git checkout.

```bash
cp awx/bootstrap-secrets.example.yml /root/awx-bootstrap-secrets.yml
chmod 600 /root/awx-bootstrap-secrets.yml
```

Fill the secret file, then export controller credentials for the initial API call:

```bash
export CONTROLLER_HOST='https://awx.nima.local:8043'
export CONTROLLER_USERNAME='your-awx-admin-or-service-account'
export CONTROLLER_PASSWORD='REDACTED'
export CONTROLLER_VERIFY_SSL='false'

make awx-bootstrap ARGS='-e awx_bootstrap_secrets_file=/root/awx-bootstrap-secrets.yml'
```

The bootstrap creates the Machine credential, platform secret credential, optional SCM
credential, and the `AWX Self API` custom credential.

## 3. Reconcile from AWX

`playbooks/awx-controller.yml` never reads a local secret file. The `AWX Self API`
credential injects:

- `CONTROLLER_HOST`
- `CONTROLLER_USERNAME`
- `CONTROLLER_PASSWORD`
- `CONTROLLER_VERIFY_SSL`

The reconcile Job Template runs locally in its Execution Environment and manages the
non-secret desired state stored in `awx/controller.yml`.

## Upgrading AWX

The `awx.awx` source pin must move with the AWX server build. If the server version
changes from `...+g<commit>...`, update the commit in
`collections/requirements-controller.yml`, run `make controller-deps`, and validate
with `make awx-plan` before applying.

## Collection resolution guard

The controller collection is deliberately installed into the repository's
`./collections` directory. `ansible.cfg` puts that path ahead of user and system
collections. Run:

```bash
make controller-deps
make controller-doctor
```

`controller-doctor` prints the exact `awx.awx.organization` module Ansible will
execute and fails if the selected `controller_api.py` still contains the old
`/api/v2/tokens/` authentication flow.

The same pinned `awx.awx` Git dependency is also present in
`collections/requirements-ee.yml`, so AWX Project Sync installs a matching controller
collection for `AWX Controller Reconcile` jobs instead of silently falling back to
the collection baked into the generic AWX EE.
