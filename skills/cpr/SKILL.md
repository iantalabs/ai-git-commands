---
name: cpr
description: Commit, push and redeploy — cnp, then the repo's redeploy to both Macs (M16 and STD). Use when the user types cpr or /cpr, or says "commit push redeploy". Saying cpr is the user's explicit permission to commit, push, and replace the app on both Macs.
---

# /cpr — commit, push, redeploy

`cpr` is `cnp` plus a redeploy, so a commit made on one Mac never leaves the other
Mac's app behind. Saying `cpr` *is* the permission to commit, push, and quit and
replace the running app on both Macs. Don't ask again; do it.

This file lives in git at `ai-git-commands/skills/cpr/SKILL.md` (`git-cmds` on STD)
and is symlinked to `~/.claude/skills/cpr` on each machine. Edit it in the repo, never
in `~/.claude`.

## Steps

1. **Commit and push** exactly as the `cnp` skill says (`~/.claude/skills/cnp/SKILL.md`):
   its scope, secrets check, message style and push rules all apply. Anything after
   `cpr` is guidance for the message, as with `cnp`. If cnp stops (secrets, a push that
   can't fast-forward), stop here too — never deploy what isn't pushed.
2. **Redeploy**, from the repo root, if the repo has a redeploy script that knows both
   Macs:

   | Repo  | Command                                                     |
   |-------|-------------------------------------------------------------|
   | angel | `scripts/redeploy.sh --skip-phone --skip-watch --both-macs` |

   It builds once on this Mac, installs it here, then sends the same build to the other
   Mac and checks that it reports the same commit. It leaves the other Mac alone when
   that Mac already runs this commit. Run it in the foreground with a 10-minute
   timeout; a Mac build takes a few minutes.
   - `cpr all` also redeploys the iPhone and Watch: drop `--skip-phone --skip-watch`.
   - A repo not in the table gets a plain `cnp`; say there is no redeploy for it.
3. **If the redeploy fails**, the commit is still pushed. Show the failing lines from the
   script's output and its log path, and stop. Don't retry by hand over ssh.

## Report

Numbered, as `cnp` reports it: one line per commit (short SHA, subject, `main -> origin`).
Then a table of where each Mac stands, read from the script's summary:

| # | Status | Mac | Version | Commit    |
|---|--------|-----|---------|-----------|
| 1 | ✅ ok  | M16 | 1.0.79  | `abc1234` |
| 2 | ✅ ok  | STD | 1.0.79  | `abc1234` |

Then any changes left out (from cnp's scope). Nothing else.

## Don't

1. Don't redeploy when the commit or push failed.
2. Don't copy apps between Macs by hand; the script's swap is the safe one (it never
   overwrites the running app in place, and keeps the old copy in `/tmp/angel-old.app`).
3. Don't use `--dry-run` to "check first" — `cpr` is the go-ahead.
