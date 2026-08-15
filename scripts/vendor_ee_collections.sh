#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENDOR_DIR="${ROOT}/collections/vendor"
AWX_COMMIT="c0aedc6e3"

# Set EE_FETCH_PREFIX=proxychains4 when this host needs ProxyChains for
# outbound Galaxy/GitHub access.
read -r -a FETCH_PREFIX <<< "${EE_FETCH_PREFIX:-}"

run_fetch() {
  if (( ${#FETCH_PREFIX[@]} > 0 )); then
    "${FETCH_PREFIX[@]}" "$@"
  else
    "$@"
  fi
}

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: required executable not found: $1" >&2
    exit 2
  }
}

need ansible-galaxy
need git
need mktemp

mkdir -p "$VENDOR_DIR"
rm -f \
  "$VENDOR_DIR/community-general-13.3.0.tar.gz" \
  "$VENDOR_DIR/ansible-posix-2.2.2.tar.gz" \
  "$VENDOR_DIR/awx-awx-0.0.1-devel.tar.gz"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

printf '==> Downloading pinned public collections outside the container build\n'
run_fetch ansible-galaxy collection download \
  community.general:13.3.0 \
  ansible.posix:2.2.2 \
  --download-path "$TMP_DIR/galaxy" \
  --no-cache

for artifact in community-general-13.3.0.tar.gz ansible-posix-2.2.2.tar.gz; do
  if [[ ! -f "$TMP_DIR/galaxy/$artifact" ]]; then
    echo "ERROR: expected artifact was not downloaded: $artifact" >&2
    exit 3
  fi
  cp "$TMP_DIR/galaxy/$artifact" "$VENDOR_DIR/$artifact"
done

printf '==> Building awx.awx from pinned AWX commit %s\n' "$AWX_COMMIT"
run_fetch git clone --quiet --filter=blob:none https://github.com/ansible/awx.git "$TMP_DIR/awx"
git -C "$TMP_DIR/awx" checkout --quiet "$AWX_COMMIT"
ansible-galaxy collection build \
  "$TMP_DIR/awx/awx_collection" \
  --force \
  --output-path "$VENDOR_DIR"

AWX_ARTIFACT="$VENDOR_DIR/awx-awx-0.0.1-devel.tar.gz"
if [[ ! -f "$AWX_ARTIFACT" ]]; then
  echo "ERROR: expected AWX artifact was not produced: $AWX_ARTIFACT" >&2
  echo "Produced files:" >&2
  find "$VENDOR_DIR" -maxdepth 1 -type f -printf '  %f\n' >&2
  exit 4
fi

printf '==> Vendored artifacts\n'
sha256sum \
  "$VENDOR_DIR/community-general-13.3.0.tar.gz" \
  "$VENDOR_DIR/ansible-posix-2.2.2.tar.gz" \
  "$AWX_ARTIFACT"

printf '\nOK: EE collection artifacts are ready in %s\n' "$VENDOR_DIR"
