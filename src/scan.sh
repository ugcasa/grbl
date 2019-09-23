#!/bin/bash
# Neanderilainen skanneriscripti

scanimage -V >/dev/null || echo "not installed" 
gocr >/dev/null || echo "not installed" 
convert -version >/dev/null || sudo "sudo apt install imagemagick-6.q16 "


main () {

	case $command in

		invoice|inv|lasku)
			scan_invoice $@	
			error_code=$?
			;;

		receipt|rec|kuitti)
			scan_receipt $@	
			error_code=$?
			;;

		help|--help|-h)			
		 	printf "usage: '$GURU_CALL' [COMMAND] [VARIABLES] \ncommands: \n"
			printf 'receipt|rep|kuitti      scan receipt size grayscale \n'
			printf 'invoice|inv|lasku       scan receipt A4 size optimized grayscale \n'
			error_code=0
			;;		
		*)
			exit
			;;
	esac	
}


scan_receipt() {
	
	stamp=$(date +%s)
	# Start scanner now to save time (scanner takes loooong tIme to start)
	scanimage -x 75 -y 300 --mode Gray --format=pgm -v >tempimage$stamp.pgm && mv tempimage$stamp.pgm cropped$stamp.pgm & #|| echo "Error in scanning" | exit 2

	echo "please place the receipt to scnner!"	
	if [[ -z "$1" ]]; then read -p "name for receipt: " name; else name=$1; fi
	if [[ -z "$2" ]]; then read -p "company or personal account [c/p]: " organ; else organ=$2; fi

	echo "press push-button when green LED lights up"
	
	printf "waiting scanner."
	while [ ! -f cropped$stamp.pgm ]
		do
		  printf "."
		  sleep 2
		done
	printf "\n"

	gocr -i cropped$stamp.pgm -f UTF8 -v >archive$stamp.txt
	mogrify -resize 33% cropped$stamp.pgm
	convert cropped$stamp.pgm archive$stamp.pdf && rm cropped$stamp.pgm

	if [ $organ == "p" ]; then
		account_folder=$GURU_PERSONAL_ACCOUNTING
	else
		account_folder=$GURU_ACCOUNTING
	fi

	[[ -d "$account_folder/$(date +%Y)/$GURU_RECEIPTS" ]] || mkdir -p "$account_folder/$(date +%Y)/$GURU_RECEIPTS"

	cp archive$stamp.pdf "$account_folder/$(date +%Y)/$GURU_RECEIPTS/$name-$(gio.datestamp ujo).pdf" || echo "Error in copy" && rm "archive$stamp.pdf"
	cp archive$stamp.txt "$account_folder/$(date +%Y)/$GURU_RECEIPTS/$name-$(gio.datestamp ujo).txt" || echo "Error in ocr copy" && rm "archive$stamp.txt"

	echo "Scanned to $account_folder/$(date +%Y)/$GURU_RECEIPTS/$name-$(gio.datestamp ujo).pdf"
	# [[ -z "$1" ]] && nemo "$account_folder/$(date +%Y)/$GURU_RECEIPTS" # annoying

	[ -f cropped$stamp.pgm ] && rm cropped$stamp.pgm
	rm -f cropped-1.pgm image.pgm temp.sh tocompile
	return 0
}


scan_invoice () {
	if [[ -z "$1" ]]; then read -p "name for receipt: " name; else name=$1; fi
	if [[ -z "$2" ]]; then read -p "company or personal account [c/p]: " organ; else organ=$2; fi
	if [ -z "$3" ]; then read -p "pages to scan: " pages; else organ=$3; fi
	if [[ $pages == "" ]]; then pages=1; fi

	page=1
	
	while [ "$page" -le "$pages" ]
	    do
		echo "press scanner push button when green LED lights up.."
		scanimage -x 205 -y 292 --mode Gray --format=pgm -v >image$stamp.pgm 
		convert image$stamp.pgm -crop 2416x4338+55+120 cropped$stamp-$page.pgm 
		gocr -i cropped$stamp-$page.pgm -f UTF8 -v >>archive$stamp.txt 
		mogrify -resize 33% cropped$stamp-$page.pgm 
	    echo "cropped$stamp-$page.pgm" >>tocompile$stamp
	    page=$(( page+1 ))
	done

	fileItemString=$(cat tocompile$stamp |tr "\n" " ")
	fileItemArray=($fileItemString)
	echo "convert "$(echo ${fileItemArray[*]})" archive$stamp.pdf" >temp$stamp.sh 
	. ./temp$stamp.sh

	if [ $organ == "p" ]; then
		GURU_ACCOUNTING=$GURU_SCAN
		GURU_RECEIPTS=$GURU_PERSONAL_RECEIPTS
	fi

	[[ -d "$GURU_ACCOUNTING/$(date +%Y)/$GURU_RECEIPTS" ]] || mkdir -p "$GURU_ACCOUNTING/$(date +%Y)/$GURU_RECEIPTS"

	cp archive$stamp.pdf "$GURU_ACCOUNTING/$(date +%Y)/$GURU_RECEIPTS/$name-$(gio.datestamp ujo).pdf" || echo "Error in copy" && rm "archive$stamp.pdf"
	cp archive$stamp.txt "$GURU_ACCOUNTING/$(date +%Y)/$GURU_RECEIPTS/$name-$(gio.datestamp ujo).txt" || echo "Error in ocr copy" && rm "archive$stamp.txt"

	echo "Scanned to $GURU_ACCOUNTING/$(date +%Y)/$GURU_RECEIPTS/$name-$(gio.datestamp ujo).pdf"
	# [[ -z "$1" ]] && nemo "$GURU_ACCOUNTING/$(date +%Y)/$GURU_RECEIPTS" # annoying

	[ -f cropped$stamp.pgm ] && rm cropped$stamp.pgm	
	rm -f cropped-1.pgm image.pgm temp.sh tocompile
	return 0
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	command=$1
	shift
	main $@	
	exit $error_code
fi