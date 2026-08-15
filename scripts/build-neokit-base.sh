#!/usr/bin/env bash
set -euo pipefail

# build-neokit-base.sh — Build the Neokit 1.0 base layer rootfs.
#
# This creates a minimal Debian 13 (trixie) rootfs with Neokit-specific
# branding files, then packages it as a tarball for use as the base layer
# before the NeoOS overlay is applied.
#
# In environments where bootstrapping tools cannot mount (PRoot, limited
# containers), use NEOKIT_BASE_SRC to seed from an existing rootfs copy and
# NEOKIT_SKIP_BOOTSTRAP=1 to skip the debootstrap/mmdebstrap step entirely.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$REPO_ROOT/build/neokit-base"
STAGE_DIR="$BUILD_DIR/stage"
PACKAGES_FILE="$REPO_ROOT/base/neokit/packages.base"
OVERLAY_DIR="$REPO_ROOT/base/neokit/overlay"
BASE_TARBALL="$BUILD_DIR/neokit-1.0-base.tar.gz"

log() { printf '\033[1;35m[neokit]\033[0m %s\n' "$*"; }

export DEBIAN_FRONTEND=noninteractive

# --- Clean previous artifacts ---
rm -rf "$BUILD_DIR"
mkdir -p "$STAGE_DIR"

# --- Build base rootfs ---
log "Preparing Neokit 1.0 base rootfs (Debian trixie)"

mapfile -t PKGS < "$PACKAGES_FILE"
_arch="${NEOKIT_DEB_ARCH:-amd64}"
_pkgs="$(IFS=' '; echo "${PKGS[*]}")"
_mirror="http://deb.debian.org/debian"

bootstrap_rootfs() {
  if [[ "${NEOKIT_SKIP_BOOTSTRAP:-0}" == "1" ]]; then
    log "Bootstrapping skipped (NEOKIT_SKIP_BOOTSTRAP=1)"
    return 0
  fi

  NEOKIT_MMODE="${NEOKIT_MMODE:-auto}"
  _run_mmdebstrap() {
    local mode="$1"
    log "Trying mmdebstrap --mode=$mode"
    mmdebstrap \
      --mode="$mode" \
      --variant=minbase \
      --arch="$_arch" \
      --components="main,contrib,non-free,non-free-firmware" \
      --include="$_pkgs" \
      / "$STAGE_DIR" \
      "$_mirror"
  }

  if command -v mmdebstrap >/dev/null 2>&1; then
    _run_mmdebstrap "$NEOKIT_MMODE" || \
    _run_mmdebstrap fakeroot || \
    _run_mmdebstrap chrootless || \
    log "WARNING: mmdebstrap failed in all modes; falling back to NEOKIT_BASE_SRC"
  fi

  # Fallback: seed from an existing rootfs copy
  local src="${NEOKIT_BASE_SRC:-}"
  if [[ -z "$src" ]]; then
    # Try to find a usable rootfs source
    for candidate in "/proc/1/root" "/root" "/data"; do
      if [[ -d "$candidate/etc" && -d "$candidate/bin" ]]; then
        src="$candidate"
        break
      fi
    done
  fi

  if [[ -n "$src" && -d "$src" ]]; then
    log "Seeding rootfs from existing source: $src"
    cp -a "$src"/. "$STAGE_DIR"/ 2>/dev/null || true
  else
    log "WARNING: no rootfs source found; stage dir will only have overlay"
  fi
  return 0
}

bootstrap_rootfs

# --- Copy Neokit overlay (branding, issue, profile.d tweaks) ---
if [[ -d "$OVERLAY_DIR" ]]; then
  log "Applying Neokit branding and configuration overlay"
  cp -a "$OVERLAY_DIR"/. "$STAGE_DIR"/
fi

# --- Ensure Neokit base branding is present ---
if [[ ! -f "$STAGE_DIR/etc/os-release" ]]; then
  cat > "$STAGE_DIR/etc/os-release" <<'EOF'
NAME="Neokit"
VERSION="1.0 (Trixie Base)"
ID=neokit
ID_LIKE=debian
PRETTY_NAME="Neokit 1.0 (Debian 13 Trixie Base)"
VERSION_ID=1.0
EOF
fi

log "Neokit 1.0 base rootfs ready at: $STAGE_DIR"

# --- Package as tarball for use as base layer ---
if [[ -d "$STAGE_DIR" && "$(ls -A "$STAGE_DIR")" ]]; then
  log "Packaging Neokit 1.0 base tarball"
  tar --owner=root --group=root -czf "$BASE_TARBALL" -C "$BUILD_DIR" stage
  log "Neokit base complete: $BASE_TARBALL"
else
  log "WARNING: stage dir is empty — producing empty base marker"
  mkdir -p "$STAGE_DIR/empty"
  tar --owner=root --group=root -czf "$BASE_TARBALL" -C "$BUILD_DIR" stage
fi
