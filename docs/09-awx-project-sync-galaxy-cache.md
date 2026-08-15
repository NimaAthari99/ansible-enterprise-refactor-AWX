# AWX Project Sync and the ansible-galaxy `results` cache failure

A Project Update can fail with output similar to:

```text
Skipping Galaxy server https://galaxy.ansible.com/ ... 'results'
ERROR! Unexpected Exception, this is probably a bug: 'results'
```

This is an `ansible-galaxy` response-cache failure, not a malformed `community.general` requirement. Ansible upstream has documented this failure mode and recommends clearing or bypassing the Galaxy response cache as a workaround.

For this repository the permanent design is simpler: do not download third-party collections during AWX Project Sync. `collections/requirements-ee.yml` is consumed only while building the Execution Environment. There is intentionally no `collections/requirements.yml`, so Project Update only updates source code.

For diagnosing an already affected CLI environment, run the equivalent install manually with a fresh/disabled cache if that `ansible-galaxy` version supports it:

```bash
ansible-galaxy collection install -r collections/requirements-ee.yml --clear-response-cache -vvv
```

or:

```bash
ansible-galaxy collection install -r collections/requirements-ee.yml --no-cache -vvv
```

This is a diagnostic/build-host workaround. Do not patch AWX's `project_update.yml` merely to add those flags; keeping runtime dependencies in the EE removes the dependency from Project Sync entirely.
