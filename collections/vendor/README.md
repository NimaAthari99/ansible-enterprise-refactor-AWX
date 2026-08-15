# Vendored Execution Environment collections

This directory is populated by `scripts/vendor_ee_collections.sh` before the
Execution Environment image is built.

Expected artifacts:

- `community-general-13.3.0.tar.gz`
- `ansible-posix-2.2.2.tar.gz`
- `awx-awx-0.0.1-devel.tar.gz`

The tarballs are intentionally ignored by Git. In a production pipeline, store
them in an internal artifact repository and restore them here before running
`ansible-builder`.
