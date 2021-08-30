#!/bin/bash 
# webp to png multible files
# guru archive format is png all will be converted to png!

source common.sh

convert.webp_png () {
	# convert all webp in folder of given file

	if [[ $1 ]] ; then
			found_files=($@)
		else
			found_files=$(ls *webp)
		fi

	for file in ${found_files[@]} ; do

			file_base_name=$(echo $file | sed 's/\.[^.]*$//')
			# gmsg -c light_blue "$file_base_name"
			dwebp -quiet $file_base_name.webp -o $file_base_name.png
			gmsg -v3 -c light_blue $file_base_name.png

		done

}


convert.install_webp () {

	dwebp -version -quiet >/dev/null && return 0
	sudo apt update && sudo apt install webp
}

convert.install_webp
convert.webp_png $@