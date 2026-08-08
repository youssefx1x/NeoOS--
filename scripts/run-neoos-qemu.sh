#!/usr/bin/env bash
# run-neoos-qemu.sh — boot the NeoOS arm64 image under QEMU from Android Termux.
set -euo pipefail

usage() {
  cat <<'EOF'
usage: run-neoos-qemu.sh [options] [image]

  image        NeoOS disk image to boot. (default: ./neoos.img)

options:
  -m MEM       Guest RAM in MB (default: 2048)
  -c CPU       QEMU CPU model (default: cortex-a57)
  -d MODE      display: gtk | sdl | none (default: auto — gtk if $DISPLAY else serial console)
  --vnc PORT   expose VNC on port (e.g. 5900); no GTK window on host
  --spice PORT expose Spice on port (e.g. 5930); no GTK window on host
  -n           disable networking
  -f PORT      forward host:PORT -> guest ssh (default: 2222)
  -A           enable emulated audio (best-effort on Android QEMU)
  -h, --help   show this help
EOF
}

MEM=2048
CPU=cortex-a57
DISP=auto
VNC=""
SPICE=""
NET=1
AUDIO=0
SSH_FWD=2222
IMG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -m) MEM="$2"; shift 2 ;;
    -c) CPU="$2"; shift 2 ;;
    -d) DISP="$2"; shift 2 ;;
    --vnc) VNC="$2"; shift 2 ;;
    --spice) SPICE="$2"; shift 2 ;;
    -n) NET=0; shift ;;
    -f) SSH_FWD="$2"; shift 2 ;;
    -A) AUDIO=1; shift ;;
    -h|--help) usage; exit 0 ;;
    --*) echo "unknown option: $1" >&2; usage; exit 2 ;;
    -*) echo "unknown option: $1" >&2; usage; exit 2 ;;
    *)  if [[ -z "$IMG" ]]; then IMG="$1"; else echo "unexpected: $1" >&2; exit 2; fi; shift ;;
  esac
done

IMG="${IMG:-neoos.img}"

Q="qemu-system-aarch64"
if ! command -v "$Q" >/dev/null 2>&1; then
  echo "qemu-system-aarch64 not found (install: pkg install qemu-system-aarch64-headless)" >&2
  exit 1
fi
if [[ ! -f "$IMG" ]]; then
  echo "image not found: $IMG" >&2
  exit 1
fi

args=(-machine "virt,accel=tcg" -cpu "$CPU" -m "$MEM" -no-reboot)

case "$IMG" in
  *.qcow2|*.qcow) args+=(-drive "file=$IMG,format=qcow2,if=virtio") ;;
  *)               args+=(-drive "file=$IMG,format=raw,if=virtio") ;;
esac

if [[ -n "$VNC" ]]; then
  args+=(-vnc ":${VNC#-}" -serial "mon:stdio")
elif [[ -n "$SPICE" ]]; then
  args+=(-spice "port=${SPICE#-},disable-ticketing=on" -serial "mon:stdio")
elif [[ "$DISP" == "none" || ( "$DISP" == "auto" && -z "${DISPLAY:-}" ) ]]; then
  args+=(-display none -nographic -serial "mon:stdio")
elif [[ "$DISP" == "sdl" ]]; then
  args+=(-display sdl)
else
  args+=(-display gtk)
fi

if [[ $NET -eq 1 ]]; then
  args+=(-netdev "user,id=n0,hostfwd=tcp::${SSH_FWD}-:22" -device "virtio-net-device,netdev=n0")
fi

if [[ $AUDIO -eq 1 ]]; then
  args+=(-audiodev "pa,id=s0" -device "intel-hda" -device "hda-duplex")
fi

args+=(-virtfs "local,path=/sdcard,mount_tag=sdcard,security_model=mapped-file")
args+=(-virtfs "local,path=$HOME,mount_tag=home,security_model=mapped-file")

echo "running: $Q ${args[*]}"
exec "$Q" "${args[@]}"
