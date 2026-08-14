# Architecture

## Design goal

The repository separates reusable implementation from environment orchestration without forcing two Git repositories on day one.

```text
AWX / ansible-navigator
        |
        v
playbooks/*.yml  +  inventories/<env>/
        |
        v
collections/ansible_collections/nima/platform/
        |
        +--> roles/linux_baseline
        +--> roles/docker_engine
        +--> roles/nginx_setup
        +--> roles/observability_agent
        +--> roles/ssh_bootstrap
        +--> roles/privileged_access
        +--> roles/linux_network
```

The playbooks contain targeting, rollout and role composition. Roles contain implementation. Environment values live in inventory. Secrets are injected at runtime.

## Why a monorepo first

AWX can run project-adjacent collections, so this layout gives immediate development speed while preserving the normal Galaxy collection structure and FQCNs. When `nima.platform` is later published to Galaxy/Private Automation Hub, move the collection to its own repository and add `nima.platform` to `collections/requirements.yml`; playbooks do not need to change because they already use FQCNs.

## Boundaries

- Collection: reusable logic and safe defaults.
- Inventory: host/group membership and environment policy.
- Playbooks: orchestration and rollout.
- Execution Environment: runtime dependencies.
- AWX Credentials: SSH keys/passwords/API/service secrets.
