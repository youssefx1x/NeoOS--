#!/usr/bin/env bash
set -euo pipefail

# build.sh — NeoOS build driver.
#
#   ./build.sh rootfs    build the Debian 13 (trixie) rootfs + tarball
#   ./build.sh iso       build a bootable live ISO (needs root + chroot)
#   ./build.sh proot     build a proot-distro tarball for Termux (default aarch64)
#   ./build.sh all       run rootfs, then iso, then proot
#   ./build.sh clean     remove build artifacts
#
#   Env: NEOS_VARIANT=minimal   proot/rootfs build = core shell only (no XFCE GUI)
#        NEOS_VARIANT=full      (default) core + XFCE GUI
#
#   End users on Android (arm64) can install NeoOS from a localhost
#   workspace with no external/binary URL:
#     pkg install -y proot debootstrap git make gcc
#     git clone https://github.com/youssefx1x/NeoOS-- && cd NeoOS--
#     NEOS_VARIANT=minimal bash build.sh proot
#     proot-distro install build/neoos-proot-aarch64.tar.xz --name neoos
#     proot-distro login neoos

NEOS_VERSION="1.2.0"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cmd="${1:-help}"

log() { printf '\033[1;34m[neos]\033[0m %s\n' "$*"; }

case "$cmd" in
  rootfs)
    log "Building rootfs"
    bash "$REPO_ROOT/scripts/build-rootfs.sh"
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
  version|--version|-V)
    echo "NeoOS $NEOS_VERSION Stable (build driver)"
    ;;
  help|--help|-h)
    echo "NeoOS build driver. Usage:"
    grep -E '^  (rootfs|iso|proot|all|clean)' "$0" | sed 's/^/  /'
    echo "  version          print the NeoOS build version"
    ;;
  *) echo "unknown command: $cmd (try: $0 help)" >&2; exit 1;;
esac
