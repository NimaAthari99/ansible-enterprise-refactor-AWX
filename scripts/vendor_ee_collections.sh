#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENDOR_DIR="${ROOT}/collections/vendor"

COMMUNITY_GENERAL_REF="13.3.0"
ANSIBLE_POSIX_REF="2.2.2"
INVENTORY_FILTER_REF="1.1.5"
AWX_COMMIT="c0aedc6e37f453b885879717ca066397309e1c83"

# Set EE_FETCH_PREFIX=proxychains4 when this host needs ProxyChains for
# outbound GitHub access. The vendor step intentionally never contacts
# galaxy.ansible.com.
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

clone_tag() {
  local url="$1"
  local tag="$2"
  local dest="$3"
  run_fetch git clone \
    --quiet \
    --depth 1 \
    --branch "$tag" \
    --single-branch \
    "$url" "$dest"
}

download_github_commit_archive() {
  local owner_repo="$1"
  local commit="$2"
  local dest="$3"
  local archive

  archive="$(mktemp "${TMP_DIR}/github-archive.XXXXXX.tar.gz")"
  mkdir -p "$dest"

  # The previous shallow fetch used an abbreviated object ID as if it were a
  # remote ref and GitHub rejected it with "couldn't find remote ref". Use the
  # exact immutable commit archive instead; this also avoids cloning AWX history.
  run_fetch curl \
    --fail \
    --location \
    --retry 4 \
    --retry-all-errors \
    --retry-delay 2 \
    --connect-timeout 30 \
    "https://codeload.github.com/${owner_repo}/tar.gz/${commit}" \
    --output "$archive"

  tar -xzf "$archive" -C "$dest" --strip-components=1
}
build_collection() {
  local source_dir="$1"
  local expected_artifact="$2"

  ansible-galaxy collection build \
    "$source_dir" \
    --force \
    --output-path "$VENDOR_DIR"

  if [[ ! -f "$VENDOR_DIR/$expected_artifact" ]]; then
    echo "ERROR: expected collection artifact was not produced: $expected_artifact" >&2
    echo "Produced files:" >&2
    find "$VENDOR_DIR" -maxdepth 1 -type f -printf '  %f\n' >&2
    exit 4
  fi
}

need ansible-galaxy
need git
need curl
need tar
need mktemp
need sha256sum

mkdir -p "$VENDOR_DIR"
rm -f \
  "$VENDOR_DIR/community-general-${COMMUNITY_GENERAL_REF}.tar.gz" \
  "$VENDOR_DIR/ansible-posix-${ANSIBLE_POSIX_REF}.tar.gz" \
  "$VENDOR_DIR/community-library_inventory_filtering_v1-${INVENTORY_FILTER_REF}.tar.gz" \
  "$VENDOR_DIR/awx-awx-0.0.1-devel.tar.gz"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

printf '==> Vendoring EE collections from pinned GitHub sources\n'
printf '    Public Galaxy will not be contacted.\n'

printf '==> Fetching community.general %s\n' "$COMMUNITY_GENERAL_REF"
clone_tag \
  https://github.com/ansible-collections/community.general.git \
  "$COMMUNITY_GENERAL_REF" \
  "$TMP_DIR/community.general"
build_collection \
  "$TMP_DIR/community.general" \
  "community-general-${COMMUNITY_GENERAL_REF}.tar.gz"

printf '==> Fetching ansible.posix %s\n' "$ANSIBLE_POSIX_REF"
clone_tag \
  https://github.com/ansible-collections/ansible.posix.git \
  "$ANSIBLE_POSIX_REF" \
  "$TMP_DIR/ansible.posix"
build_collection \
  "$TMP_DIR/ansible.posix" \
  "ansible-posix-${ANSIBLE_POSIX_REF}.tar.gz"

# community.general 13.3.0 declares this collection as a runtime dependency.
# Pin it explicitly so the offline install never needs Galaxy dependency
# resolution and remains deterministic with ansible-core 2.20.
printf '==> Fetching community.library_inventory_filtering_v1 %s\n' "$INVENTORY_FILTER_REF"
clone_tag \
  https://github.com/ansible-collections/community.library_inventory_filtering.git \
  "$INVENTORY_FILTER_REF" \
  "$TMP_DIR/community.library_inventory_filtering"
build_collection \
  "$TMP_DIR/community.library_inventory_filtering" \
  "community-library_inventory_filtering_v1-${INVENTORY_FILTER_REF}.tar.gz"

printf '==> Fetching awx.awx from pinned AWX commit %.10s\n' "$AWX_COMMIT"
download_github_commit_archive \
  ansible/awx \
  "$AWX_COMMIT" \
  "$TMP_DIR/awx"
build_collection \
  "$TMP_DIR/awx/awx_collection" \
  "awx-awx-0.0.1-devel.tar.gz"

printf '==> Vendored artifacts\n'
sha256sum \
  "$VENDOR_DIR/community-general-${COMMUNITY_GENERAL_REF}.tar.gz" \
  "$VENDOR_DIR/ansible-posix-${ANSIBLE_POSIX_REF}.tar.gz" \
  "$VENDOR_DIR/community-library_inventory_filtering_v1-${INVENTORY_FILTER_REF}.tar.gz" \
  "$VENDOR_DIR/awx-awx-0.0.1-devel.tar.gz"

printf '\nOK: EE collection artifacts are ready in %s\n' "$VENDOR_DIR"
