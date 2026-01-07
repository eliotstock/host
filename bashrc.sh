# Do not add things to ~/.bashrc, which is not version controlled.
# Instead add things to this file, which is.

# echo "Starting repo bashrc"
#if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # echo "Linux"
#elif
if [[ "$OSTYPE" == "darwin"* ]]; then
  # echo "Mac"

  # Homebrew, on Mac OS only
  if [ -e /opt/homebrew/bin/brew ]; then
    eval $(/opt/homebrew/bin/brew shellenv)
  fi

  # Cursor
  if [ -e /Applications/Cursor.app/Contents/MacOS/cursor ]; then
    PATH="$PATH:/Applications/Cursor.app/Contents/MacOS"
  fi
fi

# echo "Home: $HOME"

# Have git and others use nano for an editor, not vi.
# crontab for one will break if you try setting this to VS Code.
export VISUAL="nano"
export EDITOR="$VISUAL"

# Docker
export PATH="$HOME/.docker/bin:$PATH"

# Cursor
if [ -e $HOME/bin/cursor/cursor ]; then
  PATH="$HOME/bin/cursor:$PATH"
fi

# Claude Code
export PATH="$HOME/.local/bin:$PATH"

# Rust
. "$HOME/.cargo/env"

# Pyenv, for installing and running multiple Python versions
if [ -d $HOME/.pyenv ]; then
  export PYENV_ROOT="$HOME/.pyenv"
  command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
fi

# Android
# Keep the gradle version here up to date with the latest that Android Studio downloads.
# PATH=/Applications/Android\ Studio.app/Contents/gradle/gradle-3.2/bin:$PATH
# PATH=~/Android/sdk/platform-tools:$PATH
# export JAVA_HOME=`/usr/libexec/java_home -v 1.8`

# App Engine
# PATH=~/r/appengine-java-sdk-1.9.51/bin:$PATH

# Fuchsia
# PATH=~/r/zircon-buildtools/mac-x64/qemu/bin:$PATH
# PATH=~/r/fuchsia/.jiri_root/bin:$PATH
# source ~/r/fuchsia/scripts/fx-env.sh
# if [ ! -d ~/r/fuchsia/.ccache ]; then
#    mkdir ~/r/fuchsia/.ccache
# fi
# export CCACHE_DIR=~/r/fuchsia/.ccache

# Google Cloud SDK
# if [ -f $HOME/r/p/google-cloud-sdk/path.bash.inc ]; then
#   source '$HOME/r/p/google-cloud-sdk/path.bash.inc'
# fi
# if [ -f $HOME/r/p/google-cloud-sdk/completion.bash.inc ]; then
#   source '$HOME/r/p/google-cloud-sdk/completion.bash.inc'
# fi

# PATH=/usr/local/bin/make:$PATH

# Solana
# PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"

# Aptos
# export PATH="$HOME/.local/bin:$PATH"

# Node.js. Fix 'FATAL ERROR: Reached heap limit Allocation failed - JavaScript heap out of memory'
export NODE_OPTIONS=--max_old_space_size=4096
# Note: you cannot use "which nvm" to see if nvm is available. It's a function, not a binary.
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
export PATH=$HOME/.meteor:$PATH

# MySQL
if [[ "$OSTYPE" == "darwin"* ]]; then
  export PATH="/opt/homebrew/opt/mysql@8.0/bin:$PATH"
fi

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
export PATH="$PATH:$HOME/.foundry/bin"

# Foundry
export PATH="$PATH:$HOME/.foundry/bin"

# Cairo & Starknet
export CAIRO_ROOT="$HOME/.cairo"
command -v cairo-compile >/dev/null || export PATH="$CAIRO_ROOT/target/release:$PATH"
if [ -f $HOME/.starkli/env ]; then
  source "$HOME/.starkli/env"
fi

# Aztec, including Secretive
export PATH="$PATH:$HOME/.aztec/bin"
export SSH_AUTH_SOCK=$HOME/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh

# Serial comms with Rock 5B. See https://docs.radxa.com/en/general-tutorial/serial
# alias minicom='minicom -w -t xterm -l -R UTF-8'

# Aliases
alias ls='ls -lah'
alias emacs='emacs -nw'

trash() {
  mv "$1" "$HOME/.local/share/Trash/files"
}

export PS1="\$"

# Or just put things in /usr/local/bin
# No longer required because ~/.profile does this.
# export PATH="$HOME/bin:$PATH"

# Autocompletion for the Stripe CLI
if [ -f $HOME/.stripe/stripe-completion.bash ]; then
  source $HOME/.stripe/stripe-completion.bash
fi

# Autocompletion for k8s
# if ! command source <(kubectl completion bash) &> /dev/null
# then
#   echo "no k8s"
# fi

# Direnv, used by the Worldcoin Orb software repo
# Added by Nix installer
if [ -e $HOME/.nix-profile/etc/profile.d/nix.sh ]; then
  . $HOME/.nix-profile/etc/profile.d/nix.sh;
  eval "$(direnv hook bash)"
fi

# echo "Finished repo bashrc"
