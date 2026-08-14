# nima.platform

Reusable roles used by the control project in this repository.

## Roles

- `nima.platform.linux_baseline`
- `nima.platform.privileged_access`
- `nima.platform.ssh_bootstrap`
- `nima.platform.linux_network`
- `nima.platform.docker_engine`
- `nima.platform.nginx_setup`
- `nima.platform.observability_agent`

Build the Galaxy artifact from the repository root:

```bash
make build-collection
```

The generated tarball is written to `artifacts/collections/` and can be published to Ansible Galaxy or an internal Galaxy/Automation Hub-compatible server.
