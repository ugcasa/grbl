#!/bin/bash

download_app="yle-dl"
run_folder=$(pwd) 	#;echo "run_folder: $run_folder"

yle_main () {

	case "$1" in 

		install)	
			pip3 install --upgrade pip
			[ -f $download_app ] || pip3 install --user --upgrade yle-dl 
			ffmpeg -h >/dev/null 2>/dev/null || sudo apt install ffmpeg -y
			jq --version >/dev/null || sudo apt install jq -y
			sudo apt install detox vlc
			echo "Successfully installed"
			;;

		uninstall)	
			sudo -H pip3 remove --user yle-dl 
			sudo apt remove ffmpeg jq -y			
			echo "uninstalled"
			;;

		get|dl|download)			
			shift
			for item in "$@"
				do
				   get_media_metadata "$item" || return 127
				   get_media 
				   place_media
				done
			;;

		news|uutiset)			
			news_core="https://areena.yle.fi/1-3235352"
			$download_app --pipe --latestepisode "$news_core" | vlc -  &
			;;

		episodes)	
			shift			
			get_media_metadata "$1" || return 127 
			[ "$episodes" ] &&echo "$episodes" ||echo "single episode"
			;;

		play)
			shift			
			get_media_metadata "$1" || return 127 
			echo "osoite: $media_address"
			$download_app --pipe "$media_address" 2>/dev/null | vlc - 2>/dev/null & 
			;;

		subtitle|subtitles|sub|subs)	
			shift		
			get_media_metadata "$1" || return 127
			get_subtitles 
			place_media "$run_folder"
			;;

		weekly|relax|suosikit)
			printf "To remove notification do next:  \n 1. In VLC, click Tools ► Preferences \n 2. At the bottom left, for Show settings, click All \n 3. At the top left, for Search, paste the string: unimportant \n 4. In the box below Search, click: Qt \n 5. On the right-side, near the very bottom, uncheck Show unimportant error and warnings dialogs \n 6. Click Save \n 7. Close VLC to commit the pref change (otherwise, if VLC crashes, this change {or some changes} might not be saved) \n 8. Run VLC & see if that fixes the problem\n" 	
			$download_app --pipe --latestepisode https://areena.yle.fi/1-3251215 2>/dev/null | vlc - 
			$download_app --pipe --latestepisode https://areena.yle.fi/1-3245752 2>/dev/null | vlc - 
			$download_app --pipe --latestepisode https://areena.yle.fi/1-4360930 2>/dev/null | vlc - 			
			exit 0			
			;;


		meta|data|metadata|information|info)
			shift
			for item in "$@"
				do
				   get_media_metadata "$item" && get_media
				done
			;;
		
		*)			
			for item in "$@"
				do
				   get_media_metadata "$item" 
				done
			;;

		esac
}


get_media_metadata () {

	error=""
	media_title="no media for $1"
	declare -g episodes=()
	meta_data="/tmp/meta.json"
	
	echo "$1" |grep "http" && base_url="" || base_url="https://areena.yle.fi/"	
	media_id="$1"
	media_url="$base_url$media_id" 								#;echo "$media_url"; exit 0
	
	# Check if id contain episodes, then select first one (newest)
	episodes=$($download_app --showepisodepage $media_url |grep -v $media_url)
	latest=$(echo $episodes | cut -d " " -f 1) 			#; echo "latest: $latest"; exit 0
	[ "$latest" ] && media_url=$latest				#; echo "media_url: $media_url"; exit 0
	
	# Get metadata
	$download_app "$media_url" --showmetadata >"$meta_data"
	
	grep "error" "$meta_data" && error=$(cat "$meta_data" | jq '.[].flavors[].error')
	if [ "$error" ]; then  
		echo "$error"
		return 100 
	fi

	# set variables (like they be local anyway)
	media_title="$(cat "$meta_data" | jq '.[].title')"			#;echo "title: $media_title"
	media_address="$media_url "
	#$(cat "$meta_data" | jq '.[].webpage') 					#;echo "address: $media_address"
	#media_address=${media_address//'"'/""} 					#;echo "$media_address" 						# remove " signs
	media_file_name=$(cat "$meta_data" | jq '.[].filename')		#;echo "meta: $media_file_name"
	echo "${media_title//'"'/""}"
}


get_media () {
	
	yle_temp="$HOME/tmp/yle"
	[ -d "$yle_temp" ] && rm -rf "$yle_temp" 	
	mkdir -p "$yle_temp"	
	cd "$yle_temp"
	$download_app "$media_url" -o "$media_file_name" --sublang all #2>/dev/null
	media_file_name=$(detox -v * | grep -v "Scanning")			#;echo "detox: $media_file_name"
	media_file_name=${media_file_name#*"-> "}					#;echo "cut: $media_file_name"	
}

get_subtitles () {
	
	yle_temp="$HOME/tmp/yle"
	[ -d "$yle_temp" ] && rm -rf "$yle_temp" 	
	mkdir -p "$yle_temp"	
	cd "$yle_temp"
	$download_app "$media_url" --subtitlesonly #2>/dev/null
	media_file_name=$(detox -v * | grep -v "Scanning")			#;echo "detox: $media_file_name"
	media_file_name=${media_file_name#*"-> "}					#;echo "cut: $media_file_name"	
}

place_media () {

	#location="$@"
	media_file_format="${media_file_name: -5}" 		#; echo "media_file_format:$media_file_format|"		# read last characters of filename
	media_file_format="${media_file_format#*.}"		#; echo "media_file_format:$media_file_format|" 	# read after separator
	media_file_format="${media_file_format^^}" 		#; echo "media_file_format:$media_file_format|" 	# upcase

	$GURU_CALL tag "$media_file_name" "yle $(date +$GURU_FILE_DATE_FORMAT) $media_title $media_url"

	case "$media_file_format" in 

		MP3)	
			[ "$location" ] && location="$1" || location="$GURU_AUDIO"
			;;
		MP4)
			[ "$location" ] && location="$1" || location="$GURU_VIDEO"
			;;
		SRC|SUB)
			[ "$location" ] && location="$1" || location="$GURU_VIDEO"
			;;
		*)
			[ "$location" ] && location="$1" || location="$GURU_MEDIA"		
	esac

	echo "saving to: $location/$media_file_name"
	mv -f "$media_file_name" "$location"
	media_file=$location/$media_file_name
	[ "$2" == "play" ] && play_media "$media_file"
	#[ "$2" == "cast" ] && play_media "$media_file"
}


play_media () {
	vlc --play-and-exit "$1" &
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	yle_main "$@"
fi




