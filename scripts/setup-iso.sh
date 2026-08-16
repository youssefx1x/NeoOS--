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
if [[ "${NEOS_INCLUDE_INSTALLER:-0}" == "1" ]]; then
  log "Installing Calamares installer (NEOS_INCLUDE_INSTALLER=1)"
  if [[ -r /usr/lib/neos/packages.calamares ]]; then
    grep -v '^[[:space:]]*#' /usr/lib/neos/packages.calamares | xargs -r apt-get install -y
  else
    apt-get install -y calamares calamares-settings-debian rsync cryptsetup os-prober \
      qml-module-qtquick-window2 qml-module-qtquick2 qml-module-qtquick-controls2 \
      qml-module-qtgraphicaleffects polkitd pkexec weston xwayland
  fi
fi

# Regenerate initramfs with live-boot hook
update-initramfs -k all -u || true

# Create live boot config
mkdir -p /etc/live
cat > /etc/live/boot.conf <<'EOF'
# NeoOS live boot: no persistent overlay, auto-configure network via DHCP
boot=live
toram
quickreboot
EOF

# Create the 'neo' user for auto-login
if command -v useradd >/dev/null 2>&1 && ! id neo >/dev/null 2>&1; then
  log "Creating 'neo' user for auto-login"
  useradd -m -s /bin/bash neo
  echo "neo ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/neo
  chmod 0440 /etc/sudoers.d/neo
fi

# Configure LightDM for auto-login as neo user
mkdir -p /etc/lightdm
cat > /etc/lightdm/lightdm.conf <<'EOF'
[Seat:*]
autologin-user=neo
autologin-user-timeout=0
greeter-session=lightdm-gtk-greeter
user-session=xfce
EOF

# Ensure desktop shortcut exists
mkdir -p /home/neo/Desktop
cat > /home/neo/Desktop/neos-installer.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Install NeoOS
Comment=Launch the NeoOS graphical installer
Exec=neos-installer
Icon=drive-harddisk
Terminal=false
Categories=System;
StartupNotify=true
EOF
chmod +x /home/neo/Desktop/neos-installer.desktop
chown -R neo:neo /home/neo/Desktop /home/neo/.config/autostart 2>/dev/null || true

# Set default session to XFCE
mkdir -p /etc/X11
echo "xfce" > /etc/X11/default-display-manager

log "ISO setup complete."
