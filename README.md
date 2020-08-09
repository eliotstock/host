# linux-setup

Small script to set up a new Linux desktop/laptop for personal use.

## Read this much from the old machine

* Go for the minimal installation, plus 3P software.
* Add a Google account straight out of setup. This puts a mountable network drive into the file manager.
* Sign in to Canonical Livepatch
* Open Firefox, search “Chrome download” and download the `.deb` file. Save it, don't open it with the archive manager. 
* `sudo apt install ./google-chrome*`
* This also sets up the Google repository for Chrome. Find Chrome in all apps and add it to the favourites.
* Open Chrome and go to [this repo on Github](https://github.com/eliotstock/linux-setup)

## Now switch to the new machine

* `sudo apt install git`
* `git clone https://github.com/eliotstock/linux-setup`
* `cd linux-setup`
* `./setup.sh`

Fix any errors in the script and push them up for next time.

Configure git user.

* `git config --global user.email "foo@example.com"`
* `git config --global user.name "Your Name"`

Then use the GUI tool to make more tweaks. Run it with dconf running in another terminal tab to see which gsettings keys are being modified, then add those above for next time.

* `dconf watch /`
* `gnome-tweaks`

Go to Settings > Printers and expect the HP Laserjet MFP M125nw to be there, without having to add it, even over WiFi. Print a test page. May no longer be required for 20.04.

Get a udev rules file for Open OCD, maybe the one from their Sourceforge repo [here](https://sourceforge.net/p/openocd/code/ci/master/tree/contrib/60-openocd.rules), and put it in `/etc/udev/rules.d`. `chmod` it to 644. Make sure your user is in the `plugdev` (and maybe `dailout`) groups. Reboot.

Set up scanner manually with:

* `sudo hp-setup -i`

Then test with:

* `simple-scan`

Get new firmware from the LVFS stable channel if anything doesn't work (eg. fingerprint reader)

* `fwupdmgr enable-remote lvfs`
* `fwupdmgr get-devices`
* `fwupdmgr refresh`
* `fwupdmgr get-updates`
* `fwupdmgr update`
* `fwupdmgr disable-remote lvfs`

So that `apt-get source foo` will work, open the "Software & Updates" application and check "Source code"
