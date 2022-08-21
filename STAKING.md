# Build an Ethereum 2 staking machine

1. (Optional) Update the firmware in your router, factory reset, reconfigure.
1. Get an Intel NUC.
1. (Optional) If re-installing, back up the following from the existing target.
    1. `~/[repo_dir]/dro/out/dro.log`
    1. `~/[repo_dir]/dro/out/database.db`
    1. `~/.ssh/authorized_keys`
1. Install Ubuntu Server 22.04 LTS amd64
    1. F10 on boot to boot from USB for Intel NUC
    1. Minimal server installation
    1. US international keyboard
    1. Check ethernet interface(s) have a connection, use DHCP for now
    1. Use an entire disk, 250GB SSD, LVM group, no need to encrypt
    1. Take photo of file system summary screen during installation
    1. Hostname: stake, username: [redacted]
    1. Import SSH identity: yes, GitHub, don’t allow password auth over SSH
    1. Use the [redacted] SSH public key from GitHub
    1. No extra snaps
1. Remember `Ctrl-Alt F1` through `F6` are there for switching to new terminals and multitasking.
1. Disable `cloud-init`
    1. `sudo touch /etc/cloud/cloud-init.disabled`
    1. `sudo reboot`
    1. Make sure you can still log in as your new user.
    1. `sudo dpkg-reconfigure cloud-init` and uncheck everything except `None`.
    1. `sudo apt-get purge cloud-init`
    1. `sudo rm -rf /etc/cloud/ && sudo rm -rf /var/lib/cloud/`
    1. `sudo reboot`
    1. Again, make sure you can still log in as your new user.
1. Configure a static IP address.
    1. Get the interface name from `ip link`. This might be `epn88s0`.
    1. Paste the below block into a new `netplan` config file: `sudo nano /etc/netplan/01-config.yaml`.
        1. A subnet mask of `/24` means only the last octet (8 bits) in the address changes for each device on the subnet.
        1. The DNS servers here are Google's and Cloudflare's.
        1. We might also consider using 9.9.9.9 in future (Quad9, does filtering of known malware sites).
        1. `.yaml` files use spaces for indentation (either 2 or 4), not tabs.
    1. `sudo netplan apply`
    1. Don't plug the ethernet cable in yet though
```
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      addresses:
        - 192.168.20.41/24
      gateway4: 192.168.20.1
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1, 1.0.0.1]
```
1. Change the ssh port from the default
    1. `sudo nano /etc/ssh/sshd_config`
    1. Uncomment the `Port` line. Pick a memorable port number/make a note of it.
    1. Restart `sshd`: `sudo service sshd restart`
    1. Make sure there's an `.ssh` directory in your home directory for later: `mkdir -p ~/.ssh`
    1. When connecting from a client, use the `-p [port]` arg for `ssh`
1. Configure the firewall
    1. Confirm `ufw` is installed: `which ufw`
    1. `sudo ufw default deny incoming`
    1. `sudo ufw default allow outgoing`
    1. `sudo ufw allow [your ssh port]/tcp comment 'ssh'`
    1. `sudo ufw enable`
    1. Note that `http` and `https` are absent above.
    1. Check which ports are accessible with `sudo ufw status`
    1. Also block pings: `sudo nano /etc/ufw/before.rules`, find the line reading `A ufw-before-input -p icmp --icmp-type echo-request -j ACCEPT` and change `ACCEPT` to `DROP`
    1. `sudo ufw reload`
1. If you chose the wrong hostname during the installer, change it now. `sudo nano /etc/hostname` and pick a cool hostname.
1. Connect to the internet
    1. Plug the ethernet cable in and reboot: `sudo reboot`
    1. Check the output of `ip a show`.
    1. Now you can set your ssh alias on the client(s).
1. Update packages and get some stuff
    1. `sudo apt update`
    1. `sudo apt upgrade` (make coffee)
    1. `sudo apt install net-tools emacs git`
1. (Optional and only required if you didn't restore SSH keys from GitHub during installation) Set up ssh keys for all client machines from which you'll want to connect.
    1. If re-installing, restore the `~/.ssh/authorized_keys` file you backed up earlier, using `scp`.
        1. Try connecting using `ssh` first
        1. You'll get an error about the host key changing, including a command to run to forget the old host key. Run it.
        1. Now do the `scp` copy: `scp -P 1035 ./authorized_keys [username]@[ip]:/home/[username]/.ssh/authorized_keys`
    1. Otherwise:
        1. You might like to set an alias in `~/.bashrc` such as `alias <random-name>="ssh -p [port] [username]@[server IP]"`
        1. Similarly for scp: `alias <random-name>="scp -P [port] $1 [username]@[server IP]:/home/[username]"`
        1. `ssh-keygen -t rsa -b 4096 -C "[client nickname]"`
        1. No passphrase.
        1. Accept the default path. You'll get both `~/.ssh/id_rsa.pub` (public key) and `~/.ssh/id_rsa` (private key).
        1. Copy the public key to the server: `scp -P [port] ~/.ssh/id_rsa.pub [username]@[server IP]:/home/[username]/.ssh/authorized_keys`
        1. Verify the file is there on the server.
        1. Verify you can ssh in to the server and you're not prompted for a password. Use the alias you created earlier.
1. Only allow ssh'ing in using a key from now on. `sudo nano /etc/ssh/sshd_config` and set `PasswordAuthentication no`.
    1. `sudo service sshd restart`
    1. Check you can `ssh` in from the client without entering a password.
1. Ban any IP address that has multiple failed login attempts using `fail2ban`
    1. `sudo apt install fail2ban`
    1. `sudo cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.local`
    1. `sudo nano /etc/fail2ban/fail2ban.local` and add:
        1. `[sshd]`
        1. `enabled = true`
        1. `port = [port]`
        1. `filter = sshd`
        1. `logpath = /var/log/auth.log`
        1. `maxretry = 3`
        1. `bantime = -1`
    1. `sudo service fail2ban restart`
    1. Check for any banned IPs later with `sudo fail2ban-client status sshd`
1. Configure git user. Cache the personal access token from Github for one week.
    1. `git config --global user.email "foo@example.com"`
    1. `git config --global user.name "Your Name"`
    1. `git config --global credential.helper cache`
    1. `git config --global credential.helper 'cache --timeout=604800'`
    1. Assuming your Github user auth is configured like mine, copy your personal access token to the clipboard and `ssh` into the host
    1. Pull any private repo: `git clone [repo's https url] [repo dir]`
    1. From inside each repo working directory: `git config pull.rebase false`
1. (Optional) Set up a Node.js environment
    1. Install `nvm`, the Node.js version manager.
    1. Copy the `curl` script from https://github.com/nvm-sh/nvm and execute it.
    1. Exit and restart the terminal to get `nvm` onto the path.
    1. `cd` to this repo and `nvm use` then `nvm install [version]`
    1. `sudo apt install make gcc g++ python dpkg-dev`
    1. Edit your apt sources list (in the .d directory) to add the source servers.
        1. `sudo cp /etc/apt/sources.list /etc/apt/sources.list.d/foo.list`
        1. `sudo nano /etc/apt/sources.list.d/foo.list`
        1. Comment out all the `deb` lines, uncomment all the `deb-src` lines and save
        1. `sudo apt update`
    1. (Optional) If re-installing, don't forget to copy up the `dro.log` file to `out`.
    1. Switch to the `README.md` in this repo to configure and run the dro.
1. (Optional) Switch the display to portrait mode.
    1. Test this works first: `sudo echo 3 | sudo tee /sys/class/graphics/fbcon/rotate_all`
    1. Consider a sysvinit script or similar for this. The Raspberry Pi bootloader can't be configured to do this.
