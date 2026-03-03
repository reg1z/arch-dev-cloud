export EDITOR=nvim
export PATH="$HOME/.local/bin:$PATH"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"

# Rust
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

[ -f ~/.config/shell/aliases ] && source ~/.config/shell/aliases
[ -f ~/.config/shell/tmux_fns ] && source ~/.config/shell/tmux_fns
