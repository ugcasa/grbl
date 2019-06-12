#!/bin/bash
# Installer for giocon client


## Install requirements
# [[ $(git --version) ]] || apt-get install git

# $(cat "$target" |grep ".gururc" |grep -v "#") 


## Manupulate .bashrc
target="$HOME/.bashrc"
backup="$HOME/.bashrc.giobackup"
disable="$HOME/.gururc.disabled"
bin="/opt/gio/bin"

if grep -q ".gururc" "$target"; then
	echo "Alredy installed"
	exit 1
fi
	
read -p "modifying .bashrc and .profile files [Y/n] : " edit	
if [[ $edit == "n" ]]; then
	echo "aborting.."
	exit 2
fi	


[ -f $disable ] && rm -f $disable
[ -d $bin ] || sudo mkdir -p $bin

cp -f "$target" "$backup"
cat ./src/tobashrc.sh >>"$target"
cp -f ./src/gururc.sh "$HOME/.gururc"
sudo cp -f ./src/notes.sh "$bin/gio.notes"
sudo cp -f ./src/datestamp.py "$bin/gio.datestamp"

if grep -q "/opt/gio/bin" $HOME/.profile; then
	exit 0
else
	cp -f "$HOME/.profile" "$HOME/.profile.giobackup"
	cat ./src/toprofile.sh >>$HOME/.profile
fi









## Test
#gnome-terminal -- /bin/bash -c "play.by nyan cat; $SHELL"



