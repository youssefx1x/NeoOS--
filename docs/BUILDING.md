# Building a bootable NeoOS ISO

The ISO build runs in two stages: in-rootfs setup (chroot) and host-side
packaging.

## Prerequisites

Host packages: `mmdebstrap xorriso grub-mkrescue squashfs-tools`.

## Steps

```sh
# 1. Build the base rootfs
./build.sh rootfs

# 2. Install kernel + live-boot + grub inside the rootfs (needs root)
sudo NEOS_ROOTFS="$PWD/build/rootfs" scripts/setup-iso.sh   # chroot helper
sudo chroot build/rootfs /bin/bash -c 'DEBIAN_FRONTEND=noninteractive \
  bash /scripts/setup-iso.sh'                                # or run in chroot

# 3. Package the ISO
./build.sh iso
```

The produced `build/neoos.iso` boots into a live terminal session. The
`neo` user (password: none, `sudo` passwordless) drops straight into
`neos-menu` on login.

## Test the ISO

```sh
qemu-system-x86_64 -cdrom build/neoos.iso -m 2G -boot d
```
