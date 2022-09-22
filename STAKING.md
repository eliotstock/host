# Build an Ethereum 2 staking machine

1. (Optional) Update the firmware in your router, factory reset, reconfigure.
1. Get an Intel NUC.
1. Set the machine to restart after a power failure.
    1. `F2` during boot to get into BIOS settings
    1. Power > Secondary power settings
    1. After power failure: Power on
    1. `F10` to save and exit
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
1. Partition and mount the big drive
    1. `lsblck` and confirm the big drive isn't mounted yet and is called `sda`
    1. `sudo parted --list` and confirm it's not partitioned yet
    1. `sudo fdisk /dev/sda`, `n` for new partition, `p` for primary, `1`, default first sector, default last sector, `w` to write.
    1. `sudo parted /dev/sda`, `mklabel gpt`, `unit TB`, `mkpart`, `primary`, `ext4`, `0`, `2`, `print` and check output, `quit`.
    1. Format the partition: `sudo mkfs -t ext4 /dev/sda`
    1. Get the UUID for the drive from `sudo blkid`
    1. Add something like this to the bottom of `/etc/fstab`: `/dev/disk/by-uuid/8723beb1-8bb4-4a34-8c01-c309361eedc5 /data ext4 defaults 0 2`
    1. `sudo mount -a` and confirm the drive is mounted with `ls -lah /data`
    1. Make the drive writable by your user with `sudo chown -R [USERNAME]:[USERNAME] /data`
    1. `df -H` and confirm the drive is there and mostly free space
    1. Reboot and make sure the drive mounts again
1. Test the performance of the big drive
    1. `sudo apt install fio`
    1. `fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=test --filename=random_read_write.fio --bs=4k --iodepth=64 --size=4G --readwrite=randrw --rwmixread=75`
    1. Output is explained here: https://tobert.github.io/post/2014-04-17-fio-output-explained.html
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
    1. `sudo ufw allow 30303 comment 'execution client'`
    1. `sudo ufw allow 9000 comment 'consensus client'`
    1. `sudo ufw allow 8545/tcp comment 'execution client health'`
    1. `sudo ufw allow 8551/tcp comment 'execution client health'`
    1. `sudo ufw enable`
    1. Note that `http` and `https` are absent above.
    1. Check which ports are accessible with `sudo ufw status`
    1. Also block pings: `sudo nano /etc/ufw/before.rules`, find the line reading `A ufw-before-input -p icmp --icmp-type echo-request -j ACCEPT` and change `ACCEPT` to `DROP`
    1. `sudo ufw reload`
1. If you chose the wrong hostname during the installer, change it now. `sudo nano /etc/hostname` and pick a cool hostname.
1. Update packages and get some stuff
    1. `sudo apt update`
    1. `sudo apt upgrade` (make coffee)
    1. `sudo apt install net-tools emacs git`
1. Make sure that `unattended-updates` works for more than just security updates and includes non-Ubuntu PPAs.
    1. `sudo nano /etc/apt/apt.conf.d/50unattended-upgrades`
    1. Change the origins section to this:
```
Unattended-Upgrade::Origins-Pattern {
      "o=*";
}
```
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
1. Forward ports from the router to the host:
    1. Any execution client: 30303 (both TCP and UDP)
    1. Lighthouse (consensus client): 9000 (both TCP and UDP)
    1. Only while travelling, SSH: [redacted] TCP
1. Install the execution client, Nethermind
    1. Follow instructions here: https://docs.nethermind.io/nethermind/first-steps-with-nethermind/getting-started. Use the Ubuntu repo.
    1. Create a directory for the Rocks DB: `mkdir /data/nethermind`
    1. Run the client as your normal user `nethermind --config goerli --baseDbPath /data/nethermind --JsonRpc.Enabled true`
    1. Follow instructions for `systemd` running here: https://docs.nethermind.io/nethermind/first-steps-with-nethermind/manage-nethermind-with-systemd, except:
        1. Create the `nethermind` user with a specific home dir: `sudo useradd -m -s /bin/bash -d /data/nethermind nethermind`
        1. Note that `adduser` accepts ` --disabled-password` but the lower level `useradd` does not.
    1. Add the `nethermind` user to sudoers: `sudo usermod -aG sudo nethermind`
    1. TODO: Maybe not: Set a password for the `nethermind` user
        1. `sudo -i`
        1. `passwd nethermind`
    1. Change to the `nethermind` user: `sudo su nethermind`
    1. Run the serivce: `sudo service nethermind start`
    1. Check the output: `journalctl -u nethermind -f`
    1. Enable autorun: `sudo systemctl enable nethermind`
    1. TODO: Blocked on docs bug: https://github.com/NethermindEth/nethermind/issues/4482
    1. Disable the `systemd` unit while it isn't working on boot: `sudo systemctl disable nethermind`
1. Install the consensus client, Lighthouse.
    1. Go to https://github.com/sigp/lighthouse/releases and find the latest (non-portable) release, with suffix `x86_64-unknown-linux-gnu`. Download, extract and delete  it on the host.
        1. `wget https://github.com/sigp/lighthouse/releases/download/v3.1.0/lighthouse-v3.1.0-x86_64-unknown-linux-gnu.tar.gz`
        1. `tar -xvf lighthouse-v3.1.0-x86_64-unknown-linux-gnu.tar.gz`
        1. `rm lighthouse-v3.1.0-x86_64-unknown-linux-gnu.tar.gz`
    1. Make sure it runs: `./lighthouse --version`
    1. Move the binary out of your home dir:
        1. `sudo mv ./lighthouse /usr/bin`
        1. `sudo chown root:root /usr/bin/lighthouse`
    1. Do the key management stuff: https://lighthouse-book.sigmaprime.io/key-management.html
        1. Create a password file for this network: `nano stake-goerli.pass` and `chmod 600 ./stake-goerli.pass`
        1. `lighthouse --network prater account wallet create --name stake-goerli --password-file stake-goerli.pass`
        1. Write down mnemonic -> sock drawer (not really obvs)
        1. `lighthouse --network prater account validator create --wallet-name stake-goerli --wallet-password stake-goerli.pass --count 1`
1. Do the Staking Launchpad stuff at: https://launchpad.ethereum.org/en/generate-keys
    1. Download, extract and tidy up the staking deposit CLI.
        1. `wget https://github.com/ethereum/staking-deposit-cli/releases/download/v2.3.0/staking_deposit-cli-76ed782-linux-amd64.tar.gz`
        1. `tar -xvf staking_deposit-cli-76ed782-linux-amd64.tar.gz`
        1. `rm staking_deposit-cli-76ed782-linux-amd64.tar.gz`
        1. `mv staking_deposit-cli-76ed782-linux-amd64/deposit .`
        1. `rmdir staking_deposit-cli-76ed782-linux-amd64`
    1. Run it and record the mnemonic.
        1. `./deposit new-mnemoic --num_validators 1 --chain mainnet`
    1. This will generate:
        1. `~/validator_keys/deposit_data-*.json`
        1. `~/validator_keys/keystore-m_12381_3600_0_0_0-1663727039.json`
1. Just once, import the deposit keystore into the validator:
    1. `lighthouse --network mainnet --datadir /data/lighthouse/mainnet account validator import --directory ~/validator_keys` and enter the password for the depsoit keystore (ie. NOT the validator keystore)
1. Just once, generate a JWT token to be used by the clients:
    1. `openssl rand -hex 32 | tr -d "\n" > "/home/[username]/jwtsecret"`
1. Each time the server starts, run these three processes. For mainnet:
    1. Run `tmux`. Refresher:
        1. Create three panes with `C-b "`
        1. Move around the panes with `C-b [arrow keys]`
        1. Kill a pane with `C-b C-d`
        1. Dettach from the session with `C-b d`
    1. `nethermind --datadir /data/nethermind --config /usr/share/nethermind/configs/mainnet.cfg --JsonRpc.Enabled true --HealthChecks.Enabled true --HealthChecks.UIEnabled true --JsonRpc.JwtSecretFile /home/[username]/jwtsecret --JsonRpc.Host [host local IP address] --log DEBUG`
        1. This one will prompt for your password in order to become root, which it probably shouldn't.
        1. You can wait for this to sync before you continue, but you don't need to. The beacon node will retry if the execution client isn't sync'ed yet.
        1. Nethermind will expose:
            1. http://[host local IP address]:8545 (JSON RPC with `/health` and `/healthchecks-ui`)
            1. http://[host local IP address]:8551 (JSON RPC)
        1. Once up and running, check health with `curl http://localhost:8545/health` or go to http://localhost:8545/healthchecks-ui in a browser if you have a GUI.
    1. `lighthouse --network mainnet --datadir /data/lighthouse/mainnet bn --execution-endpoint http://localhost:8551 --execution-jwt /home/[username]/jwtsecret`
    1. `lighthouse --network mainnet --datadir /data/lighthouse/mainnet vc`
1. To stop staking:
    1. `lighthouse account validator exit`
1. Or just install and run `sedge`: https://docs.sedge.nethermind.io/docs/quickstart/install-guide
    1. Expect `segde` to use about 1TB per month in bandwidth. It'll be more while sync'ing, then decrease.
    1. To start the `sedge` containers once installed: `sudo docker compose -f docker-compose-scripts/docker-compose.yml up -d execution consensus`
    1. To stop them: `sudo docker compose -f docker-compose-scripts/docker-compose.yml down`
