ZSH_THEME=agnoster
source '/home/kiran/dotfiles/zsh/zshrc_manager.sh'

# added by Anaconda3 installer
export PATH="/work/conda3/bin:$PATH"

if [ -z "$TMUX" ] && [[ $TERM == xterm* ]]; then
  tmux has-session -t global-session > /dev/null
  if [ $? -ne 0 ]; then
    tmux new -d -s global-session -n work 
    # tmux new-session -d -t global-session -s work \; set-option destroy-unattached \; new-window \; attach-session -t work 
    # tmux new -s work 
  fi
  # <F20>exec tmux new-session -d -t global-session -s $CLIENTID \; set-option destroy-unattached \; new-window \; attach-session -t $CLIENTID
fi

#tmux select-window -t global-session:work \; a -t global-session
tmux a


[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
