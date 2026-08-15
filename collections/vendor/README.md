# Vendored Execution Environment collections

This directory is populated by `scripts/vendor_ee_collections.sh` before the
Execution Environment image is built.

The vendor script fetches pinned source revisions from GitHub and builds the
collection artifacts locally. It does **not** contact `galaxy.ansible.com`.

Expected artifacts:

- `community-library_inventory_filtering_v1-1.1.5.tar.gz`
- `community-general-13.3.0.tar.gz`
- `ansible-posix-2.2.2.tar.gz`
- `awx-awx-0.0.1-devel.tar.gz`

`community.general` 13.3.0 declares
`community.library_inventory_filtering_v1 >= 1.0.0`; version 1.1.5 is pinned
explicitly so `ansible-galaxy --offline` has a complete dependency graph.

The tarballs are intentionally ignored by Git. In a production pipeline, store
them in an internal artifact repository and restore them here before running
`ansible-builder`.
