# guru-client easy to use platform for ubuntu based os.

guru-client contains:

- simplify and rationalize terminal commands (core.sh)
- module based structure, all modules should run alone, but may lean on guru-cli environmental variables
- user level flag controlled daemon for timed operations to avoid need of root privileges (daemon.sh)
- sshfs based file sharing in local network (mount.sh)
- ssh based keys only access to local server (ssh.sh)
- ssl tunnel management tools (tunnel.sh)
- keeps critical personal keys, tokens and configurations available for future projects, locally and server
- takes backup from files and configurations from server to local encrypted hd.
- takes backups of containerd services  (backup.sh)
- vpn account and client usage simplification (vpn.sh)
- local message network clinet tools (mqtt.sh)
- simple speaking capabilities (say.sh)
- simple project, timing and invoicing tools (project.sh, timer.sh, counter.sh)
- system upgrading, installing and removing tools (system.sh, os.sh)
- many fun tools for Corsair keyboard and mice based on ckb-next driver (corsair.sh, corsair_raw.sh)
- finance tools for budgeting and follow up (stonks.sh) prototype
- few cloud api's (fingrid.sh, google.sh, stonks/op.sh)
- audio, video and picture placing converting and tagging tools (place.sh, convert.sh, tag.sh)
- youtube and yleisradio file download and stream viewing tools (youtube.sh yle.sh)
- audio control and tunneling tools
- web radio and fm radio listening tools with three key control (radio.sh )
- tor tools (tor.sh)
- microchip, st and at-mega chip programmer environment installer (program.sh)
- messaging tool installer and terminal based integration (telegram.sh)
- some simple ai tool integrations (ai.sh ailib.sh)
- note taking, coding and idea cloud tools edi integration subl, vscode, obsidian (note.sh, configs)
- some automatic template generating tools for new modules and semi automated test templates

guru.server will be:

- local server scripts guru-server (under development)

casa@ujo.guru 2018-2024


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

Pull current configurations for Hesus
```bash
guru config pull
```

Setting can be changed with dialog by
```bash
guru config user
```

..Or with editor
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

Cause of global cyber security state after year 2018 curent server is not available for external users. 

Sandbox server will be added during year 2024. 

## Examples - Basic functions

### UI print function 'gr.msg' and read function 'gr.ask'

gr.msg supports verbose leveling, text color, speak out, control line width, blink indication keys on keyboard, timestamps etc.
gr.ask is simple yes no selector. it is ´read´ wrap with almost same properties than gr.msg.
With both, message string cannot stat with a line '-'


```bash
gr.ask -s "did it explode?" && gr.msg -c green "it did" -s || gr.msg -s "it didn't"
```

speaks out the question and answer, blinks 'y' key green and 'n' key red on corsair rgb gaming keyboard.

----

[![License: GPL v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
