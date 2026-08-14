# Migration notes

The uploaded project was already partly refactored, but its documentation, Makefile and CI described a different directory layout than the files actually used. This version makes the repository internally consistent.

Key compatibility changes:

- `nima.platform.nginx` was corrected to `nima.platform.nginx_setup`.
- Docker variables are now `docker_engine_*`.
- Nginx variables are now `nginx_setup_*`.
- Observability variables are now `observability_agent_*`.
- Linux baseline variables are now `linux_baseline_*`.
- Privileged users use `privileged_access_sudo_users`.
- SSH migration variables use `ssh_bootstrap_*`.
- The old plaintext `vault.yml` was removed.
- Third-party `community.general` source is no longer vendored into this repository.
- `ELK` mode no longer silently succeeds while doing nothing; it fails with an implementation message.

The lab inventory retains the current host/group topology. Disruptive role defaults are safe, while lab-specific opt-ins are placed in `inventories/lab/group_vars/all/platform.yml`.
