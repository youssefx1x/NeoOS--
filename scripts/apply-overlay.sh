#!/usr/bin/env bash
set -euo pipefail

# apply-overlay.sh <rootfs> — copy the NeoOS overlay tree into a rootfs and
# install the NeoLIBs tool, menu, and configuration files.

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <rootfs-dir>" >&2
  exit 1
fi
ROOTFS="$1"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OVERLAY="$REPO_ROOT/overlay"

if [[ ! -d "$ROOTFS" ]]; then
  echo "rootfs dir not found: $ROOTFS" >&2
  exit 1
fi

log() { printf '\033[1;36m[neos-overlay]\033[0m %s\n' "$*"; }

# 1. Copy overlay tree (preserves symlinks, avoids .gitignore'd junk)
log "Copying overlay -> $ROOTFS"
if [[ -d "$OVERLAY" ]]; then
  tar --no-same-owner -C "$OVERLAY" -cf - . | tar --no-same-owner -C "$ROOTFS" -xf -
fi

# 2. Install NeoLIBs tool + tests + proot plugin
log "Installing NeoLIBs"
install -Dm0755 "$REPO_ROOT/neolibs/neolibs" "$ROOTFS/usr/bin/neolibs"
install -Dm0644 "$REPO_ROOT/neolibs/README.md" "$ROOTFS/usr/share/doc/neolibs/README.md"
install -Dm0644 "$REPO_ROOT/neolibs/COMPAT.md" "$ROOTFS/usr/share/doc/neolibs/COMPAT.md"

# 2b. Ship the Calamares package list so neos-installer can install it on demand
log "Shipping Calamares package list"
install -Dm0644 "$REPO_ROOT/config/packages.calamares" "$ROOTFS/usr/lib/neos/packages.calamares" 2>/dev/null || true

# 3. os-release branding
cat > "$ROOTFS/etc/os-release" <<'EOF'
PRETTY_NAME="NeoOS (Debian 13 trixie based)"
NAME="NeoOS"
ID=neoos
ID_LIKE=debian
VERSION_ID="13"
VERSION="13 (trixie)"
VERSION_CODENAME=trixie
HOME_URL="https://neoos.local"
SUPPORT_URL="https://neoos.local/support"
BUG_REPORT_URL="https://neoos.local/bugs"
EOF

# 4. Machine-info / hostname defaults
echo "NeoOS (trixie)" > "$ROOTFS/etc/machine-info" 2>/dev/null || true
touch "$ROOTFS/etc/hostname"

# 5. motd
cat > "$ROOTFS/etc/motd" <<'EOF'

  NeoOS — a Debian 13 terminal distribution

  Start menu ........ neos-menu
  Drivers ........... neos-drivers
  Install to disk ... neos-installer
  NeoLIBs ........... neolibs --help

EOF

# 6. mark overlay as applied
touch "$ROOTFS/.neoos-overlay"

log "Overlay applied."
