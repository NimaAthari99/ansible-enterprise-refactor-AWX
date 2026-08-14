# AWX setup

## 1. Execution Environment

Build and push the EE image, then create an AWX Execution Environment pointing to that image.

## 2. Project

Create a Project using the Git repository containing this tree. Enable **Update Revision on Launch** for environments where always consuming the selected branch/revision is appropriate. Keep `collections/requirements.yml` at the repository root path shown here; AWX recognizes this location for project collection dependencies.

## 3. Inventory

Create one AWX Inventory per environment. Add an inventory source:

- Source: **Sourced from a Project**
- Project: this repository
- Inventory file: `inventories/lab/hosts.yml` (or staging/production)
- Update on launch: enabled if desired

## 4. Credentials

Attach a **Machine Credential** for SSH username/private key and privilege escalation. Do not define `ansible_user` or private keys in Git.

For service secrets, create the Custom Credential Type using:

- Input configuration: `awx/credential-types/platform-secrets-input.yml`
- Injector configuration: `awx/credential-types/platform-secrets-injector.yml`

Then create a credential of that type and attach it to templates that need Nginx auth, Loki credentials, or the optional authorized-key service.

## 5. Job Templates

Recommended templates:

| Template | Playbook | Default target | Notes |
|---|---|---|---|
| Baseline | `playbooks/baseline.yml` | `managed_linux` | use limit/check mode for rollout |
| Docker | `playbooks/docker.yml` | `docker_servers` | role is Debian-family only |
| Nginx | `playbooks/nginx.yml` | `nginx_servers` | needs secret when basic auth is enabled |
| Observability | `playbooks/observability.yml` | `observability_clients` | `prom` implemented; `elk` fails explicitly |
| Site | `playbooks/site.yml` | composed groups | normal converging run |
| Bootstrap | `playbooks/bootstrap.yml` | `managed_linux` | serial=1; high-risk access change |
| Network | `playbooks/network.yml` | explicit only | require Survey `target_hosts`; never `all` |

For `target_hosts`, prefer an AWX Survey whose value is constrained to approved inventory patterns rather than granting arbitrary extra vars broadly.

## 6. First rollout

Run `playbooks/check-ee.yml`, then inventory sync, then baseline with `--check --diff` and a single-host limit. Expand the limit only after the first host converges cleanly. Run SSH bootstrap and network changes separately from the normal `site.yml` convergence path.
