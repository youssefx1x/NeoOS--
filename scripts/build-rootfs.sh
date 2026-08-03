#!/usr/bin/env bash
set -euo pipefail

# build-rootfs.sh — assemble the NeoOS root filesystem from Debian 13 (trixie)
# using mmdebstrap. Produces a plain directory tree and an optional tarball.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

NEOS_SUITE="${NEOS_SUITE:-trixie}"
NEOS_ARCH="${NEOS_ARCH:-amd64}"
NEOS_ROOTFS="${NEOS_ROOTFS:-$REPO_ROOT/build/rootfs}"
NEOS_MIRROR="${NEOS_MIRROR:-http://deb.debian.org/debian/}"
NEOS_SECURITY="${NEOS_SECURITY:-http://security.debian.org/debian-security}"
NEOS_KEYRING="${NEOS_KEYRING:-/usr/share/keyrings/debian-archive-keyring.gpg}"
NEOS_TARBALL="${NEOS_TARBALL:-$REPO_ROOT/build/neoos-rootfs.tar.xz}"
NEOS_COMPONENTS="${NEOS_COMPONENTS:-main,contrib,non-free-firmware}"

log() { printf '\033[1;36m[neos-build]\033[0m %s\n' "$*"; }

usage() {
  cat <<EOF
Usage: $0 [--suite SUITE] [--arch ARCH] [--out DIR] [--tarball FILE]
       $0 --skip-install   # only produce tarball from existing rootfs

Builds the NeoOS root filesystem from Debian 13 (trixie).
EOF
}

SKIP_INSTALL=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --suite) NEOS_SUITE="$2"; shift 2;;
    --arch) NEOS_ARCH="$2"; shift 2;;
    --out) NEOS_ROOTFS="$2"; shift 2;;
    --tarball) NEOS_TARBALL="$2"; shift 2;;
    --skip-install) SKIP_INSTALL=1; shift;;
    -h|--help) usage; exit 0;;
    *) echo "unknown option: $1" >&2; usage; exit 1;;
  esac
done

require() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "missing required tool: $1" >&2
    exit 1
  }
}
require mmdebstrap

if [[ ! -f "$NEOS_KEYRING" ]]; then
  NEOS_KEYRING=""
fi

if [[ "$SKIP_INSTALL" -eq 0 ]]; then
  log "Bootstrapping NeoOS rootfs ($NEOS_ARCH / $NEOS_SUITE) -> $NEOS_ROOTFS"
  rm -rf "$NEOS_ROOTFS"
  mkdir -p "$NEOS_ROOTFS"

  keyring_args=()
  if [[ -n "$NEOS_KEYRING" ]]; then
    keyring_args=(--keyring "$NEOS_KEYRING")
  fi

  mmdebstrap \
    --variant=minbase \
    --arch="$NEOS_ARCH" \
    --components="$NEOS_COMPONENTS" \
    "${keyring_args[@]}" \
    --include="$(tr '\n' ' ' < "$REPO_ROOT/config/packages.base" | tr -s ' ')" \
    "$NEOS_SUITE" "$NEOS_ROOTFS"
fi

log "Applying NeoOS configuration overlay"
bash "$REPO_ROOT/scripts/apply-overlay.sh" "$NEOS_ROOTFS"

if [[ "$NEOS_TARBALL" != "none" ]]; then
  log "Creating tarball: $NEOS_TARBALL"
  mkdir -p "$(dirname "$NEOS_TARBALL")"
  tar -C "$NEOS_ROOTFS" -cJf "$NEOS_TARBALL" .
fi

log "Done. Rootfs at $NEOS_ROOTFS, tarball at $NEOS_TARBALL"
