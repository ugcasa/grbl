#!/bin/bash

tag_main () { 

	tag_cell="Comment"
	
	target_file="$1"; shift
	value="$1"; shift 

	case "$value" in
	
		rm)
			rm_tag 
			;;
		add)
			[[ "$@" ]] && add_tag "$@" 
			;;
		ls|"")			
			ls_tag 
			;;
		*)			
			[[ "$@" ]] && string="$value $@" || string="$value"
			[[ "$value" ]] && add_tag "$string" 			
			;;
		esac
}

add_tag () { _value="$@"		
	current_tags=$(exiftool -$tag_cell $target_file)
	current_tags=${current_tags##*": "}
	[[ $current_tags == "" ]] && current_tags="$GURU_USER $GURU_TEAM"
	exiftool -$tag_cell="$current_tags $_value" "$target_file"  -overwrite_original_in_place -q 	
	# current_tags=$(exiftool -$tag_cell $target_file); echo "$target_file tags:${current_tags##*:}"
}

rm_tag () { 	
	exiftool -$tag_cell= "$target_file" -overwrite_original_in_place -q 							
	# #current_tags=$(exiftool -$tag_cell $target_file); #echo "$target_file tags:${current_tags##*:}"
}

ls_tag () { 
	current_tags=$(exiftool -$tag_cell $target_file) 
	current_tags=${current_tags##*": "}
	[[ $current_tags == "" ]] || echo "$current_tags"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	
	case "$1" in 
	install)
		sudo apt install libimage-exiftool-perl
		exit 0
		;;
	uninstall)
		sudo apt remove libimage-exiftool-perl
		exit 0
		;;
	*)	
		tag_main $@
		;;
	esac
fi
