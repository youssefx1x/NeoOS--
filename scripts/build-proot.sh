#!/usr/bin/env bash
set -euo pipefail

# build-proot.sh — build a NeoOS rootfs tarball suitable for installation
# inside Termux via proot-distro (modern versions: `proot-distro install <file>`).

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NEOS_ARCH="${NEOS_ARCH:-aarch64}"
NEOS_OUT="${NEOS_OUT:-$REPO_ROOT/build/neoos-proot-$NEOS_ARCH.tar.xz}"
NEOS_SUITE="${NEOS_SUITE:-trixie}"

log() { printf '\033[1;36m[neos-proot]\033[0m %s\n' "$*"; }

# 1. Bootstrap the base rootfs
log "Bootstrapping $NEOS_ARCH rootfs"
NEOS_ROOTFS="$REPO_ROOT/build/proot-$NEOS_ARCH" \
NEOS_ARCH="$NEOS_ARCH" \
NEOS_TARBALL=none \
bash "$REPO_ROOT/scripts/build-rootfs.sh" --arch "$NEOS_ARCH" --out "$REPO_ROOT/build/proot-$NEOS_ARCH"

ROOTFS="$REPO_ROOT/build/proot-$NEOS_ARCH"

# 2. proot-specific adjustments
log "Applying proot/termux adjustments"
# Systemd init is useless under proot; keep packages but no boot.
touch "$ROOTFS/.proot-distro"

# 3. Termux-style resolv.conf so networking works inside proot
cat > "$ROOTFS/etc/resolv.conf" <<'EOF'
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF

# 4. Package the tarball (strip leading './')
log "Packaging -> $NEOS_OUT"
mkdir -p "$(dirname "$NEOS_OUT")"
tar -C "$ROOTFS" -cJf "$NEOS_OUT" .

log "Done. On Termux run: proot-distro install $NEOS_OUT"
echo "  or:  proot-distro install $NEOS_OUT --name neoos"
