---
name: ingest
description: Ingest the last link posted in a Matrix room (a YouTube video) into a 3AI Desk skill spreadsheet — frames every 10s, chapters, transcript — and reply in that message's thread with the new skill's link. Use when the user types /ingest, or says "ingest last link from <room>", "ingest the video I posted in AI-Tech", or similar. YouTube only in v1; unencrypted rooms only.
---

# /ingest — a link from a room becomes a desk skill

The operator drops a YouTube link in a Matrix room; you turn it into a skill
spreadsheet on the desk and answer in that message's thread. It runs the same
editor-server ingest as the desk's YouTube panel, so the result is identical.

This file and its script live in git at `ai-git-commands/skills/ingest/` (`git-cmds` on
STD) and the folder is symlinked to `~/.claude/skills/ingest` on each machine, like `cnp`.
Edit them in the repo, never in `~/.claude`. They moved out of 3aidesk on 2026-09-30: the
desk checkout can be on any branch, and the skill must not depend on which.

## Run it

```bash
node ~/.claude/skills/ingest/ingest-from-matrix.js --room <room> [flags]
```

| They type | Run |
|---|---|
| `/ingest`, `ingest last link from AI-Tech`, `latest YT from SI Fit` | `--room AI-Tech` / `--room "SI Fit"` (AI-Tech is the default). It takes the newest **YouTube** link and names any newer non-YouTube links it skipped |
| `ingest last link from <room>` | `--room <room>`: the room's name, or its `!id` |
| `… every 5 seconds` | add `--interval 5` (default 10) |
| `ingest <youtube url> in <room>` | `--room <room> --url <url>`: that link, answered in the room |
| `ingest <youtube url>` (no room) | `--url <url>` only: ingested, nothing posted |
| `… again`, `… anyway` | add `--force`: the video is already on the desk |
| `what would ingest do?` | add `--dry-run`: title, length, chapters, frame count; nothing posted |

1. **Dry-run first when the request is ambiguous** (which room, which link). Otherwise
   run it straight away — posting the reply in the room is the point of the command.
2. **It takes minutes** (download, then frames per chapter: ~1 min per 10 min of video
   at 10s). Say "working in background on the ingest …", run it with
   `run_in_background`, and report when it finishes.
3. **Report** the skill link it prints (`http://localhost:1314/skills/skillN/`), the
   row/cell/frame counts, and any row errors. The room already has the same in the thread.

## Before it runs

- **The editor-server must be up** on :3005. If the script says it is not answering,
  run `aidesk start` (see the 3aidesk README) and retry.
- **Any 3aidesk branch works.** The new skill's number is free across every branch and
  every media dir on L256 (3aidesk `editor-server/skills/skill-ids.js`, 2026-09-30), and its
  content lands on whichever branch is checked out — say which in the report, since that is
  the branch the skill has to be committed on.
- `AIDESK_DIR` overrides where 3aidesk is (default `~/workspace/iantalabs/3aidesk`);
  `MEDIA_DIR` where the media root is (default `/Volumes/L256/il30mar26`).

## When it fails

1. **`FIX: yt-dlp is out of date`**: run the `pip install` line it prints, then retry.
   YouTube breaks old yt-dlp versions every few months; this happened 2026-03 and 2026-09.
2. **`… has no invite to one`**: `@claude:saltm.w3ai.org` needs an invite to that room.
   A pending invite is accepted automatically when the room is unencrypted, so "I
   invited you to X, ingest from it" needs no extra step.
3. **`is encrypted`**: this reads the plain API only; ask for an unencrypted room.
4. **`Already on the desk`**: the video was ingested before, on this branch or (by its
   `source.json` on L256) on another; the reply links the skill.
   Only re-run with `--force` if they asked for another copy.
5. **`no YouTube link`**: none among the room's last 250 messages. v1 handles YouTube
   only (PDFs, courses and frame selection are todo #26 and later); tell them.

Credentials are `@claude`'s, the account `/post` and `/look` use, read from
`~/.claude/matrix-post.json` → `secrets_from`. Not the desk bot `@3aidesk`, which is a
different user.
6. **`media dir … belongs to …` / `has no source.json`**: the ingester refused to put this
   video into a media folder that holds another source. That is the guard working: report
   it, don't delete the folder.
