# nima.platform.zsh_setup

Installs Zsh, Oh My Zsh, selected plugins, syntax highlighting, aliases, and optionally makes Zsh the target user's login shell.

## Example

```yaml
- hosts: managed_linux
  become: true
  roles:
    - role: nima.platform.zsh_setup
      vars:
        zsh_setup_user: root
```

The role is idempotent. Override `zsh_setup_user` per inventory/group vars when the managed account is not root.
