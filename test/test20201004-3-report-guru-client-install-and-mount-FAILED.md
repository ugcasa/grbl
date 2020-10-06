test20201004-3-report-guru-client-install-and-mount-FAILED.md
# Test Report 20201004-3 guru-client install and mount

mint 19.3 cinnamon "second user" while one active session on back round

target: re-test basic installation and to see how badly two user installation collide together
method: try to install and then mount all folders

## 1) clone OK

master cloned during previous test.

	roger@electra:/git/guru-client$ git pull origin core-flow
	Username for 'https://github.com': ugcasa
	Password for 'https://ugcasa@github.com':
	From https://github.com/ugcasa/guru-client
	 * branch            core-flow  -> FETCH_HEAD
	Updating ae89d5f..67c8336
	Fast-forward
	 cfg/{user.cfg => user-default.cfg}       |  83 ++++++++++++----------
	 core/common.sh                           | 109 ++++++++++++++++++++++++++++
	 {src => core}/config.sh                  |  62 +++++++++-------
	 core/core.sh                             | 294 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	 {src => core}/corsair.sh                 |  67 +++++++++--------
	 core/counter.sh                          |  95 +++++++++++++++++++++++++
	 {src => core}/daemon.sh                  |  42 +++++------
	 {src => core}/install.sh                 |  49 ++-----------
	 core/keyboard.sh                         | 146 +++++++++++++++++++++++++++++++++++++
	 {src/lib => core}/os.sh                  |   1 +
	 {src => core}/remote.sh                  |  52 +++++---------
	 src/lib/deco.sh => core/style.sh         |  78 ++------------------
	 {src => core}/system.sh                  |  21 +++---
	 core/uninstall.sh                        |  49 +++++++++++++
	 foray/datestamp.py                       |  25 +++++++
	 {src/trial => foray}/dialog-test.sh      |   0
	 {src/trial => foray}/dialog-wrap_test.sh |   0
	 {src/trial => foray}/fmradio.py          |   0
	 foray/hosts.sh                           | 221 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	 {src/trial => foray}/input.sh            |   0
	 {src/lib => foray}/install-pk2.sh        |  24 +++----
	 foray/poller.sh                          |  51 +++++++++++++
	 {src/trial => foray}/tme.py              |   0
	 icons/giocon-150px.png                   | Bin 6240 -> 0 bytes
	 icons/giocon-2000px.png                  | Bin 109457 -> 0 bytes
	 icons/giocon-256px.png                   | Bin 11058 -> 0 bytes
	 icons/giocon-48px.png                    | Bin 1929 -> 0 bytes
	 icons/giocon-512px.png                   | Bin 24081 -> 0 bytes
	 icons/my-connections.jpg                 | Bin 5323 -> 0 bytes
	 icons/noter-128px.png                    | Bin 11253 -> 0 bytes
	 icons/noter-256px.png                    | Bin 34008 -> 0 bytes
	 icons/noter-512px.png                    | Bin 110363 -> 0 bytes
	 icons/noter-512px.xcf                    | Bin 25296 -> 0 bytes
	 icons/noter-64px.png                     | Bin 3982 -> 0 bytes
	 icons/noter-c-512px.png                  | Bin 115067 -> 0 bytes
	 icons/noter-m-512px.png                  | Bin 110614 -> 0 bytes
	 icons/walk-trought.png                   | Bin 5222 -> 0 bytes
	 install.sh                               | 375 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++--------------------------
	 modules/conda.sh                         |  77 ++++++++++++++++++++
	 {src => modules}/mount.sh                |  59 +++++----------
	 modules/mqtt.sh                          | 114 +++++++++++++++++++++++++++++
	 modules/news.py                          | 365 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	 {src => modules}/note.sh                 |  72 ++++++++++---------
	 {src => modules}/phone.sh                |  96 +++++++++++++++----------
	 {src => modules}/play.sh                 |   5 +-
	 {src => modules}/print.sh                |  19 ++---
	 {src => modules}/project.sh              |  33 ++++++---
	 {src => modules}/scan.sh                 |   6 +-
	 {src/lib => modules}/ssh.sh              |  85 ++++++++++++++--------
	 {src => modules}/stamp.sh                |  62 +++++++++-------
	 {src => modules}/tag.sh                  |   7 ++
	 modules/timer.sh                         | 333 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	 modules/tor.sh                           | 120 +++++++++++++++++++++++++++++++
	 modules/trans.sh                         |  71 ++++++++++++++++++
	 modules/user.sh                          |  96 +++++++++++++++++++++++++
	 {src => modules}/vol.sh                  |   6 +-
	 modules/yle.sh                           | 202 ++++++++++++++++++++++++++++++++++++++++++++++++++++
	 src/conda.sh                             |  76 --------------------
	 src/counter.sh                           |  83 ----------------------
	 src/functions.sh                         | 164 ------------------------------------------
	 src/guru.sh                              | 228 ----------------------------------------------------------
	 src/gururc.sh                            | 134 ----------------------------------
	 src/keyboard.sh                          | 125 --------------------------------
	 src/lib/common.sh                        |  16 -----
	 src/mqtt.sh                              | 111 -----------------------------
	 src/obsolete/datestamp.py                |  25 -------
	 src/obsolete/prompt.py                   |  22 ------
	 src/obsolete/prompt.sh                   |   5 --
	 src/obsolete/unmount.sh                  |   4 --
	 src/poller.sh                            |  51 -------------
	 src/timer.sh                             | 333 -------------------------------------------------------------------------------------
	 src/tobashrc.sh                          |  10 ---
	 src/trial/datestamp.py                   |  25 -------
	 src/trial/hosts.sh                       | 221 --------------------------------------------------------
	 src/uninstall.sh                         |  95 -------------------------
	 src/user.sh                              |  92 ------------------------
	 src/uutiset.py                           | 356 -------------------------------------------------------------------------------------------
	 src/yle.sh                               | 197 --------------------------------------------------
	 {src/test => test}/template.sh           |   2 +-
	 {src/test => test}/test-config.sh        |   0
	 {src/test => test}/test-mount.sh         |   0
	 {src/test => test}/test-note.sh          |   0
	 {src/test => test}/test-project.sh       |   0
	 {src/test => test}/test-remote.sh        |   0
	 {src/test => test}/test-system.sh        |   0
	 {src/test => test}/test.sh               |   4 +-
	 86 files changed, 3102 insertions(+), 2949 deletions(-)
	 rename cfg/{user.cfg => user-default.cfg} (63%)
	 create mode 100755 core/common.sh
	 rename {src => core}/config.sh (67%)
	 create mode 100755 core/core.sh
	 rename {src => core}/corsair.sh (79%)
	 create mode 100755 core/counter.sh
	 rename {src => core}/daemon.sh (77%)
	 rename {src => core}/install.sh (84%)
	 create mode 100755 core/keyboard.sh
	 rename {src/lib => core}/os.sh (99%)
	 rename {src => core}/remote.sh (73%)
	 rename src/lib/deco.sh => core/style.sh (58%)
	 rename {src => core}/system.sh (76%)
	 create mode 100755 core/uninstall.sh
	 create mode 100755 foray/datestamp.py
	 rename {src/trial => foray}/dialog-test.sh (100%)
	 rename {src/trial => foray}/dialog-wrap_test.sh (100%)
	 rename {src/trial => foray}/fmradio.py (100%)
	 create mode 100755 foray/hosts.sh
	 rename {src/trial => foray}/input.sh (100%)
	 rename {src/lib => foray}/install-pk2.sh (75%)
	 create mode 100755 foray/poller.sh
	 rename {src/trial => foray}/tme.py (100%)
	 delete mode 100644 icons/giocon-150px.png
	 delete mode 100644 icons/giocon-2000px.png
	 delete mode 100644 icons/giocon-256px.png
	 delete mode 100644 icons/giocon-48px.png
	 delete mode 100644 icons/giocon-512px.png
	 delete mode 100644 icons/my-connections.jpg
	 delete mode 100644 icons/noter-128px.png
	 delete mode 100644 icons/noter-256px.png
	 delete mode 100644 icons/noter-512px.png
	 delete mode 100644 icons/noter-512px.xcf
	 delete mode 100644 icons/noter-64px.png
	 delete mode 100644 icons/noter-c-512px.png
	 delete mode 100644 icons/noter-m-512px.png
	 delete mode 100644 icons/walk-trought.png
	 create mode 100755 modules/conda.sh
	 rename {src => modules}/mount.sh (82%)
	 create mode 100755 modules/mqtt.sh
	 create mode 100755 modules/news.py
	 rename {src => modules}/note.sh (85%)
	 rename {src => modules}/phone.sh (74%)
	 rename {src => modules}/play.sh (97%)
	 rename {src => modules}/print.sh (53%)
	 rename {src => modules}/project.sh (79%)
	 rename {src => modules}/scan.sh (96%)
	 rename {src/lib => modules}/ssh.sh (78%)
	 rename {src => modules}/stamp.sh (65%)
	 rename {src => modules}/tag.sh (98%)
	 create mode 100755 modules/timer.sh
	 create mode 100755 modules/tor.sh
	 create mode 100755 modules/trans.sh
	 create mode 100755 modules/user.sh
	 rename {src => modules}/vol.sh (93%)
	 create mode 100755 modules/yle.sh
	 delete mode 100755 src/conda.sh
	 delete mode 100755 src/counter.sh
	 delete mode 100755 src/functions.sh
	 delete mode 100755 src/guru.sh
	 delete mode 100755 src/gururc.sh
	 delete mode 100755 src/keyboard.sh
	 delete mode 100755 src/lib/common.sh
	 delete mode 100755 src/mqtt.sh
	 delete mode 100755 src/obsolete/datestamp.py
	 delete mode 100755 src/obsolete/prompt.py
	 delete mode 100755 src/obsolete/prompt.sh
	 delete mode 100755 src/obsolete/unmount.sh
	 delete mode 100755 src/poller.sh
	 delete mode 100755 src/timer.sh
	 delete mode 100755 src/tobashrc.sh
	 delete mode 100755 src/trial/datestamp.py
	 delete mode 100755 src/trial/hosts.sh
	 delete mode 100755 src/uninstall.sh
	 delete mode 100755 src/user.sh
	 delete mode 100755 src/uutiset.py
	 delete mode 100755 src/yle.sh
	 rename {src/test => test}/template.sh (97%)
	 rename {src/test => test}/test-config.sh (100%)
	 rename {src/test => test}/test-mount.sh (100%)
	 rename {src/test => test}/test-note.sh (100%)
	 rename {src/test => test}/test-project.sh (100%)
	 rename {src/test => test}/test-remote.sh (100%)
	 rename {src/test => test}/test-system.sh (100%)
	 rename {src/test => test}/test.sh (99%)

	roger@electra:/git/guru-client$ ls
	cfg  core  foray  install.sh  LICENSE.md  modules  README.md  test

PASSED

## 2) install attempt 1 NOT_VALID

	roger@electra:/git/guru-client$ ./install.sh
	already installed, force re-install [y/n] : ^C

	roger@electra:/git/guru-client$ ./install.sh -V
	checking current installation..
	already installed, force re-install [y/n] : ^C

.bashrc edited, gururc and gururc2 launcher removed

## 3) install attempt 2 FAILED

	roger@electra:/git/guru-client$ ./install.sh -V
	checking current installation..
	setting up launchers.. DONE
	checking launchers.. PASSED
	setting up folder structure.. DONE
	checking created folders.. PASSED
	installing core.. DONE
	checking core modules
	common.sh.. OK
	config.sh.. OK
	core.sh.. OK
	corsair.sh.. OK
	counter.sh.. OK
	daemon.sh.. OK
	install.sh.. OK
	keyboard.sh.. OK
	os.sh.. OK
	remote.sh.. OK
	style.sh.. OK
	system.sh.. OK
	uninstall.sh.. OK
	checking configuration files
	kbbind.guruio.cfg.. OK
	phone.locations.cfg.. OK
	rss-feed.list.. OK
	user-default.cfg.. OK
	vt.list.. OK
	installing modules
	installing mount.. DONE
	installing mqtt.. DONE
	installing note.. DONE
	installing phone.. DONE
	installing print.. DONE
	installing project.. DONE
	installing scan.. DONE
	installing ssh.. DONE
	installing stamp.. DONE
	installing tag.. DONE
	installing timer.. DONE
	installing tor.. DONE
	installing trans.. DONE
	installing user.. DONE
	installing vol.. DONE
	installing yle.. DONE
	installing news.. DONE
	checking installed modules
	mount.. OK
	mqtt.. OK
	note.. OK
	phone.. OK
	print.. OK
	project.. OK
	scan.. OK
	ssh.. OK
	stamp.. OK
	tag.. OK
	timer.. OK
	tor.. OK
	trans.. OK
	user.. OK
	vol.. OK
	yle.. OK
	news.. OK
	setting user configurations
	user specific configuration not found, using default..
	/home/roger/.config/guru//user.cfg > /home/roger/.gururc2
	cat: /home/roger/.config/guru/installed.modules: No such file or directory 									<-- BUG #1: should be created
	cat: /home/roger/.config/guru/installed.modules: No such file or directory
	core/keyboard.sh: line 130: /home/roger/.config/guru/roger/kbbind.guruio.cfg: No such file or directory  	<-- BUG #2: make installer copy this to personal config folder
	101: TBD keyboard.set_shortcut_linuxmint   	                  												<-- BUG #3: should use keyboard.set_guru_linuxmint fucntion

FAILED: see bugs #1 to #3. installation is valid for test to continue: issues are not fixed.


## 4) check path NOT_VALID

	roger@electra:/git/guru-client$ set |grep PATH
	DEFAULTS_PATH=/usr/share/gconf/cinnamon.default.path
	MANDATORY_PATH=/usr/share/gconf/cinnamon.mandatory.path
	PATH=/home/roger/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin
	XDG_SEAT_PATH=/org/freedesktop/DisplayManager/Seat0
	XDG_SESSION_PATH=/org/freedesktop/DisplayManager/Session2
	    local PATH=$PATH:/sbin;
	    if [[ -z "${CDPATH:-}" || "$cur" == ?(.)?(.)/* ]]; then
	    for i in ${CDPATH//:/'
	    PATH=$PATH:/usr/sbin:/sbin:/usr/local/sbin type $1 &> /dev/null
	    COMPREPLY=($( compgen -W "$( PATH="$PATH:/sbin" lsmod |         awk '{if (NR != 1) print $1}' )" -- "$1" ))
	    local PATH=$PATH:/sbin;
	    local PATH="$PATH:/sbin:/usr/sbin";
	    COMPREPLY+=($( compgen -W         "$( PATH="$PATH:/sbin" lspci -n | awk '{print $3}')" -- "$cur" ))
	    local PATH=$PATH:/sbin:/usr/sbin:/usr/local/sbin;
	    COMPREPLY+=($( compgen -W         "$( PATH="$PATH:/sbin" lsusb | awk '{print $6}' )" -- "$cur" ))

EXPECTED: logout made during the last test this makes .profile to set bin to path


## 5) guru startup PASSED

	roger@electra:/git/guru-client$ guru
	cat: /home/roger/.config/guru/installed.modules: No such file or directory 						<-- BUG #1
	guru in shell mode (type 'help' enter for help) 								 				OK
	cat: /home/roger/.config/guru/installed.modules: No such file or directory 						<-- BUG #1
	roger@guru:/home/roger/git/guru-client$ exit

PASSSED


## 6) start new terminal

gnome-terminal

	cat: /home/roger/.config/guru/installed.modules: No such file or directory
	roger@electra:$

how core is run with bash?

## 7) fix BUG #1 temperaly TESTER_ACTION


echo "mount mqtt note phone print project scan ssh stamp tag timer tor trans user vol yle news corsair config remote counter core daemon install system uninstall" >  /home/roger/.config/guru/installed.modules

roger@electra:/git/guru-client$ guru
	guru in shell mode (type 'help' enter for help)

OK

## 8) environmental variables PASSED

	roger@electra:/git/guru-client$ set |grep GURU
	roger@electra:/git/guru-client$

EXPECTED: bash not reloaded

	roger@electra:/git/guru-client$ bash
	roger@electra:/git/guru-client$ set |grep GURU
	GURU_ACCESS_DOMAIN=127.0.0.1
	GURU_ACCESS_KEY_FILE=/home/roger/.ssh/ujo.guru_id_rsa
	GURU_ACCESS_LAN_IP=
	GURU_ACCESS_LAN_PORT=
	GURU_ACCESS_PORT=22
	GURU_ACCESS_USERNAME=roger
	GURU_BIN=/home/roger/bin
	GURU_CALL=guru
	GURU_CFG=/home/roger/.config/guru
	GURU_CLOUD_DOMAIN=
	GURU_CLOUD_KEY_FILE=/home/roger/.ssh/ujo.guru_id_rsa
	GURU_CLOUD_LAN_IP=127.0.0.1
	GURU_CLOUD_LAN_PORT=22
	GURU_CLOUD_PORT=
	GURU_CLOUD_USERNAME=roger
	GURU_COLOR_PATH_AT=lblue
	GURU_COLOR_PATH_CALL=lcyan
	GURU_COLOR_PATH_DIR=normal
	GURU_COLOR_PATH_INPUT=normal
	GURU_COLOR_PATH_SEPA=white
	GURU_COLOR_PATH_USER=cyan
	GURU_DAEMON_INTERVAL=150
	GURU_DAEMON_POLL_LIST=([0]="system" [1]="remote" [2]="mqtt")
	GURU_FILE_CORE_DUMP=/home/roger/.data/guru-client.CORE_DUMP
	GURU_FILE_ERROR_MSG=/tmp/guru-last.error
	GURU_FILE_LOG=/home/roger/.data/guru-client.log
	GURU_FILE_TRACKDATA=/home/roger/.data/timetrack/current_work.csv
	GURU_FILE_TRACKLAST=/home/roger/.data/timetrack/timer.last
	GURU_FILE_TRACKSTATUS=/home/roger/.data/timetrack/timer.status
	GURU_FLAG_AUDIO=true
	GURU_FLAG_COLOR=true
	GURU_FLAG_VERBOSE=
	GURU_FORMAT_DATE=%-d.%-m.%Y
	GURU_FORMAT_FILE_DATE=%Y%m%d
	GURU_FORMAT_FILE_TIME=%H%M%S
	GURU_FORMAT_TIME=%H:%M:%S
	GURU_GIT_EMAIL=
	GURU_GIT_HOME=/home/roger/git
	GURU_GIT_KEY_FILE=/home/roger/.ssh/
	GURU_GIT_REMOTE=github
	GURU_GIT_TRIALS=/home/roger/git/foray
	GURU_GIT_USER=
	GURU_HOSTNAME=electra
	GURU_KEYBIND_DATESTAMP=
	GURU_KEYBIND_NOTE='<Ctrl><Super>n'
	GURU_KEYBIND_PICTURE_MD=
	GURU_KEYBIND_SIGNATURE=
	GURU_KEYBIND_TERMINAL=F1
	GURU_KEYBIND_TIMESTAMP='<Ctrl><Super>t'
	GURU_LOCAL_ACCOUNTING=/home/roger/Economics
	GURU_LOCAL_CHROME_DATA=/home/roger/.config/chromium/roger@ujo.guru
	GURU_LOCAL_COUNTER=/home/roger/.data/counters
	GURU_LOCAL_PERSONAL_ACCOUNTING=/home/roger/Economics/Personal
	GURU_LOCAL_PROJECT=/home/roger/.data/project
	GURU_LOCAL_TRASH=/home/roger/.data/trash
	GURU_LOCAL_WORKTRACK=/home/roger/.data/timetrack
	GURU_MODULES=
	GURU_MOUNT_AUDIO=([0]="/home/roger/audio" [1]="/home/roger/guru/audio")
	GURU_MOUNT_DOCUMENTS=([0]="/home/roger/documents" [1]="/home/roger/guru/documents")
	GURU_MOUNT_MUSIC=([0]="/home/roger/music" [1]="/home/roger/guru/music")
	GURU_MOUNT_NOTES=([0]="/home/roger/notes" [1]="/home/roger/guru/notes")
	GURU_MOUNT_PHOTOS=([0]="/home/roger/photos" [1]="/home/roger/guru/photos")
	GURU_MOUNT_PICTURES=([0]="/home/roger/pictures" [1]="/home/roger/guru/pictures")
	GURU_MOUNT_TEMPLATES=([0]="/home/roger/templates" [1]="/home/roger/guru/templates")
	GURU_MOUNT_VIDEO=([0]="/home/roger/videos" [1]="/home/roger/guru/videos")
	GURU_MQTT_CLIENT=electra
	GURU_MQTT_KEY_FILE=/home/roger/.ssh/mqtt.electra_id_rsa
	GURU_MQTT_LOCAL_PORT=
	GURU_MQTT_LOCAL_SERVER=
	GURU_MQTT_PASSWORD=
	GURU_MQTT_REMOTE_PORT=
	GURU_MQTT_REMOTE_SERVER=
	GURU_MQTT_USERNAME=
	GURU_NOTE_CHANGE_LOG=true
	GURU_NOTE_HEADER='Notes Roger von Gullit'
	GURU_NOTE_PROJECTS=/home/roger/.data/sublime-projects
	GURU_PHONE_LAN_IP=
	GURU_PHONE_LAN_PORT=
	GURU_PHONE_MOUNTPOINT=/home/roger/Phone
	GURU_PHONE_PASSWORD=
	GURU_PHONE_USERNAME=
	GURU_PREFERRED_BROWSER=firefox
	GURU_PREFERRED_EDITOR=subl
	GURU_PREFERRED_OFFICE_DOC=libreoffice
	GURU_PREFERRED_OFFICE_SPR=libreoffice
	GURU_PREFERRED_TERMINAL=gnome-terminal
	GURU_SYSTEM_APPLICATIONS=/home/roger/apps
	GURU_SYSTEM_INSTALL_TYPE=desktop
	GURU_SYSTEM_MOUNT=([0]="/home/roger/.data" [1]="/home/roger/guru/data")
	GURU_SYSTEM_NAME=guru
	GURU_SYSTEM_RC=/home/roger/.gururc2
	GURU_SYSTEM_VERSION=core-module
	GURU_TEST_RESULT=PASSED
	GURU_USER_DOMAIN=ujo.guru
	GURU_USER_EMAIL=roger@ujo.guru
	GURU_USER_FULL_NAME='Roger von Gullit'
	GURU_USER_NAME=roger
	GURU_USER_PHONE='+358 00000 000'
	GURU_USER_TEAM=ujo.guru
	GURU_YOUTUBE_API_KEY=


## 9) ssh.sh help  FAILED

	roger@electra:/git/guru-client$ guru ssh help
	ssh: Could not resolve hostname help: Name or service not known 				<.. BUG #4: should printout help nto make connection
	ERROR
	ERROR 																			<-- TODO remove curernt error manager

## 10) data mount NOT VALID

	roger@electra:$ cd .data
	bash: cd: .data: No such file or directory

EXPECTED: mount.system removed from core.main BUT:

```bash
	core.main () {
	    counter.main add guru-runned >/dev/null 								 	  <-- BUG 5: should mount .data
```


## 11) mount.sh help PASSED

	roger@electra:$ guru mount help
	usage:    guru mount|unount|check|check-system <source> <target>

	roger@electra:$ guru mount help -V
	guru-client mount help

	usage:    guru mount|unount|check|check-system <source> <target>

	commands:
	 ls                       list of mounted folders
	 mount [source] [target]  mount folder in file server to local folder
	 unmount [mount_point]    unmount [mount_point]
	 mount all                mount all known folders in server
	                          edit /home/roger/.config/guru/roger/user.cfg or run
	                          'guru config user' to setup default mountpoints
	                          more information of adding default mountpoint type: guru mount help-default
	 unmount [all]            unmount all default folders
	 check [target]           check that mount point is mounted
	 check-system             check that guru system folder is mounted

	example:
	      guru mount /home/roger/share /home/roger/test-mount
	      guru umount /home/roger/test-mount


## 12) mount.sh check FAILED

	roger@electra:$ mount check .data
	mount: only root can do that

roger is't a sudoer, cause roger ia a gardener


## 13) mount check-system PASSED

	roger@electra:$ guru mount check-system -V
	18:43:38 /home/roger/.data status OFFLINE

NEW_FEATURE: mount system


## guru mount ls FAILED

	roger@electra:$ guru mount ls
	/home/casa/.data
	/home/casa/Notes
	/home/casa/Economics
	/home/casa/Templates
	/home/casa/Documents
	/home/casa/Photos
	/home/casa/Audio
	/home/casa/Videos
	/home/casa/Music
	/home/casa/ujo.guru
	/home/casa/bubble.bay
	/home/casa/Pictures

BUG #6: leak fron another user: fix by adding username to grep list

NEW_FEAURE: print status after mountpoint

## guru mount info FAILED

	roger@electra:$ guru mount info
	roger@192.168.1.10  /home/casa/Track                /home/casa/.data                        4-19:11:23           4581
	roger@192.168.1.10  /home/casa/Notes                /home/casa/Notes                        18:16:33             23187
	roger@192.168.1.10  /home/casa/ujo.guru/Accounting  /home/casa/Economics                    18:16:29             23212
	roger@192.168.1.10  /home/casa/Templates            /home/casa/Templates                    18:16:26             23235
	roger@192.168.1.10  /home/casa/Documents            /home/casa/Documents                    18:16:21             23270
	roger@192.168.1.10  /home/casa/Photos               /home/casa/Photos                       18:16:17             23552
	roger@192.168.1.10  /home/casa/Audio                /home/casa/Audio                        18:16:14             23705
	roger@192.168.1.10  /home/casa/Videos               /home/casa/Videos                       18:16:10             23727
	roger@192.168.1.10  /home/casa/Music                /home/casa/Music                        18:16:07             23755
	roger@192.168.1.10  /home/casa/ujo.guru/Accounting  /home/casa/Economicsroger@192.168.1.10  /home/casa/ujo.guru  /home/casa/ujo.guru  18:16:29  23212
	roger@192.168.1.10  /home/casa/bubble               /home/casa/bubble.bay                   18:16:00             24294
	roger@192.168.1.10  /home/casa/Pictures             /home/casa/Pictures                     18:15:41             24747


WHTF:

	"roger@192.168.1.10"

Why labelled as rogers connection? some ripples fron previous tests whit other user login?

	oger@electra:~$ ps auxf |grep sshfs
	casa      4581  0.0  0.0 314344  1416 ?        Ssl  Sep29   0:03  \_ sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 -p 22 casa@192.168.1.10:/home/casa/Track /home/casa/.data
	casa     23187  0.0  0.0 388208   524 ?        Ssl  00:30   0:01  \_ sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 -p 22 casa@192.168.1.10:/home/casa/Notes /home/casa/Notes
	casa     23212  0.0  0.0 388212   496 ?        Ssl  00:30   0:00  \_ sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 -p 22 casa@192.168.1.10:/home/casa/ujo.guru/Accounting /home/casa/Economics
	casa     23235  0.0  0.0 388212   496 ?        Ssl  00:30   0:00  \_ sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 -p 22 casa@192.168.1.10:/home/casa/Templates /home/casa/Templates
	casa     23270  0.0  0.0 388220   524 ?        Ssl  00:30   0:00  \_ sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 -p 22 casa@192.168.1.10:/home/casa/Documents /home/casa/Documents
	casa     23552  0.0  0.0 462080   500 ?        Ssl  00:31   0:00  \_ sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 -p 22 casa@192.168.1.10:/home/casa/Photos /home/casa/Photos
	casa     23705  0.0  0.0 388208   520 ?        Ssl  00:31   0:00  \_ sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 -p 22 casa@192.168.1.10:/home/casa/Audio /home/casa/Audio
	casa     23727  0.0  0.0 462080   520 ?        Ssl  00:31   0:00  \_ sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 -p 22 casa@192.168.1.10:/home/casa/Videos /home/casa/Videos
	casa     23755  0.0  0.0 388288  1416 ?        Ssl  00:31   0:00  \_ sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 -p 22 casa@192.168.1.10:/home/casa/Music /home/casa/Music
	casa     24241  0.0  0.0 683692   812 ?        Ssl  00:31   0:00  \_ sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 -p 22 casa@192.168.1.10:/home/casa/ujo.guru /home/casa/ujo.guru
	casa     24294  0.0  0.0 388212   524 ?        Ssl  00:31   0:00  \_ sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 -p 22 casa@192.168.1.10:/home/casa/bubble /home/casa/bubble.bay
	casa     24747  0.0  0.0 388248  1256 ?        Ssl  00:31   0:00  \_ sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 -p 22 casa@192.168.1.10:/home/casa/Pictures /home/casa/Pictures

least here the are casa's connections.. is "roger@nnn" a faked or assumed value?

FIX_ATTEMPT: try to log casa out - canceled, see above

WHTF:

	roger@192.168.1.10  /home/casa/ujo.guru/Accounting  /home/casa/Economicsroger@192.168.1.10  /home/casa/ujo.guru  /home/casa/ujo.guru  18:16:29  23212

what is this?

	/home/casa/Economicsroger  			<-- mis-position or variable on printout, or special character causing line fuck-ups? Not shown on ps list


## guru mount all - FAILED

	roger@electra:~$ guru mount all
	roger@127.0.0.1's password:

found out on test 20201004-2 (or something) asks password about 500 times and result is broken mounts

NEW_FEATURE: if no key generated, go and generate if

----

**Test ends**

operator: casa@ujo.guru 2020104 19:15

