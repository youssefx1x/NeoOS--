#!/usr/bin/env bash
# install-neeos.sh — one-command NeoOS install into Termux (or any Linux)
# via proot-distro.
#
# Downloads the NeoOS proot rootfs tarball for the current architecture from
# the GitHub Release (default tag 1.1.1) and installs it, then drops you in.
#
#   curl -fsSL https://raw.githubusercontent.com/youssefx1x/NeoOS--/main/scripts/install-neeos.sh | bash
#
# Environment overrides:
#   NEOS_REPO        GitHub repo (default youssefx1x/NeoOS--)
#   NEOS_RELEASE     exact tag to fetch (default: 1.1.1)
#   NEOS_INSTALL_TARBALL  local tarball path to use instead of downloading
#   NEOS_NAME        container name (default neoos)
#   NEOS_NOLOGIN     1 = install only, do not start login shell
set -euo pipefail

NEOS_REPO="${NEOS_REPO:-youssefx1x/NeoOS--}"
NEOS_NAME="${NEOS_NAME:-neoos}"

arch="$(uname -m)"
case "$arch" in
  aarch64|arm64)  asset="neoos-proot-aarch64.tar.xz";;
  x86_64|amd64)   asset="neoos-proot-amd64.tar.xz";;
  *) echo "install-neeos: unsupported architecture: $arch" >&2; exit 1;;
esac

TARBALL="${NEOS_INSTALL_TARBALL:-}"
# Support an HTTP(S) mirror/URL instead of a GitHub Release (no-GitHub installs).
if [[ "$TARBALL" == http://* || "$TARBALL" == https://* ]]; then
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT
  local_tarball="$tmpdir/$asset"
  echo "install-neeos: downloading NeoOS from $TARBALL"
  curl -fL "$TARBALL" -o "$local_tarball"
  TARBALL="$local_tarball"
fi
if [[ -n "$TARBALL" && ! -f "$TARBALL" ]]; then
  echo "install-neeos: local tarball not found: $TARBALL" >&2
  exit 1
fi

if [[ -z "$TARBALL" && -z "${NEOS_INSTALL_TARBALL:-}" ]]; then
  NEOS_RELEASE="${NEOS_RELEASE:-1.1.1}"
  url="https://github.com/$NEOS_REPO/releases/download/$NEOS_RELEASE/$asset"
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT
  TARBALL="$tmpdir/$asset"
  echo "install-neeos: downloading $asset from $url"
  curl -fL "$url" -o "$TARBALL"
fi

if ! command -v proot-distro >/dev/null 2>&1; then
  echo "install-neeos: proot-distro not found. Install it:" >&2
  echo "  pkg install proot-distro     (Termux)" >&2
  echo "  sudo apt install proot-distro  (other Linux)" >&2
  exit 1
fi

echo "install-neeos: installing NeoOS as '$NEOS_NAME' from $TARBALL"
if proot-distro install "$TARBALL" --name "$NEOS_NAME"; then
  echo
  echo "NeoOS installed. Files: ~/.neos-distro/$NEOS_NAME"
  echo "Run:  proot-distro login $NEOS_NAME"
  echo "      proot-distro run   $NEOS_NAME   # one-off command"
else
  echo "install-neeos: proot-distro install failed" >&2
  exit 1
fi

if [[ -z "${NEOS_NOLOGIN:-}" ]]; then
  if [[ -t 0 ]]; then
    echo "install-neeos: starting NeoOS login shell..."
    proot-distro login "$NEOS_NAME"
  else
    echo "install-neeos: (non-interactive) run 'proot-distro login $NEOS_NAME' to start NeoOS."
  fi
fi
