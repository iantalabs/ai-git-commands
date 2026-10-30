---
name: cnp
description: Commit and push the current repo. Use when the user types cnp or /cnp, or says "commit and push". Saying cnp is the user's explicit permission to commit and push every uncommitted change in this repo.
---

# /cnp — commit and push

`cnp` means **commit and push** — in the terminal (`gx`'s successor, todo #8 in
ncol) and here. When the user types `cnp` or `/cnp`, that *is* the explicit permission
to commit and push that a CLAUDE.md or the harness asks for. Don't ask again; do it.

This file lives in git at `ai-git-commands/skills/cnp/SKILL.md` and is symlinked to
`~/.claude/skills/cnp` on each machine (M16, STD). Edit it in the repo, never in
`~/.claude`.

## Scope

- **The repo the session is working in.** If this session also changed other repos,
  commit and push each of them the same way, one after another, and say so.
- **Every uncommitted change**, this session's or not (the operator, 2026-10-17: "it is just
  2 of us on both macs in all repos"). Nobody else works in these repos, so a change this
  session didn't make is something left behind — the other Mac's session, a script's log
  lines written after its own commit — never someone's work in progress. Look at each one
  and commit it in its own commit, with a message that says what it is. Still add paths by
  name, never `git add -A`, and the secrets check below still applies to every file.
- **The current branch**, as the repo already works. Do not create a branch unless the
  repo's CLAUDE.md says to.
- Anything after `cnp` is guidance for the message (`cnp the legend merge`).

## Steps

1. **Look.** `git status --short`, `git diff --stat`, and `git log -5` for the repo's
   message style.
2. **Stop on secrets.** If a file to be committed looks like a credential — `.env*`,
   `secrets/`, `*token*`, `*.pem`, `*.key`, `id_*`, a `.json` holding an `access_token` —
   do not commit it. Say which, and ask.
3. **Draft the message from the repo's own records**, which is what `gx`'s clipboard
   used to carry by hand. In order of strength:
   1. rows the diff strikes through or adds in `docs/project_notes/todos.md`
      ("✅ #6 `ncol` shell command", "Todo #8: cnp")
   2. status changes in `docs/roadmap.md` or a `docs/handoff-*.md` table
   3. the headings of new docs in the diff
   4. what this session did, from the conversation; for a change it didn't make, what
      the diff itself shows (`git diff`, `git log -3 -- <path>`)
4. **Write it in the repo's style**, from `git log`: a subject that reads as a sentence
   and a body on *why*, where the log does that; a repo whose log is terse gets a terse
   message. End with the co-author line the harness gives. Split into several commits
   when the changes are separate things.
5. **Align the tables** in each `.md` file about to be committed, the way the operator wants
   them in every repo (`~/.claude/CLAUDE.md`, "Markdown tables"):
   `node ~/workspace/iantalabs/aipmo/tools/md-tables/format-tables.mjs <files.md>`. It
   changes only the padding inside tables, so it goes in the same commit. Leave out
   Markdown a program writes (fixtures, archives, captured transcripts). If aipmo isn't
   cloned on this Mac, say so in the report and commit anyway.
6. **Commit** with `git add <paths>` then `git commit -F -` (a heredoc). Never `--amend`,
   never `--no-verify`. If a hook fails, fix the cause and make a new commit.
7. **Push.** `git fetch` first; if the branch is behind, `git pull --ff-only`, and if that
   fails, stop and say so. Never force. No upstream: `git push -u origin <branch>`.
   Then, if the repo has a remote named `mini` (`git remote | grep -qx mini`), push the
   same branch to it: `git push mini <branch>`. That remote is a bare copy on the family
   server, and it has only what is pushed to it. If this push fails because the mini is
   off or unreachable, or it is rejected, say so in the report and carry on. The commit
   is on origin, so the push has not failed. Never force it.
8. **Report**, numbered, one line per commit: short SHA, subject, and where it went
   (`main -> origin, mini`). Then anything still uncommitted, numbered, and why: only a
   file held back by the secrets check. Nothing else.

## Don't

1. Don't commit or push when the user only asked a question about committing.
2. Don't touch files outside the repo to make the commit work (git config, hooks).
3. Don't rewrite history that is already pushed.
