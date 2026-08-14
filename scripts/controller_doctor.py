#!/usr/bin/env python3
"""Report the exact awx.awx module selected by Ansible and reject old token auth."""
from pathlib import Path
import sys

try:
    from ansible.plugins.loader import init_plugin_loader, module_loader
except Exception as exc:
    print(f"ERROR: cannot import Ansible plugin loader: {exc}", file=sys.stderr)
    sys.exit(2)

# Standalone Python scripts do not go through Ansible CLI.run(), so they must
# initialize the collection/plugin loader explicitly. This makes the doctor
# honor ANSIBLE_COLLECTIONS_PATH / collections_path and
# ANSIBLE_COLLECTIONS_SCAN_SYS_PATH / collections_scan_sys_path.
init_plugin_loader()

ctx = module_loader.find_plugin_with_context("awx.awx.organization")
resolved = getattr(ctx, "resolved", False)
module_path = getattr(ctx, "plugin_resolved_path", None)

if not resolved or not module_path:
    print("ERROR: awx.awx.organization could not be resolved.", file=sys.stderr)
    sys.exit(3)

module_path = Path(module_path).resolve()
# .../awx/awx/plugins/modules/organization.py -> collection root is parents[2]
collection_root = module_path.parents[2]
controller_api = collection_root / "plugins" / "module_utils" / "controller_api.py"
galaxy_yml = collection_root / "galaxy.yml"

print(f"Resolved awx.awx.organization: {module_path}")
print(f"Resolved awx.awx collection root: {collection_root}")
if galaxy_yml.exists():
    for line in galaxy_yml.read_text(errors="replace").splitlines():
        if line.strip().startswith("version:"):
            print(f"Collection {line.strip()}")
            break

if not controller_api.exists():
    print(f"ERROR: controller_api.py not found at {controller_api}", file=sys.stderr)
    sys.exit(4)

text = controller_api.read_text(errors="replace")
old_markers = (
    'Failed to get token',
    'build_url("tokens")',
    "build_url('tokens')",
)
if any(marker in text for marker in old_markers):
    print("ERROR: selected awx.awx uses the old temporary-token authentication flow.", file=sys.stderr)
    print("It will try /api/v2/tokens/ and is incompatible with this AWX build.", file=sys.stderr)
    sys.exit(5)

if "_authenticate_with_basic_auth" not in text or 'build_url("me")' not in text:
    print("ERROR: selected awx.awx does not contain the expected Basic Auth implementation.", file=sys.stderr)
    sys.exit(6)

print("OK: selected awx.awx uses Basic Auth via /api/v2/me/ and is compatible with this AWX API shape.")
