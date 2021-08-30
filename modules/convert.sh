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
				convert.install_webp
				convert.webp_png $@
				return $?
				;;
			help)
				convert.help
				return $?
				;;
			*)  convert.webp_png $format $@
				;;
			"")  gmsg -c yellow "unknown format $format"
		esac
	return 0
}


convert.help () {
	gmsg -v1 -c white "guru convert help "
    gmsg -v2
    gmsg -v0 "usage:    $GURU_CALL convert <input_format> file list"
    gmsg -v2
    gmsg -v1 "all pictures are converted to png"
    gmsg -v1 "default input format is webp"
    gmsg -v2
    gmsg -v1 -c white "example:"
    gmsg -v1 "      $GURU_CALL convert "
    gmsg -v2
	return 0
}


convert.webp_png () {
	# convert all webp in folder of given file

	if [[ $1 ]] ; then
			found_files=($@)
		else
			found_files=$(ls *webp)
		fi

	if ! [[ $found_files ]] ; then
			gmsg -c yellow "no files found"
		fi

	for file in ${found_files[@]} ; do

			file_base_name=$(echo $file | sed 's/\.[^.]*$//')
			# gmsg -c light_blue "$file_base_name"
			if [[ -f "$file_base_name.webp" ]] ; then
					# force remove existing file
					[[ $GURU_FORCE ]] && [[ $file_base_name.png ]] && rm $file_base_name.png

					gmsg -c light_blue "> $file_base_name.png.."
					dwebp -quiet $file_base_name.webp -o $file_base_name.png
					# force remove original if convert success
					[[ $GURU_FORCE ]] && [[ $file_base_name.png ]] && rm $file_base_name.webp
				else
					gmsg -c yellow "file $file_base_name.webp not found"
				fi
		done
	return 0
}


convert.install_webp () {

	dwebp -version -quiet >/dev/null && return 0
	sudo apt update && sudo apt install webp
}

convert.install_webp () {

	dwebp -version -quiet >/dev/null || return 0
	sudo apt remove webp
}



if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
    source "$GURU_RC"
    convert.main "$@"
    exit $?
fi




