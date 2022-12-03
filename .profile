set -o vi
bind -m vi-insert '\c-l':clear-screen
bind -m vi-insert '\c-e':end-of-line
bind -m vi-insert '\c-a':beginning-of-line
bind -m vi-insert '\c-h':backward-kill-word
bind -m vi-insert '\c-k':kill-line

if [[ $(id -u) -eq 0 ]] ; then
  PS1='\[\e[31m\][root]\[\e[0m\] \W\$ ' # root prompt
else 
  PS1="\[\e[38;5;243m\]\u\[\e[38;5;29m\]@\[\e[38;5;29m\]\h \[\e[38;5;255m\]\w \[\033[0m\]\n\[\e[38;5;89m\]λ\[\033[0m\] "
fi

export ENV=~/.env
export PATH="$HOME/bin:$PATH"
export LANG='en_US.UTF-8'
export EDITOR='vim'
export VISUAL='vim'
