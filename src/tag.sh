#!/bin/bash

function tag_picture () { 

	tag="Comment"
	file="$1"; shift
	value="$1"; shift 

	add_tag () { _value="$@"		
		current_tags=$(exiftool -$tag $file)
		current_tags=${current_tags##*": "}
		[[ $current_tags == "" ]] && current_tags="$GURU_USER $GURU_TEAM"
		exiftool -$tag="$current_tags $_value" "$file"  -overwrite_original_in_place -q 	
		# current_tags=$(exiftool -$tag $file); echo "$file tags:${current_tags##*:}"
	}

	rm_tag () { 	
		exiftool -$tag= "$file" -overwrite_original_in_place -q 							
		# #current_tags=$(exiftool -$tag $file); #echo "$file tags:${current_tags##*:}"
	}

	ls_tag () { 
		current_tags=$(exiftool -$tag $file) 
		current_tags=${current_tags##*": "}
		[[ $current_tags == "" ]] || echo "$current_tags"
	}

	# if [[ "$file" == "." ]]; then 
	# 	ls
	# 	#exiftool -Comment . 
	# 	# current_tags=$(exiftool -Comment . -q)
	# 	# current_tags=${current_tags##*"."}
	# 	# echo "$current_tags"
	# 	return 0
	# fi

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

		install)
			sudo apt install libimage-exiftool-perl
			;;

		*)			
			[[ "$@" ]] && string="$value $@" || string="$value"
			[[ "$value" ]] && add_tag "$string" 			
			;;
		esac
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	tag_picture $@
fi
