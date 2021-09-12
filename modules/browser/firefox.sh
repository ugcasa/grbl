
profile_location="$HOME/.config/guru/mozilla"

firefox.add_profile () {
	local profile_name=$GURU_USER ; [[ $1 ]] && profile_name="$1"
	local profile="$profile_location/$profile_name"	
	gmsg -v3 "$profile"

	if ! [[ -d "$profile" ]] ; then 
			[[ -d "$profile" ]] || mkdir -p "$profile"
			firefox -CreateProfile "$profile"
			gmsg -c white "profile added now set your settings, like resize window etc and then exit"
			firefox --new-instance --profile $profile 
			# --window-size width=100,height=20   # does not work, informed user to set windows size here
		else
			gmsg "profile exist"
		fi
}


firefox.set_config () {
	# set firefox config values (about:config) values from command line

	if [[ $2 ]]	then
			gmsg -c yellow "key value pair needed"
			return 100
		fi

	local key=$1
	local value=$2
	gmsg "change key $key to value $value"
	gask "quite sure?"

	cd
	sed -i 's/user_pref("'$key'",.*);/user_pref("'$key'",'$value');/' user.js
	grep -q $key user.js || echo "user_pref(\"$key\",$value);" >> user.js

}


firefox.play_stream () {
	local profile_name="player"
	local profile="$profile_location/$profile_name"
	gmsg -v3 "$profile"
	firefox --profile $profile --new-window stream.rollfm.fi &
	# --window-size width=100,height=20   # does not work, but kept in profile
	
}


firefox.launch () {
	local profile_name="$GURU_USER"
	local profile="$profile_location/$profile_name"
	gmsg -v3 "$profile"
	firefox --profile $profile  &
	# --window-size width=100,height=20   # does not work, but kept in profile
	
}

firefox.foray () {	

	# DO NOT RUN/CALL THIS FUNCTION

	firefox https://developer.mozilla.org/en-US/docs/Mozilla/Command_Line_Options

	firefox --screenshot $GURU_MOUNT_PICTURES -new-window https://yle.fi/uutiset/tuoreimmat
	# thiss rolls
	alias rollfm='firefox --profile rollfm --new-instance --window-size 100,20 stream.rollfm.fi'
	# this headless shit is
	firefox --profile rollfm --new-instance stream.rollfm.fi --headless & pid=$! ; read -p "keypress to kill $pid" ; kill -9 $pid

	firefox --profile rollfm --new-instance stream.rollfm.fi --headless & echo $! >/tmp/rollfm.pid
	kill -9 $(tail /tmp/rollfm.pid) 

	## other noice 
	# --search <term>   
	# --private-window 
	# --kiosk 

	# set focus to adress on browser tab
	xdotool search --onlyvisible --classname Navigator windowactivate --sync key F6

	# copy adress from browser tab
	xdotool search --onlyvisible --classname Navigator windowactivate --sync key Ctrl+c

	# get off the focus from adress from browser tab
	xdotool search --onlyvisible --classname Navigator windowactivate --sync key F6

	# delivery of clipboard content to variable
	clipboard=`xclip -o -selection clipboard`

	# clear clipboard
	xsel -bc; xsel -c

	# echo URL of active tab of active browser
	echo $clipboard

}

source common.sh
firefox.add_profile player
firefox.play_stream 