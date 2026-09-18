#!/bin/sh
# bootstrap.sh — install the short commands on an ephemeral Linux VM.
#
# The mini is a known host you PUSH to over ssh. A lab VM is anonymous, timed and
# unreachable from your laptop, so it has to PULL. One line, from the VM:
#
#   curl -fsSL https://raw.githubusercontent.com/iantalabs/ai-git-commands/master/cloud/bootstrap.sh | sh
#
# Options (env vars, because it is usually run through a pipe):
#   SI_REF=master        branch or tag to install from
#   SI_TARBALL=<url>     override the source tarball entirely
#   SI_SRC=/path/to/repo install from a local checkout instead of downloading
#   SI_DRY=1             show what would change, write nothing
#
#   SI_DRY=1 sh cloud/bootstrap.sh          # dry run from a local checkout
#
# POSIX sh on purpose: /bin/sh is dash on Debian/Ubuntu, so this file may not use
# a single bashism. The commands it installs are POSIX too — that was not true
# before 2026-09-18, when 23 of them still carried `args=("$@")` and died at
# parse time on any Debian box.
set -eu

REPO="iantalabs/ai-git-commands"
REF="${SI_REF:-master}"
DRY="${SI_DRY:-0}"
MARK_B='# >>> si-shortcuts >>>'
MARK_E='# <<< si-shortcuts <<<'

say(){ printf '%s\n' "$*"; }
note(){ printf '  %-9s %s\n' "$1" "$2"; }
changed=0

say ""
say "== si-shortcuts bootstrap"
say "   host   $(uname -s) $(uname -m)   sh -> $(readlink -f /bin/sh 2>/dev/null || echo /bin/sh)"
say "   mode   $([ "$DRY" = 1 ] && echo 'DRY RUN — nothing will be written' || echo INSTALL)"

# ---------------------------------------------------------------- get a source
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

if [ -n "${SI_SRC:-}" ]; then
  SRC="$SI_SRC"
  say "   src    local checkout $SRC"
else
  TARBALL="${SI_TARBALL:-https://codeload.github.com/$REPO/tar.gz/refs/heads/$REF}"
  say "   src    $TARBALL"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$TARBALL" | (cd "$WORK" && tar -xzf -)
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- "$TARBALL" | (cd "$WORK" && tar -xzf -)
  else
    say "   need curl or wget"; exit 1
  fi
  SRC="$(find "$WORK" -maxdepth 1 -mindepth 1 -type d | head -1)"
  [ -n "$SRC" ] || { say "   tarball did not unpack as expected"; exit 1; }
fi

MANIFEST="$SRC/cloud/manifest"
[ -f "$MANIFEST" ] || { say "   no cloud/manifest in the source"; exit 1; }

# ------------------------------------------------------------------- runtimes
say ""
say "== runtimes present on this box"
for t in git docker kubectl gcloud npm python3 vim; do
  p="$(command -v "$t" 2>/dev/null || true)"
  printf '  %-5s %-8s %s\n' "$([ -n "$p" ] && echo ok || echo MISS)" "$t" "$p"
done
say "  (commands for a missing runtime still install; they are one line each and"
say "   labs vary. Nothing here shells out at install time.)"

# ----------------------------------------------------------------------- ~/bin
say ""
say "== ~/bin"
[ -d "$HOME/bin" ] || { note create "~/bin"; changed=1; [ "$DRY" = 1 ] || mkdir -p "$HOME/bin"; }

n=0
while read -r line; do
  line="$(printf '%s' "$line" | sed 's/#.*//' | tr -d '[:space:]')"
  [ -n "$line" ] || continue
  f="$SRC/$line"
  if [ ! -f "$f" ]; then note MISSING "$line (not in the repo)"; continue; fi
  n=$((n + 1))
  b="$(basename "$line")"          # manifest entries may carry a path (logger/slog)
  t="$HOME/bin/$b"
  if [ ! -e "$t" ]; then note install "~/bin/$b"; changed=1
  elif ! cmp -s "$f" "$t"; then note update "~/bin/$b"; changed=1
  else continue
  fi
  [ "$DRY" = 1 ] || { cp "$f" "$t" && chmod 755 "$t"; }
done < "$MANIFEST"
note total "$n commands in the manifest"

# ------------------------------------------------------- idempotent rc editing
# Strips any previous block, appends the new one at the END so these definitions
# win over anything the image set earlier. Never rewrites the file wholesale.
apply_block(){ # target, content-file, label
  t="$1"; c="$2"; label="$3"
  [ -e "$t" ] || { [ "$DRY" = 1 ] || : > "$t"; }
  cur=""; [ -e "$t" ] && cur="$(cat "$t")"
  stripped="$(printf '%s\n' "$cur" | awk -v b="$MARK_B" -v e="$MARK_E" '
    $0==b {skip=1; next} $0==e {skip=0; next} !skip {print}')"
  new="$(printf '%s\n\n%s\n%s\n%s\n' "$stripped" "$MARK_B" "$(cat "$c")" "$MARK_E" \
        | awk 'BEGIN{blank=0} /^$/{blank++; if(blank>2) next; print; next} {blank=0; print}')"
  if [ "$cur" = "$new" ]; then note same "$label"; return; fi
  note "$([ -s "$t" ] && echo update || echo create)" "$label"; changed=1
  if [ "$DRY" != 1 ]; then
    [ -s "$t" ] && cp "$t" "$t.bak-$(date +%Y%m%d-%H%M%S)"
    printf '%s\n' "$new" > "$t"
  fi
}

say ""
say "== ~/.profile  (PATH; read by login bash — Cloud Shell and ssh both qualify)"
apply_block "$HOME/.profile" "$SRC/cloud/profile" "~/.profile"

say ""
say "== ~/.bashrc.si + ~/.bashrc  (interactive aliases)"
if [ -e "$HOME/.bashrc.si" ] && cmp -s "$SRC/cloud/bashrc.si" "$HOME/.bashrc.si"; then
  note same "~/.bashrc.si"
else
  note "$([ -e "$HOME/.bashrc.si" ] && echo update || echo create)" "~/.bashrc.si"; changed=1
  [ "$DRY" = 1 ] || cp "$SRC/cloud/bashrc.si" "$HOME/.bashrc.si"
fi
SRCLINE="$WORK/srcline"
cat > "$SRCLINE" <<'SL'
# Interactive shortcuts. Managed by ai-git-commands/cloud/bootstrap.sh.
[ -r "$HOME/.bashrc.si" ] && . "$HOME/.bashrc.si"
SL
apply_block "$HOME/.bashrc" "$SRCLINE" "~/.bashrc"

# -------------------------------------------------------------------- wrap up
say ""
if [ "$DRY" = 1 ]; then
  say "  DRY RUN — nothing was written. Re-run without SI_DRY=1."
elif [ "$changed" = 0 ]; then
  say "  already in sync"
else
  say "  done. Start using them now with:  . ~/.profile && . ~/.bashrc"
  say "  backups, if any: ~/.profile.bak-* ~/.bashrc.bak-*"
fi
say ""
say "  Cloud Shell persists \$HOME, so this survives across sessions."
say "  A Qwiklabs VM does not — re-run the one-liner each lab (about two seconds)."
say ""
