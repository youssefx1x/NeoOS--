#!/usr/bin/env bash
set -euo pipefail

# build-rootfs.sh — assemble the NeoOS root filesystem from Debian 13 (trixie)
# using mmdebstrap. Produces a plain directory tree and an optional tarball.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

NEOS_SUITE="${NEOS_SUITE:-trixie}"
NEOS_ARCH="${NEOS_ARCH:-amd64}"
NEOS_ROOTFS="${NEOS_ROOTFS:-$REPO_ROOT/build/rootfs}"
NEOS_MIRROR="${NEOS_MIRROR:-http://deb.debian.org/debian/}"
NEOS_SECURITY="${NEOS_SECURITY:-http://security.debian.org/debian-security}"
NEOS_KEYRING="${NEOS_KEYRING:-/usr/share/keyrings/debian-archive-keyring.gpg}"
NEOS_TARBALL="${NEOS_TARBALL:-$REPO_ROOT/build/neoos-rootfs.tar.xz}"
NEOKIT_BASE_TARBALL="${NEOKIT_BASE_TARBALL:-$REPO_ROOT/build/neokit-base/neokit-1.0-base.tar.gz}"
NEOS_COMPONENTS="${NEOS_COMPONENTS:-main,contrib,non-free-firmware}"
# Build variant: "full" (default) = core + XFCE GUI; "minimal" = core shell only
# (fast local builds, no GUI). Lets end users install NeoOS from a localhost
# workspace without pulling the large XFCE stack.
NEOS_VARIANT="${NEOS_VARIANT:-full}"
NEOS_INCLUDE_PKGS=("$REPO_ROOT/config/packages.base")
[[ "$NEOS_VARIANT" == "minimal" ]] || NEOS_INCLUDE_PKGS+=("$REPO_ROOT/config/packages.xfce")
[[ "$NEOS_ARCH" == "x86_64" || "$NEOS_ARCH" == "amd64" ]] && NEOS_INCLUDE_PKGS+=("$REPO_ROOT/config/packages.iso")
[[ "${NEOS_INCLUDE_INSTALLER:-0}" == "1" ]] && NEOS_INCLUDE_PKGS+=("$REPO_ROOT/config/packages.calamares")

# Map NeoOS arch aliases to Debian/Ubuntu arch names used by
# mmdebstrap/debootstrap. (e.g. aarch64 -> arm64, x86_64 -> amd64.)
case "$NEOS_ARCH" in aarch64) _deb_arch="arm64";; x86_64) _deb_arch="amd64";; *) _deb_arch="$NEOS_ARCH";; esac

log() { printf '\033[1;36m[neos-build]\033[0m %s\n' "$*"; }

usage() {
  cat <<EOF
Usage: $0 [--suite SUITE] [--arch ARCH] [--out DIR] [--tarball FILE]
       $0 --skip-install   # only produce tarball from existing rootfs

Builds the NeoOS root filesystem from Debian 13 (trixie).
EOF
}

SKIP_INSTALL=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --suite) NEOS_SUITE="$2"; shift 2;;
    --arch) NEOS_ARCH="$2"; shift 2;;
    --out) NEOS_ROOTFS="$2"; shift 2;;
    --tarball) NEOS_TARBALL="$2"; shift 2;;
    --skip-install) SKIP_INSTALL=1; shift;;
    -h|--help) usage; exit 0;;
    *) echo "unknown option: $1" >&2; usage; exit 1;;
  esac
done

require() {
  local tool="$1" pkg="${2:-$1}"
  command -v "$tool" >/dev/null 2>&1 || {
    echo "Missing required tool: $tool" >&2
    echo "Install it with:" >&2
    echo "  sudo apt install $pkg" >&2
    exit 1
  }
}
# Prefer mmdebstrap (single-stage, fast). On systems without it — e.g.
# Android/Termux, whose package repos do not ship mmdebstrap — fall back to
# debootstrap: a host-side `--foreign` first stage followed by a second
# stage run *inside* the rootfs (chroot if available, otherwise proot,
# which requires no root). Wherever mmdebstrap exists the build path is
# unchanged, so the main ISO/rootfs pipelines are unaffected.
HAVE_MMEDEBSTRAP=0
if command -v mmdebstrap >/dev/null 2>&1; then
  HAVE_MMEDEBSTRAP=1
else
  log "mmdebstrap not found; falling back to debootstrap"
  require debootstrap debootstrap
  # debootstrap's --foreign stage runs on the host (no target binaries are
  # executed); the second stage runs inside the rootfs and needs chroot or
  # proot to provide the target root view.
  command -v chroot >/dev/null 2>&1 || require proot proot-distro
fi

if [[ ! -f "$NEOS_KEYRING" ]]; then
  NEOS_KEYRING=""
fi

if [[ "$SKIP_INSTALL" -eq 0 ]]; then
  if [[ -f "$NEOKIT_BASE_TARBALL" ]]; then
    log "Using Neokit 1.0 base layer: $NEOKIT_BASE_TARBALL"
    rm -rf "$NEOS_ROOTFS"
    mkdir -p "$NEOS_ROOTFS"
    tar -C "$NEOS_ROOTFS" -xzf "$NEOKIT_BASE_TARBALL" --strip-components=1
    log "Neokit base layer extracted to $NEOS_ROOTFS"
  else
    log "Building rootfs"
    log "Bootstrapping NeoOS rootfs ($NEOS_ARCH / $NEOS_SUITE) -> $NEOS_ROOTFS"
    rm -rf "$NEOS_ROOTFS"
    mkdir -p "$NEOS_ROOTFS"

  keyring_args=()
  if [[ -n "$NEOS_KEYRING" ]]; then
    keyring_args=(--keyring "$NEOS_KEYRING")
  fi

  if (( HAVE_MMEDEBSTRAP )); then
    keyring_args=()
    if [[ -n "$NEOS_KEYRING" ]]; then
      keyring_args=(--keyring "$NEOS_KEYRING")
    fi
    apt_opts=()
    if [[ -z "$NEOS_KEYRING" ]]; then
      log "WARNING: no Debian keyring found on host; disabling apt signature verification for this build"
      apt_opts+=(--aptopt=-oAcquire::AllowInsecureRepositories=true)
      apt_opts+=(--aptopt=-oAcquire::AllowDowngradeToInsecureRepositories=true)
      apt_opts+=(--aptopt=-oAPT::Get::AllowUnauthenticated=true)
    fi
    mmdebstrap \
      --variant=minbase \
      --arch="$_deb_arch" \
      --components="$NEOS_COMPONENTS" \
      "${keyring_args[@]}" \
      "${apt_opts[@]}" \
      ${NEOS_QEMU:+--qemu "$NEOS_QEMU" --crossdeps} \
       --include="$(cat "${NEOS_INCLUDE_PKGS[@]}" 2>/dev/null | grep -v '^[[:space:]]*#' | tr '\n' ' ' | tr -s ' ' | sed 's/^ //; s/ $//')" \
      "$NEOS_SUITE" "$NEOS_ROOTFS"
  else
    # debootstrap fallback (Termux: mmdebstrap unavailable). The --foreign
    # first stage runs on the host and never executes target binaries.
    deboot_args=(--foreign --arch="$_deb_arch" --variant=minbase)
    if [[ -n "$NEOS_KEYRING" ]]; then
      deboot_args+=(--keyring="$NEOS_KEYRING")
    else
      log "WARNING: no Debian keyring found; proceeding without GPG signature verification"
      deboot_args+=(--no-check-gpg)
    fi
    # debootstrap --include expects a comma-separated list; all packages.base
    # entries live in `main`, which debootstrap fetches by default, so
    # --components is intentionally omitted (older debootstrap lacks it).
    deboot_inc="$(cat "${NEOS_INCLUDE_PKGS[@]}" 2>/dev/null | grep -v '^[[:space:]]*#' | tr '\n' ',' | sed 's/^[[:space:]]*,//; s/,$//; s/,,*/,/g')"
    if [[ -n "$deboot_inc" ]]; then
      deboot_args+=(--include="$deboot_inc")
    fi
    log "Running debootstrap first stage"
    debootstrap "${deboot_args[@]}" "$NEOS_SUITE" "$NEOS_ROOTFS" "$NEOS_MIRROR"

    log "Running debootstrap second stage inside rootfs"
    if command -v chroot >/dev/null 2>&1; then
      chroot "$NEOS_ROOTFS" /debootstrap/debootstrap --second-stage
    else
      proot -r "$NEOS_ROOTFS" /debootstrap/debootstrap --second-stage
    fi
    fi  # end mmdebstrap vs debootstrap
  fi  # end neokit base vs fresh bootstrap
fi  # end SKIP_INSTALL

# --- Ensure rootfs exists (extract from Neokit base if --skip-install) ---
if [[ ! -d "$NEOS_ROOTFS" || -z "$(ls -A "$NEOS_ROOTFS" 2>/dev/null)" ]]; then
  if [[ -f "$NEOKIT_BASE_TARBALL" ]]; then
    log "Extracting Neokit base layer into rootfs (Neokit base was not pre-installed)"
    mkdir -p "$NEOS_ROOTFS"
    tar -C "$NEOS_ROOTFS" -xzf "$NEOKIT_BASE_TARBALL" --strip-components=1
  else
    log "ERROR: rootfs not found at $NEOS_ROOTFS and no Neokit base tarball available"
    exit 1
  fi
fi

log "Applying NeoOS configuration overlay"
bash "$REPO_ROOT/scripts/apply-overlay.sh" "$NEOS_ROOTFS"

if [[ "$NEOS_TARBALL" != "none" ]]; then
  log "Creating tarball: $NEOS_TARBALL"
  mkdir -p "$(dirname "$NEOS_TARBALL")"
  tar -C "$NEOS_ROOTFS" -cJf "$NEOS_TARBALL" .
fi

log "Done. Rootfs at $NEOS_ROOTFS, tarball at $NEOS_TARBALL"
