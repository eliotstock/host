# When setting up a new machine, add all this to ~/.bash_profile, which may not exist yet.

# Have git and others use emacs for an editor, not vi.
export VISUAL="emacs -nw"
export EDITOR="$VISUAL"

# Keep the gradle version here up to date with the latest that Android Studio downloads.
# PATH=/Applications/Android\ Studio.app/Contents/gradle/gradle-3.2/bin:$PATH
# PATH=~/Library/Android/sdk/platform-tools:$PATH
# PATH=~/Library/Python/2.7/bin:$PATH

# PATH=~/r/appengine-java-sdk-1.9.51/bin:$PATH

# Fuchsia
# PATH=~/r/zircon-buildtools/mac-x64/qemu/bin:$PATH
PATH=~/r/fuchsia/.jiri_root/bin:$PATH
if [ ! -d ~/r/fuchsia/.ccache ]; then
   mkdir ~/r/fuchsia/.ccache
fi
export CCACHE_DIR=~/r/fuchsia/.ccache

# PATH=/usr/local/bin/make:$PATH

# PATH=/Volumes/GoogleDrive/My\ Drive/bin:$PATH

# export JAVA_HOME=`/usr/libexec/java_home -v 1.8`

alias ls='ls -lah'

export PS1="\$"

# cd ~/r/biketracker/biketracker-firmware/app/bt08

# Update PATH for the Google Cloud SDK.
if [ -f /home/e/r/google-cloud-sdk/path.bash.inc ]; then
  source '/home/e/r/google-cloud-sdk/path.bash.inc'
fi

# Enables shell command completion for gcloud.
if [ -f /home/e/r/google-cloud-sdk/completion.bash.inc ]; then
  source '/home/e/r/google-cloud-sdk/completion.bash.inc'
fi
