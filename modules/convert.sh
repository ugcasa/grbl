#!/bin/bash 
# webp to png multible files
# guru archive format is png all will be converted to png!

source common.sh

convert.main () {
	# convert format parser

	declare -l format=$1
	shift

	case $format in

			webp)
				convert.install
				convert.webp $@
				return $?
				;;
			help)
				convert.help
				return $?
				;;
			*)  convert.webp $format $@
				;;
			"")  gmsg -c yellow "unknown format $format"
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
    gmsg -v1 "default input format is webp"
    gmsg -v2
    gmsg -v1 -c white "example:"
    gmsg -v1 "      $GURU_CALL convert webp 		# converts all webp in folder to $GURU_FORMAT_PICTURE "
    gmsg -v2
	return 0
}


convert.webp () {
	# convert all webp in folder of given file

	if [[ $1 ]] ; then
			found_files=($@)
		else
			found_files=$(ls *webp)
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


convert.install () {
	# install needed

	# webp format support
	dwebp -version -quiet && return 0
	sudo apt update && sudo apt install webp
}

convert.remove () {
	# remove tools

	dwebp -version -quiet >/dev/null || return 0
	sudo apt remove webp
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
    source "$GURU_RC"
    convert.main "$@"
    exit $?
fi




