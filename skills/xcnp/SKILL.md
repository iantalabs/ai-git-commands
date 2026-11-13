---
name: xcnp
description: Commit and push the handoffs this session wrote into other repos (docs/handoff-*.md, added todo rows), and nothing else there. Use when the user types xcnp or /xcnp, "cnp all", or "cnp <other repo>…", or when cnp finds this session changed other repos. Saying it is the user's explicit permission for those repos.
---

# /xcnp — commit a session's handoffs in other repos, safely

A session in one repo often writes into another: a `docs/handoff-*.md`, a row and section in
its `docs/project_notes/todos.md`. Running `cnp` there, a raw `git -C <other repo> push`, is
what Claude Code's permission check should stop, and does. `xcnp` is the one command allowed
to cross that line, and it carries only handoffs across it.

This file lives in git at `ai-git-commands/skills/xcnp/SKILL.md`, symlinked to
`~/.claude/skills/xcnp`; the script is `ai-git-commands/xcnp`, symlinked to
`~/.local/bin/xcnp`. Edit them in the repo. `xcnp --help` says the rest.

## What it commits

In each named repo, **only**:

1. `docs/handoff-*.md`, new or changed;
2. `docs/project_notes/todos.md`, when rows and sections were **added** and none changed or
   removed (a table the formatter re-padded still counts as added).

Everything else there is named in the plan and left for that repo's own session: code crosses
a repo line as a handoff, and the owner's own `cnp`/`cpr` commits and ships it. A file not on
the list but staged, a branch with unpushed commits of its own, a detached HEAD, or a repo
outside `~/workspace/iantalabs` and aipmo's `portfolio.yml` stops that repo.

It also reads aipmo's `docs/cross-repo.md`: for each todo it commits (the repo, for a handoff
alone) that no X row cites, the plan and the report say `no X row for <repo> #N`. It never
writes the row; aipmo is the session's to edit, as the log is.

## Steps

1. **Name the repos** this session wrote into: from the conversation, and `git -C <repo>
   status --short` for the ones it may have touched. Not the session's own repo; that is `cnp`.
2. **Plan.** `xcnp --plan <repo>… --coauthor "<the co-author line's name and email>"`, the
   co-author the harness gives for commits (`Claude Opus 5.5 <noreply@anthropic.com>`).
   `--from <repo>` only when the cwd isn't the session's repo. Read the plan: each repo, its
   branch, the files and the message, what is left and why.
3. **Check it against what this session wrote.** A handoff the plan shows that this session
   didn't write is another session's: still fine to commit (the operator, 2026-10-17: "it is
   just 2 of us"), but say so. A file this session wrote that the plan leaves (code, a changed
   row) stays uncommitted: it is a handoff for that repo's session. Don't commit it any other way.
4. **Apply.** `xcnp --apply` runs exactly the saved plan. It refuses a repo whose files, branch
   or HEAD changed since; plan again then. It fetches, fast-forwards, commits, pushes origin and
   then `mini`, posts a notice in the repo's Matrix room, and adds a row to aipmo's
   `docs/cross-repo-log.md`, committed there.
5. **Report**, numbered, what `xcnp` printed: each repo's short SHA, message and where it went,
   each refusal and why, the log commit, each `no X row for <repo> #N` line (tell the session
   to add that row to aipmo's `docs/cross-repo.md`); then what was left in each repo, so the operator
   knows what waits for whose session.

`xcnp <repo>…` without `--plan` plans and applies in one go; use it when the user has already
seen the list (they named the repos and the files).

## Don't

1. Don't run `git commit` or `git push` in another repo yourself, not even with `-C`: that is
   the bypass this exists to close.
2. Don't widen what xcnp takes by staging files for it; a staged file not on its list stops it.
3. Don't redeploy another repo. Its own `cpr` does that, from its own session.
