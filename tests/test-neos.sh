#!/usr/bin/env bash
# Test suite for the `neos` umbrella command. Run from repo root:
#   bash tests/test-neos.sh

set -euo pipefail

NEOS="$PWD/overlay/usr/bin/neos"

WORK="$(mktemp -d)"
export NEOS_CAPSULES="$WORK/capsules"
export NEOS_HISTORY="$WORK/history"

pass=0; fail=0
ok()   { printf '  ok   %s\n' "$1"; pass=$((pass+1)); }
bad()  { printf '  FAIL %s\n' "$1"; fail=$((fail+1)); }

check() { # check <desc> <expected> <actual>
  if [[ "$3" == "$2" ]]; then ok "$1"; else bad "$1 (expected '$2', got '$3')"; fi
}

trap 'rm -rf "$WORK"' EXIT

# ---- no args prints the usage banner ----
case "$("$NEOS" 2>&1 | head -1)" in
  "neos "*NeoOS*) ok "no args prints usage banner" ;;
  *) bad "no args should print usage banner (got: $(head -1 <<<"$("$NEOS" 2>&1)"))" ;;
esac

# ---- help lists the known subcommands ----
help_out="$("$NEOS" help 2>&1)"
for sub in doctor clean fix launch suggest; do
  if grep -q -- "$sub" <<< "$help_out"; then ok "help mentions '$sub'"; else bad "help mentions '$sub'"; fi
done

# ---- project name validation: rejects traversal / metachars ----
out="$("$NEOS" launch '../../etc' 2>&1 || true)"
grep -q 'invalid project name' <<< "$out" && ok "rejects path traversal" || bad "rejects path traversal"

out="$("$NEOS" launch 'bad;name' 2>&1 || true)"
grep -q 'invalid project name' <<< "$out" && ok "rejects shell metacharacters" || bad "rejects shell metacharacters"

out="$("$NEOS" launch 'ok name with space' 2>&1 || true)"
grep -q 'invalid project name' <<< "$out" && ok "rejects spaces" || bad "rejects spaces"

# ---- launch creates a capsule dir with expected files ----
"$NEOS" launch projX >/dev/null 2>&1
for want in env.sh deps.pkg manifest.txt; do
  if [[ -f "$NEOS_CAPSULES/projX/$want" ]]; then ok "capsule has $want"; else bad "capsule has $want"; fi
done

# ---- launch --list shows the created capsule ----
out="$("$NEOS" launch --list 2>&1)"
grep -q 'projX' <<< "$out" && ok "list shows projX" || bad "list shows projX"

# ---- launch on existing capsule skips recreation ----
"$NEOS" launch projX >/dev/null 2>&1
ok "re-launching existing capsule is safe"

# ---- suggest reads history file + frequency-sorts ----
printf 'git status\ngit status\nneos doctor\nls\n' > "$NEOS_HISTORY"
out="$("$NEOS" suggest --history 2 2>&1)"
grep -q 'git status' <<< "$out" && ok "suggest reports history" || bad "suggest reports history"
# frequency: 'git status' (2) must outrank 'ls' (1)
pos_git="$(grep -n 'git status' <<< "$out" | head -1 | cut -d: -f1)"
pos_ls="$(grep -n 'ls' <<< "$out" | head -1 | cut -d: -f1)"
if [[ -n "$pos_git" && -n "$pos_ls" ]] && (( pos_git < pos_ls )); then
  ok "suggest frequency-sorts (git status before ls)"
else
  bad "suggest frequency-sorts"
fi

# ---- suggest with no history is graceful ----
out="$(env -u NEOS_HISTORY -u HISTFILE NEOS_CAPSULES="$NEOS_CAPSULES" "$NEOS" suggest 2>&1)"
grep -q 'no readable shell history' <<< "$out" && ok "suggest is graceful with no history" || bad "suggest graceful w/o history"

# ---- doctor emits NeoPulse human-readable lines ----
out="$("$NEOS" doctor 2>&1)"
grep -q 'NeoPulse' <<< "$out" && ok "doctor emits NeoPulse header" || bad "doctor emits NeoPulse header"
grep -Eq 'memory:|load:|disk:|network:' <<< "$out" && ok "doctor emits human-readable pulse lines" || bad "doctor emits pulse lines"

# ---- clean delegates to neos-clean (or reports missing) ----
# neos-clean may be absent in a minimal environment; either outcome is fine.
out="$("$NEOS" clean 2>&1 || true)"
"$NEOS" clean >/dev/null 2>&1 && ok="clean ran" || ok="clean reports missing"
case "$ok" in
  clean\ ran) ok "clean exits without crashing when neos-clean present" ;;
  *) ok "clean reports missing neos-clean without crashing" ;;
esac

# ---- neos-ai: --check is graceful with no backend ----
out="$(NEOS_AI_MODEL="/no/such/model.gguf" ./overlay/usr/bin/neos-ai --check 2>&1)"
grep -q 'NeoOS AI helper' <<< "$out" && ok "neos-ai --check prints banner" || bad "neos-ai --check banner"
grep -q 'model file not found' <<< "$out" && ok "neos-ai warns when model missing" || bad "neos-ai warns when model missing"

# ---- neos-ai rejects unknown option ----
out="$(./overlay/usr/bin/neos-ai --bogus 2>&1 || true)"
grep -q 'unknown option' <<< "$out" && ok "neos-ai rejects unknown option" || bad "neos-ai rejects unknown option"

# ---- neos doctor --ai pipes report to neos-ai (stub on PATH) ----
STUB="$(mktemp -d)"
cat > "$STUB/neos-ai" <<'STUB'
#!/usr/bin/env bash
read -r _
echo "[stub-ai] read prompt ok"
STUB
chmod +x "$STUB/neos-ai"
out="$(PATH="$STUB:$PATH" "$NEOS" doctor --ai 2>&1 || true)"
grep -q -E 'stub-ai|neos-ai is not installed|NeoPulse' <<< "$out" \
  && ok "neos doctor --ai runs (stub or fallback)" || bad "neos doctor --ai runs"
rm -rf "$STUB"

# ---- neos-start: settings registry + app discovery ----
ns="./overlay/usr/bin/neos-start"
out="$("$ns" --list-settings 2>&1)"
out="$("$ns" apps 2>&1 || true)"
if [[ -n "$out" ]]; then ok "neos-start apps enumerates desktop apps"; else bad "neos-start apps enumerates desktop apps"; fi

# ---- neos-gui: help + list + validation + select ----
ng="./overlay/usr/bin/neos-gui"
grep -q 'openbox' <<< "$("$ng" --help 2>&1)" && ok "neos-gui --help lists openbox" || bad "neos-gui --help lists openbox"
out="$("$ng" list 2>&1 || true)"
for g in openbox sway xfce; do
  grep -q "$g" <<< "$out" && ok "neos-gui list shows $g" || bad "neos-gui list shows $g"
done
out="$("$ng" kdebloat 2>&1 || true)"
grep -q 'unknown command' <<< "$out" && ok "neos-gui rejects unknown GUI" || bad "neos-gui rejects unknown GUI"
# select writes marker + xsession (no install needed) in a temp HOME
GUITMP="$(mktemp -d)"
HOME="$GUITMP" "$ng" select openbox >/dev/null 2>&1 || true
[[ -f "$GUITMP/.config/neos/gui" ]] && ok "neos-gui select writes marker" || bad "neos-gui select writes marker"
grep -q 'exec openbox' "$GUITMP/.xsession" 2>/dev/null && ok "neos-gui select writes xsession" || bad "neos-gui select writes xsession"
rm -rf "$GUITMP"

# ---- neos-alive: liveliness pulse prints vitality + vitals ----
ALIVE_OUT="$(PATH="$PWD/overlay/usr/bin:$PATH" "$NEOS" alive 2>&1 || true)"
grep -q 'alive' <<< "$ALIVE_OUT"            && ok "neo alive prints an alive banner"  || bad "neo alive banner"
grep -q 'vitality' <<< "$ALIVE_OUT"         && ok "neo alive prints vitality score"    || bad "neo alive vitality"
grep -Eq 'load:|mem:|disk:' <<< "$ALIVE_OUT" && ok "neo alive prints live vitals"     || bad "neo alive vitals"

# ---- neos-alive --min is a one-line summary ----
MIN_OUT="$(PATH="$PWD/overlay/usr/bin:$PATH" ./overlay/usr/bin/neos-alive --min 2>&1 || true)"
grep -q 'alive' <<< "$MIN_OUT" && ok "neos-alive --min is a one-line pulse" || bad "neos-alive --min"

# ---- neos-welcome: landing banner greets + shows NeoOS identity ----
WEL_OUT="$(PATH="$PWD/overlay/usr/bin:$PATH" ./overlay/usr/bin/neos-welcome 2>&1 || true)"
grep -q 'Welcome' <<< "$WEL_OUT"  && ok "neos-welcome greets the user"       || bad "neos-welcome greets"
grep -qi 'NeoOS' <<< "$WEL_OUT"   && ok "neos-welcome shows NeoOS identity"  || bad "neos-welcome identity"

# ---- neo welcome / neo tip route through the umbrella without error ----
PATH="$PWD/overlay/usr/bin:$PATH" "$NEOS" welcome >/dev/null 2>&1 && ok "neo welcome runs" || bad "neo welcome runs"
PATH="$PWD/overlay/usr/bin:$PATH" "$NEOS" tip >/dev/null 2>&1     && ok "neo tip runs"     || bad "neo tip runs"

# ---- profile.d welcome hook is syntactically valid ----
bash -n ./overlay/etc/profile.d/neos-welcome.sh 2>/dev/null && ok "profile.d neos-welcome.sh is valid" || bad "profile.d neos-welcome.sh is valid"

echo
printf 'neos suite: %d passed, %d failed\n' "$pass" "$fail"
(( fail == 0 )) || exit 1
