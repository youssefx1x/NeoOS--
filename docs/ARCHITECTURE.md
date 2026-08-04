# NeoOS Architecture

## Overview

NeoOS is a terminal-first Linux distribution assembled from **Debian 13
(trixie)**. It is produced entirely by scripts in this repository — there is
no custom kernel or fork of the archive; NeoOS layers a curated terminal
experience on top of the standard Debian archive.

```
  +---------------------------------------------------------------+
  |  NeoOS layer  (overlay/ + neolibs/)                          |
  |   neos-menu · neos-drivers · neos-wayland · neos-wine        |
  |   neos-winevm · neos-winetricks · pkg · neos-distro          |
  |   neos-fetch · neos-serve · neos-backup · neos-update        |
  |   neos-ports · neos-where · neos-installer · neolibs         |
  |   motd · os-release · calamares branding                      |
  +---------------------------------------------------------------+
  |  Debian 13 (trixie) archive                                    |
  |  main + contrib + non-free-firmware                            |
  +---------------------------------------------------------------+
```

## Build pipeline

1. **`scripts/build-rootfs.sh`** — `mmdebstrap` creates a minimal trixie
   rootfs (`build/rootfs`) with the base package list
   (`config/packages.base`), using the sources in `config/sources.list`.
2. **`scripts/apply-overlay.sh`** — copies `overlay/` into the rootfs,
   installs NeoLIBs + its docs, writes `os-release`, `motd`,
   `machine-info`.
3. **`scripts/setup-iso.sh`** — runs inside the rootfs via chroot: installs
   kernel, initramfs, live-boot, grub files; creates the `neo` user and
   hooks `.profile` to drop into the start menu.
4. **`scripts/build-iso.sh`** — packs the rootfs into a squashfs, assembles
   a bootable ISO with `grub-mkrescue` + `xorriso` (live boot menu).
5. **`scripts/build-proot.sh`** — produces a plain rootfs tarball
   (`build/neoos-proot-<arch>.tar.xz`) plus Termux-friendly resolv.conf for
   use with proot-distro on Android.
6. **Installer (on demand)** — `neos-installer` installs Calamares + a
   minimal Qt6/QML + Weston/XWayland GUI stack on first use (packages in
   `config/packages.calamares`, shipped at `/usr/lib/neos/packages.calamares`)
   and launches it against a NeoOS-branded `/etc/calamares/settings.conf`.
   With `NEOS_INCLUDE_INSTALLER=1` the ISO build embeds the installer
   directly into the live media instead.

## Components

### Start menu — `neos-menu` (`overlay/usr/bin/neos-menu`)

A whiptail/dialog TUI with six sections:

- **Code** — installs updated code apps: toolchains, editors, languages,
  debuggers (drives `apt`).
- **Internet** — terminal browsers, download tools, network diagnostics,
  IRC messaging.
- **Drivers** — launches `neos-drivers`.
- **Wayland** — starts/installs the Wayland stack and Winetricks.
- **Wine** — `neos-wine`/`neos-winevm` (Windows apps + Win10 VMs).
- **NeoLIBs** — thin wrapper around `neolibs`.
- **Tools** — pkg manager, `neos-distro`, `neos-update`,
  `neos-fetch`, `neos-ports`, `neos-where`, `neos-serve`,
  `neos-backup`, `pkg self-update`.
- **System** — apt update/upgrade, package management, sources editor,
  graphical installer (`neos-installer`), shutdown/reboot.

It re-executes after each action (`main_menu` recursion) until *Quit*.

### Graphical installer — `neos-installer` (`overlay/usr/bin/neos-installer`)

NeoOS is terminal-first, so installing to disk from live media needs a GUI
stack brought up on demand:

- Ensures `calamares` + `calamares-settings-debian` and the Qt6/QML +
  Weston/XWayland deps are installed (packages listed in
  `config/packages.calamares`).
- Writes `/etc/calamares/settings.conf`: a Debian-compatible install
  sequence (partition, mount, unpackfs, machineid, fstab, users,
  displaymanager, networkcfg, grubcfg, bootloader, initramfs, ...) with
  `branding: neoos`. If the settings package already wrote the file, only
  the `branding:` line is rewritten so the sequence tracks package config.
- Starts a Weston + XWayland session (DRM backend when `/dev/dri/card0` is
  writable, headless fallback otherwise) and runs `pkexec calamares`.
- `--install` (deps only), `--check` (prerequisites), `--no-gui` (use an
  existing display).

Branding ships in `overlay/usr/share/calamares/branding/neoos/`
(`branding.desc`, QML slideshow `show.qml`, `neos.svg`, `welcome.svg`) and
is found via Calamares's branding search paths. Module lookup uses
`modules-search: [ local, /usr/lib/calamares/modules ]` — `local` resolves
to the Debian multiarch libdir (`/usr/lib/<arch>/calamares/modules`).

### Driver installer — `neos-drivers` (`overlay/usr/bin/neos-drivers`)

- Enables `non-free-firmware` in sources.list (with backup) if absent.
- `--detect` shows hardware via `/proc/cpuinfo`, `lspci`, `lsusb`.
- Menu-driven installs: All, GPU (Mesa/Vulkan + AMD/NVIDIA firmware), WiFi
  (`wpa_supplicant`, NetworkManager, wireless tools), Bluetooth (BlueZ),
  Audio (ALSA + PipeWire/PulseAudio), Printer (CUPS + drivers), Firmware
  (`firmware-linux*`).
- Re-execs via sudo when not root.

### Wayland — `neos-wayland` (`overlay/usr/bin/neos-wayland`)

- Ensures the stack (`weston`, `seatd`, `xwayland`, `foot`, `wmenu`,
  mesa) is installed.
- Writes a session script to `~/.config/neos/wayland-session.sh` that sets
  up `XDG_RUNTIME_DIR`, launches `weston --backend=auto --xwayland`, then
  starts `foot` inside the compositor.
- `neos-wayland install` / `neos-wayland session` subcommands.

### Wine / Winetricks

- `neos-wine` — runs Windows `.exe` terminal/console apps. Ensures Wine is
  installed (Wine 10 on trixie; `wine32` auto-added only when a candidate
  exists), initializes a `win64` prefix, defaults the reported version to
  `win10`, and pipes app stdout/stderr cleanly (WINEDEBUG=-all). Prefers
  `wine64` to avoid the `wine32` wrapper warning.
- `neos-winevm` — a Wine "VM" creator: each VM is a self-contained prefix
  under `~/.winevm/<name>/` (arch `win64`, winver `win10`). Commands:
  `create`, `list`, `run <vm> -- app`, `install <vm> setup.exe`, `config`
  (winetricks GUI), `apps`, `info`, `remove`.
- `neos-winetricks` — thin compat wrapper delegating to `neos-wine`
  (`install` -> `neos-wine --install`, `config` -> `neos-wine --setup`,
  `run -- cmd` -> `neos-wine cmd`).

### Package manager & utilities — `pkg`, `neos-*` (`overlay/usr/bin/`)

- `pkg` — Termux-style wrapper over apt/dpkg: `update`/`upgrade`/
  `install`/`remove`/`purge`/`search`/`show`/`files`/`depends`/`list`/
  `autoremove`/`clean`, plus `pkg self-update` which pulls the NeoOS tool
  scripts from `NEOS_REPO` (default `/opt/neos`) and re-applies the
  overlay. Uses sudo transparently when not root.
- `neos-distro` — installs Debian/Ubuntu/Alpine/Arch (or any
  tarball/URL) as isolated **proot containers** under `~/.neos-distro`.
  Debootstrap for deb-based distros, direct tarball for Alpine/Arch.
  Subcommands: `list`, `install`, `run`, `exec`, `info`, `remove`,
  `available`, `doctor`.
- `neos-update` — plan-first updater; lists upgradable packages,
  applies with `--apply`, optionally cleans cache.
- `neos-fetch` — neofetch-style banner with the NeoOS ASCII logo
  (replaces `neofetch`, which left trixie).
- `neos-ports` — list listening TCP/UDP sockets with pid/process and
  the owning package (`--pkg`) or JSON (`--json`).
- `neos-where` — which installed package owns a command or file
  (`dpkg -S`, `apt-file`, `apt-cache` fallback).
- `neos-serve` — quick HTTP file listing server; `--upload` adds POST
  file reception (`curl -F file=@x http://host:port/`).
- `neos-backup` — tar.gz snapshot of apt/package state, `/etc` configs,
  NeoLIBs store and Wine VM / distro container listings; `--restore`
  re-installs the saved package list.

### NeoLIBs — `neolibs/neolibs` (installed to `/usr/bin/neolibs`)

Multi-version shared-library manager. Storage layout:

```
/opt/neolibs/
  store/<name>/<version>/lib/*.so*
  active/<name>/lib -> ../../store/<name>/<version>/lib
  active/<name>/*.so*          (symlinks)
  active/<name>/.active-version
/var/lib/neolibs/<name>.reg    (installed versions, one per line)
/etc/ld.so.conf.d/neolibs.conf -> /opt/neolibs/active
```

- Global switching (`use`) writes the ld.so.conf.d entry and runs `ldconfig`
  (root).
- Per-command pinning (`run`) sets `LD_LIBRARY_PATH` (no root).
- Rootless fallback to `~/.local/share/neolibs` when `/opt` is unwritable.
- Sources: local `.so`/dir (`--from`), URL (`--from-url`), apt package
  (`--from-deb`).

## Termux / proot-distro

- Modern proot-distro (v4/v5) installs a plain rootfs tarball:
  `proot-distro install <path>/neoos-proot-<arch>.tar.xz --name neoos`.
- Legacy plugin API: `proot-distro/neoos.sh` (install into
  `$PREFIX/etc/proot-distro/`).
- resolv.conf pinned to 8.8.8.8/1.1.1.1 for proot networking.

## Security & policy notes

- NeoLIBs deliberately does not swap glibc (`libc.so.6`); it targets
  application-level libraries. See `neolibs/COMPAT.md`.
- Firmware (non-free-firmware) is optional and only enabled by the driver
  installer when requested.
