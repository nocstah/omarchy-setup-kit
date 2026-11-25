#!/usr/bin/env bash
# Setup kit installer for Omarchy 4.5: keyboard shortcuts, desktop feel,
# terminal and app settings, dictation. Read README.md first.
#
#   ./install.sh --dry-run          show what would change, change nothing
#   ./install.sh                    install everything, asking before packages
#   ./install.sh --only desktop     just some modules: desktop, terminal, dictation
#   ./install.sh --restore latest   undo the last run (or --restore all, or a backup's name)
#   ./install.sh --help             all options
set -euo pipefail

KIT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
MOD_DIR="$KIT_DIR/modules"
ALL_MODULES=(desktop terminal dictation)
STATE_DIR="$HOME/.local/state/setup-kit"
BACKUPS="$STATE_DIR/backups"

DRY=0 YES=0 FORCE=0 NO_SYSTEM=0 ONLY="" ENGINE="" RESTORE="" LIST_BACKUPS=0

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

  -n, --dry-run           Show what would change; change nothing.
  -y, --yes               Don't ask: install missing packages, use the defaults.
      --only LIST         Install only these modules, comma-separated:
                          desktop, terminal, dictation (default: all three).
      --dictation ENGINE  groq (cloud Whisper, needs a free key) or local (offline).
                          Asked if not given; with --yes: groq if a key is
                          already in ~/.config/dictate/env, else local.
      --restore NAME      Undo a run: a backup's name, "latest", or "all"
                          (every run, newest first: back to before the kit).
      --list-backups      List the backups.
      --force             Install on an Omarchy other than 4.5.
      --no-system         Change files only: no packages, services or Hyprland reload.
  -h, --help              This help.
EOF
}

while (($#)); do
  case $1 in
    -n | --dry-run) DRY=1 ;;
    -y | --yes) YES=1 ;;
    --only) ONLY=${2:?--only needs a list}; shift ;;
    --only=*) ONLY=${1#*=} ;;
    --dictation) ENGINE=${2:?--dictation needs groq or local}; shift ;;
    --dictation=*) ENGINE=${1#*=} ;;
    --restore) RESTORE=${2:?--restore needs a name, latest or all}; shift ;;
    --restore=*) RESTORE=${1#*=} ;;
    --list-backups) LIST_BACKUPS=1 ;;
    --force) FORCE=1 ;;
    --no-system) NO_SYSTEM=1 ;;
    -h | --help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [[ -t 1 ]]; then B=$'\e[1m' D=$'\e[2m' G=$'\e[32m' Y=$'\e[33m' R=$'\e[31m' N=$'\e[0m'; else B="" D="" G="" Y="" R="" N=""; fi
say() { printf '%s\n' "$*"; }
step() { printf '\n%s%s%s\n' "$B" "$*" "$N"; }
note() { printf '  %s\n' "$*"; }
warn() { printf '  %s%s%s\n' "$Y" "$*" "$N"; }
die() { printf '%s%s%s\n' "$R" "$*" "$N" >&2; exit 1; }

# A yes/no question. --yes answers yes; with no terminal to ask, the default.
ask() {
  local question=$1 default=${2:-y} reply
  ((YES)) && return 0
  if [[ ! -t 0 ]]; then [[ $default == y ]]; return; fi
  local hint="[Y/n]"
  [[ $default == n ]] && hint="[y/N]"
  read -r -p "  $question $hint " reply || reply=""
  reply=${reply:-$default}
  [[ $reply == [yY]* ]]
}

# ---------------------------------------------------------------- backups ---

list_backups() {
  [[ -d $BACKUPS ]] || { say "No backups yet."; return; }
  local d
  for d in "$BACKUPS"/*/; do
    [[ -f $d/manifest ]] || continue
    printf '%s  %s changes\n' "$(basename "$d")" "$(wc -l <"$d/manifest")"
  done
}

restore_one() {
  local dir=$1 kind rel
  [[ -f $dir/manifest ]] || die "No backup at $dir"
  step "Undoing $(basename "$dir")"
  # Newest change first.
  while IFS=$'\t' read -r kind rel; do
    case $kind in
      replaced)
        if ((DRY)); then note "would put back ~/$rel"; else
          mkdir -p "$(dirname "$HOME/$rel")"
          rm -rf "${HOME:?}/$rel"
          cp -a "$dir/files/$rel" "$HOME/$rel"
          note "put back ~/$rel"
        fi ;;
      created)
        if ((DRY)); then note "would remove ~/$rel"; else
          rm -f "${HOME:?}/$rel"
          note "removed ~/$rel"
        fi ;;
    esac
  done < <(tac "$dir/manifest")
  ((DRY)) || mv "$dir" "$dir.undone"
}

do_restore() {
  local target=$1 dirs=()
  [[ -d $BACKUPS ]] || die "No backups in $BACKUPS"
  case $target in
    latest) mapfile -t dirs < <(find "$BACKUPS" -mindepth 1 -maxdepth 1 -type d ! -name '*.undone' | sort | tail -1) ;;
    all) mapfile -t dirs < <(find "$BACKUPS" -mindepth 1 -maxdepth 1 -type d ! -name '*.undone' | sort -r) ;;
    *) dirs=("$BACKUPS/$target") ;;
  esac
  ((${#dirs[@]})) || die "Nothing to undo."
  local d
  for d in "${dirs[@]}"; do restore_one "$d"; done
  reload_hyprland
  say ""
  say "Done. Packages the kit installed stay installed."
}

# ------------------------------------------------------------- file steps ---

RUN_ID=$(date +%Y%m%d-%H%M%S)-$$
RUN_DIR="$BACKUPS/$RUN_ID"
CHANGES=0

record() { # kind relpath
  ((DRY)) && return
  mkdir -p "$RUN_DIR"
  printf '%s\t%s\n' "$1" "$2" >>"$RUN_DIR/manifest"
}

backup() { # relpath
  ((DRY)) && return
  mkdir -p "$RUN_DIR/files/$(dirname "$1")"
  cp -a "$HOME/$1" "$RUN_DIR/files/$1"
  record replaced "$1"
}

# put SRC DEST [MODE]: install a kit file (DEST is relative to your home),
# backing up what was there.
put() {
  local src=$1 rel=$2 mode=${3:-644} dest="$HOME/$2"
  if [[ -e $dest || -L $dest ]]; then
    if [[ ! -L $dest ]] && cmp -s "$src" "$dest"; then
      note "$D""same     ~/$rel$N"
      return
    fi
    if ((DRY)); then note "replace  ~/$rel"; CHANGES=$((CHANGES + 1)); return; fi
    backup "$rel"
    rm -f "$dest"
    note "replaced ~/$rel $D(yours is in the backup)$N"
  else
    if ((DRY)); then note "add      ~/$rel"; CHANGES=$((CHANGES + 1)); return; fi
    record created "$rel"
    note "added    ~/$rel"
  fi
  mkdir -p "$(dirname "$dest")"
  install -m "$mode" "$src" "$dest"
  CHANGES=$((CHANGES + 1))
}

# put_once SRC DEST [MODE]: only when nothing is there yet (your own settings).
put_once() {
  local rel=$2
  if [[ -e $HOME/$rel ]]; then note "$D""kept     ~/$rel (yours)$N"; return; fi
  put "$@"
}

# link TARGET DEST: a symlink.
link() {
  local target=$1 rel=$2 dest="$HOME/$2"
  if [[ -L $dest && $(readlink "$dest") == "$target" ]]; then note "$D""same     ~/$rel$N"; return; fi
  if ((DRY)); then note "link     ~/$rel -> $target"; CHANGES=$((CHANGES + 1)); return; fi
  if [[ -e $dest || -L $dest ]]; then backup "$rel"; rm -rf "$dest"; else record created "$rel"; fi
  mkdir -p "$(dirname "$dest")"
  ln -s "$target" "$dest"
  note "linked   ~/$rel -> $target"
  CHANGES=$((CHANGES + 1))
}

# The lines in hyprland.lua that load the kit: right after Omarchy's defaults
# and before your own files, so your bindings.lua and looknfeel.lua still win.
BLOCK_BEGIN='-- >>> setup-kit >>>'
BLOCK_END='-- <<< setup-kit <<<'
hypr_block() {
  local rel=.config/hypr/hyprland.lua conf="$HOME/.config/hypr/hyprland.lua" tmp
  if grep -qF -e "$BLOCK_BEGIN" "$conf"; then note "$D""same     ~/$rel (loads the kit)$N"; return; fi
  if ((DRY)); then note "edit     ~/$rel (add the lines that load the kit)"; CHANGES=$((CHANGES + 1)); return; fi
  backup "$rel"
  tmp=$(mktemp)
  awk -v b="$BLOCK_BEGIN" -v e="$BLOCK_END" '
    function block() {
      print ""
      print b
      print "-- The setup kit: keys and tweaks in ~/.config/hypr/kit (options in kit/options.lua)."
      print "-- Delete these lines to turn it all off. Your own files below still win."
      print "require(\"hypr.kit.init\")"
      print e
      done = 1
    }
    { print }
    !done && /^[[:space:]]*require\("default\.hypr\.omarchy"\)/ { block() }
    END { if (!done) block() }
  ' "$conf" >"$tmp"
  cat "$tmp" >"$conf"
  rm -f "$tmp"
  note "edited   ~/$rel (loads the kit after Omarchy's defaults)"
  CHANGES=$((CHANGES + 1))
}

# ---------------------------------------------------------- system steps ---

have() { command -v "$1" >/dev/null 2>&1; }

PKGS_WANTED=()
want_pkg() { # package [command]
  have "${2:-$1}" || PKGS_WANTED+=("$1")
}

install_pkgs() { # what they're for
  ((${#PKGS_WANTED[@]})) || return 0
  local list="${PKGS_WANTED[*]}"
  PKGS_WANTED=()
  if ((NO_SYSTEM)); then note "$D""skipped installing $list (--no-system)$N"; return 0; fi
  if ((DRY)); then note "would ask to install: $list"; return 0; fi
  if ask "Install $list ($*)?" y; then
    # shellcheck disable=SC2086 # one word per package
    omarchy-pkg-add $list || warn "Installing $list failed; what needs them stays off."
  else
    note "Not installing $list; what needs them stays off."
  fi
}

reload_hyprland() {
  if ((DRY || NO_SYSTEM)); then return; fi
  if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] && have hyprctl; then
    if hyprctl reload >/dev/null; then note "Hyprland reloaded."; else warn "hyprctl reload failed; log out and in."; fi
  fi
}

# ---------------------------------------------------------------- modules ---

hypr_core() {
  local f
  for f in init lib; do put "$MOD_DIR/desktop/hypr/kit/$f.lua" ".config/hypr/kit/$f.lua"; done
  put_once "$MOD_DIR/desktop/hypr/kit/options.lua" .config/hypr/kit/options.lua
  hypr_block
}

module_desktop() {
  step "Desktop: keys, look, pads, window rules"
  local f
  hypr_core
  for f in input mouse windows look omarchy40 mac apps pads autostart; do
    put "$MOD_DIR/desktop/hypr/kit/$f.lua" ".config/hypr/kit/$f.lua"
  done
  for f in foot-popup-opaque thumb-wheel; do put "$MOD_DIR/desktop/bin/$f" ".local/share/setup-kit/bin/$f" 755; done
  put "$MOD_DIR/desktop/xkb/symbols/usno" .config/xkb/symbols/usno
  put_once "$MOD_DIR/desktop/notes/.helix/config.toml" notes/.helix/config.toml
  want_pkg wl-clip-persist
  install_pkgs "keeps what you copied after its app closes"
}

module_terminal() {
  step "Terminal and apps: glass terminals, fish, Helix, Yazi, atuin"
  put "$MOD_DIR/terminal/files/foot/foot.ini" .config/foot/foot.ini
  put "$MOD_DIR/terminal/files/omarchy/hooks/theme-set.d/zz-kit-foot-glass" .config/omarchy/hooks/theme-set.d/zz-kit-foot-glass 755
  if ((!DRY)) && [[ -f $HOME/.local/state/omarchy/current/theme/foot.ini ]]; then
    if ((NO_SYSTEM)); then
      note "$D""skipped running the glass hook for the current theme (--no-system)$N"
    else
      "$HOME/.config/omarchy/hooks/theme-set.d/zz-kit-foot-glass" || warn "The glass hook failed; it runs again on the next theme change."
    fi
  fi

  want_pkg fish
  want_pkg helix
  want_pkg yazi
  want_pkg atuin
  want_pkg glow
  install_pkgs "the shell, editor, file manager, history search and Markdown viewer these settings are for"

  local f rel
  if have fish || ((DRY)); then
    put "$MOD_DIR/terminal/files/fish/config.fish" .config/fish/config.fish
    for f in "$MOD_DIR"/terminal/files/fish/functions/*.fish "$MOD_DIR"/terminal/files/fish/completions/*.fish; do
      rel=${f#"$MOD_DIR/terminal/files/"}
      put "$f" ".config/$rel"
    done
  else
    note "$D""fish isn't installed: its settings are left out$N"
  fi
  if have helix || have hx || ((DRY)); then
    put "$MOD_DIR/terminal/files/helix/config.toml" .config/helix/config.toml
    put "$MOD_DIR/terminal/files/helix/languages.toml" .config/helix/languages.toml
    link "$HOME/.local/state/omarchy/current/theme/helix.toml" .config/helix/themes/omarchy.toml
  else
    note "$D""Helix isn't installed: its settings are left out$N"
  fi
  if have yazi || ((DRY)); then put "$MOD_DIR/terminal/files/yazi/yazi.toml" .config/yazi/yazi.toml; fi
  if have atuin || ((DRY)); then
    if [[ -e $HOME/.config/atuin/config.toml ]]; then
      note "$D""kept     ~/.config/atuin/config.toml (yours; the kit's two lines are in modules/terminal/files/atuin)$N"
    else
      put "$MOD_DIR/terminal/files/atuin/config.toml" .config/atuin/config.toml
    fi
  fi
}

has_groq_key() { [[ -f $HOME/.config/dictate/env ]] && grep -qE '^VOXTYPE_WHISPER_API_KEY=.+' "$HOME/.config/dictate/env"; }

module_dictation() {
  step "Dictation: Voxtype with Groq or offline Whisper, and an AI cleanup"
  if ! have voxtype; then
    if ((NO_SYSTEM)); then note "$D""Voxtype isn't installed; not installing it (--no-system)$N"
    elif ((DRY)); then note "would ask to install Voxtype (omarchy-install-dictation-voxtype)"
    elif ask "Voxtype isn't installed. Install it now (Omarchy's installer; asks for your password)?" y; then
      omarchy-install-dictation-voxtype || warn "Voxtype's installer failed; its settings are installed anyway."
    fi
  fi

  if [[ -z $ENGINE ]]; then
    if ((YES || DRY)) || [[ ! -t 0 ]]; then
      if has_groq_key; then ENGINE=groq; else ENGINE=local; fi
    elif ask "Use Groq's Whisper (fast and accurate; needs a free key from console.groq.com)? No = offline Whisper on this computer." y; then
      ENGINE=groq
    else
      ENGINE=local
    fi
  fi
  case $ENGINE in groq | local) ;; *) die "--dictation is groq or local, not $ENGINE" ;; esac
  note "Whisper: $ENGINE"

  local tmp
  tmp=$(mktemp)
  if [[ $ENGINE == local ]]; then
    sed -e 's/^mode = "remote"$/mode = "local"/' -e 's/^model = "whisper-large-v3-turbo"$/model = "base.en"/' \
      "$MOD_DIR/dictation/files/voxtype/config.toml" >"$tmp"
  else
    cp "$MOD_DIR/dictation/files/voxtype/config.toml" "$tmp"
  fi
  put "$tmp" .config/voxtype/config.toml
  rm -f "$tmp"
  put "$MOD_DIR/dictation/files/bin/dictate-cleanup" .config/bin/dictate-cleanup 755
  put "$MOD_DIR/dictation/files/systemd/voxtype.service.d/10-dictate-env.conf" .config/systemd/user/voxtype.service.d/10-dictate-env.conf
  put_once "$MOD_DIR/dictation/files/dictate/env.example" .config/dictate/env 600
  put_once "$MOD_DIR/dictation/files/dictate/dictionary.txt" .config/dictate/dictionary.txt
  hypr_core
  put "$MOD_DIR/dictation/hypr/kit/dictation.lua" .config/hypr/kit/dictation.lua

  if ((!DRY && !NO_SYSTEM)) && have systemctl; then
    systemctl --user daemon-reload || true
    if systemctl --user is-active --quiet voxtype.service; then
      if systemctl --user restart voxtype.service; then note "Voxtype restarted."; else warn "Voxtype didn't restart: systemctl --user status voxtype"; fi
    fi
  fi
  if ((!DRY)) && [[ $ENGINE == groq ]] && ! has_groq_key; then
    warn "Put your Groq key in ~/.config/dictate/env (VOXTYPE_WHISPER_API_KEY=...), then: systemctl --user restart voxtype"
  fi
}

# ------------------------------------------------------------------- main ---

if ((LIST_BACKUPS)); then list_backups; exit 0; fi
if [[ -n $RESTORE ]]; then do_restore "$RESTORE"; exit 0; fi

have omarchy || die "This kit is for Omarchy (omarchy.org); the omarchy command isn't here."
version=$(omarchy version 2>/dev/null | head -1)
if [[ $version != 4.5.* ]]; then
  ((FORCE)) || die "This kit is made for Omarchy 4.5; this is ${version:-an unknown version}. --force installs anyway."
  warn "Omarchy $version: installing anyway (--force)."
fi
[[ -f $HOME/.config/hypr/hyprland.lua ]] || die "No ~/.config/hypr/hyprland.lua: Omarchy 4.5 keeps its Hyprland config in Lua."

modules=("${ALL_MODULES[@]}")
if [[ -n $ONLY ]]; then
  IFS=, read -r -a modules <<<"$ONLY"
  for m in "${modules[@]}"; do
    [[ " ${ALL_MODULES[*]} " == *" $m "* ]] || die "Unknown module: $m (desktop, terminal, dictation)"
  done
fi

say "$B""Setup kit$N for Omarchy $version: ${modules[*]}"
((DRY)) && say "$Y""Dry run: nothing is changed.$N"

for m in "${modules[@]}"; do "module_$m"; done

((CHANGES)) && reload_hyprland
say ""
if ((DRY)); then
  say "$CHANGES changes. Run without --dry-run to make them."
elif ((CHANGES)); then
  say "$G""Done.$N $CHANGES changes. Backup: $RUN_DIR"
  say "Undo with: ./install.sh --restore $RUN_ID"
  say "Keys: SHORTCUTS.md. Options: ~/.config/hypr/kit/options.lua"
else
  say "$G""Nothing to change$N: it's all installed already."
fi
