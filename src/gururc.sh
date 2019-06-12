# ujo,guru giocon .gururc
# Runs every time terminal is opened

### main functions

function gio.disable () {
	if [ -f "$HOME/.gururc" ]; then 
		mv -f "$HOME/.gururc" "$HOME/.gururc.disabled" 
		echo "giocon.client disabled"
	else		
		echo "disabling failed"
	fi	
}


function gio.uninstall () {	 
	if [ -f "$HOME/.bashrc.giobackup" ]; then 
		mv -f "$HOME/.bashrc.giobackup" "$HOME/.bashrc"		
		mv -f "$HOME/.profile.giobackup" "$HOME/.profile"				
		rm -f "$HOME/.gururc"
		sudo rm -fr /opt/gio
		echo "giocon.client uninstalled"
	else		
		echo "uninstall failed"
	fi	
}


function gio.connect () {
	echo "ssh ujo.guru -p2010 ... TODO"
}


export -f gio.disable
export -f gio.uninstall
export -f gio.connect

### Notes

function gio.subl () {
	# Open sublime project 
	if ! [ -z "$1" ]; then 
		subl --project $HOME/Dropbox/Notes/casa/project/$1.sublime-project -a 
		subl --project $HOME/Dropbox/Notes/casa/project/$1.sublime-project -a #$2 $3 $3 $4 $5 $6 $7 $8 $9
	else
		echo "enter project, and optional file name"
	fi
}


function gio.dozer () {
	cfg=$HOME/.config/guru.io/noter.cfg
	[[ -z "$2" ]] && template="ujo.guru.004" || template="$2"
	[[ -f "$cfg" ]] && . $cfg || echo "cfg file missing $cfg" | exit 1 
	pandoc "$1" --reference-odt="$notes/$USER/$template-template.odt" -f markdown -o  $(echo "$1" |sed 's/\.md\>//g').odt
}

export -f gio.subl
export -f gio.dozer



### youtube player (mpsyt) controls

function play.by () {	
	command="mpsyt set show_video True, set search_music True, /$@, 1-, q"
	gnome-terminal --geometry=80x28 --zoom=0.75 -- /bin/bash -c "$command; exit; $SHELL; "
}


function play.bg () {		
	command="for i in {1..3}; do mpsyt set show_video False, set search_music True, //$@, "'$i'", 1-, q; done"	
	gnome-terminal --geometry=80x28 --zoom=0.75 -- /bin/bash -c "$command; exit; $SHELL; "
}


function play.video () {	
	command="mpsyt set show_video True, set search_music False, /$@, 1-, q"
	gnome-terminal --geometry=80x28 --zoom=0.75 -- /bin/bash -c "$command; exit; $SHELL; "
}


export -f play.bg
export -f play.by
export -f play.video

