# Refactor report

## Result

The project was converted into an AWX-ready monorepo with a reusable Ansible Collection at `collections/ansible_collections/nima/platform` and thin orchestration playbooks at the repository root.

## Main changes

- Migrated reusable roles into the `nima.platform` collection and standardized playbooks on FQCN role names.
- Consolidated the lab inventory into `inventories/lab/hosts.yml` and added staging/production skeletons.
- Separated reusable role defaults from environment-specific inventory data.
- Removed vendored third-party collection content; external collections are declared in `collections/requirements-ee.yml`.
- Removed plaintext vault material from the generated repository and added AWX Custom Credential Type examples for service secrets.
- Removed Git-managed SSH identity variables; AWX Machine Credentials are the intended SSH/become source.
- Reworked Docker installation to avoid an unconditional OS upgrade and to keep insecure repository behavior opt-in.
- Made Nginx basic authentication opt-in and secret-backed.
- Reworked SSH bootstrap to validate configuration before reconnecting and to use serial rollout.
- Made network changes require an explicit target and kept them out of the normal site convergence path.
- Made the unimplemented ELK observability path fail explicitly instead of silently succeeding.
- Added an Ansible Builder v3 Execution Environment definition, dependency locks, lint configuration, CI, Make targets, and a static structure validator.

## Validation performed in this workspace

- Parsed all YAML files successfully with PyYAML.
- Parsed Jinja templates and verified local role references, static task imports, literal template/copy sources, collection metadata, and secret guards with `scripts/validate_structure.py`.
- Compared credential-like scalar values found in the legacy vault files against the generated tree; no matches were found.

The workspace does not provide `ansible-core`, `ansible-lint`, `yamllint`, or `ansible-builder`, and outbound package installation is unavailable. Therefore the full Ansible syntax/lint/collection-build/EE-build commands could not be executed here. They are wired into `make validate`, `make build-collection`, and CI for execution in a normal development or CI environment.

## Security action required

The source archive contained plaintext credentials. Rotate those original credentials. Removing them from the generated tree does not remove them from any existing Git history or earlier copies of the repository.

## Publishing note

The collection currently uses the FQCN `nima.platform`. Before publishing to public Ansible Galaxy, confirm that the `nima` namespace is yours/registered for your organization. If the collection is internal-only, keep the namespace stable and publish it to your chosen internal Galaxy/Automation Hub-compatible source when you split it out of this monorepo.

## AWX controller bootstrap correction (v3)

The previous controller playbook attempted to read `awx/bootstrap-secrets.yml` while that file was intentionally excluded from Git. That cannot work from an AWX Project checkout. Controller-as-code is now split into an external secret-bearing bootstrap (`playbooks/awx-bootstrap.yml`) and a secretless AWX self-reconcile (`playbooks/awx-controller.yml`).


## v6 controller loader fix

- Fixed `scripts/controller_doctor.py` to call Ansible `init_plugin_loader()` before resolving FQCN modules.
- Disabled collection scanning from Python `sys.path` in `ansible.cfg`.
- Controller Make targets now force project-local collection resolution with `ANSIBLE_COLLECTIONS_PATH` and `ANSIBLE_COLLECTIONS_SCAN_SYS_PATH=false`.
- This prevents stale system copies such as `/usr/lib/python3/dist-packages/ansible_collections/awx/awx` from being selected for controller-as-code.

## v8: Decouple AWX Project Sync from Galaxy

- Renamed `collections/requirements.yml` to `collections/requirements-ee.yml`.
- `execution-environment.yml` now consumes the EE-only requirements file.
- AWX Project Sync no longer has a `collections/requirements.yml` trigger, so source updates do not run `ansible-galaxy collection install`.
- Third-party runtime dependencies (`community.general`, `ansible.posix`, and the matching `awx.awx`) are expected in the custom Execution Environment.
- Added `docs/09-awx-project-sync-galaxy-cache.md` for the upstream `KeyError: 'results'` cache failure.

## v9: tracked AWX task files and bootstrap boundary

- Removed broad `.gitignore` rules matching every `*secret*.yml`/`*.yaml` file.
  Those rules incorrectly hid operational code such as
  `playbooks/tasks/awx-secret-credentials.yml` and AWX credential schemas.
- Secret *data* is now excluded with explicit/local naming conventions and the
  one real bootstrap secret path remains ignored.
- Added a bootstrap guard that refuses to run `awx-bootstrap.yml` under
  `/runner/project`; bootstrap is external-only by design.
- Extended structural validation to check top-level playbook `import_tasks`
  targets and the required AWX operational files.

## v11: offline Galaxy stage for EE builds

The EE collection stage now uses vendored tarballs plus `ansible-galaxy
--offline`. This removes public Galaxy TLS/proxy instability from the container
build itself. A helper script stages `community.general`, `ansible.posix`, and
a commit-pinned `awx.awx` artifact before `ansible-builder` runs.


## v12 EE vendoring hardening

The EE vendor step no longer calls the public Galaxy API. It clones exact
GitHub tags/commits and builds local collection artifacts. It also vendors
`community.library_inventory_filtering_v1==1.1.5`, which is a declared runtime
dependency of `community.general==13.3.0`, so the `--offline` collection install
has a complete deterministic dependency graph.
