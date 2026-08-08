#!/usr/bin/env bash
# chroot-run.sh <rootfs> <command...>
#
# Run <command...> inside <rootfs> via chroot, with /proc, /sys, /dev and
# /dev/pts bind-mounted and resolv.conf + hosts copied in, so that
# apt-get / dpkg / update-initramfs work inside the chroot. All mounts are
# removed again on exit (even on failure).
#
# Usage:
#   scripts/chroot-run.sh build/rootfs /tmp/setup-iso.sh
#
# Exported environment variables (e.g. NEOS_INCLUDE_INSTALLER=1) are passed
# through to the chrooted command.

set -euo pipefail

ROOTFS="$1"; shift
if [[ ! -d "$ROOTFS" ]]; then
  echo "chroot-run: rootfs not found: $ROOTFS" >&2
  exit 1
fi
if [[ $# -eq 0 ]]; then
  echo "usage: chroot-run.sh <rootfs> <command...>" >&2
  exit 2
fi

require() {
  local tool="$1" pkg="${2:-$1}"
  command -v "$tool" >/dev/null 2>&1 || {
    echo "Missing required tool: $tool" >&2
    echo "Install it with:" >&2
    echo "  sudo apt install $pkg" >&2
    exit 1
  }
}
require chroot util-linux
require mount util-linux
require umount util-linux

# Bind-mount the filesystems the chroot needs.
mount --bind /proc "$ROOTFS/proc"   2>/dev/null || \
  { echo "chroot-run: cannot mount /proc (need root)" >&2; exit 1; }
mount --bind /sys  "$ROOTFS/sys"   2>/dev/null || true
mount --bind /dev  "$ROOTFS/dev"   2>/dev/null || true
mkdir -p "$ROOTFS/dev/pts"
mount --bind /dev/pts "$ROOTFS/dev/pts" 2>/dev/null || true

# Networking + hostname so chrooted apt works.
cp /etc/resolv.conf "$ROOTFS/etc/resolv.conf" 2>/dev/null || true
cp /etc/hosts        "$ROOTFS/etc/hosts"        2>/dev/null || true

cleanup() {
  # Unmount in reverse order; tolerate "not mounted" errors.
  umount "$ROOTFS/dev/pts" 2>/dev/null || true
  umount "$ROOTFS/dev"     2>/dev/null || true
  umount "$ROOTFS/sys"     2>/dev/null || true
  umount "$ROOTFS/proc"    2>/dev/null || true
}
trap cleanup EXIT INT TERM

# /usr/bin/env (inside the chroot) exec's the command, inheriting the
# exported environment of this process (e.g. NEOS_INCLUDE_INSTALLER=1).
exec chroot "$ROOTFS" /usr/bin/env -- "$@"
