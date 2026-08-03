# NeoOS plugin for proot-distro (classic plugin API, proot-distro <= 2.x)
# Modern proot-distro versions install NeoOS directly from a rootfs tarball:
#   proot-distro install <path>/neoos-proot-<arch>.tar.xz --name neoos
#
# For older proot-distro versions that use the plugin API, place this file
# into $PREFIX/etc/proot-distro/ and run:
#   proot-distro install neoos
#
# The tarball is produced by scripts/build-proot.sh and can be downloaded
# into $PREFIX/tmp/ before installing.

DISTRO_NAME="NeoOS"
DISTRO_COMMENT="NeoOS — Debian 13 (trixie) terminal distribution, Wayland + NeoLIBs"

TARBALL_STRIP_COMPONENTS=1

distro_setup() {
  run_proot_cmd apt-get update
  run_proot_cmd apt-get -y install bash neofetch
  run_proot_cmd bash -c "cat >> /etc/motd <<'EOF'

  NeoOS — installed via proot-distro

  Start menu .... neos-menu
  Drivers ....... neos-drivers
  NeoLIBs ....... neolibs --help

EOF
"
}
