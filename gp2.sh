#!/usr/bin/env bash
set -euo pipefail

# gp2.sh — Push to both GitHub (origin) and GitLab (gitlab) safely.
#
# Avoids the rebase ping-pong by:
#   1. Fetching both remotes first
#   2. Merging (never rebasing) any remote-only commits
#   3. Pushing to both in one go
#
# Usage:
#   ./gp2.sh                      # push current branch (default: main)
#   ./gp2.sh feature/foo          # push a specific branch
#   ./gp2.sh --tags               # ...and every tag
#   ./gp2.sh --tag ep21-run       # ...and one named tag
#   ./gp2.sh feature/foo --tags   # both
#
# ⚠ WHY TAGS ARE PUSHED EXPLICITLY, NOT WITH --follow-tags.
# --follow-tags only pushes ANNOTATED tags. Most epN-run tags in this repo are
# LIGHTWEIGHT (ep18-run, ep19-run, ep20-run are plain commit refs; only ep17-run
# is annotated), so --follow-tags silently skips them. That is how ep19-run sat
# unpushed for two weeks. episodes.json `ref` is load-bearing -- T1 is stripped
# after every episode, so the tag is the only handle on that state -- which makes
# a silently-skipped tag a real loss, not an inconvenience.
#
# The DEFAULT is unchanged: no tags unless asked. Pushing every local tag by
# default would publish scratch and experiment tags too.

BRANCH=""
PUSH_ALL_TAGS=0
NAMED_TAGS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --tags) PUSH_ALL_TAGS=1; shift ;;
    --tag)  [ $# -ge 2 ] || { echo "✗ --tag needs a tag name"; exit 2; }
            NAMED_TAGS+=("$2"); shift 2 ;;
    -h|--help) sed -n '4,27p' "$0"; exit 0 ;;
    -*) echo "✗ unknown option: $1"; exit 2 ;;
    *)  [ -z "$BRANCH" ] || { echo "✗ more than one branch given: $BRANCH and $1"; exit 2; }
        BRANCH="$1"; shift ;;
  esac
done

BRANCH="${BRANCH:-$(git symbolic-ref --short HEAD)}"
REMOTE_GH="origin"
REMOTE_GL="gitlab"

# Fail early on a tag that does not exist locally, rather than after the branch
# push has already happened.
for t in ${NAMED_TAGS+"${NAMED_TAGS[@]}"}; do
  git rev-parse -q --verify "refs/tags/$t" >/dev/null || { echo "✗ no such local tag: $t"; exit 2; }
done

echo "── gp2: pushing '$BRANCH' to GitHub + GitLab ──"
echo ""

# 1. Fetch both remotes so we know what's out there
echo "Fetching $REMOTE_GH..."
git fetch "$REMOTE_GH" "$BRANCH" 2>/dev/null || echo "  (no remote branch on $REMOTE_GH yet)"
echo "Fetching $REMOTE_GL..."
git fetch "$REMOTE_GL" "$BRANCH" 2>/dev/null || echo "  (no remote branch on $REMOTE_GL yet)"
echo ""

# 2. Merge any remote-ahead commits (--no-rebase to avoid hash rewriting)
BEHIND_GH=$(git rev-list --count "HEAD..${REMOTE_GH}/${BRANCH}" 2>/dev/null || echo 0)
BEHIND_GL=$(git rev-list --count "HEAD..${REMOTE_GL}/${BRANCH}" 2>/dev/null || echo 0)

if [ "$BEHIND_GH" -gt 0 ]; then
  echo "GitHub is $BEHIND_GH commit(s) ahead — merging..."
  git merge --no-edit "${REMOTE_GH}/${BRANCH}" || { echo "✗ Merge conflict with GitHub. Resolve and re-run."; exit 1; }
  echo ""
fi

if [ "$BEHIND_GL" -gt 0 ]; then
  echo "GitLab is $BEHIND_GL commit(s) ahead — merging..."
  git merge --no-edit "${REMOTE_GL}/${BRANCH}" || { echo "✗ Merge conflict with GitLab. Resolve and re-run."; exit 1; }
  echo ""
fi

# 3. Push to both
echo "Pushing to GitHub ($REMOTE_GH)..."
git push "$REMOTE_GH" "$BRANCH" || { echo "✗ Push to GitHub failed."; exit 1; }

echo "Pushing to GitLab ($REMOTE_GL)..."
git push "$REMOTE_GL" "$BRANCH" || { echo "✗ Push to GitLab failed."; exit 1; }

# 4. Tags — only when asked, and always by explicit ref (see the note above).
if [ "$PUSH_ALL_TAGS" -eq 1 ] || [ ${#NAMED_TAGS[@]} -gt 0 ]; then
  echo ""
  for REMOTE in "$REMOTE_GH" "$REMOTE_GL"; do
    if [ "$PUSH_ALL_TAGS" -eq 1 ]; then
      echo "Pushing all tags to $REMOTE..."
      git push "$REMOTE" --tags || { echo "✗ Tag push to $REMOTE failed."; exit 1; }
    else
      echo "Pushing tag(s) to $REMOTE: ${NAMED_TAGS[*]}"
      git push "$REMOTE" "${NAMED_TAGS[@]}" || { echo "✗ Tag push to $REMOTE failed."; exit 1; }
    fi
  done
fi

echo ""
if [ "$PUSH_ALL_TAGS" -eq 1 ]; then
  echo "✓ Both remotes synced on '$BRANCH' + all tags."
elif [ ${#NAMED_TAGS[@]} -gt 0 ]; then
  echo "✓ Both remotes synced on '$BRANCH' + tag(s): ${NAMED_TAGS[*]}."
else
  echo "✓ Both remotes synced on '$BRANCH'.  (tags NOT pushed — use --tags or --tag <name>)"
fi
