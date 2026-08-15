#!/usr/bin/env python3
"""Fast repository checks that do not require contacting managed hosts."""
from __future__ import annotations

import re
import sys
from pathlib import Path

import yaml
from jinja2 import Environment, TemplateSyntaxError

ROOT = Path(__file__).resolve().parents[1]
COLLECTION = ROOT / "collections/ansible_collections/nima/platform"
ROLE_ROOT = COLLECTION / "roles"
errors: list[str] = []


def fail(message: str) -> None:
    errors.append(message)


# 1. YAML syntax.
for path in ROOT.rglob("*"):
    if path.is_file() and path.suffix in {".yml", ".yaml"}:
        try:
            list(yaml.safe_load_all(path.read_text(encoding="utf-8")))
        except Exception as exc:  # noqa: BLE001 - validation should report all parser errors
            fail(f"YAML: {path.relative_to(ROOT)}: {exc}")

# 2. Jinja syntax.
env = Environment()
for path in COLLECTION.rglob("*.j2"):
    try:
        env.parse(path.read_text(encoding="utf-8"))
    except TemplateSyntaxError as exc:
        fail(f"Jinja: {path.relative_to(ROOT)}:{exc.lineno}: {exc.message}")

# 3. Local collection role references from playbooks must exist.
roles = {p.name for p in ROLE_ROOT.iterdir() if p.is_dir()}
role_ref = re.compile(r"\brole:\s*nima\.platform\.([a-zA-Z0-9_]+)\b")
for path in (ROOT / "playbooks").glob("*.yml"):
    for name in role_ref.findall(path.read_text(encoding="utf-8")):
        if name not in roles:
            fail(f"Role reference: {path.relative_to(ROOT)} -> nima.platform.{name} does not exist")

# 4. Static import_tasks references must exist in their role.
import_ref = re.compile(r"ansible\.builtin\.import_tasks:\s*['\"]?([A-Za-z0-9_.-]+)['\"]?")
for role in ROLE_ROOT.iterdir():
    if not role.is_dir():
        continue
    for path in (role / "tasks").glob("*.y*ml") if (role / "tasks").exists() else []:
        for ref in import_ref.findall(path.read_text(encoding="utf-8")):
            if not (role / "tasks" / ref).exists():
                fail(f"Task import: {path.relative_to(ROOT)} -> {ref} missing")

# 4b. Static import_tasks references from top-level playbooks must exist.
for path in (ROOT / "playbooks").glob("*.yml"):
    text = path.read_text(encoding="utf-8")
    for ref in import_ref.findall(text):
        candidate = path.parent / ref
        if not candidate.exists():
            fail(f"Playbook task import: {path.relative_to(ROOT)} -> {ref} missing")

# 4c. Do not use broad gitignore rules that hide operational YAML merely
# because its filename contains 'secret'. These previously hid AWX task/schema
# files from Git while leaving them present in local ZIPs.
gitignore = (ROOT / ".gitignore").read_text(encoding="utf-8")
for dangerous in ("**/*secret*.yml", "**/*secret*.yaml"):
    if any(line.strip() == dangerous for line in gitignore.splitlines()):
        fail(f"Dangerous .gitignore rule hides code/config files: {dangerous}")

required_git_files = (
    ROOT / "playbooks/tasks/awx-secret-credentials.yml",
    ROOT / "awx/credential-types/platform-secrets-input.yml",
    ROOT / "awx/credential-types/platform-secrets-injector.yml",
    ROOT / "inventories/lab/group_vars/all/05_secrets.yml",
)
for required in required_git_files:
    if not required.exists():
        fail(f"Required tracked operational file missing: {required.relative_to(ROOT)}")

# 5. Literal role template/file sources must exist.
for role in ROLE_ROOT.iterdir():
    if not role.is_dir() or not (role / "tasks").exists():
        continue
    for path in (role / "tasks").glob("*.y*ml"):
        text = path.read_text(encoding="utf-8")
        docs = list(yaml.safe_load_all(text))
        for doc in docs:
            if not isinstance(doc, list):
                continue
            for task in doc:
                if not isinstance(task, dict):
                    continue
                for module, folder in (("ansible.builtin.template", "templates"), ("ansible.builtin.copy", "files")):
                    body = task.get(module)
                    if not isinstance(body, dict):
                        continue
                    src = body.get("src")
                    if not isinstance(src, str) or "{{" in src or "{%" in src or src.startswith("/"):
                        continue
                    # copy(content=...) has no src; directories are allowed.
                    candidate = role / folder / src.rstrip("/")
                    if not candidate.exists():
                        fail(f"Source: {path.relative_to(ROOT)} -> {folder}/{src} missing")

# 6. No vendored third-party collections in the source tree.
collection_ns = ROOT / "collections/ansible_collections"
for namespace in collection_ns.iterdir():
    if namespace.name != "nima":
        fail(f"Vendored third-party collection namespace found: {namespace.relative_to(ROOT)}")

# 7. No old vault variable references or obvious private keys in tracked source.
text_extensions = {".yml", ".yaml", ".j2", ".md", ".cfg", ".txt", ".ini", ".py", ""}
for path in ROOT.rglob("*"):
    if not path.is_file() or path.suffix not in text_extensions or path == Path(__file__).resolve():
        continue
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        continue
    if re.search(r"\bvault_[A-Za-z0-9_]+", text):
        fail(f"Legacy vault_ reference remains: {path.relative_to(ROOT)}")
    if "BEGIN OPENSSH PRIVATE KEY" in text or "BEGIN RSA PRIVATE KEY" in text:
        fail(f"Private key material found: {path.relative_to(ROOT)}")

# 8. Required collection metadata.
galaxy = yaml.safe_load((COLLECTION / "galaxy.yml").read_text(encoding="utf-8"))
for key in ("namespace", "name", "version", "readme", "authors"):
    if not galaxy.get(key):
        fail(f"galaxy.yml missing required value: {key}")
if galaxy.get("namespace") != "nima" or galaxy.get("name") != "platform":
    fail("galaxy.yml must identify the collection as nima.platform")

if errors:
    print(f"FAILED: {len(errors)} structural issue(s)")
    for error in errors:
        print(f"- {error}")
    sys.exit(1)

print("OK: YAML, Jinja, local role references, static imports/sources, collection metadata, and secret guards passed")
