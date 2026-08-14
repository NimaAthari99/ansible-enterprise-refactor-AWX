# Inventory design

Each environment has one explicit inventory entry point:

```text
inventories/
├── lab/
│   ├── hosts.yml
│   └── group_vars/
├── staging/hosts.yml
└── production/hosts.yml
```

`hosts.yml` owns topology. `group_vars` owns environment policy. Do not put implementation tasks into inventory and do not put lab IP addresses into collection defaults.

Role variables are namespaced by role, for example `docker_engine_*`, `nginx_setup_*`, `observability_agent_*` and `linux_baseline_*`. This prevents collisions as the inventory grows.

AWX should create a separate Inventory object per environment and use a Project inventory source pointing to the corresponding `inventories/<environment>/hosts.yml` file.
