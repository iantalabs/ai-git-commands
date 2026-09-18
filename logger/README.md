# slog — terminal session logger for cloud labs

Records a whole Cloud Skills Boost / Qwiklabs session — commands *and* their
output — then packs it so you can carry it back to M16/STD instead of
copy-pasting scrollback. Later, `slog-split` turns it into a per-task reference.

## In the lab

```bash
curl -fsSL https://raw.githubusercontent.com/W3AI/ai-git-commands/master/cloud/bootstrap.sh | sh
. ~/.profile

slog start gke-autopilot           # begins recording, drops you in a subshell
slog mark "Task 1: Set up"         # stamp each task as you reach it
... work normally ...
slog mark "Task 2: Create a cluster"
... work normally ...
exit                               # ends the recording
slog push                          # packs it and gets it off the box
```

`slog mark` is the part that makes the log useful later. Everything else is
recorded whether you think about it or not; the marks are what let the split be
exact rather than guesswork.

## Getting it back

`slog push` picks the path for you:

- **In Cloud Shell** — runs `cloudshell download`, which lands the tarball in
  your browser's Downloads on M16/STD. No bucket, no token, no third party.
- **On a lab GCE VM** — prints the two lines to run *in Cloud Shell*
  (`gcloud compute scp` then `cloudshell download`).

Deliberately no transfer.sh / file.io / gist upload. A lab transcript can carry
project ids, IPs and occasionally a token echoed by a setup step, and those
services are public by URL.

## On M16 / STD

```bash
slog-split ~/Downloads/gke-autopilot-20260918-084530.tgz
slog-split <session> --tasks tasks.txt      # titles pasted off the lab page
slog-split <session> --commands-only        # just the cheat sheet
```

Writes `<session>.md`: a metadata table, the numbered lab tasks, a **Commands**
section (every command in order, with `[exit N]` on the ones that failed), and
the transcript split under one heading per mark.

## What is in a session

```
~/si-logs/<name>-<timestamp>/
  transcript.raw    what script(1) captured, escape codes and all
  transcript.log    same, ANSI stripped, progress bars collapsed
  commands.tsv      timestamp \t exit-status \t command
  meta              session, start/end, host, user, project
```

Two artifacts rather than one, because splitting a raw transcript into steps
means guessing where the prompt ends and the output begins, and lab images vary.
The `PROMPT_COMMAND` hook records each command and its exit status exactly, so
`slog-split` never parses a prompt.

## Notes and limits

- **`script` differs by platform.** util-linux takes `script -q -c CMD file`,
  BSD takes `script -q file CMD`. `slog` detects which and uses the right form,
  so it works on a lab VM and on macOS.
- **Heredoc bodies** land in the transcript but only the opening line
  (`cat <<'Y'`) reaches `commands.tsv` — bash history records it that way.
- **The first hook call is swallowed** on purpose. It fires before you type
  anything, by which point bash has loaded `~/.bash_history`, so it would
  otherwise record the last command of your *previous* session as the first
  command of this one.
- **`slog` commands are filtered** out of `commands.tsv`; the bookkeeping is not
  lab work.
- **Secrets.** The transcript captures whatever the terminal showed. If a lab
  echoes a key, it is in the log. Skim before committing one to a repo.
- **Verified** end to end on macOS through a real pty. The util-linux `script`
  branch and `cloudshell download` are written from their documented behaviour
  and want one confirming run in an actual lab.
