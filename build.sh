#!/usr/bin/env bash
set -euo pipefail

# build.sh — NeoOS build driver.
#
#   ./build.sh rootfs         build the Debian 13 (trixie) rootfs + tarball
#   ./build.sh neokit-base    build Neokit 1.0 base rootfs layer
#   ./build.sh iso            build a bootable live ISO (needs root + chroot)
#   ./build.sh proot          build a proot-distro tarball for Termux (default aarch64)
#   ./build.sh all            run rootfs, then iso, then proot
#   ./build.sh neokit-all     neokit-base + rootfs + iso + proot
#   ./build.sh clean          remove build artifacts

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cmd="${1:-help}"

log() { printf '\033[1;34m[neos]\033[0m %s\n' "$*"; }

build_neokit_base() {
  log "Building Neokit 1.0 base layer"
  bash "$REPO_ROOT/scripts/build-neokit-base.sh"
}

case "$cmd" in
  rootfs)
    log "Building rootfs"
    bash "$REPO_ROOT/scripts/build-rootfs.sh"
    ;;
  neokit-base)
    build_neokit_base
    ;;
  neokit-all)
    log "Full build via Neokit base layer"
    build_neokit_base
    bash "$REPO_ROOT/scripts/build-rootfs.sh"
    bash "$REPO_ROOT/scripts/build-iso.sh"
    bash "$REPO_ROOT/scripts/build-proot.sh"
    ;;
  iso)
    log "Building ISO"
    bash "$REPO_ROOT/scripts/build-iso.sh"
    ;;
  proot)
    log "Building proot-distro tarball"
    bash "$REPO_ROOT/scripts/build-proot.sh"
    ;;
  all)
    log "Full build"
    bash "$REPO_ROOT/scripts/build-rootfs.sh"
    bash "$REPO_ROOT/scripts/build-iso.sh"
    bash "$REPO_ROOT/scripts/build-proot.sh"
    ;;
  clean)
    rm -rf "$REPO_ROOT/build"
    log "Cleaned build artifacts"
    ;;
  help|-h|--help)
    echo "NeoOS build driver. Usage:"
    grep -E '^  \./build\.sh ' "$0"
    ;;
  *) echo "unknown command: $cmd" >&2; exit 1;;
esac
