# ToDos — backlog with effort estimates

Deferred work, each with a rough estimate so an item can be slotted into a session. The format
is [vsum's](../../../iantalabs/vsum/docs/project_notes/todos.md) (ncol's, which is 3aidesk's with
*St* next to *Pri*), at the same path, so aipmo's inbox and the desk read it without a second
dialect.

**Legend** — *Pri* = priority (P1 = do first). *St* = status, one icon from the status legend
(`3aidesk/docs/roadmap.md`): ✅ done, 🧪 being tested, 🔨 built and waiting on a check, 🟡 under
way, 📋 a section says what to build, ⏸ waiting on a decision, ⬜ an idea with no spec yet.
*Effort* = focused build hours. *Tokens* = session throughput, order-of-magnitude. *Context* =
peak fraction of a ~200k-token window. **The matrix holds open items only**; a done one moves to
**Closed** with the date, and its section stays as the record.

## Scheduling matrix (active)

| Pri | St  | #   | Item                                                       | Effort | Tokens    | Context | Pairing and notes |
| --- | --- | --- | ---------------------------------------------------------- | ------ | --------- | ------- | ----------------- |
| P2  | 🔨  | 1   | `xcnp`: commit a session's handoffs in other repos, safely | ~2h    | ~150–250k | ~25%    | Built 2026-11-10 on STD and tested in a sandbox (see the section). Left: M16 install, and the first real handoff (vsum → aipmo) with its Matrix notice and no prompt. Touches `skills/cnp`; aipmo #22 keeps its log |

## Closed

None yet.

---

## #1 — `xcnp`: commit a session's handoffs in other repos, safely

**Why:** it recurs. A session working in one repo writes a handoff into another
(`docs/handoff-*.md`, a todo row), and then either leaves it untracked for that repo's next
session, or commits there by hand. On 2026-10-28 vsum's session ran `cnp` in aipmo and 3aidesk
as the `cnp` skill says it may, and Claude Code's auto-mode permission check refused it as a
write to an outside system: it reads the command, not the skill, and an unscoped commit and push
into another repo is what it should stop. Naming the repos in the request ("cnp aipmo 3aidesk")
got it through; the operator asked for a mechanism that doesn't depend on that.

**What industry practice says, applied here:**

1. **The owner merges its own code** (CODEOWNERS, protected branches): code in another repo
   travels as a handoff, never as a commit from outside.
2. **Changes across many repos go in as proposals each repo's own checks decide on**
   (Sourcegraph Batch Changes, multi-gitter, turbolift, all-repos): the coordinator proposes,
   it doesn't push code past the owner.
3. **Plan, then apply** (Terraform): the exact list of repo, file, branch and message is shown,
   approved once, and applied only if nothing changed in between.
4. **Least privilege, an allowlist:** known repos, harmless paths.
5. **Each target pulls its own deploy** (GitOps: Argo, Flux): a repo redeploys from its own
   `cpr` or watcher, never from another repo's session.
6. **An audit trail and a notice:** every cross-repo commit logged, and the owner told.

**What to build:**

1. **`xcnp`**, a script here beside `menubar`, with a skill in `skills/xcnp/` symlinked like
   `cnp`'s. `xcnp <repo>… [--from <repo>]` commits and pushes, in each named repo, **only**
   `docs/handoff-*.md` and added rows in `docs/project_notes/todos.md`.
   1. A repo must be in aipmo's `portfolio.yml` (or a checkout under `~/workspace/iantalabs`).
   2. Any other change in that repo is left alone and named; a staged file not on the list stops
      it for that repo.
   3. The cnp secrets check on every file; then fetch, fast-forward only, push origin, then `mini`
      when the remote exists (its failure reported, not fatal). Never force, never amend.
   4. On the repo's current branch, named in the report (3aidesk works on `ingest-from-matrix`).
   5. The message: "Handoff from <from>: <the handoff's title>", and the co-author line.
2. **Plan, then apply:** `xcnp --plan <repo>…` prints each repo, file, branch and message, and
   writes the plan with each file's hash; `xcnp --apply` runs exactly that plan and refuses a
   file that changed since.
3. **The notice:** after a push, a line in the target repo's Matrix room through
   `ncol/tools/matrix-post` ("handoff from vsum: docs/handoff-ai-desk-sections.md, ed681e3"),
   and a line appended to aipmo's cross-repo log (its todo #22) with the date, both commits and
   the file.
4. **One allow rule** in `~/.claude/settings.json` on both Macs for `xcnp` alone, so the check
   doesn't stop it; a raw `git -C <other repo> push` stays blocked, which is the protection.
5. **`skills/cnp`** reworded: cnp commits the current repo; `cnp all` or `cnp <repo>…` hands the
   other repos to `xcnp`. Code a session changed in another repo stays a handoff for that repo's
   session and its own `cpr`; xcnp says so and lists it.

**Built** 2026-11-10: [`xcnp`](../../xcnp), [`skills/xcnp`](../../skills/xcnp/SKILL.md),
`skills/cnp` reworded, `"Bash(xcnp *)"` in STD's `~/.claude/settings.json`. Two choices the
spec left open: a todos.md counts as "added rows" when HEAD's version survives in it in
order, table padding ignored (so a formatter re-pad still passes); and the log is a new
`docs/cross-repo-log.md` in aipmo, committed by xcnp itself, since #22's `cross-repo.md`
(the index of open X rows) isn't built and is a different thing. A branch with unpushed
commits of its own is refused: pushing them would push the owner's work.

Tested in a sandbox (bare remotes, a fake room): plan lists the handoff and an added row
(re-padded table) and names `app.js` as left; a handoff edited after the plan is refused;
apply commits, pushes origin and mini, sends the notice, writes and pushes the log row; a
changed row, a staged code file, an unpushed commit and a GitHub token each stop or hold
back as they should; a branch behind its upstream is fast-forwarded first. A `--plan` on
the real aipmo, 3aidesk, ncol and vsum listed only ncol's added todo #74.

**Left:** on M16, the two symlinks and the allow rule (README, `xcnp`); and the real check
below, which needs a real handoff.

**Validate:** by check. A handoff written from vsum into aipmo: `xcnp --plan aipmo` lists only it;
a code file changed beside it is named and left; `--apply` commits and pushes it with no
permission prompt, the notice appears in aipmo's room and the log has its line; a file edited
between plan and apply is refused.
