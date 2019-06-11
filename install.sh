#!/bin/bash
# Installer for giocon client


## Install requirements
# [[ $(git --version) ]] || apt-get install git

# $(cat "$target" |grep ".gururc" |grep -v "#") 


## Manupulate .bashrc

target="$HOME/.bashrc"
backup="$HOME/.bashrc_giobackup.old"

if ! grep -q ".gururc" "$target"; then
	cp -f "$target" "$backup"
	cat ./src/tobashrc.sh >>$HOME/.bashrc
	cp -f ./src/gururc.sh $HOME/.gururc
fi

## Test
gnome-terminal -- /bin/bash -c "play.by nyan cat; $SHELL"



