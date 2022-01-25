# linux-setup

Small script to set up a new Linux desktop/laptop for personal use.

## Things to test manually before committing to a new release

* External monitor works after locking and unlocking.
* Screensharing works in Google Meet (Wayland has/had no support for this).
* Bluetooth headphones work as a headset. Mic works and audio quality is good.

## Read this much from the old machine

* If retaining the Windows installation
    * Don't be surprised if the machine doesn't give you the boot menu with F1 or F12. Boot into Windows first.
    * Disable Bitlocker in settings.
    * Search "boot" in settings, and do an advanced boot.
    * Boot from USB drive.
    * Hit enter while the machine is booting.
* Go for the minimal installation, plus 3P software.
* Add a Google account straight out of setup. This puts a mountable network drive into the file manager.
* Sign in to Canonical Livepatch
* Open Firefox, search “Chrome download” and download the `.deb` file. Save it, don't open it with the archive manager. 
* `sudo apt install ./google-chrome*`
* This also sets up the Google repository for Chrome. Find Chrome in all apps and add it to the favourites.
* Open Chrome and go to [this repo on Github](https://github.com/eliotstock/linux-setup)

## Now switch to the new machine

### Git and this script

* `sudo apt install git`
* `git clone https://github.com/eliotstock/linux-setup`
* `cd linux-setup`
* `./setup.sh`

Fix any errors in the script.

Configure git user. Cache the personal access token from Github for one week.

* `git config --global user.email "foo@example.com"`
* `git config --global user.name "Your Name"`
* `git config --global credential.helper cache`
* `git config --global credential.helper 'cache --timeout=604800'`
* `git config pull.rebase false`

Push any changes to the script up for next time.

### Gnome config

Then use the GUI tool to make more tweaks. Run it with dconf running in another terminal tab to see which gsettings keys are being modified, then add those above for next time.

* `dconf watch /`
* `gnome-tweaks`

### Printer/scanner

Go to Settings > Printers and expect the HP Laserjet MFP M125nw to be there, without having to add it, even over WiFi. Print a test page. May no longer be required for 20.04.

Set up scanner manually with:

* `sudo hp-setup -i`

Then test with:

* `simple-scan`

### udev

Get a udev rules file for Open OCD, maybe the one from their Sourceforge repo [here](https://sourceforge.net/p/openocd/code/ci/master/tree/contrib/60-openocd.rules), and put it in `/etc/udev/rules.d`. `chmod` it to 644. Make sure your user is in the `plugdev` (and maybe `dailout`) groups. Reboot.

### Firmware

Get new firmware from the LVFS stable channel if anything doesn't work (eg. fingerprint reader)

* `fwupdmgr enable-remote lvfs`
* `fwupdmgr get-devices`
* `fwupdmgr refresh`
* `fwupdmgr get-updates`
* `fwupdmgr update`
* `fwupdmgr disable-remote lvfs`

Go to Settings, Users, e and enable the fingerprint reader.

### Package sources

So that `apt-get source foo` will work, open the "Software & Updates" application and check "Source code"

### Dev env

Follow instructions [here](https://github.com/nodesource/distributions/blob/master/README.md#debinstall) to get Node.js. Don't use the snap for this.

Then get `nvm` (Node.js version manager) from [here](https://heynode.com/tutorial/install-nodejs-locally-nvm/).

Follow your nose at [rustup.rs](https://rustup.rs/) to get the latest stable Rust, including cargo.

### VPN

Install OpenVPN3 by adding their repo accoring to their instructions.

Start a VPN connection with `sudo openvpn3 session-start -c ./vpn.ovpn`

Stop the connection with `sudo openvpn3 session-manage --disconnect -c ./vpn.ovpn`

Check the connection is live with `ifconfig -a`. Check for an adapter called `tun0`.
