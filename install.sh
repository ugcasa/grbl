#!/bin/bash
# Installer for giocon client


## Install requirements
# [[ $(git --version) ]] || apt-get install git

# $(cat "$target" |grep ".gururc" |grep -v "#") 


## Manupulate .bashrc
target="$HOME/.bashrc"
backup="$HOME/.bashrc.giobackup"

if grep -q ".gururc" "$target"; then
	echo "Alredy installed"
	exit 1
fi
	
read -p "modifying .bashrc file [Y/n] : " edit	
if [[ $edit == "n" ]]; then		
	echo "aborting.."
	exit 2
fi	

[ -f "$HOME/.gururc.disabled" ] && rm -f "$HOME/.gururc.disabled"
cp -f "$target" "$backup"
cat ./src/tobashrc.sh >>$HOME/.bashrc
cp -f ./src/gururc.sh $HOME/.gururc

## Test
#gnome-terminal -- /bin/bash -c "play.by nyan cat; $SHELL"



