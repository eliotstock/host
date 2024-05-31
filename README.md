# Host setup

Small script to set up a new Ubuntu or MacOS desktop/laptop for personal use.

## Things to test manually before committing to a new Ubuntu release

* External monitor works after locking and unlocking.
* Screensharing works in Google Meet (Wayland has/had no support for this).
* Bluetooth headphones work as a headset. Mic works and audio quality is good.

## Ubuntu

### To upgrade in-place rather than reinstall

If you wait long enough the Software Updater app will offer to upgrade Ubuntu. Before that, or if it doesn't:

* `sudo apt update`
* `sudo apt upgrade`
* `sudo apt dist-upgrade`
* `sudo apt autoremove`
* `sudo do-release-upgrade`

### Read this much from the old machine

* If reinstalling over an existing Ubuntu instance:
    * Back up `~/.ssh` to a USB drive. The Ubuntu installer image has a 25GB writable partition you can use for this.
    * `sudo mkdir /media/[username]/writable/dot-ssh`
    * `sudo cp -r ~/.ssh/* /media/e/writable/dot-ssh` (this preserves the file modes)
    * Do the same for any `.env` files in local repos.
    * Larger files can go to a back up machine over `scp`, but `sshd` will need to be running there.
* If retaining the Windows installation:
    * Don't be surprised if the machine doesn't give you the boot menu with F1 or F12. Boot into Windows first.
    * Disable Bitlocker in settings.
    * Search "boot" in settings, and do an advanced boot.
    * Boot from USB drive.
    * Hit enter while the machine is booting.
* Go for the minimal installation, plus 3P software.
* Add a Google account straight out of setup. This puts a mountable network drive into the file manager.
* While the installation is happening, review the list of apps to install in `setup.sh` in this repo.
* Sign in to Ubuntu Single Sign-on and then Canonical Livepatch
* Open Firefox, search “Chrome download” and download the `.deb` file. Save it, don't open it with the archive manager. 
* `sudo apt install ./google-chrome*`
* This also sets up the Google repository for Chrome. Find Chrome in all apps and add it to the favourites.
* Open Chrome and go to [this repo on Github](https://github.com/eliotstock/linux-setup)

### Now switch to the new machine

#### Install git and run this script

* `sudo apt install git`
* `git clone https://github.com/eliotstock/host`
* `cd host`
* `./setup.sh`

Fix any errors in the script.

Configure git user. Cache the personal access token from Github for one week. Get your `noreply` email address from https://github.com/settings/emails.

* `git config --global user.email "ID+USERNAME@users.noreply.github.com"`
* `git config --global user.name "Your Name"`
* `git config --global credential.helper cache`
* `git config --global credential.helper 'cache --timeout=604800'`
* `git config pull.rebase false`

Push any changes to the script up for next time. If there are no changes, do a push anyway just to get the Github password into the cache.

Open [github.com](https://github.com) in a browser and sign in, using 2FA.

#### Gnome config

Then use the GUI tool to make more tweaks. Run it with dconf running in another terminal tab to see which gsettings keys are being modified, then add those above for next time.

* `dconf watch /`
* `gnome-tweaks`

As of Ubuntu 22.10, `gnome-tweaks` doesn't give you much. Use Settings instead.

* Appearance
  * Style -> Dark
  * Wallpaper
* Ubuntu Desktop
  * Desktop Icons -> Size: Small

Also do the Terminal Preferences.

* 106 columns by 55 rows
* GNOME dark

#### Printer/scanner

Go to Settings > Printers and expect the HP Laserjet MFP M125nw to be there, without having to add it, even over WiFi. Print a test page. May no longer be required for 20.04.

Set up scanner manually with:

* `sudo hp-setup -i`

Then test with:

* `simple-scan`

#### udev

Get a udev rules file for Open OCD, maybe the one from their Sourceforge repo [here](https://sourceforge.net/p/openocd/code/ci/master/tree/contrib/60-openocd.rules), and put it in `/etc/udev/rules.d`. `chmod` it to 644. Make sure your user is in the `plugdev` (and maybe `dailout`) groups. Reboot.

#### Firmware, for Thinkpad laptops only

Get new firmware from the LVFS stable channel if anything doesn't work (eg. fingerprint reader)

* `fwupdmgr enable-remote lvfs`
* `fwupdmgr get-devices`
* `fwupdmgr refresh`
* `fwupdmgr get-updates`
* `fwupdmgr update`
* `fwupdmgr disable-remote lvfs`

Go to Settings, Users, e and enable the fingerprint reader.

#### Package sources

So that `apt-get source foo` will work, open the "Software & Updates" application and check "Source code"

#### Dev env

##### Node.js

Follow instructions [here](https://github.com/nodesource/distributions/blob/master/README.md#debinstall) to get Node.js. Don't use the snap for this.

Then get `nvm` (Node.js version manager) from [here](https://github.com/nvm-sh/nvm#installing-and-updating).

##### Rust

Follow your nose at [rustup.rs](https://rustup.rs/) to get the latest stable Rust, including cargo.

##### Docker

Follow your nose at [docker.com](https://docs.docker.com/desktop/linux/install/ubuntu/) to get Docker set up.

To be able to run docker without sudo'ing, follow instructions [here](https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user).

##### Python

Get Python 3.9 for AWS SAM but do NOT downgrade the system Python to it or you'll break it. Get `virtualenv` working instead. Note that the `deadsnakes` PPA only supports LTS versions of Ubuntu (22.04, 24.04). Use `pyenv` instead.

* Folow your nose at the `pyenv` [repo](https://github.com/pyenv/pyenv).
  * Don't forget the [suggested build environment](https://github.com/pyenv/pyenv/wiki#suggested-build-environment)
* `pyenv install 3.9`
* Follow your nose at `pyenv-virtualenv` [repo](https://github.com/pyenv/pyenv-virtualenv)

##### Golang

* `sudo apt install golang`

##### AWS

Follow this to get the AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

Follow this to get the AWS SAM CLI: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html

#### ssh keys

If reinstalling over an existing Ubuntu instance, restore `~/.ssh` from old instance.

* The Ubuntu installer image has a writable partition you can use for this.
* `mkdir ~/.ssh`
* `sudo cp -r /media/[username]/writable/dot-ssh ~/.ssh` (this preserves the file modes)

Otherwise, generate new ssh keys locally. Use no passphrase.

* `ssh-keygen -t rsa -b 4096 -C "[hostname]"`

Push them up to the server(s) you need to connect to. This won't work if the server doesn't allow password auth for ssh, ie. `/etc/ssh/sshd_config` already has `PasswordAuthentication` set to `no`. You'll need to set that to `yes` and `sudo service sshd restart` first.

* `scp -P [port] ~/.ssh/id_rsa.pub [username]@[server IP]:/home/[username]/.ssh/authorized_keys.[new_host]`

ssh to the server, verify the file is there and then append it to the existing `.ssh/authorized_keys` file if it exists (`cat ~/.ssh/authorized_keys.[new_host] >> ~/.ssh/authorized_keys`) or create it if not.

Put `/etc/ssh/sshd_config` back to having `PasswordAuthentication` set to `no` and `sudo service sshd restart` if applicable.

#### tmux config

Make mouse wheel scrolling work in tmux.

* `code ~/.tmux.conf`
* Add `set -g mouse on`
* Kill any running tmux sessions to pick up the change: `tmux kill-server`

## MacOS

Install Mac OS developer tools first (Google it)

Change the hostname

```
sudo scutil --set HostName eliot_mac
```

Change to `bash`

```
chsh -s /bin/bash
```

## Browser extension wallets

Enter seed phrases to recover accounts.

Re-import the same accounts that were imported on previous machine.
