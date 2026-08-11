#!/usr/bin/env bash
# libneocore.sh — NeoCore: the core system layer for NeoOS.
#
# Sourced by the `neo` dispatcher (and optionally by neos-* tools) to provide a
# consistent System API:
#   NeoCore
#   ├── System API        neocore_status / neocore_info
#   ├── Service Manager   neocore_services
#   ├── Configuration Mgr neocore_config_*
#   ├── Hardware Abstraction neocore_hw
#   ├── Process Manager   neocore_procs
#   ├── Event Bus         neocore_emit / neocore_events
#   └── Capability Manager neocore_has_cap
#
# It is safe to source: no side effects, no `set -e` imposed on the caller.
# The stable API surface is versioned via NEOAPI_* (see libneo-core C headers).

# --- once guard ---------------------------------------------------------------
if [[ -n "${NEOCORE_LOADED:-}" ]]; then
  if [[ "${BASH_SOURCE[0]:-$0}" == "${0:-}" ]]; then exit 0; else return 0; fi
fi
NEOCORE_LOADED=1

# --- version / API ------------------------------------------------------------
NEOCORE_VERSION="1.2.0"
NEOAPI_VERSION_MAJOR=1
NEOAPI_VERSION_MINOR=2
NEOAPI_VERSION_MICRO=0
NEOAPI_VERSION="${NEOAPI_VERSION_MAJOR}.${NEOAPI_VERSION_MINOR}.${NEOAPI_VERSION_MICRO}"
NEOCORE_LIB="/usr/lib/neos/libneocore.sh"
NEOCORE_CONF="/etc/neos/neocore.conf"
NEOCORE_STATE_DIR="${NEOCORE_STATE_DIR:-/var/lib/neos}"
NEOCORE_EVENTS_LOG="${NEOCORE_STATE_DIR}/events.log"
NEOCORE_DIAG_CACHE="${NEOCORE_STATE_DIR}/last-diag.cache"

# --- colors (NO_COLOR aware) ---------------------------------------------------
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  __nc=()  # empty array sentinel
  _nc() { printf '\033[1;36m'; }
  _gc() { printf '\033[1;32m'; }
  _yc() { printf '\033[1;33m'; }
  _rc() { printf '\033[1;31m'; }
  _bc() { printf '\033[1;34m'; }
  _ec() { printf '\033[0m'; }
else
  _nc() { :; }
  _gc() { :; }
  _yc() { :; }
  _rc() { :; }
  _bc() { :; }
  _ec() { :; }
fi

log()   { printf '%s[neocore]%s %s\n' "$(_nc)" "$(_ec)" "$*"; }
good()  { printf '%s[ok]%s   %s\n' "$(_gc)" "$(_ec)" "$*"; }
warn()  { printf '%s[warn]%s %s\n' "$(_yc)" "$(_ec)" "$*"; }
err()   { printf '%s[err]%s  %s\n' >&2 "$(_rc)" "$(_ec)" "$*"; }

# --- capability manager -------------------------------------------------------
# neocore_has_cap <cap> -> 0 if available. Caps: root, online, gui, apt, systemd, net
neocore_has_cap() {
  case "$1" in
    root)   [[ $EUID -eq 0 ]];;
    apt)    command -v apt-get >/dev/null 2>&1;;
    systemd) [[ -d /run/systemd/system ]] || { [[ -e /run/systemd/system ]] && false; } ;;
    gui)    { [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]; };;
    online) getent hosts deb.debian.org >/dev/null 2>&1;;
    net)    command -v ip >/dev/null 2>&1 || command -v ifconfig >/dev/null 2>&1;;
    *)      return 1;;
  esac
}

# --- configuration manager ----------------------------------------------------
# Simple key=value store: /etc/neos/neocore.conf  (lines: key="value" or key=value)
neocore_config_get() {
  local key="$1" default="${2:-}" v
  v="$(grep -E "^[[:space:]]*${key}[[:space:]]*=" "$NEOCORE_CONF" 2>/dev/null | tail -n1 | sed -E 's/^[^=]+=[[:space:]]*//; s/^"(.*)"$/\1/' | tr -d '"' || true)"
  if [[ -n "$v" ]]; then printf '%s' "$v"; return 0; fi
  printf '%s' "$default"; [[ -n "$default" ]] || return 1
}

# --- event bus ----------------------------------------------------------------
# neocore_emit <event> <payload> — append a single-line record.
neocore_emit() {
  local event="$1" payload="${2:-}"
  mkdir -p "$(dirname "$NEOCORE_EVENTS_LOG")" 2>/dev/null || return 0
  printf '%s\tneo:%s\t%s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$event" "$payload" \
    >> "$NEOCORE_EVENTS_LOG" 2>/dev/null || true
  log "event: $event $payload"
}

neocore_events() {
  local n="${1:-20}"
  if [[ -r "$NEOCORE_EVENTS_LOG" ]]; then
    tail -n "$n" "$NEOCORE_EVENTS_LOG"
  else
    echo "no events recorded"
  fi
}

# --- system API ---------------------------------------------------------------
# Small numeric field extractor: neocore_num_field <field-id>
_neofield() { awk -v want="$1" '{print $1}' </proc/loadavg 2>/dev/null; }

neocore_status() {
  local up
  up="$(awk '{print int($1)}' /proc/uptime 2>/dev/null || echo 0)"
  printf 'NeoCore %s (NeoAPI %s)\n' "$NEOCORE_VERSION" "$NEOAPI_VERSION"
  printf 'uptime      : %dd %02dh %02dm\n' $((up/86400)) $(((up%86400)/3600)) $(((up%3600)/60))
  printf 'load        : %s\n' "$(tr '\0' ' ' </proc/loadavg 2>/dev/null | cut -d' ' -f1-3)"
  local mem
  mem="$(awk '/^MemTotal:/{t=$2}/^MemAvailable:/{a=$2}END{printf "used %d / total %d MB", (t-a)/1024, t/1024}' /proc/meminfo 2>/dev/null)"
  printf 'memory      : %s\n' "${mem:-n/a}"
  local disk
  disk="$(df -hT / 2>/dev/null | awk 'NR==2{printf "%s on %s (%s used, %s free)", $1,$7,$6,$5}')"
  printf 'root disk   : %s\n' "${disk:-n/a}"
  local iface
  iface="$(ip route 2>/dev/null | awk '/default/{print $5; exit}')"
  printf 'net default : %s\n' "${iface:-none}"
  printf 'users logged : %s\n' "$(who 2>/dev/null | wc -l)"
  printf 'capabilities: root=%s apt=%s systemd=%s online=%s\n' \
    "$(neocore_has_cap root     && echo yes || echo no)" \
    "$(neocore_has_cap apt      && echo yes || echo no)" \
    "$(neocore_has_cap systemd  && echo yes || echo no)" \
    "$(neocore_has_cap online   && echo yes || echo no)"
}

neocore_info() {
  local osrel="" kver="" arch=""
  osrel="$(grep -E '^(PRETTY_NAME|VERSION_ID)=' /etc/os-release 2>/dev/null | tr '\n' ' ')"
  kver="$(uname -r 2>/dev/null)"
  arch="$(uname -m 2>/dev/null)"
  printf 'NeoAPI      : %s\n' "$NEOAPI_VERSION"
  printf 'NeoOS       : %s\n' "${osrel:-NeoOS}"
  printf 'kernel      : %s\n' "$kver"
  printf 'arch        : %s\n' "$arch"
  printf 'hostname    : %s\n' "$(hostname 2>/dev/null)"
  printf 'libneocore  : %s\n' "$NEOCORE_LIB"
  local t
  for t in git gcc make python3 node flatpak; do
    printf '%-9s : %s\n' "$t" "$({ command -v "$t"; } 2>/dev/null || echo 'not found')"
  done
}

neocore_services() {
  echo "service state (important units):"
  local units=(
    "networking.service NetworkManager.service systemd-networkd.service"
    "ssh.service sshd.service"
    "lightdm.service display-manager.service"
    "apt-daily.service apt-daily-upgrade.service"
    "docker.service containerd.service"
  )
  if neocore_has_cap systemd; then
    local u
    for u in "${units[@]}"; do
      local first=1
      local _u
      for _u in $u; do
        [[ $first -eq 0 ]] || first=0
        local state
        state="$(systemctl is-active "$_u" 2>/dev/null || echo inactive)"
        printf '  %-32s %s\n' "$_u" "$state"
      done
    done
    echo "failed units:"
    systemctl --failed --no-pager --no-legend 2>/dev/null | awk '{print "  "$1"  "$2}' || true
  else
    warn "systemd not available; showing init.d/sysv status only"
    service --status-all 2>/dev/null | head -n 40 || true
  fi
}

neocore_hw() {
  local cpu model
  cpu="$(awk -F': ' '/^model name/{print $2; exit}' /proc/cpuinfo 2>/dev/null)"
  model="$(awk -F': ' '/^model/{print $2; exit}' /proc/cpuinfo 2>/dev/null)"
  printf 'cpu  : %s (%s)\n' "${cpu:-unknown}" "${model:-unknown}"
  printf 'cores: %s thread(s), %s cpu(s)\n' "$(nproc 2>/dev/null || echo 1)" "$(nproc 2>/dev/null || echo 1)"
  if [[ -d /sys/class/drm ]]; then
    printf 'gpu  : %s\n' "$({ readlink /sys/class/drm/card0/device/driver 2>/dev/null | xargs basename 2>/dev/null; } | head -1)"
  fi
  printf 'mem  : %s total\n' "$(awk '/^MemTotal:/{printf "%.1f GB", $2/1024/1024}' /proc/meminfo 2>/dev/null)"
  printf 'net  : %s\n' "$(ip -o link 2>/dev/null | awk -F': ' '{print $2}' | paste -sd, -)"
  if command -v neos-uranium >/dev/null 2>&1; then
    printf 'note : run neos-uranium for driver install/suggest\n'
  else
    printf 'note : neos-uranium not installed\n'
  fi
}

neocore_procs() {
  local n="${1:-10}"
  echo "top $n processes by CPU:"
  ps -eo pid,ppid,user,%cpu,%mem,rss,comm --sort=-%cpu 2>/dev/null | head -n $((n+1)) \
    | awk 'NR==1{print} NR>1{printf "  %-7s %-8s %-7s %5s%% %5s%%  %s\n",$1,$3,$4,$5,$6,$7}'
  echo
  echo "top $n processes by memory:"
  ps -eo pid,user,%mem,rss,comm --sort=-%mem 2>/dev/null | head -n $((n+1)) \
    | awk 'NR==1{print} NR>1{printf "  %-7s %-8s %5s%% %6s KB  %s\n",$1,$2,$3,$4,$5}'
}

# --- diagnostic battery -------------------------------------------------------
neocore_diagnose() {
  local pass=0 fail=0
  local outdir
  outdir="$(dirname "$NEOCORE_DIAG_CACHE")"
  mkdir -p "$outdir" 2>/dev/null || true
  : > "$NEOCORE_DIAG_CACHE"

  _check() {
    local name="$1"; shift
    if "$@" 2>/dev/null; then
      good "$name"
      printf '%s OK\n' "$name" >> "$NEOCORE_DIAG_CACHE" 2>/dev/null || true
      pass=$((pass+1))
    else
      err "$name"
      printf '%s FAIL\n' "$name" >> "$NEOCORE_DIAG_CACHE" 2>/dev/null || true
      fail=$((fail+1))
    fi
  }

  _check "apt cache updated"      apt-cache policy
  _check "dpkg audit clean"      sh -c 'dpkg --audit 2>&1 | grep -q . && exit 1 || exit 0'
  _check "root disk free>5%"     sh -c 'df / | awk "NR==2{p=\$5+0}END{exit !(p<95)}"'
  _check "network online"        neocore_has_cap online
  _check "systemd running"       neocore_has_cap systemd
  _check "time in sync"          sh -c '[[ -e /run/systemd/timesync ]] || timedatectl show -p NTPSynchronized 2>/dev/null | grep -qi yes'
  _check "kernel modules dir"    test -d /lib/modules/"$(uname -r 2>/dev/null)"

  echo
  printf 'summary: %d passed, %d failed\n' "$pass" "$fail"
  neocore_emit "diagnose" "pass=$pass fail=$fail"
  [[ $fail -eq 0 ]]
}

# --- repair -------------------------------------------------------------------
neocore_repair() {
  log "NeoCore repair: fixing broken packages and stalled services"
  if neocore_has_cap apt; then
    if ! dpkg --configure -a 2>&1 | tail -3; then warn "dpkg --configure -a reported issues"; fi
    apt-get --fix-broken install -y 2>&1 | tail -3 || warn "apt fix-broken had errors"
    apt-get autoremove -y 2>&1 | tail -3 || true
    apt-get clean 2>/dev/null || true
  else
    warn "apt not available; skipping package repair"
  fi
  if neocore_has_cap systemd; then
    systemctl daemon-reload 2>/dev/null || true
    local failed
    failed="$(systemctl --failed --no-pager --no-legend 2>/dev/null | awk '{print $1}')"
    if [[ -n "$failed" ]]; then
      local u
      for u in $failed; do systemctl restart "$u" 2>/dev/null && log "restarted $u" || warn "could not restart $u"; done
    else
      good "no failed units"
    fi
    journalctl --vacuum-time=7d --vacuum-size=100M 2>/dev/null | tail -1 || true
  fi
  neocore_emit "repair" "complete"
  good "repair pass complete"
}

# --- public dispatcher used by `neo system <sub>` -----------------------------
neocore_main() {
  local sub="${1:-help}"
  shift || true
  case "$sub" in
    status)   neocore_status "$@";;
    info)     neocore_info "$@";;
    services) neocore_services "$@";;
    diagnose) neocore_diagnose "$@";;
    repair)   neocore_repair "$@";;
    hw)       neocore_hw "$@";;
    procs)    neocore_procs "$@";;
    config)   neocore_config_get "$@";;
    events)   neocore_events "$@";;
    version|api) printf 'NeoCore %s / NeoAPI %s\n' "$NEOCORE_VERSION" "$NEOAPI_VERSION";;
    help|-h|--help)
      cat <<EOF
NeoCore — NeoOS core system layer (NeoAPI ${NEOAPI_VERSION})

Usage: neo system <command> [args]
  status    Snapshot: uptime, load, memory, disk, net, capabilities
  info      OS/kernel/arch/hostname + tool availability
  services  Important systemd units and any failed units
  diagnose  Run health checks (apt, dpkg, disk, net, systemd, time, modules)
  repair    dpkg --fix-broken, apt autoremove/clean, restart failed units, journal vacuum
  hw        CPU/GPU/memory/network summary
  procs [n] Top n processes by CPU then memory (default 10)
  config <key> [default]   Read /etc/neos/neocore.conf
  events [n]              Last n event-bus records
  version                 Show NeoCore/NeoAPI versions
EOF
      ;;
    *) err "unknown neocore command: $sub"; neocore_main help; return 1;;
  esac
}

# Export nothing globally except what callers may want to read.
export NEOCORE_VERSION NEOAPI_VERSION NEOCORE_CONF
