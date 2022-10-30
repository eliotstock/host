# Do not add things to ~/.bashrc, which is not version controlled.
# Instead add things to this file, which is.

# Have git and others use emacs for an editor, not vi.
export VISUAL="emacs -nw"
export EDITOR="$VISUAL"

# Python
# PATH=~/Library/Python/2.7/bin:$PATH

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
if [ -f /home/e/r/p/google-cloud-sdk/path.bash.inc ]; then
  source '/home/e/r/p/google-cloud-sdk/path.bash.inc'
fi
if [ -f /home/e/r/p/google-cloud-sdk/completion.bash.inc ]; then
  source '/home/e/r/p/google-cloud-sdk/completion.bash.inc'
fi

# PATH=/usr/local/bin/make:$PATH

# Solana
PATH="/home/e/.local/share/solana/install/active_release/bin:$PATH"

# Node.js. Fix 'FATAL ERROR: Reached heap limit Allocation failed - JavaScript heap out of memory'
export NODE_OPTIONS=--max_old_space_size=4096

alias ls='ls -lah'
alias emacs='emacs -nw'

export PS1="\$"
