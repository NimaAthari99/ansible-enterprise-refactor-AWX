# Offline collection stage for the Execution Environment

The EE build does not contact public Galaxy during the container build. The
vendor preparation step also avoids Galaxy entirely: it fetches pinned source
revisions from GitHub, builds collection artifacts locally under
`collections/vendor/`, and `ansible-builder` installs those artifacts with
`ANSIBLE_GALAXY_CLI_COLLECTION_OPTS=--offline`.

## Prepare artifacts

Direct GitHub path:

```bash
make ee-vendor
```

Only when this host truly requires ProxyChains for GitHub:

```bash
EE_FETCH_PREFIX=proxychains4 make ee-vendor
```

The vendor step builds these exact artifacts:

- `community.general==13.3.0`
- `ansible.posix==2.2.2`
- `community.library_inventory_filtering_v1==1.1.5`
- `awx.awx` from AWX commit `c0aedc6e37f453b885879717ca066397309e1c83` (short: `c0aedc6e3`)

`community.general` 13.3.0 declares
`community.library_inventory_filtering_v1 >= 1.0.0`. The helper collection is
therefore pinned explicitly; otherwise an offline install would have an
incomplete dependency graph.

The public Galaxy API is not used in this workflow. Prefer the direct GitHub path when it works. If `ee-vendor` fails, test GitHub connectivity instead of Galaxy connectivity:

```bash
EE_FETCH_PREFIX=proxychains4 git ls-remote \
  https://github.com/ansible-collections/community.general.git \
  refs/tags/13.3.0
```

## Build the EE

```bash
make build-ee EE_IMAGE=nima-platform-ee:1.0.0 \
  ANSIBLE_BUILDER=/opt/ansible-builder-venv/bin/ansible-builder
```

The Galaxy stage consumes only local tarballs. Network access may still be
required for the base image, RPM packages, and Python packages unless those are
also mirrored internally.
