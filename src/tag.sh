function tag_picture () { 

	tag="Comment"
	file="$1"; shift
	# if ! [ -f "$file" ]; then
	# 	echo "file not found"
	# 	return 1
	# fi;	
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

		*)			
			[[ "$@" ]] && string="$value $@" || string="$value"
			[[ "$value" ]] && add_tag "$string" 			
			;;
		esac

}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	tag_picture $@
fi









		# case "$file" in
		# 	.)
		# 		echo "kokohakemisto"
		# 		file="."
		# 		#return 1
		# 		;;
		# 	"\*"|all) 
		# 		echo "kaikkifilut"
		# 		file="*.$value"
		# 		#return 1
		# 		;;
		# 	"")
		# 		echo "input file"
		# 		return 1
		# 		;;
		# 	*) 
		# 		echo "file not found"
		# 		return 1
		# 	esac
