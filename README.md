# NeoOS--
A hybrid, lightweight Debian-based OS for Desktop and Mobile (Proot), featuring custom tools and seamless Windows app support
The setup
# 🌌 Neoos (Neolinux)

![Build Status](https://img.shields.io/badge/build-passing-brightgreen)
![Version](https://img.shields.io/badge/version-v1.0.0--beta-blue)
![License](https://img.shields.io/badge/license-GPLv3-orange)

**Neoos** is a highly modular, lightweight Debian-based hybrid operating system designed for desktop environments and embedded/mobile Proot containers. It features a custom toolchain, native Wayland support, pre-configured Windows app compatibility, and a fully branded Calamares installation wizard.

---

## ✨ System Features

*   **🧰 Custom Ecosystem (`neos-*`):** Complete set of custom maintenance utilities located in `/usr/bin/` including `neos-update`, `neos-backup`, `neos-drivers`, `neos-ports`, `neos-serve`, and the `pkg` wrapper.
*   **📱 Hybrid Target Support:** Built to compile both bootable Live ISO images for PCs and rootfs tarballs for Android/Termux environments (`proot-distro/neoos.sh`).
*   **🍷 Pre-configured Windows Compatibility:** Integrated out-of-the-box support for Windows applications using `neos-wine`, `neos-winetricks`, and `neos-winevm`.
*   **🎨 Custom Calamares Installer:** Includes customized installer configurations (`settings.conf`) and full branding assets (`branding.desc`, `show.qml`, SVG icons).
*   **⚡ Lightweight & Fast:** Optimized package selection across base, wayland, devel, and internet configurations, creating a full-featured system inside a ~2.23 GB ISO.

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
🛠️ Building Neoos
​Prerequisites
​Make sure you have the required build tools installed on your host system:
sudo apt update
sudo apt install debootstrap squashfs-tools xorriso grub-pc-bin grub-efi mtools make



Build Live ISO (PC)
​To compile the rootfs and wrap it into a bootable Live ISO:
sudo ./build.sh
# Or using make:
sudo make iso

Build Proot Tarball (Mobile/Termux)
​To generate the standalone neoos-rootfs.tar.xz for mobile container environments:
sudo ./scripts/build-proot.sh


🧪 Testing & Verification
​Run the neolibs test suite to ensure system library compatibility:
./tests/test-neolibs.sh









