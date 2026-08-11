#!/usr/bin/env bash
set -euo pipefail

# build-iso.sh — create a bootable NeoOS live ISO from a rootfs.
# Uses grub-mkrescue + squashfs. Requires the rootfs to already contain
# a kernel, initramfs and grub config (see setup-iso.sh, run via chroot).

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NEOS_ROOTFS="${NEOS_ROOTFS:-$REPO_ROOT/build/rootfs}"
NEOS_ISO="${NEOS_ISO:-$REPO_ROOT/build/neoos.iso}"
NEOS_ARCH="${NEOS_ARCH:-amd64}"

log() { printf '\033[1;36m[neos-iso]\033[0m %s\n' "$*"; }

require() {
  local tool="$1" pkg="${2:-$1}"
  command -v "$tool" >/dev/null 2>&1 || {
    echo "Missing required tool: $tool" >&2
    echo "Install it with:" >&2
    echo "  sudo apt install $pkg" >&2
    exit 1
  }
}
require grub-mkrescue grub2-common
require xorriso xorriso

# Make sure the rootfs has a kernel + live-boot + grub layer. If not, run
# setup-iso.sh inside the rootfs via chroot (build-helper). NEOS_INCLUDE_INSTALLER
# is passed through to optionally embed the Calamares installer.
if ! compgen -G "$NEOS_ROOTFS/boot/vmlinuz-*" >/dev/null; then
  if [[ -x "$REPO_ROOT/scripts/chroot-run.sh" ]] && [[ -f "$REPO_ROOT/scripts/setup-iso.sh" ]]; then
    log "Preparing ISO rootfs (kernel/live-boot/grub) via chroot"
    cp "$REPO_ROOT/scripts/setup-iso.sh" "$NEOS_ROOTFS/tmp/setup-iso.sh"
    chmod +x "$NEOS_ROOTFS/tmp/setup-iso.sh"
    "$REPO_ROOT/scripts/chroot-run.sh" "$NEOS_ROOTFS" /tmp/setup-iso.sh
    rm -f "$NEOS_ROOTFS/tmp/setup-iso.sh"
  else
    echo "rootfs does not contain a kernel yet: $NEOS_ROOTFS" >&2
    echo "run scripts/setup-iso.sh inside the rootfs (see scripts/chroot-run.sh)" >&2
    exit 1
  fi
fi

ISODIR="$REPO_ROOT/build/iso-staging"
rm -rf "$ISODIR"
mkdir -p "$ISODIR/boot/grub" "$ISODIR/live"

log "Creating squashfs from rootfs"
mksquashfs "$NEOS_ROOTFS" "$ISODIR/live/filesystem.squashfs" -comp zstd -Xcompression-level 3 -noappend

log "Copying kernel + initramfs"
cp "$NEOS_ROOTFS"/boot/vmlinuz-* "$ISODIR/boot/vmlinuz"
cp "$NEOS_ROOTFS"/boot/initrd.img-* "$ISODIR/boot/initrd.img"

cat > "$ISODIR/boot/grub/grub.cfg" <<EOF
set timeout=5
set default=0
menuentry "NeoOS 1.2.0 Stable (Debian 13 trixie) — Live Terminal" {
  linux /boot/vmlinuz boot=live quiet toram components
  initrd /boot/initrd.img
}
menuentry "NeoOS — Safe Mode (nomodeset)" {
  linux /boot/vmlinuz boot=live nomodeset components
  initrd /boot/initrd.img
}
EOF

log "Building ISO: $NEOS_ISO"
grub-mkrescue -o "$NEOS_ISO" "$ISODIR" -- \
  --boot-info-table \
  --iso-level 3 \
  --volid "NeoOS" 2>/dev/null || grub-mkrescue -o "$NEOS_ISO" "$ISODIR"

ls -lh "$NEOS_ISO"
log "ISO ready. Test with: qemu-system-x86_64 -cdrom $NEOS_ISO -m 2G"
