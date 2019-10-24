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
		MEF|MIE|MOS|MOV|QT|MP4|MPO|MQV|MRW|NEF|NRW|ORF|PDF|PEF|PNG|\
		JNG|MNG|PPM|PBM|PGM|PSD|PSB|PSDT|QTIF|QTI|QIF|RAF|RAW|RW2|\
		RWL|SR2|SRW|THM|TIFF|TIF|VRD|X3F|XMP)
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


tag_audio () {
	# Audio tagging tools

	tag_tool="mid3v2"
	tag_container="TIT3"
	
	ls_tag () { 
		current_tags=$($tag_tool -l $tag_file_name |grep $tag_container) 
		current_tags=${current_tags##*=}
		[[ $current_tags == "" ]] || echo "${current_tags//,/ }"
	}

	add_tag () { 		
		current_tags=$(ls_tag)																		#; echo "current_tags:$current_tags|"; echo "new tags:$@|"
		[[ $current_tags == "" ]] && current_tags="audio ${tag_file_format,,} $GURU_USER $GURU_TEAM"
		$tag_tool --$tag_container "${current_tags// /,},${@// /,}" "$tag_file_name" 				# use "," as separator to use multible tags
	}	

	rm_tag () { 	
		$tag_tool --delete-frames="$tag_container" "$tag_file_name" 								
	}						
	
	case "$tag_action" in
	
		ls|"")						
			ls_tag 
			;;
		add)			
			[[ "$@" ]] && add_tag "$@" 
			;;
		rm)
			rm_tag 
			;;
		*)			
			[[ "$@" ]] && string="$tag_action $@" || string="$tag_action"
			[[ "$tag_action" ]] && add_tag "$string" 			
			;;
		esac
}


tag_picture () {
	# Picture tagging tools

	tag_container="Comment" 			# the title under which the information is stored in the image
	tag_tool="exiftool"

	ls_tag () { 
		current_tags=$($tag_tool -$tag_container "$tag_file_name") 
		current_tags=${current_tags##*": "}
		[[ $current_tags == "" ]] || echo "$current_tags"
	}
	
	add_tag () { 
		current_tags=$($tag_tool -$tag_container "$tag_file_name")
		current_tags=${current_tags##*": "}
		[[ $current_tags == "" ]] && current_tags="picture ${tag_file_format,,} $GURU_USER $GURU_TEAM"
		$tag_tool -$tag_container="$current_tags $@" "$tag_file_name" -overwrite_original_in_place -q 	
	}

	rm_tag () { 	
		$tag_tool -$tag_container= "$tag_file_name" -overwrite_original_in_place -q 							
	}


	case "$tag_action" in
	
		ls|"")						
			ls_tag 
			;;
		add)			
			[[ "$@" ]] && add_tag "$@" 
			;;
		rm)
			rm_tag 
			;;
		*)			
			[[ "$@" ]] && string="$tag_action $@" || string="$tag_action"
			[[ "$tag_action" ]] && add_tag "$string" 			
			;;
		esac
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then			# run if called or act like lib is included
	
	case "$1" in 

		install)
			sudo apt install libimage-$tag_tool-perl 		# install picture tag tool
			sudo apt-get install python-mutagen 			# install mp3 tag tool
			exit 0
			;;

		uninstall)
			sudo apt remove libimage-$tag_tool-perl 		# remove picture tag tool
			sudo apt-get remove python-mutagen 				# remove mp3 tag tool
			exit 0
			;;

		*)	
			tag_main "$@"
	esac


fi
