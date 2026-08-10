# NeoOS

A terminal-first Linux distribution built on **Debian 13 (trixie)**. This is **NeoOS 1.1.0 Stable**, the fully apt-updated, stable release.

NeoOS is a minimal, terminal-only operating system focused on development,
networking and tinkering. It ships a **terminal start menu** (code
applications, internet tools, driver installer), a **Wayland + Winetricks**
stack for running GUI apps when you want them, and **NeoLIBs** — a new tool
for installing and switching between multiple versions of the same shared
library.

```
      NeoOS 1.1.0 Stable — Debian 13 (trixie) terminal distribution
      ┌─────────────────────────────────────────────────┐
      │  Code        updated code apps + toolchains     │
      │  Internet    browsers, messaging, network utils │
      │  Drivers     hardware / driver installer        │
      │  Wayland     Weston + XWayland session          │
      │  Wine        Windows apps (neos-wine + VM)      │
      │  NeoLIBs     multi-version library manager      │
      │  Monitor     live sysmon, disk, cleaner, bat    │
      │  Network     diagnostics, IP, speed test        │
      │  Productivity todos, notes, timer, calc         │
      │  Dev         project scaffolds + lang toolchains │
      │  Tools       pkg, help, distro installer, ...   │
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
- **Graphical installer** (`neos-installer`) — Calamares (Qt6) based
  installer that writes NeoOS to disk from the live media. Ships NeoOS
  branding + a Debian-compatible install sequence; pulls the GUI stack in
  on demand so the base system stays lean.
- **Utility toolkit** — `neos-update` (plan-first updater),
  `neos-fetch` (neofetch-style banner), `neos-help` (lists every NeoOS
  command, with full usage per tool), `neos-ports` (listening
  services + owning package), `neos-where` (which package owns a
  command/file), `neos-serve` (HTTP file share with upload),
  `neos-backup` (configs + package-list backup/restore).
- **Monitor & health section** — `neos-monitor` (live CPU/memory/top),
  `neos-health` (system health check), `neos-disk` (disk analyzer),
  `neos-clean` (cache/log/temp cleaner, dry-run first),
  `neos-battery` (power status).
- **Network section** — `neos-net` (interfaces/gateway/DNS/ping),
  `neos-ip` (local + public IPs), `neos-speedtest`.
- **Productivity section** — `neos-todo`, `neos-notes`, `neos-timer`
  (countdown/pomodoro), `neos-calc`, `neos-fortune`.
- **Dev section** — `neos-new` (scaffolds bash/python/C/web/shlib
  projects) and `neos-lang` (install/list language toolchains).
- **User manager** (`neos-users`) — create multiple users with two
  levels (normal / Administrator), delete/passwd/groups, plus a
  disposable `guest` account with first-time auto-login on tty1.
- **Wayland support** — `neos-wayland` starts a Weston compositor with
  XWayland; Wayland apps (foot, wmenu) are one menu click away.
- **Winetricks / Wine** — `neos-winetricks` bootstraps Wine, initializes a
  prefix and launches Winetricks for Windows apps. Use `neos-wine` to run
  console `.exe` apps and `neos-winevm` for isolated Windows-10 VMs.
- **proot-distro on Termux** — install NeoOS on Android via proot-distro.
- **ISO build** — build a bootable live ISO from the rootfs.

## Phase 3 preview (current development)

- **NeoOS Uranium** (`neos-uranium`) — one-tap driver installer. `neos-uranium`
  installs every driver package in `config/packages.drivers`; `neos-uranium
  suggest`/`update`/`scan` consult an online package index (apt) plus a bundled
  PCI/USB driver DB (`config/driver-db.tsv`). Covers GPU/Mesa/Vulkan,
  AMD/NVIDIA firmware, WiFi (Intel/Qualcomm/Broadcom/Atheros), Bluetooth,
  audio, printing and `qemu-guest-agent`.
- **Auto-suggest on network up** — `/etc/network/if-up.d/neos-uranium-suggest`
  fires when Ethernet or USB-tethering comes up and prints a driver tip.
- **QEMU on Android** — `scripts/run-neoos-qemu.sh` boots the image on a
  non-rooted Termux host (TCG arm64, virtio GPU, user-net + SSH forward,
  `/sdcard` and `$HOME` 9p shares, optional VNC/SPICE/headless).
- **Centralised mirror** — `neos-mirror {status|apply|revert}` switches apt
  sources to `NEOS_MIRROR_URL` (template in `config/sources.neoos.list`).
- **One-click OTA** — `neos-update --ota` checks and `--ota-apply` downloads +
  installs a signed distribution delta from `NEOS_OTA_URL` (GPG-verified when
  `NEOS_OTA_KEY` is set to a keyring path).
- **Dark Windows-like desktop** — XFCE with Arc-Dark/Papirus-Dark, a bottom
  Whisker start menu, libinput tap-to-click + natural-scroll tuning
   (`overlay/etc/X11/xorg.conf.d/40-libinput-touch.conf`), and lightdm auto-login.

## NeoCore, NeoPkg 2.0 & the `neo` CLI  (Stable — NeoOS 1.1.0)

NeoOS 1.1.0 ships three new, stable pieces that sit cleanly on top of the
existing `neos-*` tools and `pkg`:

- **NeoCore** — a thin, dependency-free system layer at
  `overlay/usr/lib/neos/libneocore.sh`. It exposes system status/info,
  service state, diagnostics, repair, hardware inventory and a small event
  bus plus a capability manager (`root`/`apt`/`systemd`/`online`). It is the
  shared backend for every `neo` subcommand and for `neos-help`.
- **`neo`** — the unified, version-stable entry point. `neo` is a pure
  alias/facade layer: it loads NeoCore and delegates. `neo system <cmd>`
  (status/info/services/diagnose/repair/hw/procs), `neo <pkg-op>` delegates
  to `pkg` (install/remove/upgrade/search/show/files/depends/list/doctor/
  rollback/history/clean/self-update), and `neo ai|health|update|menu|...`
  pass through to the existing `neos-*` tools.
  ```
  neo system status          # uptime, load, memory, disk, net, caps
  neo system info            # kernel/arch/host/os/toolchain versions
  neo install neovim         # -> pkg install neovim  (NeoPkg 2.0)
  neo doctor                 # -> pkg doctor          (dependency audit)
  neo rollback 2             # -> pkg rollback 2      (snapshots)
  neo history                # -> pkg history         (txn log)
  neo version                # NeoCore 1.1.0 / NeoAPI 1.1.0
  ```
- **NeoPkg 2.0 (in `pkg`)** — `pkg` is extended (not rewritten) with
  dependency resolution, automatic rollback via per-transaction snapshots
  (`/var/lib/neopkg/snapshots`), package verification, repository
  priorities, package signing, parallel downloads, delta updates, and an
  offline cache. New subcommands: `pkg doctor`, `pkg rollback [id]`,
  `pkg history`, and multi-source `pkg search`/`pkg show`.
- **NeoLIBs native core (NeoAPI 1.1)** — `neolibs/libneo-core` ships a C ABI
  core (`libneo.so`, NeoAPI v1.1.0 stable) backing `core`, `system`, `fs`,
  `net`, `process` and `package` modules, with multi-language bindings
  (C/C++/Rust/Python/JS/TS via ctypes/node-ffi-napi). It is built and
  installed into the rootfs by `scripts/apply-overlay.sh` as
  `/usr/lib/libneo.so{,.1,.1.1.0}` + headers in `/usr/include/neo/`.
  ```
  pkg-config --modversion neoapi     # 1.1.0
  ```

These three are wired into the live ISO at build time (see
`scripts/apply-overlay.sh`) and listed by the unified command reference
(`neos-help`).

## NeoOS architecture (NeoX components)

NeoOS 1.1.0 is built from **40 versioned NeoX system components**. Each ships a
`neos-<name>` entry-point tool that you can run directly or through the `neo`
dispatcher (e.g. `neo core`, `neo sdk`, `neo model`). Run `neos-help` for the
full list and `neos-help <tool>` for usage.

| # | Component | Tool | Purpose |
|---|-----------|------|---------|
| 1 | NeoCore | `neos-core` | Core OS services & unified system API |
| 2 | NeoLIBs | `neos-libs` | Native libraries and developer APIs |
| 3 | NeoPkg | `neos-pkg` / `pkg` | Unified package manager |
| 4 | NeoSecurity | `neos-security` | Permissions, verification & system security |
| 5 | NeoAI | `neos-ai` | Native AI assistant |
| 6 | NeoAgent | `neos-agent` | AI system-agent with controlled capabilities |
| 7 | NeoApps | `neos-apps` | Native application framework |
| 8 | NeoStore | `neos-store` | App/package store |
| 9 | NeoShell | `neos-shell` | Modern command shell & launcher |
| 10 | NeoDesktop | `neos-desktop` | NeoOS desktop environment |
| 11 | NeoWM | `neos-wm` | Wayland window management |
| 12 | NeoMobile | `neos-mobile` | Android/Proot mobile environment |
| 13 | NeoHardware | `neos-hw` | Hardware detection & abstraction |
| 14 | NeoDoctor | `neos-doctor` | Automatic system diagnostics & repair |
| 15 | NeoRecovery | `neos-recovery` | System recovery & rollback |
| 16 | NeoUpdate | `neos-update` | Safe atomic system updates |
| 17 | NeoSnapshots | `neos-snapshots` | System snapshots & restore |
| 18 | NeoSandbox | `neos-sandbox` | Application/process isolation |
| 19 | NeoWin | `neos-wine` | Windows/Wine application integration |
| 20 | NeoVM | `neos-vm` | Virtual machine management |
| 21 | NeoContainer | `neos-distro` | Container management |
| 22 | NeoDev | `neos-dev` | Developer toolkit & project management |
| 23 | NeoCode | `neos-code` | Integrated development environment |
| 24 | NeoFiles | `neos-files` | Modern file manager |
| 25 | NeoSearch | `neos-search` | System-wide search |
| 26 | NeoNotify | `neos-notify` | Unified notification system |
| 27 | NeoMonitor | `neos-monitor` | System/resource monitoring |
| 28 | NeoLogs | `neos-logs` | Centralized system logs |
| 29 | NeoConfig | `neos-config` | Unified configuration management |
| 30 | NeoNetwork | `neos-net` | Network management & diagnostics |
| 31 | NeoPower | `neos-power` | Power/battery management |
| 32 | NeoPerformance | `neos-perf` | Performance profiles & optimization |
| 33 | NeoTheme | `neos-theme` | Unified themes, icons & appearance |
| 34 | NeoAccessibility | `neos-access` | Accessibility framework |
| 35 | NeoLocalization | `neos-locale` | Language & RTL support |
| 36 | NeoTest | `neos-test` | Automated system/component testing |
| 37 | NeoBuild | `neos-build` | ISO/rootfs/package build system |
| 38 | NeoSDK | `neos-sdk` | Developer SDK for NeoOS apps |
| 39 | NeoRepo | `neos-repo` | Official package repository infrastructure |
| 40 | NeoModel | `neos-model` | Local AI model management |

## Quick start

```sh
# Build the root filesystem (Debian 13 trixie)
./build.sh rootfs

# Build a bootable live ISO (needs root; auto-chroots to add kernel/grub)
./build.sh iso

# Build a proot-distro tarball for Termux (default: aarch64)
./build.sh proot

# All of the above
./build.sh all

# Clean build artifacts
./build.sh clean

# Boot the live ISO in QEMU on the host (x86-64)
qemu-system-x86_64 -cdrom build/neoos.iso -m 2G
```

## NeoOS in WSL2

NeoOS also runs as a **WSL2 distribution** — no emulator, full WSLg GUI support.
WSL2 is x86-64, and `build.sh rootfs` defaults to `--arch amd64`, so the build
is a native match.

**Prerequisites** (Windows 11 22H2+, with WSL2 + WSLg GUI enabled):

```powershell
wsl --install     # installs a base distro; GUI comes via WSLg
```

**Steps** (run from a WSL2 distro):

```sh
# 1. Build the NeoOS rootfs (x86-64 by default on WSL2)
./build.sh rootfs                       # produces build/rootfs
( cd build && tar -cf ../neoos-rootfs.tar -C rootfs . )   # plain .tar for WSL import
```

```powershell
# 2. Import into WSL (run in an elevated PowerShell on Windows)
wsl --import NeoOS "$env:USERPROFILE\NeoOS" .\neoos-rootfs.tar --version 2
```

Then launch NeoOS directly (native speed) or its XFCE desktop (via WSLg):

```sh
wsl -d NeoOS                          # NeoOS shell
wsl -u root -d NeoOS neos-xfce        # start the dark XFCE desktop (WSLg)
```

Notes:
- To force a specific arch, build with `bash scripts/build-rootfs.sh --arch amd64 --out build/neoos-rootfs`.
- WSL2 networking is NAT — USB tethering doesn't apply here, so the
  `neos-uranium` auto-suggest-on-network hook (if-up.d) won't fire; run
  `neos-uranium` manually to install drivers when you connect an Ethernet cable
  in WSL Settings.
- For the arm64 image instead: install `qemu-system-aarch64` in WSL2 and run
  `scripts/run-neoos-qemu.sh build/neoos.img` (TCG emulation — slower).

## Project layout

```
config/              package lists and sources.list (trixie): packages.base,
                    packages.xfce, packages.drivers, packages.calamares, ...
scripts/             build drivers: rootfs, ISO, proot, overlay, chroot
                    setup, and run-neoos-qemu.sh (Termux QEMU launcher)
overlay/             files injected into the rootfs
  usr/bin/neos-menu      terminal start menu
  usr/bin/neos-uranium   one-tap driver installer (NeoOS Uranium)
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
  usr/bin/neos-installer graphical Calamares installer launcher
  usr/bin/neos-users     user manager (normal/admin levels, guest autologin)
  usr/bin/neos-guest     guest-account front-end (neos-users guest ...)
  usr/share/calamares/branding/neoos/  NeoOS installer branding (branding.desc, QML slideshow, SVG logos)
  etc/calamares/settings.conf          NeoOS Calamares install sequence
neolibs/             the NeoLIBs tool (usr/bin/neolibs)
proot-distro/        proot-distro plugin for Termux
tests/               test suites (tests/test-neolibs.sh)
build/               build artifacts (gitignored)
```

## Users & accounts (`neos-users`)

A small account manager for the terminal:

```sh
neos-users list                          # users: name, uid, level, groups
neos-users add alice                     # normal user
neos-users add bob --admin               # Administrator (sudo group)
neos-users delete alice                  # remove a user + home
neos-users passwd bob                    # change password
neos-users groups bob                    # show groups

neos-users guest enable                  # create guest + auto-login on tty1
neos-users guest status                  # guest account + autologin state
neos-users guest disable                 # keep guest, stop auto-login
neos-users guest remove                  # delete guest account
neos-guest status                        # same as neos-users guest status
```

- **Levels** — an *Administrator* is a member of the `sudo` group; a normal
  user is not. `list` shows each user's level.
- **First-time auto-login onto guest** — `guest enable` creates a disposable
  `guest` account (password locked, home reset from `/etc/skel` on every
  login) and installs a systemd `getty@tty1` override so the machine boots
  straight into the guest account. A `/var/lib/neos/.guest-firstdone` marker
  makes the one-time setup idempotent.
- `neo`, `guest` and `root` are reserved: `delete` refuses them.
- `autologin <name|none>` sets a regular TTY autologin for any user.

## Installer (`neos-installer`)

NeoOS is terminal-first, but installing to real hardware from the live
media needs a GUI. `neos-installer` brings up the pieces on demand:

```sh
neos-installer              # install Calamares + GUI stack, then launch
neos-installer --install    # only install Calamares + GUI stack
neos-installer --check      # verify prerequisites and exit
neos-installer --no-gui     # run against an existing DISPLAY/Wayland
```

On first launch it:

1. Installs `calamares`, `calamares-settings-debian` and a small Qt6/QML +
   Weston/XWayland GUI stack (packages listed in
   `config/packages.calamares`, shipped to the system at
   `/usr/lib/neos/packages.calamares`).
2. Writes a NeoOS-branded `/etc/calamares/settings.conf` with a
   Debian-compatible install sequence (partition, mount, unpackfs, fstab,
   grub, bootloader, initramfs, displaymanager, ...). If the settings
   package already wrote it, only the `branding:` line is rewritten to
   `neoos`, so the sequence stays robust across package config drift.
3. Starts a Weston + XWayland session (DRM backend when a GPU is present,
   headless fallback otherwise) and runs `pkexec calamares`.

Installer branding (logos, slideshow, product name) ships in
`overlay/usr/share/calamares/branding/neoos/`.

The base rootfs stays lean: Calamares is installed on demand from the
running system's apt sources. To embed it directly into the live media
instead, build the ISO with:

```sh
NEOS_INCLUDE_INSTALLER=1 ./build.sh iso
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
(`NEOS_REPO`, default `/opt/neos`) and re-applies the overlay; on first
use it can clone from a URL you provide via `NEOS_GH`. A plan-first
updater is also available: `neos-update` shows what would change and
applies with `neos-update --apply`.

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
neos-tools              # list/run every NeoOS tool
```

`neos-serve` prints a LAN URL to share files; `--upload` adds
`curl -F file=@x.tar.gz http://<host>:<port>/` transfer. `neos-backup`
saves apt/package state, `/etc` configs and NeoLIBs/Wine VM listings, and
can restore the installed package list on a fresh install.

`neos-tools` is a meta-menu: `neos-tools list` shows every installed NeoOS
tool with a one-line summary, `neos-tools run <name> [args]` runs one, and
`neos-tools menu` opens an interactive picker (whiptail). It auto-discovers
tools, so it always reflects what's installed.

## Termux / proot-distro

NeoOS runs on Android phones via Termux + proot-distro. Two ways are
supported, matching modern (v4/v5) and older proot-distro.

### 1. One-command install (recommended)

The fastest way to get NeoOS on your phone is the installer script, which
downloads the correct release tarball for your CPU and installs it with
proot-distro in one step — no build, no manual download:

```sh
# Runs on arm64 phones/tablets (detects aarch64 automatically).
curl -fsSL https://raw.githubusercontent.com/youssefx1x/NeoOS--/main/scripts/install-neeos.sh | bash
```

The script picks `neoos-proot-aarch64.tar.xz` on arm64 or
`neoos-proot-amd64.tar.xz` on x86_64, fetches it from the
[NeoOS GitHub Release](https://github.com/youssefx1x/NeoOS--/releases),
installs it as `neoos`, and logs you in. Override the release with
`NEOS_RELEASE=1.1.0`, the container name with `NEOS_NAME=neoos`, or install
from a local/HTTP tarball with `NEOS_INSTALL_TARBALL=<path-or-url>`:

```sh
# Example: install from an arbitrary HTTP URL (e.g. a local mirror)
NEOS_INSTALL_TARBALL=https://example.org/neoos-proot-aarch64.tar.xz \
  curl -fsSL https://raw.githubusercontent.com/youssefx1x/NeoOS--/main/scripts/install-neeos.sh | bash
```

### 2. Modern proot-distro — install from a release tarball

NeoOS publishes prebuilt rootfs tarballs for proot-distro in the
[GitHub Releases](https://github.com/youssefx1x/NeoOS--/releases). Point
proot-distro directly at the release URL for your architecture:

```sh
# Install proot-distro (if not present)
pkg install proot-distro

# Install NeoOS straight from the release URL (proot-distro fetches the .tar.xz)
proot-distro install https://github.com/youssefx1x/NeoOS--/releases/download/1.1.0/neoos-proot-aarch64.tar.xz --name neoos   # arm64 phone

# Log in
proot-distro login neoos

# You are now in NeoOS — run the start menu
neos-menu
```

(Use `neoos-proot-amd64.tar.xz` for x86_64 devices.) The tarball is a plain
rootfs (strip components 1), so modern proot-distro v4/v5 installs it directly
without a plugin. Prefer to build it yourself? Run `./build.sh proot` and
install the local `./neoos-proot-aarch64.tar.xz` with the same command. The
classic plugin is still shipped for older proot-distro versions (see below).

### 3. Classic proot-distro — plugin API

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
