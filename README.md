# NeoOS--
A hybrid, lightweight Debian-based OS for Desktop and Mobile (Proot), featuring custom tools and seamless Windows app support
The setup
# 🌌 Neoos (Neolinux)

![Build Status](https://img.shields.io/badge/build-passing-brightgreen)
![Version](https://img.shields.io/badge/version-v1.0.1--Stable-blue)
![License](https://img.shields.io/badge/license-GPLv3-orange)

**Neoos** is a highly modular, lightweight Debian-based hybrid operating system designed for desktop environments and embedded/mobile Proot containers. It features a custom toolchain, native Wayland support, pre-configured Windows app compatibility, and a fully branded Calamares installation wizard.

---

## ✨ System Features

*   **🧰 Custom Ecosystem (`neos-*`):** Complete set of custom maintenance utilities located in `/usr/bin/` including `neos-update`, `neos-backup`, `neos-drivers`, `neos-ports`, `neos-serve`, and the `pkg` wrapper.
*   **📱 Hybrid Target Support:** Built to compile both bootable Live ISO images for PCs and rootfs tarballs for Android/Termux environments (`proot-distro/neoos.sh`).
*   **🍷 Pre-configured Windows Compatibility:** Integrated out-of-the-box support for Windows applications using `neos-wine`, `neos-winetricks`, and `neos-winevm`.
*   **🎨 Custom Calamares Installer:** Includes customized installer configurations (`settings.conf`) and full branding assets (`branding.desc`, `show.qml`, SVG icons).
*   **⚡ Lightweight & Fast:** Optimized package selection across base, wayland, devel, and internet configurations, creating a full-featured system inside a ~1 GB ISO.

NeoOS equips you with a full suite of custom binaries designed to replace bloated commands with fast, intuitive CLI utilities:

### 🤖 Core System & AI Integrations
* `neos` – Main unified CLI controller and launcher for the OS.
* `neos-ai` – Terminal AI assistant interface driven by `/etc/neos/ai.conf`.
* `neos-gui` – Graphical interface launcher and session controller.
* `pkg` – Universal simplified wrapper for package management (`apt` helper).

### 🛠️ System Health, Diagnostics & Maintenance
* `neos-health` – Complete system health check and diagnostic suite.
* `neos-clean` – Cleans system caches, temp files, and orphan packages.
* `neos-disk` – Disk usage analyzer and filesystem monitoring.
* `neos-monitor` – Real-time resource monitor (CPU, RAM, Processes).
* `neos-battery` – Power management, battery health, and power profiles.
* `neos-backup` – Fast system snapshot and configuration archiver.
* `neos-update` – Complete system upgrade and mirror synchronizer.
* `neos-drivers` – Automatic hardware and GPU driver detection tool.
* `neos-users` – User accounts, groups, and permissions manager.
* `neos-guest` – Quick guest session sandbox launcher.

### 🌐 Network & Connectivity Utilities
* `neos-net` – Network interface status and configuration tool.
* `neos-ip` – Instant display of local and public IP addresses.
* `neos-speedtest` – CLI internet bandwidth speed testing.
* `neos-ports` – Active listening ports and network sockets monitor.
* `neos-serve` – Instant local HTTP file server launcher.

### ⚡ Productivity & Everyday Utilities
* `neos-help` – Interactive manual and guide for all `neos-*` commands.
* `neos-new` – Scaffold new projects and templates from terminal.
* `neos-notes` – Fast CLI quick notes manager.
* `neos-todo` – Lightweight terminal to-do list manager.
* `neos-calc` – Fast command-line calculator.
* `neos-timer` – Terminal stopwatch and countdown timer.
* `neos-lang` – Fast system language and keyboard layout switcher.
* `neos-start` – Startup applications and autostart services manager.
* `neos-fortune` – Quick quotes and tips generator.
* `neos-fetch` – NeoOS customized system information fetcher.
* `neos-where` – Locates system binary sources and configs.

### 🎮 Compatibility & Installation Layer
* `neos-wine` – Wine launcher wrapper for Windows executables.
* `neos-winetricks` – Quick launcher for Wine library dependencies.
* `neos-winevm` – Isolated sandbox environment for running Windows applications.
* `neos-wayland` – Wayland compositor configuration and session tools.
* `neos-installer` – Calamares GUI installer launcher.
* `neos-menu` – Terminal application menu and launcher.
* `neos-distro` – Distribution release and kernel info utility.

---

## 🤔 Why NeoOS instead of Stock Debian?

While Debian provides rock-solid stability, it requires significant manual post-configuration for lightweight desktop usage, compatibility layers, and container setups. 

**NeoOS focuses on:**
* **Aggressive Performance Tuning:** Out-of-the-box Wayland stack stripped of unnecessary background bloat.
* **Unified Desktop/Mobile Workflow:** Run the exact same base system on PC hardware (Live ISO) or Android environments via Proot.
* **Lightweight Developer Tooling:** Native wrapper utilities (`neos-*`) that simplify driver management, system backups, and package management.
* **Zero-Setup Windows App Support:** Pre-configured WineVM and WineTricks integrations ready on first boot.
---

## 🚦 Feature Status & Roadmap

| Feature | Status | Description |
| :--- | :---: | :--- |
| **Debian Base Rootfs Generation** | ✅ Available | Stable base image build pipelines (`build-rootfs.sh`) |
| **Wayland Desktop Stack** | ✅ Available | Lightweight compositor and interface setup |
| **Custom Maintenance CLI Toolchain** | ✅ Available | Native utilities for system management (`/usr/bin/neos-*`) |
| **Calamares GUI Installer** | ✅ Available | Full installer integration with custom branding |
| **Proot Mobile Environment** | ✅ Available | Android/Termux deployment wrapper (`proot-distro/neoos.sh`) |
| **Wine / WineVM Integration** | ✅️ Avaiable | Automated pre-configured environment for Windows apps |
| **Automated Driver Detection** | ✅️ Available | Hardware-specific GPU/Wi-Fi driver setup (`neos-drivers`) |
| **OTA System Update Pipeline** | ✅️ Available | Centralized binary repository updating via `neos-update` |

---
# 🗺️ Development Roadmap
​Phase 1: Foundation (Current - v1.0.0-beta)
​✅ Automated Rootfs compilation pipeline.
​✅ Custom Calamares GUI installer integration.
​✅️Native neos-* CLI helper suite.
​Phase 2: Compatibility & Hardware (v1.1.0 - Upcoming)
​✅️ Automated GPU/Wi-Fi driver detection script.
​✅️ Stable WineVM sandboxing for Windows apps.
​🧪 Mobile touch gestures optimization for Proot display.
​Phase 3: Ecosystem & Infrastructure (v2.0.0 - Planned)
​🧪 Centralized NeoOS package repository & mirror endpoints.
​🗓️ One-click OTA distribution updates via neos-update.

# ​🐛 Known Issues (Beta)
​NVIDIA Proprietary Drivers: Wayland session may require fallback execution on select older NVIDIA hardware.[Solved]
​Wine Prefix Initialization: First run of neos-winevm requires 30–60 seconds to configure the wine prefix environment.[Not yet]
​Termux Audio Server: Sound output inside Proot mobile mode requires starting PulseAudio manually inside Termux.[Solved]




## 🛠️ NeoOS CLI Toolchain & Examples

NeoOS replaces complex multi-step commands with a suite of custom CLI tools located in `/usr/bin/`:

*   **`pkg`** – Simplified Package Manager Wrapper
    ```bash
    # Update repos and upgrade all packages
    pkg upgrade
    
    # Install specific packages without manual apt flags
    pkg install neofetch git
    ```

*   **`neos-update`** – System-wide Updater
    ```bash
    # Perform a full OS upgrade and cleanup orphan packages
    neos-update --full
    ```

*   **`neos-backup`** – Quick System Snapshot
    ```bash
    # Create a compressed backup of system configuration
    neos-backup --create /path/to/backup.tar.xz
    ```

*   **`neos-drivers`** – Hardware Driver Installer
    ```bash
    # Detect and install missing proprietary drivers (GPU/Wi-Fi)
    neos-drivers --autodetect
    ```

*   **`neos-installer`** – Calamares GUI Launcher
    ```bash
    # Launch the customized installer wizard directly from Live session
    neos-installer
    ```

---

## 📁 Repository Structure

```text
workspace/
├── config/              # APT repositories & modular package profiles
│   ├── packages.base
│   ├── packages.calamares
│   ├── packages.devel
│   ├── packages.internet
│   ├── packages.wayland
│   ├── packages.winetricks
│   └── sources.list
├── docs/                # Technical documentation
│   ├── ARCHITECTURE.md
│   └── BUILDING.md
├── neolibs/             # Core compatibility libraries & specs
│   ├── COMPAT.md
│   ├── README.md
│   └── neolibs
├── overlay/             # Rootfs filesystem overlay
│   ├── etc/calamares/   # Calamares installer configurations
│   └── usr/
│       ├── bin/         # Custom Neoos CLI commands & tools
│       └── share/calamares/branding/neoos/ # Custom UI branding & slides
├── proot-distro/        # Mobile/Termux integration script
│   └── neoos.sh
├── scripts/             # Build system automation scripts
│   ├── apply-overlay.sh
│   ├── build-iso.sh
│   ├── build-proot.sh
│   ├── build-rootfs.sh
│   └── setup-iso.sh
├── tests/               # Automated testing scripts
│   └── test-neolibs.sh
├── Makefile             # Main execution makefile
├── build.sh             # Master build launcher script
└── README.md
```
---

## 📁 Project Structure

```text
workspace/
├── config/             # APT repository source lists & package group manifests
│   ├── packages.base        # Minimal core system packages
│   ├── packages.calamares   # GUI installer dependencies
│   ├── packages.wayland     # Wayland display server & compositor packages
│   └── sources.list         # Upstream Debian mirror repositories
├── docs/               # Technical documentation & architectural design
│   ├── ARCHITECTURE.md      # In-depth system design & overlay mechanics
│   └── BUILDING.md          # Compilation guidelines
├── neolibs/            # Core compatibility libraries & specs
├── overlay/            # Rootfs filesystem overrides merged during build
│   ├── etc/calamares/       # Customized installer branding & partitioning rules
│   └── usr/
│       ├── bin/             # Custom NeoOS CLI tool binaries (`neos-*`)
│       └── share/           # Custom branding icons, logos, and QML slides
├── proot-distro/       # Mobile environment integration
│   └── neoos.sh             # Termux / proot-distro script for Android deployment
├── scripts/            # Automated build pipelines
│   ├── build-rootfs.sh      # Downloads & bootstraps Debian base
│   ├── apply-overlay.sh     # Inject custom configs & binaries into rootfs
│   ├── setup-iso.sh        # Prepares GRUB bootloader & Live environment
│   └── build-iso.sh        # Compresses rootfs into SquashFS and builds bootable ISO
├── tests/              # System validation & regression tests
├── Makefile            # Build shortcut commands
└── build.sh            # Master entry-point build launcher
```
NOTE:You can freely run this on WSL(Windows subsystem for linux) for Windows-only devices like me)
🚀 Step-by-Step Build & Installation
​1. Clone the Repository:
git clone [https://github.com/youssefx1x/NeoOS--.git](https://github.com/youssefx1x/NeoOS--.git)
cd NeoOS--


2. Install Host Dependencies
​Building NeoOS requires host tools to bootstrap Debian and generate bootable ISOs:
sudo apt update
sudo apt install -y debootstrap squashfs-tools xorriso grub-pc-bin grub-efi mtools make qemu-system-x86


3. Grant Execution Permissions
chmod +x build.sh scripts/*.sh overlay/usr/bin/*


(FIRST: MAKE SURE THAT THE TERMINAL READS THE FILES. BECAUSE SOME PEOPLE TELLS ME THE ERROR THAT HAPPENS WHEN THE TERMINAL NOT READ THE FILES / THE REPO)
4. Build the OS
• To Build the Bootable Live ISO (for PC):
sudo ./build.sh


Output: The generated ISO will be placed in build/neoos-live.iso


sudo ./scripts/build-proot.sh
:
Output: Generates build/neoos-rootfs.tar.xz.


🧪 Testing the ISO in QEMU
​You can test your freshly compiled ISO inside a QEMU virtual machine without leaving your terminal:
qemu-system-x86_64 \
  -enable-kvm \
  -m 2G \
  -smp 2 \
  -cdrom build/neoos-live.iso \
  -boot d




​📄 License
​Distributed under the GPL-3.0 License. See LICENSE for more information.




















