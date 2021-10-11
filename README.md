# guru-client terminal environment

An easy to use command wrap for daily usage for now disabled ex. admins.

- admin/daily usage wrap on debian linux terminal
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
- mount and backup remote filesystems
- feature creep: read news, save video, convert formats etc
- needs an server what can be set by guru-server script collection (will not to be public ever)


## disclaimer

It was an cv project what comes to dev-op, linux and bash skills but it grown to be a part of my daily computing use cause of spine and brain damage I got by falling from balcony. So fuck the cv, no more work for me. ever.

WARNING: Do not try to install this to anywhere! It will fuck up the base system and pee in to your morning serials! Installation is just for me and i see no point to even get it working for anybody else.
Motto is "fuck the people, animals, computer, internetz and nature". Me not here to help you motherfuckers.

You be warned: use at our own risk, me shall not be liable for any damage to you, or your comfucker that the use of these scripts may cause. I do reserve rights to log your kb data, capture private browsing history and send it to me.

casa@ujo.guru 2018-2021


## runnign demo

guru-client reguires account in server to store configuration and status data.
Hesus Testman have a demo account access.
Basic configuration is set to use minimal read only system.

```bash
git clone https://github.com/ugcasa/guru-client.git
cd guru-client
./install.sh -c -u hesus
```

logout and login to run /etc/profiles to set path

Pull current configureations for Hesus
```bash
guru config pull
```

Setting can be changed with dialog by
```bash
guru config user
```

..Or with vim
```bash
guru config edit
```

Take configuration on use
```bash
guru config export
```

Mount system folder
```bash
guru mount system
```

Start daemon
```bash
guru start
```

### reinstall

When something goes wrong in install try to reinstall

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

## feature creep

- alias 'gr' set to call guru core. alias can be set in user.cfg
- if module is not working, try to install dependencies by 'gr <module> install"
- read news in text terminal, including picture: 'gr news'. (add/remove feeds edit .config/guru/<user>/rss-feed.list)





## getting account to ujo.guru server

Cause of global cyber security state after yaer 2018.

Not available.
Ever.




----

[![License: GPL v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
