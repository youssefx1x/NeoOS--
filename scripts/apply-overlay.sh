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

for __f in "$ROOTFS"/usr/bin/neos-* "$ROOTFS"/usr/bin/neo "$ROOTFS"/usr/bin/neolibs "$ROOTFS"/usr/bin/pkg; do
  chmod 0755 "$__f" 2>/dev/null || true
done
unset __f
chmod 0755 "$ROOTFS/etc/network/if-up.d/neos-uranium-suggest" 2>/dev/null || true
chmod 0644 "$ROOTFS/etc/X11/xorg.conf.d/40-libinput-touch.conf" 2>/dev/null || true

APPS="$ROOTFS/usr/share/applications"
mkdir -p "$APPS"
for tool in "$ROOTFS"/usr/bin/neos-*; do
  [[ -f "$tool" ]] || continue
  tname="${tool##*/}"
  short="${tname#neos-}"
  if [[ "$tname" == "neos-xfce" || "$tname" == "neos-gui" || "$tname" == "neos-start" ]]; then
    is_gui=0
  else
    is_gui=1
  fi
  {
    printf '[Desktop Entry]\n'
    printf 'Type=Application\n'
    printf 'Name=NeoOS %s\n' "$short"
    printf 'Comment=%s - NeoOS tool\n' "$short"
    printf 'Exec=/usr/bin/bash /usr/bin/%s\n' "$tname"
    printf 'Icon=utilities-terminal\n'
    printf 'Terminal=%d\n' "$is_gui"
    printf 'Categories=System;Utility;\n'
    printf 'StartupNotify=false\n'
    printf 'Keywords=neos;%s;neoos;\n' "$short"
  } > "$APPS/neos-${short}.desktop"
done

# 2. Install NeoLIBs tool + tests + proot plugin
log "Installing NeoLIBs"
install -Dm0755 "$REPO_ROOT/neolibs/neolibs" "$ROOTFS/usr/bin/neolibs"
install -Dm0644 "$REPO_ROOT/neolibs/README.md" "$ROOTFS/usr/share/doc/neolibs/README.md"
install -Dm0644 "$REPO_ROOT/neolibs/COMPAT.md" "$ROOTFS/usr/share/doc/neolibs/COMPAT.md"

# 2b. Ship the Calamares package list so neos-installer can install it on demand
log "Shipping Calamares package list"
install -Dm0644 "$REPO_ROOT/config/packages.calamares" "$ROOTFS/usr/lib/neos/packages.calamares" 2>/dev/null || true

# 2c. Build + install the NeoLIBs native C ABI core (libneo / NeoAPI, v1.1 stable)
log "Building NeoLIBs native core (libneo)"
NEOLIBS_DIR="$REPO_ROOT/neolibs/libneo-core"
if [[ -d "$NEOLIBS_DIR" && -x "$(command -v make)" ]]; then
  # Build inside the project; install a relocatable libneo.so + headers.
  ( cd "$NEOLIBS_DIR" && make clean >/dev/null 2>&1; make all ) >/dev/null 2>&1 || true
  install -d "$ROOTFS/usr/lib" "$ROOTFS/usr/include/neo"
  if [[ -f "$NEOLIBS_DIR/libneo.so" ]]; then
    install -m 0755 "$NEOLIBS_DIR/libneo.so" "$ROOTFS/usr/lib/libneo.so"
    ln -sf libneo.so "$ROOTFS/usr/lib/libneo.so.1"
    ln -sf libneo.so.1 "$ROOTFS/usr/lib/libneo.so.1.1.1"
    install -m 0644 "$NEOLIBS_DIR/libneo.a" "$ROOTFS/usr/lib/libneo.a" 2>/dev/null || true
    cp -r "$NEOLIBS_DIR/include/neo/." "$ROOTFS/usr/include/neo" 2>/dev/null || true
    log "Installed libneo.so (NeoAPI 1.1) -> $ROOTFS/usr/{lib,include/neo}"
  else
    log "WARNING: libneo.so build failed; native core not installed"
  fi
fi

log "Shipping driver manifest"
install -Dm0644 "$REPO_ROOT/config/packages.drivers" "$ROOTFS/usr/lib/neos/packages.drivers"
install -Dm0644 "$REPO_ROOT/config/driver-db.tsv" "$ROOTFS/usr/lib/neos/driver-db.tsv"
chmod 0755 "$ROOTFS/etc/network/if-up.d/neos-uranium-suggest" 2>/dev/null || true

# 3. os-release branding
cat > "$ROOTFS/etc/os-release" <<'EOF'
PRETTY_NAME="NeoOS 1.1.1 Stable (Debian 13 trixie based)"
NAME="NeoOS"
ID=neoos
ID_LIKE=debian
VERSION_ID="1.1.1"
VERSION="1.1.1 Stable"
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

  NeoOS 1.1.1 Stable — a Debian 13 terminal distribution

  Unified CLI ........ neo        (NeoCore + NeoPkg 2.0 + neos-*)
  Start menu ........ neos-menu
  Help .............. neos-help
  GUI (XFCE) ......... neos-xfce
  Health ............ neos-health
  Drivers ........... neos-uranium (one-tap)
  Install to disk ... neos-installer
  Users ............. neos-users
  Package mgr ....... pkg (NeoPkg 2.0)
  NeoLIBs ........... neolibs --help   (native NeoAPI: libneo.so)

EOF

# 6. Auto-start XFCE on first boot (lightdm on graphical.target, root autologin)
log "Enabling graphical auto-start"
mkdir -p "$ROOTFS/etc/systemd/system" "$ROOTFS/etc/lightdm" "$ROOTFS/etc/X11"
ln -sf /lib/systemd/system/graphical.target "$ROOTFS/etc/systemd/system/default.target" || true
if [[ -e "$ROOTFS/lib/systemd/system/lightdm.service" ]]; then
  ln -sf /lib/systemd/system/lightdm.service "$ROOTFS/etc/systemd/system/display-manager.service"
elif [[ -e "$ROOTFS/usr/lib/systemd/system/lightdm.service" ]]; then
  ln -sf /usr/lib/systemd/system/lightdm.service "$ROOTFS/etc/systemd/system/display-manager.service"
fi
echo "/usr/sbin/lightdm" > "$ROOTFS/etc/X11/default-display-manager"
cat > "$ROOTFS/etc/lightdm/lightdm.conf" <<'EOF'
[Seat:*]
autologin-user=root
autologin-user-timeout=0
user-session=xfce
greeter-session=lightdm-gtk-greeter
allow-guest=false
EOF

# 7. mark overlay as applied
touch "$ROOTFS/.neoos-overlay"

log "Overlay applied."
