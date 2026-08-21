# Ansible Role: nima_local_ca_role

Adds the Nima Local Root CA to:
- Podman/container registry trust path
- System CA trust store

Also validates the CA certificate fingerprint and subject on awx-server-1 (or any target host where the role runs).
