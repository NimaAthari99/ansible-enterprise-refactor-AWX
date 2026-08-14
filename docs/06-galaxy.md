# Galaxy collection lifecycle

The reusable content is a normal collection rooted at:

```text
collections/ansible_collections/nima/platform/
```

Build it:

```bash
make build-collection
```

The artifact is created under `artifacts/collections/`.

Before publishing a release, update the semantic version in `galaxy.yml`, run validation, build the artifact, and publish it to Ansible Galaxy or an internal Galaxy/Automation Hub-compatible service.

After the collection is moved to an independent repository, the control repository can replace the embedded source with a dependency such as:

```yaml
collections:
  - name: nima.platform
    version: "==1.2.0"
```

No playbook role names change because all calls already use `nima.platform.<role>`.
