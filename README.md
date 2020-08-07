# linux-setup

Small script to set up a new Linux desktop/laptop

## Read this much from the old machine

* Go for the minimal installation, plus 3P software
* Add a Google account straight out of setup. This puts a mountable network drive into the file manager.
* Open Firefox, search “Chrome download” and download the .deb file. Save it, don't open it with the archive manager. 
* `sudo apt install ./google-chrome*`
* This also sets up the Google repository for Chrome. Find Chrome in all apps and add it to the favourites.
* Open Chrome and go to [this repo on Github](https://github.com/eliotstock/linux-setup)

## Now switch to the new machine

* `git clone https://github.com/eliotstock/linux-setup`
* `cd linux-setup`
* `chmod 755 ./setup.sh`
* `./setup.sh`
* Fix any errors in the script and push them up for next time.
