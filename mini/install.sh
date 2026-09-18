#!/bin/bash
# install.sh — put the portable short commands on the mini.
#
# Run from the Studio (or any machine with `ssh mini`). DRY RUN BY DEFAULT:
# it shows every change and writes nothing until you pass --apply.
#
#   ./mini/install.sh                    dry run against `mini`
#   ./mini/install.sh --apply            do it
#   ./mini/install.sh --host other       a different ssh host alias
#   ./mini/install.sh --apply --verify   apply, then prove it over non-interactive ssh
#
# What it touches on the remote, and nothing else:
#   ~/bin/<cmd>     the commands in mini/manifest, mode 755
#   ~/.zshenv       a marked block: PATH, EDITOR, CMDI_DEST
#   ~/.zshrc.si     mini/zshrc.si, wholesale (managed file)
#   ~/.zshrc        ONE marked block appended at the end, sourcing ~/.zshrc.si
#
# It never overwrites ~/.zshrc. That file on the mini carries MacPorts, nvm and a
# sqlite Cellar PATH line, and `cp .zshrc ~/.zshrc` — what `uz` does on the Mac —
# would destroy all three silently. Every edit here is an idempotent marked
# block, and ~/.zshrc is backed up before it is touched at all.
set -euo pipefail

HOST="mini"
APPLY=0
VERIFY=0
REPO="$(cd "$(dirname "$0")/.." && pwd)"

while [ $# -gt 0 ]; do
  case "$1" in
    --apply)  APPLY=1; shift ;;
    --verify) VERIFY=1; shift ;;
    --host)   HOST="${2:?--host needs a value}"; shift 2 ;;
    -h|--help) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

SSH=(ssh -o BatchMode=yes -o ConnectTimeout=10 "$HOST")

say(){ printf '%s\n' "$*"; }
hdr(){ printf '\n== %s\n' "$*"; }

# ------------------------------------------------------------------ manifest
MANIFEST="$REPO/mini/manifest"
[ -f "$MANIFEST" ] || { echo "missing $MANIFEST" >&2; exit 1; }
CMDS=()
while read -r line; do
  line="${line%%#*}"; line="$(printf '%s' "$line" | tr -d '[:space:]')"
  [ -n "$line" ] && CMDS+=("$line")
done < "$MANIFEST"
[ ${#CMDS[@]} -gt 0 ] || { echo "manifest lists no commands" >&2; exit 1; }

MISSING=()
for c in "${CMDS[@]}"; do [ -f "$REPO/$c" ] || MISSING+=("$c"); done
if [ ${#MISSING[@]} -gt 0 ]; then
  echo "manifest names files that do not exist in $REPO: ${MISSING[*]}" >&2; exit 1
fi

hdr "plan"
say "host        $HOST"
say "mode        $([ $APPLY -eq 1 ] && echo APPLY || echo 'DRY RUN — nothing will be written')"
say "commands    ${#CMDS[@]} -> ~/bin"
say "            ${CMDS[*]}"

# ------------------------------------------------------------------ preflight
hdr "preflight"
if ! "${SSH[@]}" true 2>/dev/null; then
  echo "  FAIL  cannot ssh to '$HOST' — check tailscale status" >&2; exit 1
fi
say "  ok    ssh to $HOST"

REMOTE_ZSH="$("${SSH[@]}" 'command -v zsh || true' 2>/dev/null)"
[ -n "$REMOTE_ZSH" ] || { echo "  FAIL  no zsh on $HOST" >&2; exit 1; }
say "  ok    zsh at $REMOTE_ZSH"

# Report which of these will actually resolve to a runtime over there, so a
# dry run tells you what you are installing rather than just how many files.
hdr "runtime check on $HOST (non-interactive PATH)"
"${SSH[@]}" 'export PATH=$HOME/bin:/usr/local/bin:$PATH
for t in git docker nano python3 hugo; do
  printf "  %-5s %-8s %s\n" "$(command -v $t >/dev/null 2>&1 && echo ok || echo MISS)" "$t" "$(command -v $t 2>/dev/null)"
done' 2>/dev/null

# ------------------------------------------------------------------ payload
PAYLOAD="$(mktemp -d)"; trap 'rm -rf "$PAYLOAD"' EXIT
mkdir -p "$PAYLOAD/bin"
for c in "${CMDS[@]}"; do cp "$REPO/$c" "$PAYLOAD/bin/$c"; done
chmod 755 "$PAYLOAD/bin"/*
cp "$REPO/mini/zshenv"   "$PAYLOAD/zshenv"
cp "$REPO/mini/zshrc.si" "$PAYLOAD/zshrc.si"
TARB64="$(cd "$PAYLOAD" && LC_ALL=C tar -czf - . | base64)"

# ------------------------------------------------------------------ remote
REMOTE_RC=0
"${SSH[@]}" "APPLY=$APPLY bash -s" <<REMOTE_EOF || REMOTE_RC=$?
set -uo pipefail
MARK_B='# >>> si-shortcuts >>>'
MARK_E='# <<< si-shortcuts <<<'

STAGE="\$(mktemp -d)"; trap 'rm -rf "\$STAGE"' EXIT
printf '%s' '$TARB64' | base64 --decode | (cd "\$STAGE" && LC_ALL=C tar -xzf -)

changed=0
note(){ printf '  %-9s %s\n' "\$1" "\$2"; }

# ---- ~/bin ---------------------------------------------------------------
echo
echo "== ~/bin"
if [ ! -d "\$HOME/bin" ]; then
  note "create" "~/bin"; changed=1
  [ "\$APPLY" = 1 ] && mkdir -p "\$HOME/bin"
fi
for f in "\$STAGE"/bin/*; do
  n="\$(basename "\$f")"; t="\$HOME/bin/\$n"
  if [ ! -e "\$t" ]; then
    note "install" "~/bin/\$n"; changed=1
  elif ! cmp -s "\$f" "\$t"; then
    note "update" "~/bin/\$n"; changed=1
  else
    note "same" "~/bin/\$n"
    continue
  fi
  [ "\$APPLY" = 1 ] && install -m 755 "\$f" "\$t"
done

# ---- marked-block helper -------------------------------------------------
# Strips any previous block, then appends the new one at the END of the file so
# our definitions override anything defined earlier (the mini's existing ~/.zshrc
# has its own md()/mf(), and mf() there calls a VS Code that is not installed).
apply_block(){ # args: target, content-file, label
  t="\$1"; c="\$2"; label="\$3"
  [ -e "\$t" ] || { [ "\$APPLY" = 1 ] && : > "\$t"; }
  cur=""; [ -e "\$t" ] && cur="\$(cat "\$t")"
  stripped="\$(printf '%s\n' "\$cur" | awk -v b="\$MARK_B" -v e="\$MARK_E" '
    \$0==b {skip=1; next} \$0==e {skip=0; next} !skip {print}')"
  new="\$(printf '%s\n\n%s\n%s\n%s\n' "\$stripped" "\$MARK_B" "\$(cat "\$c")" "\$MARK_E" \
          | awk 'BEGIN{blank=0} /^\$/{blank++; if(blank>2) next; print; next} {blank=0; print}')"
  if [ "\$cur" = "\$new" ]; then note "same" "\$label"; return; fi
  note "\$([ -s "\$t" ] && echo update || echo create)" "\$label"; changed=1
  if [ "\$APPLY" = 1 ]; then
    [ -s "\$t" ] && cp "\$t" "\$t.bak-\$(date +%Y%m%d-%H%M%S)"
    printf '%s\n' "\$new" > "\$t"
  fi
}

echo
echo "== ~/.zshenv   (read by EVERY zsh, including \\\`ssh $HOST 'cmd'\\\`)"
apply_block "\$HOME/.zshenv" "\$STAGE/zshenv" "~/.zshenv"

echo
echo "== ~/.zshrc.si (managed, interactive aliases)"
if [ -e "\$HOME/.zshrc.si" ] && cmp -s "\$STAGE/zshrc.si" "\$HOME/.zshrc.si"; then
  note "same" "~/.zshrc.si"
else
  note "\$([ -e "\$HOME/.zshrc.si" ] && echo update || echo create)" "~/.zshrc.si"; changed=1
  [ "\$APPLY" = 1 ] && install -m 644 "\$STAGE/zshrc.si" "\$HOME/.zshrc.si"
fi

echo
echo "== ~/.zshrc    (append-only; your file is never overwritten)"
SRC="\$STAGE/srcline"
cat > "\$SRC" <<'SRCLINE'
# Interactive shortcuts. Managed by ai-git-commands/mini/install.sh.
# Appended LAST on purpose: it overrides the md()/mf() defined earlier in this
# file, whose mf() opens VS Code, which is not installed on this machine.
[ -r "\$HOME/.zshrc.si" ] && source "\$HOME/.zshrc.si"
SRCLINE
apply_block "\$HOME/.zshrc" "\$SRC" "~/.zshrc"

echo
if [ "\$changed" = 0 ]; then
  echo "  nothing to do — already in sync"
elif [ "\$APPLY" = 1 ]; then
  echo "  applied. backups: ~/.zshrc.bak-* ~/.zshenv.bak-*"
else
  echo "  DRY RUN — nothing was written. Re-run with --apply."
fi

# Aliases the mini's own ~/.zshrc defines for tools that are not installed.
# install.sh does not touch them: it only ever appends. Flagged, not fixed.
echo
STALE=""
for a in kubectl deno code lsd; do
  grep -qE "^\s*(alias [a-z0-9]+=\"?'?\s*)?\b\$a\b" "\$HOME/.zshrc" 2>/dev/null \
    && ! command -v "\$a" >/dev/null 2>&1 && STALE="\$STALE \$a"
done
[ -n "\$STALE" ] && echo "  note: ~/.zshrc still has aliases for missing tools:\$STALE (left alone — yours to prune)"
exit 0
REMOTE_EOF

# ------------------------------------------------------------------ verify
if [ $VERIFY -eq 1 ]; then
  hdr "verify — non-interactive ssh, the path that actually matters"
  "${SSH[@]}" '
    fails=0
    for c in ga gc gl gp gs gv gx de dl dr dri md mf cmdi sed-section; do
      if command -v $c >/dev/null 2>&1; then printf "  ok    %s -> %s\n" "$c" "$(command -v $c)"
      else printf "  FAIL  %s not on PATH\n" "$c"; fails=$((fails+1)); fi
    done
    if docker ps >/dev/null 2>&1; then echo "  ok    docker reachable without a hand-written PATH"
    else echo "  FAIL  docker still not reachable"; fails=$((fails+1)); fi
    if [ -d "$HOME/vsc-jobs/.git" ]; then
      cd "$HOME/vsc-jobs" && gs >/dev/null 2>&1 \
        && echo "  ok    gs runs end to end in ~/vsc-jobs" \
        || { echo "  FAIL  gs did not run"; fails=$((fails+1)); }
    fi
    echo; [ $fails -eq 0 ] && echo "  all checks passed" || echo "  $fails FAILED"
    exit $fails' 2>/dev/null || REMOTE_RC=$?
fi

exit $REMOTE_RC
