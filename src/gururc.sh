# ujo,guru giocon .gururc
# Runs every time terminal is opened


### main functions

function gio.disable () {
	if [ -f "$HOME/.gururc" ]; then 
		mv "$HOME/.gururc" "$HOME/.gururc.disabled" 
		echo "giocon.client disabled"
	else		
		echo "disabling failed"
	fi	
}


function gio.connect () {
	echo "ssh ujo.guru -p2010 ... TODO"
}


export -f gio.disable
export -f gio.connect



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

