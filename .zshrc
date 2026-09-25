#!/bin/zsh
PROMPT='%B%F{33}SI%f %* %(?.%F{green}$.%F{red}$ %?)%f %B%F{240}%1~%f%b %# '

autoload -Uz vcs_info
precmd_vcs_info() { vcs_info }
precmd_functions+=( precmd_vcs_info )
setopt prompt_subst
RPROMPT=\$vcs_info_msg_0_
zstyle ':vcs_info:git:*' formats '%F{240}(%b)%r%f'
zstyle ':vcs_info:*' enable git

alias o.="open ."
alias c.="code ."
alias gp2="/Users/stefan/workspace/git-cmds/gp2.sh"   # push to both GitHub and GitLab safely with merge-first strategy to avoid rebase ping-pong
alias ncol="command ncol"   # ncol wall: start if needed + open localhost:8080/#/ncol; ncol status|restart|stop|log (install: cmdi ncol)
alias nb="open -a 'Brave Browser' -n --args --new-window"     # start new brave browser window
alias nrs="npm run start"
alias hsd="hugo server --disableFastRender"
alias za="grep -E '^\s*alias\b' ~/.zshrc | sort | cat -n"   # list all aliases with line numbers
alias tt88="ttyd -p 7688 -W zsh "   # run tty server with zsh on http://localhost:7688 
alias nrd="npm run dev"
alias nrb="npm run build"
alias ni="npm install"
alias nv="nvim"
alias fd="firebase deploy"
alias fv="fv.sh"            # File Viewer/browser on split panel
alias green="echo -e '\e]11;#044\a'"  # set terminal bg to dark green
alias blue="echo -e '\e]11;#036\a'"  # set terminal bg to dark blue
alias grey="echo -e '\e]11;#181818\a'"  # set terminal bg to dark grey
alias lv="/Users/stefan/.local/bin/lvim"
alias cz="code ~/workspace/aiteams/zsh/.zshrc"
alias ls="lsd"
alias la="ls -la"
alias n="/opt/homebrew/bin/nano"
alias nz="n ~/.zshrc"
alias sz="source ~/.zshrc"
alias uz="cp .zshrc ~/.zshrc && source ~/.zshrc && gv && echo 'zshrc updated, sourced, & commited locally'"
alias cl="clear"
alias cr="clear && cargo run"
alias cw="cd workspace"
alias ci="cd ~/workspace/iantalabs"
alias cj="cd ~/workspace/iantalabs/vsc-jobs"
alias tl="tree -L 1"
alias tl2="tree -L 2"
alias tl3="tree -L 3"
alias python="python3"
alias p3="python3"
alias dps="docker ps"
alias dra="deno run --allow-all"
alias k="kubectl"
alias kd="kubectl get deployments"
alias ks="kubectl get services"
alias tls="termshot --show-cmd -- gls --group-directories-first -la --color=always"
alias yz="yazi" 
alias spf="spf" # lauch superfile terminal file manager
alias nt="open . -a iTerm" # new terminal window in current dir
alias x="exit"  # exit terminal
alias m="tmux"  # set -g mouse on \n set-option -g default-shell /bin/zsh
alias svim="~/.config/nvim/si-nvim-startup"  # launch si nvim multipanel layout
alias d4s="dev4 start"   # dev4 convenience aliases: start and stop the dev4 session with 4 tmux panes
alias d4q="dev4 stop"

# append Python/pip3, etc libs etc including redisgraph-bulk-insert/update
path+=('/Users/stefan/Library/Python/3.9/bin')

# export to sub-processes (make it inherited by child processes)
export PATH="$HOME/.local/bin":$PATH
export GDAL_LIBRARY_PATH=/opt/homebrew/lib/libgdal.dylib
export GEOS_LIBRARY_PATH=/opt/homebrew/lib/libgeos_c.dylib

# clear and re-run last cmd - Not working yet
re()
{
    clear && ${history[@][1]}
}

# md: make a directory and cd into it
md()
{
    test -d "$1" || mkdir "$1" && cd "$1"
}

# rd: remove dir and files inside
rd()
{
    rm -rf "$1"
}

# mf: make a file and open it in VS Code
mf()
{
    touch "$1" && code "$1"
}

# cf: find dir and cd into it
cf()
{
    echo 'cf = cd to find(dir)' && cd `find ~/workspace -type d -name "$1" | grep -wv node_modules` && pwd
}

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/stefanianta/google-cloud-sdk/path.zsh.inc' ]; then .
'/Users/stefanianta/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/stefanianta/google-cloud-sdk/completion.zsh.inc' ]; then .
'/Users/stefanianta/google-cloud-sdk/completion.zsh.inc'; fi


# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/stefan/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/stefan/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/stefan/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/stefan/google-cloud-sdk/completion.zsh.inc'; fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/stefan/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/stefan/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/stefan/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/stefan/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
conda deactivate

# Pyenv initialization
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"