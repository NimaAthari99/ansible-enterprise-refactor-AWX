# AWX bootstrap vs reconcile

There are intentionally two controller playbooks.

## `playbooks/awx-bootstrap.yml`

Run this **once from an external trusted runner**, not as an AWX Job Template.
It reads a local secret file that is deliberately excluded from Git and creates
or updates the secret-bearing AWX credentials required for normal operation.

Example:

```bash
export CONTROLLER_HOST='https://awx.example.internal'
export CONTROLLER_USERNAME='admin-or-bootstrap-service-account'
export CONTROLLER_PASSWORD='...'
export CONTROLLER_VERIFY_SSL='false'

make awx-bootstrap \
  ARGS='-e awx_bootstrap_secrets_file=/root/awx-bootstrap-secrets.yml'
```

## `playbooks/awx-controller.yml`

Run this repeatedly, including from AWX itself. It reconciles non-secret
controller configuration and obtains controller API authentication from the
`AWX Self API` custom credential created by the bootstrap step.

The corresponding AWX Job Template should use `playbooks/awx-controller.yml`,
run on localhost, and attach `AWX Self API`. It does not need a Machine
credential.

## Why the split exists

AWX cannot create the credential that grants a job access to AWX before some
trusted identity authenticates to the controller. The one-time external
bootstrap is that root of trust. After it succeeds, normal controller
configuration is self-managed and version controlled.
