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

## git

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

- **cmdi** / command install in /usr/local/bin

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
