# guru-client admin/daily usage wrap on debian linux terminal

- file sharing based on sshfs mounts - no any local data on shutdown computer
- daemon module to keep thing up to date an schedule stuff
- lan services can be used when tunneled to local computer
- secure-ish, only way to communicate is ssh with known key
- keep daily notes, convert them to to wiki, open office, pdf or html..
- managing backups between hosts and servers
- runs without gui, minimal system like raspberrypi or phones
- system level keyboard shortcuts
- server module contain instructions to set services based on docker/kubernates clusters
- deep corsair keyboard indicator support
- feature greep: read news, save video, convert formats, see modules..
- as and cv project what comes to dev-op, linux and bash skills

casa@ujo.guru 2020-2021


## runnign demo

guru-client reguires account in server to store configuration and status data.
Hesus Testman have a demo account access.
Basic configuration is set to use minimal read only system.

```bash
git clone https://github.com/ugcasa/guru-client.git
cd guru-client
./install.sh -c -u hesus

# logout and login to run /etc/profiles to set path

# pull current configureations for Hesus
gr config pull

# setting can be changed with dialog by
gr config user

# or with vim
gr config edit

# take configuration on use
gr config export

# mount system folder
gr mount system

# start daemon
gr start

```

### reinstall

If something goes wrong, reinstall

```bash
./install.sh -fc -u hesus
```

### uninstalling

Uninstalling the test installation

```bash
gr uninstall
# or
guru uninstall
# or
$HOME/bin/uninstall.sh
```

## getting account to ujo.guru server

Cause of global cyber security state after yaer 2018.

Not available.
Ever.

Check [modules/server/README.md](./modules/server/README.md) for instructions to set own server.

----

[![License: GPL v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
