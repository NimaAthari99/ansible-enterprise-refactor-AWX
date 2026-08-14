# Validation

The repository provides four validation layers through `make validate`:

1. `ansible-inventory --graph` verifies inventory parsing.
2. `yamllint` checks YAML style and structural errors.
3. `ansible-lint` checks playbooks and the local collection.
4. `ansible-playbook --syntax-check` checks every playbook against the selected inventory.

CI repeats the same checks and additionally builds the Galaxy collection artifact.

For a production promotion pipeline, add Molecule/integration tests against disposable Debian/Ubuntu hosts and an image build/push stage for the Execution Environment.
