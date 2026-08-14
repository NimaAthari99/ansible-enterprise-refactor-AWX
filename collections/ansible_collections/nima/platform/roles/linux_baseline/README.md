# linux_baseline

Applies the common Debian/Ubuntu baseline used by the control repository: package policy, resolver settings, hardening, auditd, logging, sysctl tuning, and optional Lynis installation.

All public inputs use the `linux_baseline_` prefix. Potentially disruptive behavior is opt-in: APT mirror replacement, insecure mirror trust, root shell replacement, package upgrades, iptables replacement, and Lynis are disabled by default.

Use the FQCN `nima.platform.linux_baseline`. Keep environment-specific addresses and policy values in inventory rather than in the collection.
