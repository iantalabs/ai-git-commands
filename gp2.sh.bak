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
#   ./gp2.sh              # push current branch (default: main)
#   ./gp2.sh feature/foo  # push a specific branch

BRANCH="${1:-$(git symbolic-ref --short HEAD)}"
REMOTE_GH="origin"
REMOTE_GL="gitlab"

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

echo ""
echo "✓ Both remotes synced on '$BRANCH'."
