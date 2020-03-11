#!/bin/bash
# guru tool-kit prototypes
# Some prototype functions not complicate enough to write separate scripts
# ujo.guru 2019 


PASSED(){
    printf "$PASSED" 
    printf "[PASSED]\n" >>"$GURU_LOG" 
}


FAILED() {
    printf "$FAILED" 
    printf "[FAILED]\n" >>"$GURU_LOG" 
}


ERROR() {
    printf "$ERROR"
    printf "[ERROR]\n" >>"$GURU_LOG" 
}


ONLINE() {
	printf "$ONLINE"
	printf "[ONLINE]\n" >>"$GURU_LOG" 
}


OFFLINE() {
	printf "$OFFLINE"
	printf "[OFFLINE]\n" >>"$GURU_LOG" 
}


UNKNOWN() {
	printf "$UNKNOWN"
	printf "[UNKNOWN]\n" >>"$GURU_LOG" 
}


OK() {
	printf "$OK"
	printf "[OK]\n" >>"$GURU_LOG" 
}


tor() {
    [ -d "$GURU_APP/tor-browser_en-US" ] || guru install tor
    sh -c '"$GURU_APP/tor-browser_en-US/Browser/start-tor-browser" --detach || ([ !  -x "$GURU_APP/tor-browser_en-US/Browser/start-tor-browser" ] && "$(dirname "$*")"/Browser/start-tor-browser --detach)' dummy %k X-TorBrowser-ExecShell=./Browser/start-tor-browser --detach
    error_code="$?"
    if (( error_code == 127 )); then 
        rm -rf "$GURU_APP/tor-browser_en-US"
        echo "failed, try re-install"
        return "$error_code"
    fi
    return 0
}

translate () {
	 # terminal based translator

	 if ! [ -f $GURU_BIN/trans ]; then 
	 	cd $GURU_BIN
	 	wget git.io/trans
	 	chmod +x ./trans
	 fi

	if [[ $1 == *"-"* ]]; then
		argument1=$1
		shift		
	else
	  	argument1=""	  	
	fi

	if [[ $1 == *"-"* ]]; then
		argument2=$1
		shift		
	else
	  	argument2=""	  	
	fi

	if [[ $1 == *":"* ]]; then
	  	#echo "iz variable: $variable"
		variable=$1
		shift
		word=$@

	else
	  	#echo "iz word: $word"
	  	word=$@
	  	variable=""
	fi

	$GURU_BIN/trans $argument1 $argument2 $variable "$word"

}


trans (){
	# alias
	translate $@
}


set_value () {

	[ -f "$GURU_USER_RC" ] && target_rc="$GURU_USER_RC" || target_rc="$HOME/.gururc"
	#[ $3 ] && target_rc=$3
	sed -i -e "/$1=/s/=.*/=$2 $3 $4/" "$target_rc"
}


set () {
	# set guru environmental funtions
	argument="$1"
	shift

	case "$argument" in 
			
			current|status)
				[ -f "$GURU_USER_RC" ] && source_rc="$GURU_USER_RC" || source_rc="$HOME/.gururc"
				echo "current settings:"
				cat "$source_rc" |grep "export"| cut -c13-
				;;


			editor)
				[ "$1" ] && new_value=$1 ||	read -p "input preferred editor : " new_value				
				set_value GURU_EDITOR "$new_value"					
				;;

			name)
				[ "$1" ] && new_value=$1 ||	read -p "input new call name for $GURU_CALL : " new_value				
				mv "$GURU_BIN/$GURU_CALL" "$GURU_BIN/$new_value"
				set_value GURU_CALL "$new_value"
				;;

			audio)
				[ "$1" ] &&	new_value=$1 || read -p "new value (true/false) : " new_value
				set_value GURU_AUDIO_ENABLED "$new_value"				
				;;

			conda)
				conda_setup
				return $?
				;;

			help|-h|--help)
		 		printf "usage: guru set <variable> <value> \narguments: \n"
            	printf "current|status          list of values \n"
            	printf "help|-h|--help          help \n"
            	printf "pre-made setup functions: \n"
				printf 'conda                   setup conda installation \n'
				printf 'audio <true/false>      set audio to "true" or "false" \n'
				printf 'editor <editor>         wizard to set preferred editor \n'				
				;;

			"")				
				;;
			
			*)				
				[ $1 ] || return 130
				set_value GURU_${argument^^} '"'"$@"'"'
				echo "setting GURU_${argument^^} to $@"
	esac 
}


document () {

	cfg=$HOME/.config/guru.io/noter.cfg
	[[ -z "$2" ]] && template="ujo.guru.004" || template="$2"
	[[ -f "$cfg" ]] && . $cfg || echo "cfg file missing $cfg" | exit 1 
	pandoc "$1" --reference-odt="$notes/$USER/template/$template-template.odt" -f markdown -o  $(echo "$1" |sed 's/\.md\>//g').odt
	return 0
}


upgrade() {

    local temp_dir="/tmp/guru"
    local source="git@github.com:ugcasa/guru-ui.git"
    
    [ -d "$temp_dir" ] && rm -rf "$temp_dir"
    mkdir "$temp_dir" 
    cd "$temp_dir"
    git clone "$source" || exit 666
    guru uninstall 
    cd "$temp_dir/guru-ui"
    bash install.sh "$@"
    rm -rf "$temp_dir"
}


status () {

	printf "\e[3mTimer\e[0m: $(guru timer status)\n" 
	#printf "\e[1mConnect\e[0m: $(guru connect status)\n" 
	return 0
}


slack () {
	# open slack channel - bubblecum

	if [ "$GURU_BROWSER" == "chromium-browser" ]; then 						# check browser and user data foler, if set
		[ $GURU_CHROME_USER_DATA ] && GURU_BROWSER="$GURU_BROWSER --user-data-dir=$GURU_CHROME_USER_DATA" 
	fi

	case $1 in 
		
		home|bubble|buble|kupla|koti|maea)
			$GURU_BROWSER \
			https://app.slack.com/client/T0DBYHPK6/G0DC74V0F \
			https://app.slack.com/client/T0DBYHPK6/D0DC78PJN \
			https://app.slack.com/client/T0DBYHPK6/C99KU7SG1 \
			>/dev/null &
			;;

		duplicate|random|general)
			$GURU_BROWSER \
			https://app.slack.com/client/T0DBYHPK6/C0DC5JD32 \
			https://app.slack.com/client/T0DBYHPK6/G0DC9LPTR \
			https://app.slack.com/client/T0DBYHPK6/C0DC5JDCG \
			>/dev/null &
			;;

		lassila|lab|gurulab|mechanics|electronis|radio)
			$GURU_BROWSER \
			https://app.slack.com/client/T0DBYHPK6/CGVFK0WS1 \
			https://app.slack.com/client/T0DBYHPK6/GHNK2ERHR \
			https://app.slack.com/client/T0DBYHPK6/C9A5ZATEY \
			https://app.slack.com/client/T0DBYHPK6/GHNK2ERHR \
			https://app.slack.com/client/T0DBYHPK6/GDVCYR4F7 \
			>/dev/null &
			;;
		
		duuni|work)
			$GURU_BROWSER \
			https://app.slack.com/client/T0DBYHPK6/G30H7RZLH \
			https://app.slack.com/client/T0DBYHPK6/G9VTFH74G \
			https://app.slack.com/client/T0DBYHPK6/D9V7167GQ \
			>/dev/null &
			;;

		projektit|hankkeet|project|idea|startup)
			$GURU_BROWSER \
			https://app.slack.com/client/T0DBYHPK6/GJ1EK6MHV \
			https://app.slack.com/client/T0DBYHPK6/C8TDJJ095 \
			https://app.slack.com/client/T0DBYHPK6/CHNPV8C2W \
			https://app.slack.com/client/T0DBYHPK6/CB06ESYCA \
			https://app.slack.com/client/T0DBYHPK6/GBJDUV50R \
			https://app.slack.com/client/T0DBYHPK6/GGW451ECX \
			https://app.slack.com/client/T0DBYHPK6/CHP2RK0FK \
			>/dev/null & 
			;;
		
		feed)
			$GURU_BROWSER \
			https://app.slack.com/client/T0DBYHPK6/G30H7RZLH \
			https://app.slack.com/client/T0DBYHPK6/CHP2RK0FK \
			https://app.slack.com/client/T0DBYHPK6/G363BM51S \
			https://app.slack.com/client/T0DBYHPK6/G314G4X61 \
			>/dev/null &
			;;

		code|coding)
			$GURU_BROWSER \
			https://app.slack.com/client/T0DBYHPK6/C97QYBU3W \
			https://app.slack.com/client/T0DBYHPK6/CAGG8B20G \
			https://app.slack.com/client/T0DBYHPK6/GBJDUV50R \
			>/dev/null &
			;;

		iot)
			$GURU_BROWSER \
			https://app.slack.com/client/T0DBYHPK6/CB06ESYCA \
			https://app.slack.com/client/T0DBYHPK6/CHNPV8C2W \
			https://app.slack.com/client/T0DBYHPK6/GJ1EK6MHV \
			>/dev/null &
			;;

		*)
			$GURU_BROWSER https://app.slack.com/client/T0DBYHPK6/C0DC5JD32 &
			;;
	esac

	# echo $GURU_BROWSER
}

