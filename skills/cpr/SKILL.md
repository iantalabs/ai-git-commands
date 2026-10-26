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
   can't fast-forward), stop here too — never deploy what isn't pushed. A failed push
   to the `mini` remote is not a stop; origin is what the other Mac pulls from.
2. **Redeploy**, from the repo root, if the repo has a redeploy script that knows both
   Macs:

   | Repo  | Command                                                     |
   |-------|-------------------------------------------------------------|
   | angel | `scripts/redeploy.sh --skip-phone --skip-watch --both-macs` |
   | ncol  | `scripts/redeploy.sh --both-macs`                           |
   | mural | `scripts/redeploy.sh --both-macs`                           |
   | vsc-jobs | `scripts/redeploy.sh --both-macs`                        |
   | other | `scripts/redeploy.sh --both-macs`, when the script exists   |

   Each one deploys here, then gets the other Mac onto the same commit and checks that
   it reports it. It leaves the other Mac alone when that Mac already runs this commit.
   Run it in the foreground with a 10-minute timeout; a Mac build takes a few minutes.
   - **angel** builds once here and sends the same app over ssh; its version is in the
     app's footer. `cpr all` also redeploys the iPhone and Watch: drop
     `--skip-phone --skip-watch`.
   - **ncol** builds the wall on each Mac from its own checkout (the other Mac pulls
     `--ff-only`), restarts the LaunchAgent only when the server's code changed, and asks
     each Mac's `:8080` for `/modules/version.json`. Its version is in the wall's tab title.
   - **mural** runs from each Mac's own checkout: the other Mac pulls `--ff-only`, and each
     rebuilds and reopens its menu bar app (`~/Applications/Mural.app`), stamped with the
     commit it reports (shown in the menu). Open mural pages reload when page code changed;
     the server is never restarted mid-call, and a "note" line says when it needs `mural`.
     Each Mac's displays and features are in the repo's `machines/<Mac>.env`.
   - **vsc-jobs** runs jobsops from each Mac's own checkout, as two LaunchAgents (the
     runner on `127.0.0.1:8787`, `hugo server` on `1316`, installed by the script where
     missing). The runner restarts when the commit it reports isn't HEAD, **never while a
     tailor is running** (a "note" line says so); the site only when `hugo.yaml` changed.
     The other Mac pulls `--ff-only`, and **a dirty checkout there is named and skipped**,
     never stashed: its site writes `pipeline.json`. Then the mini's tailnet copy, through
     `jobsops/deploy.sh` and its nginx guard; `--no-mini` leaves it. The version and commit
     are in the jobsops footer and the runner's `/health`.
   - **Any other repo** joins by having a `scripts/redeploy.sh` that takes `--both-macs`
     and ends with a summary naming each Mac's version and commit. No script means a
     plain `cnp`; say there is no redeploy for it.
3. **If the redeploy fails**, the commit is still pushed. Show the failing lines from the
   script's output and its log path, and stop. Don't retry by hand over ssh.

## Report

Numbered, as `cnp` reports it: one line per commit (short SHA, subject, `main -> origin`).
Then a table of where each Mac stands, read from the script's summary:

| # | Status | Mac | Version | Commit    |
|---|--------|-----|---------|-----------|
| 1 | ✅ ok  | M16 | 1.0.79  | `abc1234` |
| 2 | ✅ ok  | STD | 1.0.79  | `abc1234` |

Then anything still uncommitted (only what cnp's secrets check held back). Nothing else.

## Don't

1. Don't redeploy when the commit or push failed.
2. Don't copy apps between Macs by hand; the script's swap is the safe one (it never
   overwrites the running app in place, and keeps the old copy in `/tmp/angel-old.app`).
3. Don't use `--dry-run` to "check first" — `cpr` is the go-ahead.
