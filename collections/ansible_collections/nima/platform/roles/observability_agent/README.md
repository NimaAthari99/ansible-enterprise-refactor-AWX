# observability_agent

Use as `nima.platform.observability_agent`.

`prom` mode renders the Promtail/cAdvisor/node-exporter compose bundle. Loki credentials are required and must come from a secret backend. `elk` is deliberately rejected until the implementation exists, instead of silently doing nothing.
