# Execution Environment

`execution-environment.yml` uses Ansible Builder schema version 3. It pins the controller runtime and installs the third-party collections used by `nima.platform`.

Build locally:

```bash
make build-ee EE_IMAGE=registry.example.invalid/automation/nima-platform-ee:1.0.0
```

Push the image to the registry used by AWX, then register it under **Administration > Execution Environments** and attach the registry pull credential if the registry is private.

The local `nima.platform` collection is intentionally not baked into the image in this monorepo phase. It travels with the AWX Project checkout, so a Git revision and collection code revision are identical. Third-party runtime dependencies are pinned in `collections/requirements.yml` and the EE definition.

When `nima.platform` becomes independently released, publish it and then pin it in the EE/requirements flow as an external collection.
