#!/usr/bin/env bash
# Build the shareable tarball: run the tests, scan for anything personal, pack.
#
#   maintainer/build.sh        -> dist/omarchy-setup-kit-<date>.tar.gz
#
# The scan looks for your git name and email, your user and host names, your
# home folder, API-key shapes, and the words in
# ~/.config/setup-kit-maintainer/private-words (kept outside the kit). The
# maintainer/ folder itself is never packed.
set -euo pipefail

KIT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$KIT"

echo "Tests"
maintainer/test.sh

echo
echo "Leak scan"
words=()
for w in "$(git config --global user.email 2>/dev/null || true)" "$(git config --global user.name 2>/dev/null || true)" \
  "$USER" "$(hostname 2>/dev/null || cat /etc/hostname)" "$HOME"; do
  [[ -n $w ]] && words+=("$w")
done
# Each part of the git name on its own too.
for w in $(git config --global user.name 2>/dev/null || true); do ((${#w} > 2)) && words+=("$w"); done
list="$HOME/.config/setup-kit-maintainer/private-words"
[[ -f $list ]] && while IFS= read -r w; do [[ -n $w && $w != \#* ]] && words+=("$w"); done <"$list"

files=$(find . -path ./maintainer -prune -o -path ./dist -prune -o -path ./.git -prune -o -name LICENSE -prune -o -type f -print)
hits=0
for w in "${words[@]}"; do
  if out=$(grep -nIiwF -e "$w" $files); then
    echo "  personal word found: $w"
    echo "$out" | sed 's/^/    /'
    hits=1
  fi
done
# Shapes of real secrets: Anthropic, Groq, OpenAI, GitHub, Slack, AWS keys, private keys, tokens in URLs.
if out=$(grep -nIE 'sk-ant-[A-Za-z0-9_-]{8,}|gsk_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9]{32,}|gh[pousr]_[A-Za-z0-9]{20,}|github_pat_|xox[abprs]-|AKIA[0-9A-Z]{16}|BEGIN [A-Z ]*PRIVATE KEY|://[^/ ]+:[^@/ ]+@' $files); then
  echo "  something shaped like a secret:"
  echo "$out" | sed 's/^/    /'
  hits=1
fi
if out=$(grep -nIE '^[A-Z_]*(KEY|TOKEN|SECRET|PASSWORD)[A-Z_]*=.+' $files); then
  echo "  a filled-in key line:"
  echo "$out" | sed 's/^/    /'
  hits=1
fi
((hits)) && { echo "Not packed."; exit 1; }
echo "  clean (${#words[@]} words and the secret shapes, over $(wc -w <<<"$files") files)"

echo
mkdir -p dist
name="omarchy-setup-kit-$(date +%Y-%m-%d)"
tar --exclude=./maintainer --exclude=./dist --exclude=./.git --exclude=./.gitignore --transform "s,^\.,$name," \
  --owner=0 --group=0 --numeric-owner --sort=name -czf "dist/$name.tar.gz" .
(cd dist && sha256sum "$name.tar.gz" >"$name.tar.gz.sha256")
echo "Packed: $KIT/dist/$name.tar.gz ($(du -h "dist/$name.tar.gz" | cut -f1))"
tar tzf "dist/$name.tar.gz" | sed 's/^/  /' | head -60
