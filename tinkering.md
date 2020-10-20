todo.md

# guru-client to do list


## architecture: module construction

Cause things tend to grow or/and get separated, only to bring parts back together later it is better to create folder for module and move workers and libraries in to it. <module>.sh is just an adapter for workers located in folder named by module name.

Example:

tagging is a file operation so tag.sh should be part of file module

	/modules/file.sh
	/modules/file/tag.sh
				  send.sh
				  poller.sh
				  remove.sh

with core "module" sub-foldering should not be in use.

**to solve 1.1): command flow vs. module/sub-module naming** natural command pass trough is:

	guru file send <file(s)/folder(s)><to_where>

but is more natural to say:

	guru send file (<file(s)/folder(s)>) (to) <to_where>

Solvable by logical naming and aliases or more clever core parser.

I would go with logical file naming and clever command flow, even though it can cause temporary inconsistencies.. it's more fun.

..or something else?

Does Kali bring here some solution?


## file module to contain file operations

- file module: send function to send stuff to server, phone, hostname ...
- include tag, poller,  module functionalities file folder and create hard alias for 'tag'


## config module improvements

- add 'enable' variable to user.cfg for all configurations (affects all modules that configured trough/by terminal environmental variables)
- update config module to handle all module configuration tasks
- move all user.sh functionalities to config.sh section user

- should user.cfg chapters correlate and how strongly with core module names, now quote loosely?

## ckb-next inport/export animation settings


connected device list

	kb_device_file=$(cat /dev/input/ckb0/connected |grep Keyboard|cut -f1 -d " ")
	kb_device_serial=$(cat /dev/input/ckb0/connected |grep Keyboard|cut -f2 -d " ")
	kb_device_model=$(cat /dev/input/ckb0/connected |grep Keyboard|cut -f4- -d " ")

Nope, better

	kb_device_file=$(cat /dev/input/ckb0/connected |grep Keyboard|cut -f1 -d " ")
	kb_device_model=$(cat model)


## Disable caps lock

xmodmap tesed, did not work

To turn off caps lock key, enter:

	setxkbmap -option ctrl:nocaps

To reset caps lock. enter:

	setxkbmap -option


get method, casp lock do not have rule (i think)

	gsettings get org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ next-tab '<Primary>Right'



For gnome you can use

	gsettings set org.gnome.desktop.input-sources xkb-options "['caps:ctrl_modifier']"

While the preferred way for X is now

	setxkbmap -option caps:ctrl_modifier


how to run script instead of bind to ctrl_modifier?


dconf read /org/gnome/desktop/input-sources/xkb-options

https://www.stevencombs.com/linux/2020/04/14/capslock-as-launcher.html

	setxkbmap -option caps:none
	 xmodmap -e "keycode 66 = Scroll_Lock"
	 xmodmap -e "keycode 78 = Caps_Lock"

gsettings get org.gnome.Terminal.ProfilesList default

why this guy uses albert?

hmm.. this is not os.. but not waist of time, learned thing like xev.. evx.. vex?.. ok, did not learn a thing =D


### this guy, yes.. looks good



https://michael.humanfactors.io/blog/debian-hyperkey-binding/


### albert. who the fuck is albert?

https://albertlauncher.github.io/docs/using/

nääh.. just an launcher. I though that gnome does all this stuff already?

And "These are build by third parties and may contain malicious code!" - sorry no.

futile


## gnome-terminal setting

https://ncona.com/2019/11/configuring-gnome-terminal-programmatically/

example:

```bash
GNOME_TERMINAL_PROFILE=`gsettings get org.gnome.Terminal.ProfilesList default | awk -F \' '{print $2}'`
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$GNOME_TERMINAL_PROFILE/ font 'Monospace 10'
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$GNOME_TERMINAL_PROFILE/ use-system-font false
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$GNOME_TERMINAL_PROFILE/ audible-bell false
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$GNOME_TERMINAL_PROFILE/ use-theme-colors false
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$GNOME_TERMINAL_PROFILE/ background-color '#000000'
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$GNOME_TERMINAL_PROFILE/ foreground-color '#AFAFAF'

```

You can list all the properties that can be configured:

	gsettings list-keys org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$GNOME_TERMINAL_PROFILE/s

get value

	gsettings get org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$GNOME_TERMINAL_PROFILE/ foreground-color