# linux_network

Configures `/etc/network/interfaces` for hosts that explicitly use `ifupdown`.

The role does not guess interface names or addresses. Callers must provide `linux_network_interfaces`, and can optionally require specific physical interfaces with `linux_network_required_interfaces`. This role is intentionally kept out of `site.yml`; run `playbooks/network.yml` against one explicit target or small batch.
