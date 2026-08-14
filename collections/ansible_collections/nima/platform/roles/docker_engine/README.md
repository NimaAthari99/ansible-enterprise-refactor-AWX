# docker_engine

Installs Docker Engine from a configurable Debian-compatible repository and manages daemon/proxy settings.

Use the role with the FQCN `nima.platform.docker_engine`. All public role variables are prefixed with `docker_engine_` so the role can coexist safely with other roles in large inventories.

The default repository is Docker's official Debian repository. Internal mirrors can override `docker_engine_repo_base_url`, distribution, component, certificate validation, and the explicitly opt-in insecure repository flag from inventory.
