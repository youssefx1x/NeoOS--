#!/usr/bin/env bash
# Test suite for NeoLIBs. Run from repo root: bash tests/test-neolibs.sh

set -euo pipefail

NEOLIBS="$PWD/neolibs/neolibs"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

export NEOLIBS_ROOT="$WORK/opt/neolibs"
export NEOLIBS_REGISTRY="$WORK/var/neolibs"

pass=0; fail=0
ok()   { printf '  ok   %s\n' "$1"; pass=$((pass+1)); }
bad()  { printf '  FAIL %s\n' "$1"; fail=$((fail+1)); }

check() { # check <desc> <expected> <actual>
  if [[ "$3" == "$2" ]]; then ok "$1"; else bad "$1 (expected '$2', got '$3')"; fi
}

mkdir -p "$WORK/v1" "$WORK/v2"
printf 'libz 1.2.13\n' > "$WORK/v1/libz.so.1.2.13"
printf 'libz 1.3.1\n'  > "$WORK/v2/libz.so.1.3.1"

echo "== install =="
"$NEOLIBS" install zlib@1.2.13 --from "$WORK/v1/libz.so.1.2.13" >/dev/null
"$NEOLIBS" install zlib@1.3.1  --from "$WORK/v2/libz.so.1.3.1"  >/dev/null
[[ -f "$WORK/opt/neolibs/store/zlib/1.2.13/lib/libz.so.1.2.13" ]] && ok "v1 stored" || bad "v1 stored"
[[ -f "$WORK/opt/neolibs/store/zlib/1.3.1/lib/libz.so.1.3.1" ]]   && ok "v2 stored" || bad "v2 stored"

echo "== list/current =="
check "list shows v1" "1.2.13" "$(grep -o '1.2.13' "$WORK/var/neolibs/zlib.reg")"
"$NEOLIBS" use zlib@1.2.13 >/dev/null
check "current v1" "1.2.13" "$("$NEOLIBS" current zlib)"
"$NEOLIBS" use zlib@1.3.1 >/dev/null
check "current v2" "1.3.1" "$("$NEOLIBS" current zlib)"
check "active marker file" "1.3.1" "$(cat "$WORK/opt/neolibs/active/zlib/.active-version")"

echo "== run (per-command pin) =="
out="$("$NEOLIBS" run zlib@1.2.13 -- sh -c 'printf "libz 1.2.13\n"')"
check "run v1 output" "libz 1.2.13" "$out"

echo "== remove =="
"$NEOLIBS" remove zlib@1.2.13 >/dev/null
[[ ! -d "$WORK/opt/neolibs/store/zlib/1.2.13" ]] && ok "v1 removed" || bad "v1 removed"
check "v1 deregistered" "0" "$(grep -c '1.2.13' "$WORK/var/neolibs/zlib.reg" || true)"

echo "== invalid input =="
if "$NEOLIBS" install 'bad-spec' --from "$WORK/v1/libz.so.1.2.13" >/dev/null 2>&1; then
  bad "invalid spec rejected"
else
  ok "invalid spec rejected"
fi

echo
echo "NeoLIBs: $pass passed, $fail failed"
[[ $fail -eq 0 ]]
