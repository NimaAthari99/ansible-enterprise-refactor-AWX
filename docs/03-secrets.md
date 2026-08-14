# Secrets

No real secret belongs in Git, role defaults, inventory host vars, Execution Environment files, or command-line arguments.

The control project expects these runtime variables when the related feature is enabled:

```yaml
secret_platform_http_proxy: ""
secret_file_service_username: ""
secret_file_service_password: ""
secret_loki_password: ""
secret_nginx_auth_password: ""
```

`inventories/lab/group_vars/all/secret.example.yml` is only a schema/example with empty values.

For AWX, create the Custom Credential Type from the examples under `awx/credential-types/` and attach that credential to the Job Template. Machine login details belong in an AWX Machine Credential.

For local CLI use, inject secrets with an encrypted vars file outside Git, a secret manager lookup, or another secure runtime mechanism. Avoid `-e secret=value` because process listings and shell history have an unfortunate habit of remembering things humans hoped they would forget.

The original uploaded archive contained plaintext secrets. Rotate those source credentials before deployment.
