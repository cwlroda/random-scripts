# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
    *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=10000
HISTFILESIZE=20000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ -f ~/.bash_colors ]; then
    . ~/.bash_colors
fi

# color coding
ARROW=$(echo -e $'\uE0B0')
export VIRTUAL_ENV_DISABLE_PROMPT=1
if test -z "$VIRTUAL_ENV"; then
    VENV=""
else
    # if test -n "$CONDA_DEFAULT_ENV"; then
    #     conda deactivate
    # fi
    VENV=" (`basename \"$VIRTUAL_ENV\"`) \[${ENV_DATE_COLOR}\]${ARROW}"
fi

if test -z "$CONDA_DEFAULT_ENV"; then
    CONDAENV=""
else
    # if test -n "$VIRTUAL_ENV"; then
    #     unset VIRTUAL_ENV & deactivate
    # fi
    CONDAENV=" (`basename \"$CONDA_DEFAULT_ENV\"`) \[${ENV_DATE_COLOR}\]${ARROW}"
fi

function env_color() {
    if [[ -z "$VIRTUAL_ENV" || -z "$CONDA_DEFAULT_ENV" ]]; then
        echo -e $ENV_COLOR
    else
        echo -e $BLINK
    fi
}

function set_env() {
    VENV=set_venv
    CONDA_ENV=set_condaenv
    if [[ -z "$VIRTUAL_ENV" && -z "$CONDA_DEFAULT_ENV" ]]; then
        echo -e ""
    else
        if [[ -z "$VIRTUAL_ENV" || -z "$CONDA_DEFAULT_ENV" ]]; then
            echo -e ${ENV_COLOR}${VENV}${CONDA_ENV}${ENV_DATE_COLOR}${ARROW}
        else
            echo -e ${ENV_BLINK_COLOR}${VENV}${CONDA_ENV}${ENV_DATE_COLOR}${ARROW}
        fi
    fi
}

# get current branch in git repo
function parse_git_branch() {
    BRANCH=`git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'`
    if [ ! "${BRANCH}" == "" ]; then
        STAT=`parse_git_dirty`
        echo "[${BRANCH}${STAT}] "
    else
        echo ""
    fi
}

# get current status of git repo
function parse_git_dirty() {
    status=`git status 2>&1 | tee`
    dirty=`echo -n "${status}" 2> /dev/null | grep "modified:" &> /dev/null; echo "$?"`
    untracked=`echo -n "${status}" 2> /dev/null | grep "Untracked files" &> /dev/null; echo "$?"`
    ahead=`echo -n "${status}" 2> /dev/null | grep "Your branch is ahead of" &> /dev/null; echo "$?"`
    newfile=`echo -n "${status}" 2> /dev/null | grep "new file:" &> /dev/null; echo "$?"`
    renamed=`echo -n "${status}" 2> /dev/null | grep "renamed:" &> /dev/null; echo "$?"`
    deleted=`echo -n "${status}" 2> /dev/null | grep "deleted:" &> /dev/null; echo "$?"`
    bits=''
    if [ "${renamed}" == "0" ]; then
        bits=">${bits}"
    fi
    if [ "${ahead}" == "0" ]; then
        bits="*${bits}"
    fi
    if [ "${newfile}" == "0" ]; then
        bits="+${bits}"
    fi
    if [ "${untracked}" == "0" ]; then
        bits="?${bits}"
    fi
    if [ "${deleted}" == "0" ]; then
        bits="x${bits}"
    fi
    if [ "${dirty}" == "0" ]; then
        bits="!${bits}"
    fi
    if [ ! "${bits}" == "" ]; then
        echo " ${bits}"
    else
        echo ""
    fi
}

function nonzero_return() {
    RETVAL=$?
    [ $RETVAL -ne 0 ] && echo $RETVAL
}

if [ "$color_prompt" = yes ]; then
    PS1="${debian_chroot:+($debian_chroot)}\[${ENV_COLOR}\]${VENV}\[${ENV_COLOR}\]${CONDAENV}\[${DATE_COLOR}\] \D{%d/%m/%y} \[${DATE_TIME_COLOR}\]$ARROW \[${TIME_COLOR}\]\D{%T} \[${TIME_USER_COLOR}\]$ARROW \[${USER_COLOR}\]\u: \[${USER_DIR_COLOR}\]$ARROW \[${DIR_COLOR}\]\w \[${DIR_TOKEN_COLOR}\]$ARROW \[${TOKEN_COLOR}\]\\$ \[${END_COLOR}\]$ARROW \[${RESET}\]"
    # PS1="${debian_chroot:+($debian_chroot)}\[\`env_color\`\]\`set_venv\`\`set_condaenv\`\[${BLUE_BRIGHT}\]\D{%d/%m/%y} \[${YELLOW_BRIGHT}\]\D{%T} \[${GREEN_BRIGHT}\]\u: \[${CYAN_BRIGHT}\]\w \[${RED_BRIGHT}\]\`parse_git_branch\`\[${RESET}\]\\$ \[${RESET}\]"
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi

if [ -f "$HOME/.bash-git-prompt/gitprompt.sh" ]; then
    GIT_PROMPT_ONLY_IN_REPO=1
    GIT_PROMPT_WITH_VIRTUAL_ENV=0
    GIT_PROMPT_THEME="cwlroda"
    source $HOME/.bash-git-prompt/gitprompt.sh
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
    xterm*|rxvt*)
        PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
    *)
    ;;
esac

# enable color support of ls
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# colored GCC warnings and errors
# https://gcc.gnu.org/onlinedocs/gcc-8.3.0/gcc/Diagnostic-Message-Formatting-Options.html#Diagnostic-Message-Formatting-Options
export GCC_COLORS="error=01;31:warning=01;35:note=01;36:range1=32:range2=34:locus=01:quote=01:fixit-insert=32:fixit-delete=31:diff-filename=01:diff-hunk=32:diff-delete=31:diff-insert=32:type-diff=01;32"

# enable color support for less
export LESSOPEN="| /usr/bin/source-highlight-esc.sh %s"
export LESS='-R '

# grc aliases
# https://github.com/garabik/grc
GRC_ALIASES=true
[[ -s "/etc/profile.d/grc.sh" ]] && source /etc/grc.sh

# https://github.com/stuartleeks/wsl-notify-send
# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alert() {
    ~/wsl-notify-send.exe --category $WSL_DISTRO_NAME "${@}";
}

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
        elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

export IP_ADDR=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')
export HOST_IP="$(ip route |awk '/^default/{print $3}')"
export PULSE_SERVER=tcp:$(grep nameserver /etc/resolv.conf | awk '{print $2}');
export DISPLAY="$HOST_IP:0.0"

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# python
export PATH="$PATH:/usr/local/bin/python3"

# CUDA
export LIBGL_ALWAYS_INDIRECT=1
export PATH="/usr/local/cuda/bin:$PATH"
export LIBRARY_PATH="$CUDA_HOME/lib64:$LIBRARY_PATH"
export LD_LIBRARY_PATH="/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64:$LD_LIBRARY_PATH"
export CUDA_PATH="/usr/local/cuda"
export CUDA_HOME="/usr/local/cuda"
export NVCC="/usr/local/cuda/bin/nvcc"
export CFLAGS="-I$CUDA_HOME/include $CFLAGS"

# flutter
export PATH="$PATH:`pwd`/flutter/bin"
export CHROME_EXECUTABLE=/usr/bin/chromium-browser

# android studio
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64/
export ANDROID_HOME=$HOME/android
export PATH=$ANDROID_HOME/cmdline-tools/tools/bin/:$PATH
export PATH=$ANDROID_HOME/emulator/:$PATH
export PATH=$ANDROID_HOME/platform-tools/:$PATH

# https://github.com/nvbn/thefuck
eval $(thefuck --alias fk)

# https://github.com/gsamokovarov/jump
# eval "$(jump shell bash)"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('$HOME/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
        . "$HOME/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="$HOME/miniconda3/bin:$PATH"
    fi
fi

if [ -f "$HOME/miniconda3/etc/profile.d/mamba.sh" ]; then
    . "$HOME/miniconda3/etc/profile.d/mamba.sh"
fi
unset __conda_setup
# <<< conda initialize <<<

# git ssh key passphrase
env=~/.ssh/agent.env

agent_load_env () { test -f "$env" && . "$env" >| /dev/null ; }

agent_start () {
    (umask 077; ssh-agent >| "$env")
. "$env" >| /dev/null ; }

agent_load_env

# agent_run_state: 0=agent running w/ key; 1=agent w/o key; 2=agent not running
agent_run_state=$(ssh-add -l >| /dev/null 2>&1; echo $?)

if [ ! "$SSH_AUTH_SOCK" ] || [ $agent_run_state = 2 ]; then
    agent_start
    ssh-add
    elif [ "$SSH_AUTH_SOCK" ] && [ $agent_run_state = 1 ]; then
    ssh-add
fi

unset env

eval "$(hub alias -s)"

# node options
export NODE_OPTIONS=--max-old-space-size=16384
