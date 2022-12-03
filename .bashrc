#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

source "$HOME"/.profile
source "$HOME"/.env

export BROWSER='chromium'
export MPD_HOST=$HOME/.mpd/socket
export QT_STYLE_OVERRIDE=kvantum

shopt -s autocd
shopt -s checkwinsize
shopt -s cmdhist
shopt -s cdspell
shopt -s cdable_vars
shopt -s histappend

n ()
{
    # Block nesting of nnn in subshells
    if [ -n $NNNLVL ] && [ "${NNNLVL:-0}" -ge 1 ]; then
        echo "nnn is already running"
        return
    fi

    # The behaviour is set to cd on quit (nnn checks if NNN_TMPFILE is set)
    # If NNN_TMPFILE is set to a custom path, it must be exported for nnn to
    # see. To cd on quit only on ^G, remove the "export" and make sure not to
    # use a custom path, i.e. set NNN_TMPFILE *exactly* as follows:
    #     NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
    export NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"

    nnn "$@"

    if [ -f "$NNN_TMPFILE" ]; then
            . "$NNN_TMPFILE"
            rm -f "$NNN_TMPFILE" > /dev/null
    fi
}

function fd() {
 local dir
 dir=$(find ${1:-.} -path '*/\.*' -prune -o -type d \
      -print 2> /dev/null | fzf +m) &&
 cd "$dir"
}

function bak() {
    cp "$1" "$1.bak"
}

function wanip() {
    curl icanhazip.com
}

function lanip() {
    ip a | grep $(ip r | grep default | head | cut -d\  -f5) | grep inet | awk '{print $2}' | cut -d"/" -f1
}

function extract() {
   if [ -f $1 ] ; then
       case $1 in
           *.tar.bz2)	tar xvjf $1    ;;
           *.tar.gz)	tar xvzf $1    ;;
           *.tar.xz)	tar xJf $1     ;;
           *.bz2)	bunzip2 $1     ;;
           *.rar)	unrar x $1     ;;
           *.gz)	gunzip $1      ;;
           *.tar)	tar xvf $1     ;;
           *.tbz2)	tar xvjf $1    ;;
           *.tgz)	tar xvzf $1    ;;
           *.zip)	unzip $1       ;;
           *.Z)		uncompress $1  ;;
           *.7z)	7z x $1        ;;
           *.deb)   ar x $1        ;;
           *)		echo "Unable to extract '$1'" ;;
       esac
   else
      echo "'$1' is not a valid file"
   fi
}

function lhs() {
    for list in $(ls -a | sed 's/\ /\\ /g'); do du -hs $list; done | sort -hr
}

function yta() {
    mpv --ytdl-format=bestaudio ytdl://ytsearch:"$*"
}

function ytdl() {
  yt-dlp -xiwv4 --format "(bestaudio[acodec^=opus]/bestaudio)/best" \
             --audio-quality 0 \
             --embed-thumbnail \
             --download-archive downloaded.txt \
             --yes-playlist \
             --no-continue \
             --add-metadata \
             --external-downloader aria2c \
             --external-downloader-args "-c -j 3 -x 3 -s 3 -k 1M" \
             $@
}

alias pac="pacman -Slq | fzf --multi --preview 'pacman -Si {1}' | xargs -ro sudo pacman -S"
alias aur="paru -Slq | fzf --multi --preview 'pacman -Si {1}' | xargs -ro paru -S"
alias rem="paru -Qq | fzf --multi --preview 'pacman -Si {1}' | xargs -ro paru -Rcsn"
alias pacu="sudo pacman -Sy && sudo powerpill -Su && paru -Su"
alias progs="(pacman -Qet && pacman -Qm) | sort -u"
alias orphans="paru -Sc && paru -Qqtd"
