#!/bin/bash
# Mick Tagger - ujo.guru 2019

tag_main () { 

	# get arguments 							# debug
	tag_file_name="$1"; shift 					#; echo "tag_file_name:$tag_file_name|"	
	tag_action="$1"; shift 						#; echo "tag_action:$tag_action|"
	
	# parse file format
	tag_file_format="${tag_file_name: -5}" 		#; echo "tag_file_format:$tag_file_format|"		# read last characters of filename
	tag_file_format="${tag_file_format#*.}"		#; echo "tag_file_format:$tag_file_format|" 	# read after separator
	tag_file_format="${tag_file_format^^}" 		#; echo "tag_file_format:$tag_file_format|" 	# upcase

	case "$tag_file_format" in 

		3G2|3GP2|3GP|3GPP|AAX|AI|AIT|ARQ|ARW|CR2|CR3|CRM|CRW|CIFF|\
		CS1|DCP|DNG|DR4|DVB|EPS|EPSF|PS|ERF|EXIF|EXV|F4A|F4B|F4P|\
		F4V|FFF|FLIF|GIF|GPR|HDP|WDP|JXR|HEIC|HEIF|ICC|ICM|IIQ|IND|\
		INDD|INDT|JP2|JPF|JPM|JPX|JPEG|JPG|JPE|LRV|M4A|M4B|M4P|M4V|\
		MEF|MIE|MOS|MOV|QT|MPO|MQV|MRW|NEF|NRW|ORF|PDF|PEF|PNG|\
		JNG|MNG|PPM|PBM|PGM|PSD|PSB|PSDT|QTIF|QTI|QIF|RAF|RAW|RW2|\
		RWL|SR2|SRW|THM|TIFF|TIF|VRD|X3F|XMP)
			tag_picture "$@"
			;;

		MP3)
			tag_audio "$@"
			;;

		MP4)
			tag_mp4 "$@"
			;;

		MD|TXT|MDD)
			tag_text "$@"
			;;
		*)
			echo "unknown format"
			return 123
	esac
}

tag_text () {
	# If file has more than two lines it's taggable

	get_tags () { 
		current_tags=$(sed -n '2p' $tag_file_name) 	
		current_tags=${current_tags##*": "} 			# Cut "tag:" text away
	}

	change_table () { 

 		#echo "|$current_tags|"
		string=$(printf " $(date +$GURU_FILE_DATE_FORMAT)-$(date +$GURU_TIME_FORMAT) | $GURU_USER | tags added")
		printf "$string\n" >>$tag_file_name 
	}

	add_tags () { 

		get_tags 

		if [ "$current_tags" ]; then 
			sed '2d' $tag_file_name  >temp_file.txt && mv -f temp_file.txt $tag_file_name 
		else
			current_tags="text ${tag_file_format,,} $GURU_USER $GURU_TEAM" 
		fi 
		sed "2i\\tag: $current_tags $@" $tag_file_name >temp_file.txt && mv -f temp_file.txt $tag_file_name 
		change_table
	}

	rm_tags () { 

		get_tags 

		if [ "$current_tags" ]; then 
			sed '2d' $tag_file_name  >temp_file.txt && mv -f temp_file.txt $tag_file_name 
		fi 
	}


	case "$tag_action" in
	
		ls|"")						
			get_tags
			[ "$current_tags" ] && echo $current_tags
			;;
		add)			
			[[ "$@" ]] && add_tags "$@" 
			;;
		rm)
			rm_tags 
			;;
		*)			
			[[ "$@" ]] && string="$tag_action $@" || string="$tag_action"
			[[ "$tag_action" ]] && add_tags "$string" 			
			;;
		esac
}


tag_audio () {
	# Audio tagging tools

	tag_tool="mid3v2"
	tag_container="TIT3" 			# Comment better? is shown by default in various programs
	
	get_tags () { 
		current_tags=$($tag_tool -l $tag_file_name |grep $tag_container) 
		current_tags=${current_tags##*=}
		return 0
	}

	add_tags () { 																						#; echo "current_tags:$current_tags|"; echo "new tags:$@|"
		get_tags
		[[ $current_tags == "" ]] && current_tags="audio ${tag_file_format,,} $GURU_USER $GURU_TEAM"
		$tag_tool --$tag_container "${current_tags// /,},${@// /,}" "$tag_file_name" 					# use "," as separator to use multible tags
	}	

	rm_tags () { 	
		$tag_tool --delete-frames="$tag_container" "$tag_file_name" 								
	}						
	
	case "$tag_action" in
	
		ls|"")						
			get_tags 
			[ "$current_tags" ] && echo "${current_tags//,/ }"
			;;
		add)			
			[[ "$@" ]] && add_tags "$@" 
			;;
		rm)
			rm_tags 
			;;
		*)			
			[[ "$@" ]] && string="$tag_action $@" || string="$tag_action"
			[[ "$tag_action" ]] && add_tags "$string" 			
			;;
		esac
		
		return 0 			# Otherwice returns 1
}


tag_mp4 () {
	# Video tagging tools

	tag_tool="AtomicParsley"
	tag_container="--comment"
	
	get_tags () { 
		current_tags=$($tag_tool $tag_file_name -t |grep cmt) 
		current_tags=${current_tags##*": "}
		return 0
	}

	add_tags () { 																						#; echo "current_tags:$current_tags|"; echo "new tags:$@|"
		get_tags
		[[ $current_tags == "" ]] && current_tags="video ${tag_file_format,,} $GURU_USER $GURU_TEAM"
		$tag_tool "$tag_file_name" "$tag_container" "$current_tags $@" --overWrite  >/dev/null
	}	

	rm_tags () { 	
		$tag_tool "$tag_file_name" "$tag_container" "" --overWrite	>/dev/null
	}						
	
	case "$tag_action" in
	
		ls|"")						
		   	get_tags 
			[ "$current_tags" ] && echo "$current_tags" 
			;;
		add)			
			[[ "$@" ]] && add_tags "$@" 
			;;
		rm)
			rm_tags 
			;;
		*)			
			[[ "$@" ]] && string="$tag_action $@" || string="$tag_action"
			[[ "$tag_action" ]] && add_tags "$string" 			
			;;
		esac
		
		return 0 			# Otherwice returns 1
}

tag_picture () {
	# Picture tagging tools

	tag_tool="exiftool"
	tag_container="Comment" 				# the title under which the information is stored in the image

	get_tags () { 
		current_tags=$($tag_tool -$tag_container "$tag_file_name") 
		current_tags=${current_tags##*": "}
	}
	
	add_tags () { 
		get_tags
		[[ "$current_tags" == "" ]] && current_tags="picture ${tag_file_format,,} $GURU_USER $GURU_TEAM"
		$tag_tool -$tag_container="$current_tags $@" "$tag_file_name" -overwrite_original_in_place -q 	
	}

	rm_tags () { 	
		$tag_tool -$tag_container= "$tag_file_name" -overwrite_original_in_place -q 							
	}


	case "$tag_action" in
	
		ls|"")						
			get_tags 
			[ "$current_tags" ] && echo "$current_tags"
			;;
		add)			
			[[ "$@" ]] && add_tags "$@" 
			;;
		rm)
			rm_tags 
			;;
		*)			
			[[ "$@" ]] && string="$tag_action $@" || string="$tag_action"
			[[ "$tag_action" ]] && add_tags "$string" 			
			;;
		esac
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then				# run if called or act like lib is included
	
	case "$1" in 

		install|remove)
			sudo apt $1 libimage-$tag_tool-perl 		# install picture tag tool
			sudo apt $1 python-mutagen 			# install mp3 tag tool
			#sudo apt $1 mpeg4ip-utils
			sudo apt $1 easytag
			exit 0
			;;


		*)	
			tag_main "$@"
			exit $?
	esac

fi



# Test

# ./tag.sh test.md
# ./tag.sh test.md rm
# ./tag.sh test.md add eka
# ./tag.sh test.md toka
# ./tag.sh test.md ls
# ./tag.sh test.jpg
# ./tag.sh test.jpg rm
# ./tag.sh test.jpg add eka
# ./tag.sh test.jpg toka
# ./tag.sh test.jpg ls
# ./tag.sh test.mp3
# ./tag.sh test.mp3 rm
# ./tag.sh test.mp3 add eka
# ./tag.sh test.mp3 toka
# ./tag.sh test.mp3 ls
