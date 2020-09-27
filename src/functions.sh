#!/bin/bash
# guru client prototypes
# Some prototype functions not complicate enough to write separate scripts
# ujo.guru 2019



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



document () {

	cfg=$HOME/.config/guru.io/noter.cfg
	[[ -z "$2" ]] && template="ujo.guru.004" || template="$2"
	[[ -f "$cfg" ]] && . $cfg || echo "cfg file missing $cfg" | exit 1
	pandoc "$1" --reference-odt="$notes/$USER/template/$template-template.odt" -f markdown -o  $(echo "$1" |sed 's/\.md\>//g').odt
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

