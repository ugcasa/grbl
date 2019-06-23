
subl_project () {
	# Open sublime project 
	if ! [ -z "$1" ]; then 
		subl --project "$HOME/Dropbox/Notes/casa/project/$1.sublime-project" -a 
		subl --project "$HOME/Dropbox/Notes/casa/project/$1.sublime-project" -a 
	else
		echo "enter project, and optional file name"
	fi
}


dozer () {
	cfg=$HOME/.config/guru.io/noter.cfg
	[[ -z "$2" ]] && template="ujo.guru.004" || template="$2"
	[[ -f "$cfg" ]] && . $cfg || echo "cfg file missing $cfg" | exit 1 
	pandoc "$1" --reference-odt="$notes/$USER/$template-template.odt" -f markdown -o  $(echo "$1" |sed 's/\.md\>//g').odt
}


disable () {
	if [ -f "$HOME/.gururc" ]; then 
		mv -f "$HOME/.gururc" "$HOME/.gururc.disabled" 
		echo "giocon.client disabled"
	else		
		echo "disabling failed"
	fi	
}


uninstall () {	 
	if [ -f "$HOME/.bashrc.giobackup" ]; then 
		mv -f "$HOME/.bashrc.giobackup" "$HOME/.bashrc"		
		#mv -f "$HOME/.profile.giobackup" "$HOME/.profile"				
		rm -f "$HOME/.gururc"
		dconf load /org/cinnamon/desktop/keybindings/ < $HOME/.kbbind.backup.cfg		
		sudo rm -fr /opt/gio
		rm -fr "$HOME/.config/gio"
		echo "giocon.client uninstalled"
	else		
		echo "uninstall failed"
	fi	
}


status () {
	printf "\e[1mTimer\e[0m: $(guru timer status)\n" 
	#printf "\e[1mConnect\e[0m: $(guru connect status)\n" 
}



test_guru () {
	printf "var: $#: $*\nuser: $GURU_USER \n"
	return 10
}
