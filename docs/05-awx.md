# AWX integration

## Controller authentication for this development build

The deployed AWX API identifies itself as a `24.6.2.dev...+gc0aedc6e3` development
build and does not expose `/api/v2/tokens/`. Do not use the released
`awx.awx==24.6.1` collection with username/password against this server: that
collection attempts to POST to `/api/v2/tokens/` and fails with HTTP 404.

The controller-management dependency is intentionally separate from workload
collections in `collections/requirements-controller.yml` and is pinned to the AWX
source commit matching the deployed server.

Install it with:

```bash
make controller-deps
```

Verify:

```bash
ansible-galaxy collection list awx.awx
```

For external bootstrap or plan/apply runs, export Basic Auth credentials:

```bash
export CONTROLLER_HOST='https://awx.nima.local:8043'
export CONTROLLER_USERNAME='AWX_SERVICE_ACCOUNT'
export CONTROLLER_PASSWORD='REDACTED'
export CONTROLLER_VERIFY_SSL='false'
```

Current AWX supports Basic Authentication for API requests. The matching devel
`awx.awx` collection validates credentials against `/api/v2/me/` and uses the Basic
Authorization header directly instead of creating an OAuth token.

## Bootstrap

Keep the real bootstrap secret file outside Git:

```bash
cp awx/bootstrap-secrets.example.yml /root/awx-bootstrap-secrets.yml
chmod 600 /root/awx-bootstrap-secrets.yml
make awx-bootstrap ARGS='-e awx_bootstrap_secrets_file=/root/awx-bootstrap-secrets.yml'
```

## Reconcile

After bootstrap, the `AWX Self API` credential injects the controller URL, username,
password, and TLS verification flag into `playbooks/awx-controller.yml`. The playbook
runs on `localhost` inside the Execution Environment and manages AWX through its REST
API. It does not SSH to the AWX host.

Use:

```bash
make awx-plan
make awx-apply
```

The desired state is stored in `awx/controller.yml` and covers the organization,
Galaxy association, project, inventory, project-backed inventory source, custom
credential types, Execution Environment reference, Job Templates, and survey data.
