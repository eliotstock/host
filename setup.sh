#!/bin/bash

# Add some packages and snaps
# Dev
sudo apt-get install -y git
sudo apt-get install -y emacs
sudo apt-get install -y virtualenv
sudo apt-get install -y cloc
sudo snap install code

# Other
sudo apt-get install -y gnome-tweaks
sudo snap install telegram-desktop
sudo snap install discord
sudo snap install slack
sudo snap install spotify
sudo snap install vlc
sudo apt-get install -y simple-scan
# Required by hp-setup GUI
sudo apt-get install -y python-qt4
sudo apt-get install -y python3-pip
pip3 install pyqt5
# Fingerprint reader
sudo apt-get install -y fprintd

# Gnome settings
gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-dark'
gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll false
gsettings set org.gnome.desktop.peripherals.mouse natural-scroll false
gsettings set org.gnome.desktop.background picture-uri 'file:////usr/share/gnome-control-center/pixmaps/noise-texture-light.png'
gsettings set org.gnome.desktop.screensaver picture-uri 'file:////usr/share/gnome-control-center/pixmaps/noise-texture-light.png'
gsettings set org.gnome.desktop.peripherals.mouse speed -0.15
gsettings set org.gnome.desktop.peripherals.touchpad speed 0.60
gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 20
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false
gsettings set org.gnome.desktop.interface show-battery-percentage true
gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view'
gsettings set org.gnome.nautilus.list-view default-zoom-level 'small'
gsettings set org.gnome.desktop.session idle-delay 900
gsettings set org.gnome.desktop.screensaver lock-delay 60
gsettings set org.gnome.shell favorite-apps "['google-chrome.desktop', 'org.gnome.Terminal.desktop', 'org.gnome.Nautilus.desktop', 'code_code.desktop', 'org.gnome.Screenshot.desktop', 'telegram-desktop_telegram-desktop.desktop', 'slack_slack.desktop']"

# Increase the number of watches available to inotify for IDEs
# Not repeatable
sudo echo "fs.inotify.max_user_watches = 524288" > /etc/sysctl.d/50-eliot_more_watches.conf

# Append to ~/.bashrc with a sourcing of bashrc.sh from this repo
cat >> ~/.bashrc <<EOL

# Do not add things to ~/.bashrc, which is not version controlled.
# Instead add things to ~/r/p/linux-setup/bashrc.sh, which is.
if [ -f ~/r/p/linux-setup/bashrc.sh ]; then
  source ~/r/p/linux-setup/bashrc.sh
fi
EOL

# Git user details could go here, but let's not put my email address in an open source codebase
# git config --global user.email "foo@example.com"
# git config --global user.name "Your Name"
