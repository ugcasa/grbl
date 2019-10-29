#!/bin/bash

download_app="/home/casa/.local/bin/yle-dl"

yle_main () {

	case "$1" in 

		install)	
			pip sudo -H install --upgrade pip
			[ -f $download_app ] || pip3 install --user --upgrade yle-dl 
			ffmpeg -h >/dev/null 2>/dev/null || sudo apt install ffmpeg -y
			jq --version >/dev/null || sudo apt install jq -y
			sudo apt install detox cvlc
			echo "Successfully installed"

			;;

		uninstall)	
			sudo -H pip3 remove --user  yle-dl 
			sudo apt remove ffmpeg jq -y			
			echo "uninstalled"
			;;

		get|dl|download)			
			shift
			get_media_metadata "$@" && get_media
			;;

		news|uutiset|"")			
			yle-dl --pipe --latestepisod https://areena.yle.fi/1-4559510 2>/dev/null | vlc - &
			exit 0			
			;;

		weekly|relax|suosikit)
			#run_count=$($GURU_CALL counter guru_run)
			#(( run_count < 3 ))
			printf "To remove notification do next:  \n 1. In VLC, click Tools ► Preferences \n 2. At the bottom left, for Show settings, click All \n 3. At the top left, for Search, paste the string: unimportant \n 4. In the box below Search, click: Qt \n 5. On the right-side, near the very bottom, uncheck Show unimportant error and warnings dialogs \n 6. Click Save \n 7. Close VLC to commit the pref change (otherwise, if VLC crashes, this change {or some changes} might not be saved) \n 8. Run VLC & see if that fixes the problem\n" 	
			yle-dl --pipe --latestepisod https://areena.yle.fi/1-3251215 2>/dev/null | vlc - 
			yle-dl --pipe --latestepisod https://areena.yle.fi/1-3245752 2>/dev/null | vlc - 
			yle-dl --pipe --latestepisod https://areena.yle.fi/1-4360930 2>/dev/null | vlc - 			
			exit 0			
			;;


		meta|data|metadata|information|info)
			shift
			get_media_metadata "$@"
			;;
		
		*)
			get_media_metadata "$@"
			;;

		esac
}


get_media_metadata () {

	error=""
	media_title="no media for $1"
	meta_data="/tmp/meta.json"
	echo "$1" |grep "http" && base_url="" || base_url="https://areena.yle.fi/"	
	media_id="$1"
	media_url="$base_url$media_id" 								#;echo "$media_url"

	$download_app "$media_url" --showmetadata >"$meta_data"
	grep "error" "$meta_data" && error=$(cat "$meta_data" | jq '.[].flavors[].error')

	if [ "$error" ]; then  
		echo "$error"
		return 100 
	fi

	media_title=$(cat "$meta_data" | jq '.[].title')			#;echo "title: $media_title"
	media_address=$(cat "$meta_data" | jq '.[].webpage') 		#;echo "address: $media_address"
	media_file_name=$(cat "$meta_data" | jq '.[].filename')		#;echo "meta: $media_file_name"
	echo "$media_title"
}


get_media () {

	yle_temp="$HOME/tmp/yle"
	[ -d "$yle_temp" ] && rm -rf "$yle_temp" 	
	mkdir -p "$yle_temp"	
	cd "$yle_temp"
	$download_app "$media_url" -o "$media_file_name"
	media_file_name=$(detox -v * | grep -v "Scanning")			#;echo "detox: $media_file_name"
	media_file_name=${media_file_name#*"-> "}						#;echo "cut: $media_file_name"	
	
	place_media

}

place_media () {

	media_file_format="${media_file_name: -5}" 		#; echo "media_file_format:$media_file_format|"		# read last characters of filename
	media_file_format="${media_file_format#*.}"		#; echo "media_file_format:$media_file_format|" 	# read after separator
	media_file_format="${media_file_format^^}" 		#; echo "media_file_format:$media_file_format|" 	# upcase

	$GURU_CALL tag "$media_file_name" "yle $(date +$GURU_FILE_DATE_FORMAT) $media_title"

	case "$media_file_format" in 

		MP3|A3M)	
			echo "saving to: $GURU_AUDIO/$media_file_name"
			mv -f "$media_file_name" "$GURU_AUDIO"
			media_file=$GURU_AUDIO/$media_file_name
			;;
		MP4)
			echo "saving to $GURU_VIDEO/$media_file_name"
			mv -f "$media_file_name" "$GURU_VIDEO"
			media_file=$GURU_VIDEO/$media_file_name
			;;
		*)
			echo "saving to: $GURU_MEDIA/$media_file_name"
			mv -f "$media_file_name" "$GURU_MEDIA"
			media_file=$GURU_MEDIA/$media_file_name
		esac

	[ "$2"=="play" ] && play_media 
}

play_media () {
	vlc --play-and-exit "$media_file" &
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	yle_main "$@"
fi




