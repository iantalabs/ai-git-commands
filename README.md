# git & devops fasm - frequent shortcuts & mnemonics :-)

- **md** / make dir < dirName > && cd / .zshrc
- **mf** / make file < fileName > && code / .zshrc
- **cmdi** / install < cmdFile > in /usr/local/bin
- **rifu** / Formats Udemy course.txt for Smart sheet template
- **rifa** / Formats ACG course.txt for Smart sheet template

## sed

- **sed-section** / replace Section with ## Section in txt files
- **sed-xmin** / replace min & \n strings in txt files - Not Tested !!

## kubernetes

- **ka** / kubectl apply -f < yaml >
- **kp** / kubectl get pods
- **kd** / alias kd="kubectl get deployments" in ~/.zshrc
- **ks** / alias ks="kubectl get services" in ~/.zshrc
- **ke** / kubectl exec -it < podName > < cmd ~sh >
- **kl** / kubectl logs < podName >
- **kdp** / kubectl delete pod < podName >
- **kdd** / kubectl delete deployment < deplName >
- **kdesp** / kubectl describe pod < podName >
- **kdesd** / kubectl describe deployment < deplName >
- **kdess** / kubectl describe service < srvlName >
- **kr** / kubectl rollout restart deployment < deplName >

## docker

- **db** / docker build -t dockerUser/< image tag > .
- **dr** / docker run < image tag or id >
- **dri** / docker run -it < image tag > < cmd ~sh >
- **de** / docker exec -it < cont. id > < cmd ~sh >
- **dl** / docker logs < cont. id >
- **dp** / docker push dockerUser/< image > to dockerhub

## devops

- **fdr** / firebase deploy & resume coding (vue build > deploy > dev) / Franklin Delano Roosevelt
- **ncol** / open the ncol wall at localhost:8080/#/ncol, starting it first if needed — installs its LaunchAgent on a new machine; `ncol status | restart | stop | log`. Install with `cmdi ncol`
- **std** / from M16, attach to (or start) the tmux session `m16` on STD, the Studio, over the tailnet: Claude Code sessions keep running there when M16 sleeps; a window per repo (Ctrl-b c new, n next, d detach). tmux by full path, since ssh runs it without a login shell. See aipmo `docs/working-setups.md`
- **aidesk** / start or restart the 3AI Desk, Hugo on :1314 and the editor-server on :3005, then open the desk at localhost:1314; with no argument it restarts both, since neither picks up every change live. `aidesk start | stop | status | log | hugo | editor`. Output in `~/Library/Logs/3aidesk/`. Runs the 3aidesk repo's `bin/aidesk`; `AIDESK_DIR` overrides where that is. Install with `cmdi aidesk`, or `CMDI_DEST=~/.local/bin ./cmdi aidesk` without sudo
- **mural** / restart mural's windows on STD (the backdrop on TV2, the presenter on TV3) as last launched, on fresh code; `mural help` for the rest (`backdrop`, `presenter`, `camera`, `snap`, `clip`, `key`, `stop`). Runs the mural repo's `bin/mural`; `MURAL_DIR` overrides where that is. Install with `cmdi mural`, or `CMDI_DEST=~/.local/bin ./cmdi mural` without sudo

## git

- **cnp** / commit and push — typed to Claude Code (`cnp` or `/cnp`) on M16 and STD: commits this session's changes with a message drafted from the repo's todos, plan and diff, then pushes. Skill in `skills/cnp/`, symlinked to `~/.claude/skills/cnp`. Terminal version to come (ncol todo #8)
- **skills** / list Claude Code's /commands and skills in alphabetical order, numbered, one line each: name, where it comes from (`user:<repo>` for a symlinked skill, so you know where to edit it; `claude.ai`; or the current repo), and the first sentence of its description. Like `za` for aliases. `skills <word>` filters. Reads only `~/.claude` and the repo you're in, bash 3.2 + awk, so the same file works on STD and M16. Lives at `skills/skills` (the `skills/` dir holds the Claude skills themselves); install with `cmdi skills/skills`, or `CMDI_DEST=~/.local/bin ./cmdi skills/skills` without sudo
- **gx** / gs > ga > gs > gc(cmd-v) > gp
- **gv** / gs > ga > gs > gc(cmd-v) + UTCms
- **ga** / git add .
- **gc** / git commit -am 'comment'
- **gl** / git log
- **gp** / git push
- **gs** / git status

## firebase

- **fd** / firebase deploy

## npm, vue

- **ns** / npm start
- **nrs** / npm run serve
- **nrb** / npm run build

## Mac install

- **cmdi** / command install in /usr/local/bin (`$CMDI_DEST` overrides); takes a path too, installed under its basename: `cmdi skills/skills` → `skills`

```bash
cmdi < cmd >
```

copy files to /usr/local/bin

```bash
sudo cp * /usr/local/bin
```

might need to add permissions eg:

```bash
chmod +x /usr/local/bin/dr
# or
chmod 755 /usr/local/bin/dr
```
