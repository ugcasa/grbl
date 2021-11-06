#!/bin/bash 
# webp to png multible files
# guru archive formats
#  all images -> png
#  all videfo -> mp4
#  all photos -> jpg


source common.sh

convert.main () {
	# convert format parser

	local format=$1
	shift

	case $format in

			webp|webm|mkv)
				convert.install
				convert.$format $@
				return $?
				;;
			help|poll|status)
				convert.$format $@
				return $?
				;;
			*) 	gmsg -c yellow "unknown format $format"
				# # check what format user is targeting, lazy
				# if grep "webp" <<< $format >/dev/null ; then
				# 		convert.webp $format $@
				# 		return $?
				# 	fi
				# if grep "webm" <<< $format >/dev/null ; then
				# 		convert.webm $format $@
				# 		return $?
				# 	fi
				# if grep "mkv" <<< $format >/dev/null ; then
				# 		convert.mkv $format $@
				# 		return $?
				# 	fi
				# ;;
			# "")  gmsg -c yellow "unknown format $format"
		esac
	return 0
}


convert.help () {
	# genral help

	gmsg -v1 -c white "guru convert help "
    gmsg -v2
    gmsg -v0 "usage:    $GURU_CALL convert <input_format> file list"
    gmsg -v2
    gmsg -v1 "all pictures are converted to $GURU_FORMAT_PICTURE"
    gmsg -v1 "all videos are converted to $GURU_FORMAT_VIDEO"
    gmsg -v2
    gmsg -v1 -c white "example:"
    gmsg -v1 "      $GURU_CALL convert webp 		# converts all webp in folder to $GURU_FORMAT_PICTURE "
    gmsg -v2
	return 0
}


## TBD issue #59 make one convert.format <format> all there three are almost identical

convert.webp () {
	# convert all webp in folder of given file

	if [[ $1 ]] ; then
			found_files=($@)
		else
			eval 'detox *webp'
			found_files=($(eval 'ls *webp'))
		fi

	if ! [[ $found_files ]] ; then
			gmsg -c yellow "no files found"
		fi

	local rand=""
	local _format=$GURU_FORMAT_PICTURE

	for file in ${found_files[@]} ; do

			rand=""
			file_base_name=$(sed 's/\.[^.]*$//' <<< "$file")
			gmsg -v3 -c deep_pink "$file_base_name"

			# check do original exist
			if ! [[ -f "$file_base_name.webp" ]] ; then
					gmsg -c yellow "file $file_base_name.webp not found"
					continue
				fi

			# there is a file with same name
			if [[ -f "$file_base_name.${_format}" ]] ; then
				gmsg -n -c yellow "$file_base_name.${_format} file found "
				# convert webp to temp
				dwebp -quiet "$file_base_name.webp" -o "/tmp/$file_base_name.${_format}"

				# check does picture have same contetn
				orig=$(identify -quiet -format "%#" "$file_base_name.${_format}" )
				new=$(identify -quiet -format "%#" "/tmp/$file_base_name.${_format}")

				if [[ "$orig" == "$new" ]] ; then
						# overwrite existing file
						gmsg -c yellow "with same content, overwriting"
						rm -f "$file_base_name.${_format}"
					else
						gmsg -c yellow "with different content, renaming"
						rand="-$(shuf -i 1000-9999 -n 1)"
					fi
				fi

			# convert
			gmsg -c light_blue "$file_base_name$rand.${_format}.. "
			dwebp -quiet $file_base_name.webp -o $file_base_name$rand.${_format}

			# force remove original if convert success
			[[ $GURU_FORCE ]] && [[ $file_base_name$rand.${_format} ]] && rm $file_base_name.webp

			# clean up
			[[ -f /tmp/$file_base_name.${_format} ]] && rm /tmp/$file_base_name.${_format}

		done
	return 0
}


convert.webm () {

	local convert_indicator_key="f$(daemon.poll_order convert)"

	if [[ $1 ]] ; then
				found_files=($@)
			else
				eval 'detox *webm'
				found_files=$(eval 'ls *webm')
			fi

		if ! [[ $found_files ]] ; then
				gmsg -c yellow "no files found"
			fi

		local rand=""
		local _format=$GURU_FORMAT_VIDEO

		for file in ${found_files[@]} ; do

				rand=""
				file_base_name=${file%%.*}

				gmsg -v3 -c aqua "$file_base_name" -k $convert_indicator_key

				# check do original exist
				if ! [[ -f "$file" ]] ; then
						gmsg -c yellow "file $file not found"
						continue
					fi

				# convert
				gmsg -n -c light_blue "$file_base_name$rand.${_format}.. "

				# there is a file with same name
				if [[ -f "$file_base_name.${_format}" ]] ; then
					gmsg -n "overwriting.. "
							fi

				if ffmpeg -y -hide_banner -loglevel error -i "$file" "$file_base_name$rand.${_format}" ; then
						gmsg -c green "ok" -k $convert_indicator_key
					else
						gmsg -c red "failed: $?" -k $convert_indicator_key
					fi

				# force remove original if convert success
				[[ $GURU_FORCE ]] && [[ $file_base_name$rand.${_format} ]] && rm $file_base_name.webm

			done
		return 0
}


convert.mkv () {

	local convert_indicator_key="f$(daemon.poll_order convert)"

	if [[ $1 ]] ; then
				found_files=($@)
			else
				eval 'detox *mkv'
				found_files=$(eval 'ls *mkv')
			fi

		if ! [[ $found_files ]] ; then
				gmsg -c yellow "no files found"
			fi

		local rand=""
		local _format=$GURU_FORMAT_VIDEO

		for file in ${found_files[@]} ; do

				rand=""
				file_base_name=${file%%.*}

				gmsg -v3 -c aqua "$file_base_name" -k $convert_indicator_key

				# check do original exist
				if ! [[ -f "$file" ]] ; then
						gmsg -c yellow "file $file not found"
						continue
					fi

				# convert
				gmsg -n -c light_blue "$file_base_name$rand.${_format}.. "

				# there is a file with same name
				if [[ -f "$file_base_name.${_format}" ]] ; then
					gmsg -n "overwriting.. "
							fi

				if ffmpeg -y -hide_banner -loglevel error -i "$file" "$file_base_name$rand.${_format}" ; then
						gmsg -c green "ok" -k $convert_indicator_key
					else
						gmsg -c red "failed: $?" -k $convert_indicator_key
					fi

				# force remove original if convert success
				[[ $GURU_FORCE ]] && [[ $file_base_name$rand.${_format} ]] && rm $file_base_name.mkv

			done
		return 0
}


convert.install () {
	# install needed

	# webp format support
	dwebp -version -quiet >/dev/null && \
	ffmpeg -version -quiet >/dev/null && \
		return 0

	sudo apt update && sudo apt install webp ffmpeg detox
}


convert.remove () {
	# remove tools

	dwebp -version -quiet >/dev/null || return 0
	sudo apt remove webp ffmpeg
}


convert.status () {
    # check latest convert is reachable and returnable.

    local convert_indicator_key="f$(daemon.poll_order convert)"

    gmsg -n -v1 -t "${FUNCNAME[0]}: "

    if [[ $GURU_CONVERT_ENABLED ]] ; then
            gmsg -v1 -c green -k $convert_indicator_key \
                "enabled"
        else
            gmsg -v1 -c reset -k $convert_indicator_key \
                "disabled"
            return 1
        fi

    return 0
}


convert.poll () {
    # poll functions

    local convert_indicator_key="f$(daemon.poll_order convert)"
    local _cmd="$1" ; shift

    case $_cmd in
        start )
            gmsg -v1 -t -c black "${FUNCNAME[0]}: convert status polling started" -k $convert_indicator_key
            ;;
        end )
            gmsg -v1 -t -c reset "${FUNCNAME[0]}: convert status polling ended" -k $convert_indicator_key
            ;;
        status )
            convert.status
            ;;
        *)  gmsg -c dark_grey "function not written"
            return 0
        esac
}



if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
    source "$GURU_RC"

    convert.main $@
    exit $?
fi




