#!/bin/bash

download_app="/home/casa/.local/bin/yle-dl"

yle_main () {

	case "$1" in 

		install)	
			pip sudo -H install --upgrade pip
			#yle-dl --version >/dev/null || pip3 install --user --upgrade yle-dl 
			[ -f $download_app ] || pip3 install --user --upgrade yle-dl 
			ffmpeg -h >/dev/null 2>/dev/null || sudo apt install ffmpeg -y
			jq --version >/dev/null || sudo apt install jq -y
			echo "Successfully installed"
			;;

		uninstall)	
			sudo -H pip3 remove --user  yle-dl 
			sudo apt remove ffmpeg jq -y			
			echo "uninstalled"
			;;

		get|dl|download)			
			shift
			get_video_metadata "$@" && get_video
			;;

		meta|data|metadata|information|info)
			shift
			get_video_metadata "$@"
			;;
		
		*)
			get_video_metadata "$@"
			;;

		esac
}


get_video_metadata () {

	error=""
	meta_data="/tmp/meta.json"
	echo "$1" |grep "http" && base_url="" || base_url="https://areena.yle.fi/"	
	video_id="$1"
	video_url="$base_url$video_id" 								#;echo "$video_url"

	$download_app "$video_url" --showmetadata >"$meta_data"
	grep "error" "$meta_data" && error=$(cat "$meta_data" | jq '.[].flavors[].error')

	if [ "$error" ]; then  
		echo "$error"
		return 100 
	fi

	video_title=$(cat "$meta_data" | jq '.[].title')			#;echo "$video_title"
	video_filename=$(cat "$meta_data" | jq '.[].filename')		
	video_address=$(cat "$meta_data" | jq '.[].webpage') 		#;echo "$video_address"
	video_filename=${video_filename//'"'/''} 					
	video_filename=${video_filename//":"/""} 					
	video_filename=${video_filename//" "/-} 					#;echo "$video_filename"
	echo "$video_title"
}


get_video () {

	$download_app "$video_url" -o "$video_filename"
	$GURU_CALL tag "$video_filename" "yle $(date +$GURU_FILE_DATE_FORMAT) $video_title"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	yle_main "$@"
fi
