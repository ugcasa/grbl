#!/bin/bash
# Installer for giocon client. ujo.guru / juha.palm 2019

## installer variables 

bashrc="$HOME/.bashrc"
disable="$HOME/.gururc.disabled"
bin="/opt/gio/bin"
cfg=$HOME/.config/gio


## check and permissions to edit

if grep -q ".gururc" "$bashrc"; then
	echo "Already installed, run gio.uninstall before re-install. To apply changes system wide pls. logout"
	exit 1
fi
read -p "modifying .bashrc and .profile files [Y/n] : " edit	
if [[ $edit == "n" ]]; then
	echo "aborting.. modifications are needed to run giocon client"
	exit 2
fi	


### .bashrc

[ -f "$HOME/.bashrc.giobackup" ] || cp -f "$bashrc" "$HOME/.bashrc.giobackup"
cat ./src/tobashrc.sh >>"$bashrc"


### .profile

if ! grep -q "/opt/gio/bin" $HOME/.profile; then
	
	[ -f "$HOME/.profile.giobackup" ] || cp -f "$HOME/.profile" "$HOME/.profile.giobackup"
	cat ./src/toprofile.sh >>$HOME/.profile
fi


## folder structure 

[ -d $cfg ] || mkdir -p $cfg
[ -d $bin ] || sudo mkdir -p $bin


## copy files

[ -f $disable ] && rm -f $disable 			# remove gio.disabler file
cp -f ./src/gururc.sh "$HOME/.gururc"
cp -f ./cfg/* "$cfg"
sudo cp -f ./src/notes.sh "$bin/gio.notes"
sudo cp -f ./src/datestamp.py "$bin/gio.datestamp"


## check and install requirements

git --version 	|| sudo apt install git
pandoc -v 		|| sudo apt install pandoc
xclip -version  || sudo apt install xclip
subl -v 		|| sudo apt install sublime-text


### stamps 

read -p "install workflow stamps? :" answer
if [[ "$answer" == "y" ]]; then 
	echo 'printf $(date +%d/%m/%Y) | xclip -i -selection clipboard' | sudo tee $bin/gio.date; sudo chmod +x $bin/gio.date
	echo 'printf $(date +%H:%M:%S) | xclip -i -selection clipboard' | sudo tee $bin/gio.time; sudo chmod +x $bin/gio.time
	echo 'printf "## Project\n\tStart\tEnd\t\tTask description" | xclip -i -selection clipboard' | sudo tee $bin/gio.wttheader; sudo chmod +x $bin/gio.wttheader
	echo 'printf $(date -d @$(( (($(date +%s)) / 900) * 900)) "+%H:%M") | xclip -i -selection clipboard'| sudo tee $bin/gio.start; sudo chmod +x $bin/gio.start
	echo 'printf $(date -d @$(( (($(date +%s) + 900) / 900) * 900)) "+%H:%M") | xclip -i -selection clipboard'| sudo tee $bin/gio.end; sudo chmod +x $bin/gio.end
	echo 'printf $(date -d @$(( (($(date +%s) + 450) / 900) * 900)) "+%H:%M") | xclip -i -selection clipboard'| sudo tee $bin/gio.round; sudo chmod +x $bin/gio.round
	echo 'printf "Juha Palm, ujo.guru, +358 400 810 055, juha.palm@ujo.guru" | xclip -i -selection clipboard' | sudo tee $bin/gio.juha; sudo chmod +x $bin/gio.juha
fi


### keyboard bindings (for cinnamon only)

read -p "set keyboard bindings? :" answer
if [[ "$answer" == "y" ]]; then 
	dconf help >/dev/null || sudo apt install dconf-cli
	current=$HOME/.kbbind.backup.cfg
	new=./cfg/kbbind.guruio.cfg
	if [ ! -f $current ]; then 
		echo "Current settings:"
		dconf dump /org/cinnamon/desktop/keybindings/ > $current && cat $current |grep binding=
		read -p "WARNING! WILL OWERWRITE CURRENT SETTINGS! Continue? :" answer
		if [[ "$answer" == "y" ]]; then 
			dconf load /org/cinnamon/desktop/keybindings/ < $new
		else
			echo "Canceled - no changes made"
		fi
	fi
fi


## end 

echo "success, logout to apply settings system wide."


## test

#gnome-terminal -- /bin/bash -c "play.by nyan cat; $SHELL"



