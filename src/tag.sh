#!/bin/bash
# mick tagger - ujo.guru 2019

tag_main () { 

	tag_file_name="$1"; shift 					#; echo "|$tag_file_name|"	
	tag_action="$1"; shift 						#; echo "|$tag_action|"
	tag_file_format="${tag_file_name: -6}" 		#; echo "|$tag_file_format|" # read six last characters of filename
	tag_file_format="${tag_file_format#*.}"		#; echo "|$tag_file_format|" # read after separator
	tag_file_format="${tag_file_format^^}" 		#; echo "|$tag_file_format|" # upcase

	case "$tag_file_format" in 

		3G2|3GP2|3GP|3GPP|AAX|AI|AIT|ARQ|ARW|CR2|CR3|CRM|CRW|CIFF|CS1|DCP|DNG|DR4|DVB|EPS|EPSF|PS|ERF|EXIF|EXV|F4A|F4B|F4P|F4V|FFF|FLIF|GIF|GPR|HDP|WDP|JXR|HEIC|HEIF|ICC|ICM|IIQ|IND|INDD|INDT|JP2|JPF|JPM|JPX|JPEG|JPG|JPE|LRV|M4A|M4B|M4P|M4V|MEF|MIE|MOS|MOV|QT|MP4|MPO|MQV|MRW|NEF|NRW|ORF|PDF|PEF|PNG JNG|MNG|PPM|PBM|PGM|PSD|PSB|PSDT|QTIF|QTI|QIF|RAF|RAW|RW2|RWL|SR2|SRW|THM|TIFF|TIF|VRD|X3F|XMP)
			tag_picture "$@"
			;;

		MP3)
			tag_audio "$@"
			;;
		*)
			echo "unknown format"
			return 123
	esac
}


function tag_audio () {

	echo "audiotag TODO"
	return 0
}


function tag_picture () {

	tag_container="Comment"

	add_tag () { 
		_value="$@"		
		current_tags=$(exiftool -$tag_container $tag_file_name)
		current_tags=${current_tags##*": "}
		[[ $current_tags == "" ]] && current_tags="$GURU_USER $GURU_TEAM"
		exiftool -$tag_container="$current_tags $_value" "$tag_file_name" -overwrite_original_in_place -q 	
		# current_tags=$(exiftool -$tag_container $tag_file_name); echo "$tag_file_name tags:${current_tags##*:}"
	}

	rm_tag () { 	
		exiftool -$tag_container= "$tag_file_name" -overwrite_original_in_place -q 							
		# #current_tags=$(exiftool -$tag_container $tag_file_name); #echo "$tag_file_name tags:${current_tags##*:}"
	}

	ls_tag () { 
		current_tags=$(exiftool -$tag_container $tag_file_name) 
		current_tags=${current_tags##*": "}
		[[ $current_tags == "" ]] || echo "$current_tags"
	}

	case "$tag_action" in
	
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
			[[ "$@" ]] && string="$tag_action $@" || string="$tag_action"
			[[ "$tag_action" ]] && add_tag "$string" 			
			;;
		esac
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
		tag_main "$@"
		;;
	esac
fi
