# Offline collection stage for the Execution Environment

The EE build does not contact public Galaxy during the container build.
Instead, pinned collection artifacts are staged first under
`collections/vendor/` and `ansible-builder` installs them with
`ANSIBLE_GALAXY_CLI_COLLECTION_OPTS=--offline`.

## Prepare artifacts

Direct internet path:

```bash
make ee-vendor
```

When this host must use ProxyChains:

```bash
EE_FETCH_PREFIX=proxychains4 make ee-vendor
```

The vendor step downloads `community.general==13.3.0` and
`ansible.posix==2.2.2`, clones AWX at commit `c0aedc6e3`, and builds the
matching `awx.awx` collection tarball.

## Build the EE

```bash
make build-ee EE_IMAGE=nima-platform-ee:1.0.0
```

The Galaxy stage now consumes only local tarballs. Network access may still be
required for the base image, RPM packages, and Python packages unless those are
also mirrored internally.
