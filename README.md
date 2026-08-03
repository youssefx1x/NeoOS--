# NeoOS

A terminal-first Linux distribution built on **Debian 13 (trixie)**.

NeoOS is a minimal, terminal-only operating system focused on development,
networking and tinkering. It ships a **terminal start menu** (code
applications, internet tools, driver installer), a **Wayland + Winetricks**
stack for running GUI apps when you want them, and **NeoLIBs** — a new tool
for installing and switching between multiple versions of the same shared
library.

```
      NeoOS — Debian 13 (trixie) terminal distribution
      ┌─────────────────────────────────────────────────┐
      │  Code        updated code apps + toolchains     │
      │  Internet    browsers, messaging, network utils │
      │  Drivers     hardware / driver installer        │
      │  Wayland     Weston + XWayland session          │
      │  Wine        Windows apps (neos-wine + VM)      │
      │  NeoLIBs     multi-version library manager      │
      │  Tools       pkg, distro installer, backup, ... │
      │  System      apt, packages, shell, power        │
      └─────────────────────────────────────────────────┘
```

## Highlights

- **Terminal start menu** (`neos-menu`) — a whiptail/dialog menu that
  installs and launches updated code applications, internet tools, Wayland
  apps and drivers.
- **NeoLIBs** (`neolibs`) — install multiple versions of a shared library
  (`zlib@1.2.13`, `openssl@3.2`, ...) and switch between them globally via
  `ld.so.conf.d` or per-command via `LD_LIBRARY_PATH`.
- **Wine for Windows apps** (`neos-wine`) — run Windows `.exe` terminal
  (console) apps in NeoOS with a Windows 10 prefix; Winetricks included.
- **Wine VM creator** (`neos-winevm`) — create isolated "Windows 10 Wine
  VMs": self-contained prefixes that install and run Windows applications
  without touching the base system (a Bottles/PlayOnLinux-style CLI).
- **Driver installer** (`neos-drivers`) — hardware detection (lspci/lsusb),
  enables `non-free-firmware`, installs GPU (Mesa/Vulkan/AMD/NVIDIA),
  WiFi, Bluetooth, audio, printer and generic firmware.
- **pkg** (`pkg`) — Termux-style package manager wrapper over apt/dpkg:
  `pkg update`, `pkg upgrade`, `pkg install`, `pkg search`, `pkg list`,
  `pkg files`, `pkg depends`, `pkg autoremove`, `pkg clean` and
  `pkg self-update` (updates NeoOS's own tools from a git checkout).
- **Distro installer** (`neos-distro`) — install Debian, Ubuntu, Alpine,
  Arch or any rootfs tarball/URL as isolated **proot containers**
  (no root, no reboot) for testing distros side-by-side.
- **Utility toolkit** — `neos-update` (plan-first updater),
  `neos-fetch` (neofetch-style banner), `neos-ports` (listening
  services + owning package), `neos-where` (which package owns a
  command/file), `neos-serve` (HTTP file share with upload),
  `neos-backup` (configs + package-list backup/restore).
- **Wayland support** — `neos-wayland` starts a Weston compositor with
  XWayland; Wayland apps (foot, wmenu) are one menu click away.
- **Winetricks / Wine** — `neos-winetricks` bootstraps Wine, initializes a
  prefix and launches Winetricks for Windows apps. Use `neos-wine` to run
  console `.exe` apps and `neos-winevm` for isolated Windows-10 VMs.
- **proot-distro on Termux** — install NeoOS on Android via proot-distro.
- **ISO build** — build a bootable live ISO from the rootfs.

## Quick start

```sh
# Build the root filesystem (Debian 13 trixie)
./build.sh rootfs

# Build a bootable live ISO (requires root / chroot for kernel+grub)
./build.sh iso

# Build a proot-distro tarball for Termux (default: aarch64)
./build.sh proot

# All of the above
./build.sh all

# Clean build artifacts
./build.sh clean
```

## Project layout

```
config/              package lists and sources.list (trixie)
scripts/             build drivers: rootfs, ISO, proot, overlay, chroot setup
overlay/             files injected into the rootfs
  usr/bin/neos-menu      terminal start menu
  usr/bin/neos-drivers   driver installer
  usr/bin/neos-wayland   Wayland session launcher
  usr/bin/neos-wine      run Windows console/terminal .exe apps
  usr/bin/neos-winevm    create/run isolated Windows-10 Wine VMs
  usr/bin/neos-winetricks  Wine/Winetricks bootstrap
  usr/bin/pkg            Termux-style package manager
  usr/bin/neos-distro    proot distro installer (Debian/Ubuntu/Alpine/Arch)
  usr/bin/neos-update    plan-first system updater
  usr/bin/neos-fetch     system info banner
  usr/bin/neos-ports     listening services + owning package
  usr/bin/neos-where     which package owns a command/file
  usr/bin/neos-serve     HTTP file share (with upload)
  usr/bin/neos-backup    config + package-list backup/restore
neolibs/             the NeoLIBs tool (usr/bin/neolibs)
proot-distro/        proot-distro plugin for Termux
tests/               test suites (tests/test-neolibs.sh)
build/               build artifacts (gitignored)
```

## NeoLIBs

NeoLIBs is the signature NeoOS tool: a multi-version shared-library manager.

```sh
neolibs install zlib@1.2.13 --from /path/libz.so.1.2.13   # .so file or dir
neolibs install openssl@3.2 --from-url https://.../libssl.so.3.2
neolibs install zlib@1.3.1  --from-deb zlib1g               # from a .deb
neolibs list                                               # all libraries
neolibs use zlib@1.2.13            # global default (ld.so.conf.d)
neolibs run zlib@1.2.13 -- ./app   # per-command pin (LD_LIBRARY_PATH)
neolibs remove zlib@1.2.13
neolibs doctor                      # inspect integration
```

Versions are stored under `/opt/neolibs/store` and the active version is
exposed through `/opt/neolibs/active`, registered in
`/etc/ld.so.conf.d/neolibs.conf`. Without root it falls back to a per-user
root under `~/.local/share/neolibs`.

See `neolibs/README.md` and `neolibs/COMPAT.md` for details.

## Wine & Windows apps

```sh
# Install Wine (Wine 10 on trixie) + Winetricks
neos-wine --install

# Run a Windows console/terminal app
neos-wine ./app.exe args...
neos-wine --winver win10 ./setup.exe

# Winetricks GUI
neos-wine --setup

# Isolated "Windows 10 Wine VM" (self-contained prefix)
neos-winevm create win10
neos-winevm list
neos-winevm install win10 ./some-installer.exe
neos-winevm run win10 -- "C:\Program Files\MyApp\app.exe"
neos-winevm config win10          # winetricks for that VM
neos-winevm apps win10            # list installed .exe apps
neos-winevm remove win10
```

VMs live under `~/.winevm/<name>/`, report as `Windows 10`, and keep each
installed application isolated. The base system stays untouched.

## Package manager (`pkg`)

`pkg` is a friendly, Termux-style wrapper around apt/dpkg:

```sh
pkg update                        # refresh package lists
pkg upgrade                       # upgrade all packages
pkg install build-essential git   # install (auto -y)
pkg search editor                 # search packages
pkg show vim                      # package details
pkg files vim                     # files owned by an installed package
pkg depends vim                   # dependency tree
pkg list                          # list installed packages
pkg autoremove                    # drop unneeded packages
pkg clean                         # clean the apt cache
pkg self-update                   # update NeoOS's own tools/scripts
```

`pkg self-update` pulls the NeoOS tool scripts from a git checkout
(`NEOS_REPO`, default `/opt/neos`) and re-applies the overlay; it clones
from `NEOS_GH` on first use. A plan-first updater is also available:
`neos-update` shows what would change and applies with `neos-update --apply`.

## Distro installer (`neos-distro`)

Install other Linux distributions as **proot containers** — no root, no
reboot, run them side by side:

```sh
neos-distro list                     # installed containers
neos-distro install debian          # Debian trixie (debootstrap)
neos-distro install ubuntu          # Ubuntu noble (debootstrap)
neos-distro install alpine          # Alpine mini-rootfs
neos-distro install arch            # Arch Linux bootstrap
neos-distro install /path/rootfs.tar.xz --name mydistro   # any tarball
neos-distro install https://.../rootfs.tar.xz --name foo  # any URL
neos-distro run debian              # log into the container
neos-distro run debian -- cat /etc/os-release
neos-distro exec debian -- uname -a
neos-distro info debian             # size, os, file count
neos-distro remove debian
neos-distro available               # what we can install
neos-distro doctor                  # check prerequisites
```

Containers live under `~/.neos-distro/<name>` (override with
`NEOS_DISTRO_ROOT`). They are real root filesystems: install packages
inside them with their own `apt`/`apk`/`pacman`.

## Utility toolkit

```sh
neos-fetch            # neofetch-style banner with the NeoOS logo
neos-fetch --min      # one-line summary
neos-ports            # listening TCP/UDP + owning process
neos-ports --pkg      # also show the owning package per pid
neos-ports --json     # machine-readable
neos-where vim        # which package provides the `vim` command
neos-where /bin/bash  # which package owns this file
neos-serve [dir]      # share a directory over HTTP on :8000
neos-serve --upload   # ... with file upload support
neos-backup           # back up configs + package list to a tarball
neos-backup --list f  # inspect a backup
neos-backup --restore f  # restore package list + configs
```

`neos-serve` prints a LAN URL to share files; `--upload` adds
`curl -F file=@x.tar.gz http://<host>:<port>/` transfer. `neos-backup`
saves apt/package state, `/etc` configs and NeoLIBs/Wine VM listings, and
can restore the installed package list on a fresh install.

## Termux / proot-distro

NeoOS runs on Android phones via Termux + proot-distro. Two ways are
supported, matching modern (v4/v5) and older proot-distro.

### 1. Modern proot-distro — tarball install (recommended)

Build the proot tarball (aarch64 by default; use `NEOS_ARCH=aarch64`
or `NEOS_ARCH=arm64` for phone CPUs):

```sh
./build.sh proot                                    # build neoos-proot-aarch64.tar.xz
```

Then on Termux:

```sh
# Install proot-distro (if not present)
pkg install proot-distro

# Install NeoOS from the tarball (the .tar.xz stays on your phone,
# e.g. in ~/storage/downloads)
proot-distro install ./neoos-proot-aarch64.tar.xz --name neoos

# Log in
proot-distro login neoos

# You are now in NeoOS — run the start menu
neos-menu
```

The tarball is a plain rootfs (strip components 1), so modern
proot-distro v4/v5 installs it directly without a plugin. The classic
plugin is still shipped for older versions (see below).

### 2. Classic proot-distro — plugin API

For proot-distro versions that don't accept raw tarballs, the plugin at
`proot-distro/neoos.sh` provides the classic API. On Termux, place it
under the distro plugins dir and register it:

```sh
# From a checkout of this repo, copy the plugin into proot-distro
mkdir -p $PREFIX/etc/proot-distro
cp proot-distro/neoos.sh $PREFIX/etc/proot-distro/

# Install & login
proot-distro install neoos
proot-distro login neoos
```

The plugin declares `DISTRO_NAME="NeoOS"` and
`TARBALL_STRIP_COMPONENTS=1`; it expects the rootfs tarball to be
reachable (see `scripts/build-proot.sh`).

### Notes for Termux

- Network inside the proot uses a resolv.conf pointing at
  8.8.8.8 / 1.1.1.1 (see `scripts/build-proot.sh`) — set
  `NEOS_TARBALL=none` or keep the default if you prefer.
- Termux may prompt to grant storage access for
  `~/storage/downloads` when moving the tarball onto the phone.
- Everything else works the same as on a real NeoOS install:
  `neos-menu`, `neolibs`, `neos-drivers --detect`, `neos-wine`, etc.

## Testing

```sh
bash tests/test-neolibs.sh
```

## Requirements for building

- A Debian/Ubuntu host (Debian 12 used for development)
- `mmdebstrap`, `xorriso`, `grub-mkrescue` (installed automatically if you
  run the build as root)
- Network access to `deb.debian.org`
- The ISO build additionally needs `chroot` + root to install the kernel

## Roadmap

- [x] trixie rootfs + overlay
- [x] NeoLIBs multi-version library manager
- [x] Terminal start menu (code / internet / drivers / wayland / wine / system)
- [x] Driver installer (GPU / WiFi / BT / audio / printer / firmware)
- [x] Wayland + Winetricks integration
- [x] Wine: run Windows exe terminal apps (neos-wine)
- [x] Wine VM creator: isolated Windows-10 VMs (neos-winevm)
- [x] proot-distro support (tarball + plugin)
- [x] Live ISO build
- [x] Host + rootfs tool updates (pkg/apt update + upgrade)
- [ ] GUI desktop session (optional) via `neos-wayland --session full`
- [ ] NeoLIBs build-from-source (`--from-src`)
- [ ] Firmware mirror + offline driver packs
- [ ] QEMU-backed hardware VM for Windows 10 (real VM mode)
