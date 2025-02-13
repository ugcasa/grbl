
profile_location="$HOME/.config/guru/mozilla"
__firefox_color="light_blue"
__firefox=$__onedrive

firefox.add_profile () {
	local profile_name=$GURU_USER ; [[ $1 ]] && profile_name="$1"
	local profile="$profile_location/$profile_name"	
	gr.msg -v3 "$profile"

	if ! [[ -d "$profile" ]] ; then 
			[[ -d "$profile" ]] || mkdir -p "$profile"
			firefox -CreateProfile "$profile"
			gr.msg -c white "profile added now set your settings, like resize window etc and then exit"
			firefox --new-instance --profile $profile 
			# --window-size width=100,height=20   # does not work, informed user to set windows size here
		else
			gr.msg "profile exist"
		fi
}


firefox.set_config () {
	# set firefox config values (about:config) values from command line

	if [[ $2 ]]	then
			gr.msg -c yellow "key value pair needed"
			return 100
		fi

	local key=$1
	local value=$2
	gr.msg "change key $key to value $value"
	gr.ask "quite sure?"

	cd
	sed -i 's/user_pref("'$key'",.*);/user_pref("'$key'",'$value');/' user.js
	grep -q $key user.js || echo "user_pref(\"$key\",$value);" >> user.js

}


firefox.play_stream () {
	local profile_name="player"
	local profile="$profile_location/$profile_name"
	gr.msg -v3 "$profile"
	firefox --profile $profile --new-window stream.rollfm.fi &
	# --window-size width=100,height=20   # does not work, but kept in profile
	
}


firefox.launch () {
	local profile_name="$GURU_USER"
	local profile="$profile_location/$profile_name"
	gr.msg -v3 "$profile"
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

	firefox --profile rollfm --new-instance stream.rollfm.fi --headless & echo $! >/tmp/$USER/rollfm.pid
	kill -9 $(tail /tmp/$USER/rollfm.pid)

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


firefox.main () {
# backup cookies and cache

	local ff_folder="$HOME/.mozilla/firefox"
	local ff_profiles=($(grep -e "Path" $ff_folder/ff_profiles.ini | grep -v $ff_folder | cut -d"=" -f2-))
	local ff_profile=
	local ff_config_file=/tmp/$USER/grbl_firefox.cfg

	gr.msg -v4 -n -c $__firefox_color "$__firefox [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2
	gr.varlist "debug ff_folder ff_profiles ff_profile ff_config_file"

	firefox.profile() {
	# check available profiles and make user to select if many

		# debug shit
		gr.msg -v4 -n -c $__firefox_color "$__firefox [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

		# select profile if mote than one
		if [[ ${#ff_profiles[@]} -gt 1 ]]; then
		      echo "found more than one ff_profiles"

		      i=0
		      for _profile in ${ff_profiles[@]}; do
		            echo "$i: $_profile"
		            ((i++))
		      done

		      read -p "select one: " answer

		      if ! [[ ${ff_profiles[$answer]} ]]; then
		            echo "no match '$answer'"
		            exit 1
		      fi

		      ff_profile=${ff_profiles[$answer]}

		else
		      ff_profile=$ff_profiles
		fi
	}

	firefox_backup () {
	# make backup out of sessions, cookies and cache
		local ff_backup=$ff_folder/backup
		local ff_cache=$HOME/.cache/mozilla/firefox/backup

		# debug shit
		gr.msg -v4 -n -c $__firefox_color "$__firefox [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2
		gr.varlist "debug ff_folder ff_profiles ff_profile ff_config_file ff_backup ff_cache"

		[[ -d $ff_backup ]] || mkdir -p $ff_backup
		[[ -d $ff_cache ]] || mkdir -p $ff_cache
		cp $ff_folder/$ff_profile/sessionstore.js $ff_backup
		cp ~/.cache/mozilla/firefox/$ff_profile/* $ff_cache
	}

	firefox_rm () {
	# remove backup out of sessions, cookies and cache

		# debug shit
		gr.msg -v4 -n -c $__firefox_color "$__firefox [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

		rm $ff_folder/$ff_profile/cookies.sqlite
		rm ~/.cache/mozilla/firefox/$ff_profile/*
	}

	# check is config saved for firefox
	if [[ -f $ff_config_file ]]; then
		source $ff_config_file
	else
	# solve, ask and save
		source config.sh
		firefox.profile
		config.save ff_profile $ff_profile $ff_config_file
	fi

	case $1 in
		backup|rm) firefox_$1
		;;
		*) gr.msg -e1 "unknown action"
		;;
	esac

}

source common.sh
firefox.add_profile player
firefox.play_stream 