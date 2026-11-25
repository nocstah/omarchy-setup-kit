#!/usr/bin/env bash
# The kit's tests, run on the maintainer's machine. Everything happens in a
# throwaway home with stand-ins for every command that would change the
# system (packages, systemctl, hyprctl, signals to running terminals).
#
#   maintainer/test.sh                     run them
#   maintainer/test.sh --update-shortcuts  also rewrite SHORTCUTS.md from the Lua files
set -euo pipefail

KIT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
UPDATE=0
[[ ${1:-} == --update-shortcuts ]] && UPDATE=1
WORK=$(mktemp -d "${TMPDIR:-/tmp}/setup-kit-test.XXXXXX")
trap 'rm -rf "$WORK"' EXIT
S="$WORK/stubs" LOG="$WORK/calls.log"
mkdir -p "$S" "$WORK/run"
chmod 700 "$WORK/run"
: >"$LOG"

FAILS=0
pass() { printf '  ok    %s\n' "$*"; }
fail() { printf '  FAIL  %s\n' "$*"; FAILS=$((FAILS + 1)); }
check() { local what=$1; shift; if "$@"; then pass "$what"; else fail "$what"; fi; }

# Stand-ins: each logs its call; none touches the real system.
stub() { # name [body]
  { echo '#!/bin/bash'; echo "echo \"$1 \$*\" >>'$LOG'"; echo "${2:-exit 0}"; } >"$S/$1"
  chmod +x "$S/$1"
}
stub omarchy 'if [[ $1 == version ]]; then echo "${FAKE_OMARCHY_VERSION:-4.5.0-3}"; fi'
stub omarchy-pkg-add
stub omarchy-install-dictation-voxtype
stub omarchy-default-dictation 'echo voxtype'
stub omarchy-theme-set-foot
stub systemctl 'if [[ $* == *is-active* ]]; then exit 3; fi'
stub hyprctl
stub pgrep 'exit 1'
stub pkill 'exit 1'
stub voxtype
stub notify-send

new_home() { # a fresh home shaped like a new Omarchy 4.5 install, plus a few files of "yours"
  local h=$1
  mkdir -p "$h/.config" "$h/.local/state/omarchy/current/theme"
  cp -r /usr/share/omarchy/config/hypr "$h/.config/hypr"
  mkdir -p "$h/.config/foot" "$h/.config/fish" "$h/.config/atuin"
  cp /usr/share/omarchy/config/foot/foot.ini "$h/.config/foot/foot.ini"
  echo 'echo my own fish config' >"$h/.config/fish/config.fish"
  echo 'sync_address = "https://example.invalid"' >"$h/.config/atuin/config.toml"
  printf 'mode = "dark"\naccent = "#7aa2f7"\nred = "#f7768e"\ngreen = "#9ece6a"\nbright_red = "#ff7a93"\n' >"$h/.local/state/omarchy/current/theme/colors.toml"
  printf '[colors-dark]\nbackground=1a1b26\nforeground=c0caf5\n' >"$h/.local/state/omarchy/current/theme/foot.ini"
  echo 'inherits = "x"' >"$h/.local/state/omarchy/current/theme/helix.toml"
}

run_kit() { # home args...
  local h=$1; shift
  env -i HOME="$h" PATH="$S:/usr/bin:/bin" XDG_RUNTIME_DIR="$WORK/run" TMPDIR="$WORK" LANG=C.UTF-8 \
    HYPRLAND_INSTANCE_SIGNATURE=kit-test-fake FAKE_OMARCHY_VERSION="${FAKE_OMARCHY_VERSION:-4.5.0-3}" \
    bash "$KIT/install.sh" "$@" </dev/null
}

snapshot() { # home: every file with its contents' hash, minus the kit's own state
  (cd "$1" && find . \( -path ./.local/state/setup-kit -prune \) -o \( -type f -o -type l \) -print0 | sort -z |
    xargs -0 -I{} sh -c 'if [ -L "{}" ]; then echo "{} -> $(readlink "{}")"; else echo "{} $(sha256sum <"{}" | cut -c1-16) $(stat -c %a "{}")"; fi')
}

lua_check() { # home scenario [shortcuts-out]
  env -i HOME="$1" PATH="$S:/usr/bin:/bin" LANG=C.UTF-8 KIT_API_SOURCES="/usr/share/omarchy/default/hypr:${KIT_EXTRA_API_SOURCES:-}" \
    lua "$KIT/maintainer/hypr-check.lua" "$2" ${3:+"$3"}
}

echo "Installer"
H="$WORK/home"
new_home "$H"
before=$(snapshot "$H")

out=$(run_kit "$H" --dry-run --yes 2>&1) || { echo "$out"; fail "dry run exits 0"; }
check "a dry run changes nothing" test "$before" == "$(snapshot "$H")"
check "a dry run says so" grep -q "Dry run" <<<"$out"

out=$(run_kit "$H" --yes --dictation groq 2>&1) || { echo "$out"; fail "install exits 0"; }
conf="$H/.config/hypr/hyprland.lua"
check "hyprland.lua loads the kit" grep -q 'require("hypr.kit.init")' "$conf"
kit_line=$(grep -c '^require("hypr.kit.init")' "$conf")
check "it is loaded once" test "$kit_line" == 1
kit_line=$(grep -n -m1 '^require("hypr.kit.init")' "$conf" | cut -d: -f1)
omarchy_line=$(grep -n -m1 '^require("default.hypr.omarchy")' "$conf" | cut -d: -f1)
own_line=$(grep -n -m1 '^require("hypr.bindings")' "$conf" | cut -d: -f1)
check "the kit loads after Omarchy's defaults" test "$kit_line" -gt "$omarchy_line"
check "and before your own bindings.lua" test "$kit_line" -lt "$own_line"
check "the key files are in place" test -f "$H/.config/hypr/kit/mac.lua" -a -f "$H/.config/hypr/kit/dictation.lua"
check "the scripts are executable" test -x "$H/.local/share/setup-kit/bin/thumb-wheel" -a -x "$H/.config/bin/dictate-cleanup"
check "the env file is yours alone" test "$(stat -c %a "$H/.config/dictate/env")" == 600
check "the env file has no key in it" bash -c "! grep -qE '^[A-Z_]+=.+' '$H/.config/dictate/env'"
check "groq: Voxtype goes remote" grep -q '^mode = "remote"' "$H/.config/voxtype/config.toml"
check "it asks for the Groq key" grep -q 'Put your Groq key' <<<"$out"
check "your fish config is in the backup" grep -rq 'my own fish config' "$H/.local/state/setup-kit/backups"
check "your atuin config is kept" grep -q example.invalid "$H/.config/atuin/config.toml"
check "the helix theme links to Omarchy's" test "$(readlink "$H/.config/helix/themes/omarchy.toml")" == "$H/.local/state/omarchy/current/theme/helix.toml"
check "Hyprland is reloaded" grep -q '^hyprctl reload' "$LOG"
check "systemd learns the drop-in" grep -q '^systemctl --user daemon-reload' "$LOG"
check "the glass hook set foot's alpha" grep -q '^alpha=0.62' "$H/.config/foot/foot.ini"
check "and copied the theme's colours for light themes" grep -q '^\[colors-light\]' "$H/.local/state/omarchy/current/theme/foot.ini"

sed -i 's/^mode = "dark"/mode = "light"/' "$H/.local/state/omarchy/current/theme/colors.toml"
env -i HOME="$H" PATH="$S:/usr/bin:/bin" bash "$H/.config/omarchy/hooks/theme-set.d/zz-kit-foot-glass"
check "a light theme gets the light alpha" grep -q '^initial-color-theme=light' "$H/.config/foot/foot.ini"
sed -i 's/^mode = "light"/mode = "dark"/' "$H/.local/state/omarchy/current/theme/colors.toml"
env -i HOME="$H" PATH="$S:/usr/bin:/bin" bash "$H/.config/omarchy/hooks/theme-set.d/zz-kit-foot-glass"

echo '  thumb_wheel = true,' >"$WORK/opt" && sed -i "/^return {/r $WORK/opt" "$H/.config/hypr/kit/options.lua"
out=$(run_kit "$H" --yes --dictation groq 2>&1) || { echo "$out"; fail "second install exits 0"; }
if grep -q "Nothing to change" <<<"$out"; then pass "a second run changes nothing"; else fail "a second run changes nothing"; grep -vE '^  (same|kept) ' <<<"$out"; fi
check "your options survive it" grep -q 'thumb_wheel = true' "$H/.config/hypr/kit/options.lua"

echo "Keys (Omarchy's own Lua helpers and default keys, then the kit)"
mkdir -p "$H/.config/omarchy/plugins"
if out=$(lua_check "$H" all "$WORK/SHORTCUTS.md" 2>&1); then pass "$out"; else echo "$out"; fail "all apps present"; fi
if out=$(lua_check "$H" bare 2>&1); then pass "$out"; else echo "$out"; fail "no apps present"; fi
if ((UPDATE)); then
  cp "$WORK/SHORTCUTS.md" "$KIT/SHORTCUTS.md"
  pass "SHORTCUTS.md rewritten"
else
  check "SHORTCUTS.md matches the Lua files (--update-shortcuts rewrites it)" cmp -s "$WORK/SHORTCUTS.md" "$KIT/SHORTCUTS.md"
fi

echo "Undo"
out=$(run_kit "$H" --restore all 2>&1) || { echo "$out"; fail "restore exits 0"; }
after=$(snapshot "$H" | grep -v '^./.local/state/omarchy/current/theme/foot.ini ')
check "--restore all gives back the home as it was (but the theme's generated foot.ini)" test "$(grep -v '^./.local/state/omarchy/current/theme/foot.ini ' <<<"$before")" == "$after" || diff <(echo "$before") <(echo "$after")

echo "One module, other versions, offline Whisper"
H2="$WORK/home2"
new_home "$H2"
out=$(run_kit "$H2" --yes --only dictation --dictation local 2>&1) || { echo "$out"; fail "--only dictation exits 0"; }
check "--only dictation: dictation keys, no Mac keys" test -f "$H2/.config/hypr/kit/dictation.lua" -a ! -e "$H2/.config/hypr/kit/mac.lua"
check "local: Voxtype runs offline on base.en" grep -q '^model = "base.en"' "$H2/.config/voxtype/config.toml"
if out=$(lua_check "$H2" dictation 2>&1); then pass "$out"; else echo "$out"; fail "dictation alone loads"; fi
H3="$WORK/home3"
new_home "$H3"
if FAKE_OMARCHY_VERSION=4.0.6 run_kit "$H3" --yes >/dev/null 2>&1; then fail "Omarchy 4.0 is refused"; else pass "Omarchy 4.0 is refused"; fi
if FAKE_OMARCHY_VERSION=4.6.0 run_kit "$H3" --yes --force --no-system >/dev/null 2>&1; then pass "--force installs anyway"; else fail "--force installs anyway"; fi

echo "Scripts"
for f in "$KIT/install.sh" "$KIT"/modules/*/bin/* "$KIT"/modules/*/files/bin/* "$KIT"/modules/terminal/files/omarchy/hooks/theme-set.d/*; do
  check "bash -n $(basename "$f")" bash -n "$f"
done
if command -v fish >/dev/null; then
  for f in "$KIT"/modules/terminal/files/fish/config.fish "$KIT"/modules/terminal/files/fish/*/*.fish; do
    fish --no-execute "$f" 2>/dev/null || fail "fish --no-execute $(basename "$f")"
  done
  pass "fish files parse"
fi
for f in "$KIT"/modules/*/hypr/kit/*.lua; do luac -p "$f" || fail "luac $(basename "$f")"; done
pass "Lua files parse (Lua $(lua -v 2>&1 | cut -d' ' -f2), as Hyprland uses)"

echo
if ((FAILS)); then echo "$FAILS failed"; exit 1; fi
echo "All passed."
