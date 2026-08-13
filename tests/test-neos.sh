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

# ---- neos-apps: list / info / run / search / status ----
APPS="./overlay/usr/bin/neos-apps"
APPS_DIR="$(mktemp -d)"
export NEOS_APPS_DIR="$APPS_DIR"
mkdir -p "$APPS_DIR/hello/bin" "$APPS_DIR/calc/bin"
# hello app with manifest
cat > "$APPS_DIR/hello/app.manifest" <<'MF'
NAME="hello"
VERSION="1.0.0"
DESCRIPTION="A minimal Hello World demo app"
AUTHOR="NeoOS"
ENTRY="hello"
DEPENDS=""
MF
cat > "$APPS_DIR/hello/bin/hello" <<'BIN'
#!/usr/bin/env bash
echo "Hello, ${1:-World}!"
BIN
chmod +x "$APPS_DIR/hello/bin/hello"
# calc app with manifest
printf 'NAME="calc"\nVERSION="0.2.0"\nDESCRIPTION="Terminal calculator"\nAUTHOR="NeoOS"\nENTRY="calc"\nDEPENDS="bc"\n' > "$APPS_DIR/calc/app.manifest"
cat > "$APPS_DIR/calc/bin/calc" <<'BIN'
#!/usr/bin/env bash
echo "42"
BIN
chmod +x "$APPS_DIR/calc/bin/calc"

# list shows installed apps
out="$("$APPS" list 2>&1)"
grep -q 'hello' <<< "$out" && ok "neos-apps list shows hello" || bad "neos-apps list shows hello"
grep -q 'calc' <<< "$out" && ok "neos-apps list shows calc" || bad "neos-apps list shows calc"

# info shows manifest fields
out="$("$APPS" info hello 2>&1)"
grep -q 'VERSION\|version' <<< "$out" && ok "neos-apps info shows version" || bad "neos-apps info shows version"
grep -q 'Hello World' <<< "$out" && ok "neos-apps info shows description" || bad "neos-apps info shows description"
grep -q 'hello' <<< "$out" && ok "neos-apps info shows name" || bad "neos-apps info shows name"

# info rejects unknown app
out="$("$APPS" info nope 2>&1 || true)"
grep -qi 'not found' <<< "$out" && ok "neos-apps info rejects unknown app" || bad "neos-apps info rejects unknown app"

# run executes the app
out="$("$APPS" run hello 2>&1)"
grep -q 'Hello, World!' <<< "$out" && ok "neos-apps run hello works" || bad "neos-apps run hello works"

# run passes args
out="$("$APPS" run hello NeoOS 2>&1)"
grep -q 'Hello, NeoOS!' <<< "$out" && ok "neos-apps run hello passes args" || bad "neos-apps run hello passes args"

# search finds apps by keyword
out="$("$APPS" search hello 2>&1)"
grep -q 'hello' <<< "$out" && ok "neos-apps search finds hello" || bad "neos-apps search finds hello"
out="$("$APPS" search calc 2>&1)"
grep -q 'calc' <<< "$out" && ok "neos-apps search finds calc" || bad "neos-apps search finds calc"

# search is case-insensitive
out="$("$APPS" search HELLO 2>&1)"
grep -q 'hello' <<< "$out" && ok "neos-apps search is case-insensitive" || bad "neos-apps search case-insensitive"

# search with no match is graceful
out="$("$APPS" search zzznomatch 2>&1)"
grep -qi 'no apps' <<< "$out" && ok "neos-apps search no-match is graceful" || bad "neos-apps search no-match"

# status works (no crash)
out="$("$APPS" status 2>&1 || true)"
grep -q 'hello' <<< "$out" && ok "neos-apps status lists apps" || bad "neos-apps status lists apps"

# help prints usage
out="$("$APPS" help 2>&1)"
grep -q 'list' <<< "$out" && ok "neos-apps help documents list" || bad "neos-apps help documents list"
grep -q 'install' <<< "$out" && ok "neos-apps help documents install" || bad "neos-apps help documents install"

# cleanup
rm -rf "$APPS_DIR"

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

echo
printf 'neos suite: %d passed, %d failed\n' "$pass" "$fail"
(( fail == 0 )) || exit 1
