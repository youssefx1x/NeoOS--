#!/usr/bin/env bash
set -euo pipefail

# setup-iso.sh — run INSIDE the NeoOS rootfs (via chroot) to install the
# kernel, initramfs tooling, grub files and live-boot support needed to
# produce a bootable ISO with scripts/build-iso.sh.

log() { printf '\033[1;36m[neos-iso-chroot]\033[0m %s\n' "$*"; }

export DEBIAN_FRONTEND=noninteractive
log "Installing kernel + live-boot + grub files"
apt-get update
apt-get install -y \
  linux-image-amd64 \
  initramfs-tools \
  live-boot \
  live-boot-initramfs-tools \
  grub-pc-bin \
  grub-efi-amd64-bin \
  grub-common \
  systemd-sysv \
  isc-dhcp-client \
  iproute2

# Optionally include the Calamares graphical installer on the live media.
# Set NEOS_INCLUDE_INSTALLER=1 to ship it (pulls a Qt6 GUI stack).
if [[ "${NEOS_INCLUDE_INSTALLER:-0}" == "1" ]]; then
  log "Installing Calamares installer (NEOS_INCLUDE_INSTALLER=1)"
  # The package list is shipped into the rootfs by apply-overlay.sh.
  # Fall back to a hardcoded set if it is not present.
   if [[ -r /usr/lib/neos/packages.calamares ]]; then
     grep -v '^[[:space:]]*#' /usr/lib/neos/packages.calamares | xargs -r apt-get install -y
   else
     apt-get install -y calamares calamares-settings-debian rsync cryptsetup os-prober \
       qml-module-qtquick-window2 qml-module-qtquick2 qml-module-qtquick-controls2 \
       qml-module-qtgraphicaleffects polkitd pkexec weston xwayland
   fi
  # Ensure a desktop entry to launch the installer appears in the menu
  if command -v calamares >/dev/null 2>&1; then
    log "Calamares installer available: neos-installer"
  fi
fi

# Regenerate initramfs with live-boot hook
update-initramfs -k all -u || true

# Create casper-compatible live config dir
mkdir -p /etc/live
cat > /etc/live/boot.conf <<'EOF'
# NeoOS live boot: no persistent overlay, auto-configure network via DHCP
boot=live
toram
quickreboot
EOF

# Ensure default user can run sudo
if command -v useradd >/dev/null 2>&1 && ! id neo >/dev/null 2>&1; then
  useradd -m -s /bin/bash neo || true
  echo "neo ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/neo
fi

# Default to a login shell that lands in the menu for the neo user
echo "if [ -x /usr/bin/neos-menu ] && [ \"\$(id -u)\" != 0 ]; then /usr/bin/neos-menu; fi" >> /home/neo/.profile

log "ISO setup complete."
