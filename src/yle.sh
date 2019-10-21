download_app="/home/casa/.local/bin/yle-dl"

function yle_main () {
	case $1 in 

		install)	
			yle-dl --version >/dev/null || sudo -H pip3 install --user --upgrade yle-dl 
			ffmpeg -h >/dev/null 2>/dev/null || sudo apt install ffmpeg -y
			jq --version >/dev/null || sudo apt install jq -y
			echo "logout is first time isntall yle-dl"
			;;

		*)			
			get_video_metadata "$@" && get_video "$video_id"
			;;

		esac
}


function get_video_metadata () {

	error=""
	base_url="https://areena.yle.fi"
	meta_data="/tmp/meta.json"
	video_id="$1"

	$download_app "$base_url/$1" --showmetadata >"$meta_data"
	grep "error" "$meta_data" && error=$(cat "$meta_data" | jq '.[].flavors[].error')

	if [ "$error" ]; then  
		echo "$error"
		return 100 
	fi

	video_title=$(cat "$meta_data" | jq '.[].title')			#;echo "$video_title"
	video_filename>=$(cat "$meta_data" | jq '.[].filename')		#;echo "$video_filename"
	video_address=$(cat "$meta_data" | jq '.[].webpage') 		#;echo "$video_address"
	video_filename=${video_filename/" "/"-"}
	echo "$video_filename"
}


function get_video () {

	$download_app "$base_url/$1" -o "$video_filename"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	yle_main $@
fi
