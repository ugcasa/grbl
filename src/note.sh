#!/bin/bash
# note generator


# import and install requirements

if [ $GURU_INSTALL == "desktop" ]; then 

	subl -v >/dev/null || sudo apt install sublime-text		
	pandoc -v >/dev/null || sudo apt install pandoc

fi

. $GURU_BIN/functions.sh

# functions

main () {
	# main command parser

	variable=$1
	shift 
	
	case $command in

				make|mk)
					make_note "$variable"
					;;

				list|ls)
					list_notes $@
					;;

				open|edit)
					open_note "$variable"
					;;

				location)
					note_file_name "$variable" $@
					;;

				fromweb|web)
					md_to_html $@
					;;

				report)					
					[ $variable ] && notefile=$(note_file_name $(date +%Y%m%d -d $variable)) || notefile=$(note_file_name $(date +$GURU_FILE_DATE_FORMAT)) 	#; echo "variable: "$variable"					
					if [ -f $notefile ]; then 
						$GURU_CALL document $notefile $1																					#; echo "note file: "$notefile"
						$GURU_OFFICE_DOC ${notefile%%.*}.odt & 																				
						echo "report file: ${notefile%%.*}.odt"
					else
						echo "no note for $(date +$GURU_DATE_FORMAT -d $variable)"
					fi
					;;

		        help)
				 	printf 'Usage: '$GURU_CALL' notes [command] <date> \n'            
		            echo "Commands:"            
					printf 'open|edit         open given date notes (use time format '$GURU_FILE_DATE_FORMAT' \n'
					printf 'list              list of notes. first parameter is month (MM), second year (YYYY) \n' 
					printf 'report            open note with template to '$GURU_OFFICE_DOC' \n' 
					printf '<yesteerday|yd>   open yesterdays notes \n' 
					printf '<weekday|wkd>     open last week day notes \n' 
					printf 'without command or input open todays notes, exist or not\n'
		            ;;

				*) 			
					if [ ! -z "$command" ]; then 
						echo "opening $(date +$GURU_DATE_FORMAT -d $command) note"
						open_note $(date +%Y%m%d -d $command)
					else
						make_note
					fi
					;;
	esac
}


md_to_html() {

	[ $1 ] && url=$1 || read -p "url: " url
	[ $2 ] && filename=$2 || read -p "filename: " filename
	tempfile=/tmp/noter.temp
	[ -f $tempfile ] && rm -f $tempfile
	
	echo "converting $url to $filename"
	curl --silent $url | pandoc --from html --to markdown_strict -o $tempfile
	sed -e 's/<[^>]*>//g' $tempfile >$filename
	[ -f $tempfile ] && rm -f $tempfile
}


list_notes() {

		[ $1 ] && month=$1 || month=$(date +%m)
		[ $2 ] && year=$2 || year=$(date +%Y)

		noteDir=$GURU_NOTES/$GURU_USER/$year/$month
		
		if [ -d $noteDir ]; then 
			ls $noteDir | grep .md | grep -v "~" 
		else
			printf "no folder exist" >>$GURU_ERROR_MSG		 
			exit 126
		fi
}


make_note() {
		
		if [ "$1" ]; then  		 							# given days note
			note_data="$(note_file_details $1)" 			#Ouput: [0]file [1]folder [2]filename [3]year [4]month [5]date
			note_data=' ' read -r -a note_meta_array <<< "$note_data"
			noteDir=${note_meta_array[1]}	
			noteFile=${note_meta_array[2]}	
			note_date="${note_meta_array[5]}.${note_meta_array[4]}.${note_meta_array[3]}"
			note_date_stamp="${note_meta_array[3]}${note_meta_array[4]}${note_meta_array[5]}"
		else 												# Todays note
			noteDir=$GURU_NOTES/$GURU_USER/$(date +%Y/%m)
			noteFile=$GURU_USER"_notes_"$(date +$GURU_FILE_DATE_FORMAT).md		
			note_date=$(date +%-d.%-m.%Y)
			note_date_stamp=$(date +$GURU_FILE_DATE_FORMAT)
		fi

		note="$noteDir/$noteFile"							#; echo "note file "$note
		templateFile="template.$GURU_USER.$GURU_TEAM.md"	#; echo "temp file name "$templateFile
		template="$GURU_TEMPLATES/$templateFile"			#; echo "template file "$template

		[[  -d "$noteDir" ]] || mkdir -p "$noteDir"
		[[  -d "$GURU_TEMPLATES" ]] || mkdir -p "$GURU_TEMPLATES"

		if [[ ! -f "$note" ]]; then 	    
		    # header
		    printf "$noteFile\n\n# $GURU_NOTE_HEADER $GURU_REAL_NAME $note_date\n\n" >$note			    
		    
		    # template 
		    [[ -f "$template" ]] && cat "$template" >>$note || printf "customize your template to $template" >>$note	
		    
		    # change table
		    printf "\n\ndate                | author | change\n:------------------ | ------ |:------\n $(date +%-d.%-m.%Y)-$(date +%H:%M:%S) | $GURU_USER | created\n" >>$note
		fi
		#;echo "given day stamp "$note_date_stamp
		open_note "$note_date_stamp"
}


note_file_details () {
	# figures out note filename based on datestamp
	# input format YYYYMMDD only, no format checking
	# output is stdín passed array containing following data 
	# 0 = folder/filename, 1 = folder, 2 = filename, 3 = year, 4 = month, 5 = day

	input=$1
	if [ "$input" ]; then 		# YYYYMMDD only
		year=${input::-4}		# Tässä paukkuu jos open parametri ei ole oikeassa formaatissa
		month=${input:4:2}
		date=${input:6:2}
		noteDir=$GURU_NOTES/$GURU_USER/$year/$month
		noteFile=$GURU_USER"_notes_"$year$month$date.md
	else
		printf "no date given" >>$GURU_ERROR_MSG
		exit 124
	fi

	echo "$noteDir/$noteFile $noteDir $noteFile $year $month $date"
}


note_file_name () {
	# parses note_file location and name based on time stamp 
	# input format YYYYMMDD only, no format checking
	[ "$1" ] && target_date=$1 || target_date="20190923" 			#; printf "$1, $2"	
	[ "$2" ] && position=$2 || position=0 							#; printf "$target_date, $position\n"	
	note_data="$(note_file_details $target_date)" 					# Output: [0]file [1]folder [2]filename [3]year [4]month [5]date
	note_data=' ' read -r -a note_meta_array <<< "$note_data" 		#; echo "${note_meta_array[$position]}"																
	echo ${note_meta_array[$position]}	
}


open_note() {
	# open note to preferred editor
	# input format YYYYMMDD only, no format checking
	
	note_data="$(note_file_details $1)" 					# Ouput: [0]file [1]folder [2]filename [3]year [4]month [5]date
	note_data=' ' read -r -a note_meta_array <<< "$note_data" 	#; echo "${note_meta_array[2]}"																
	note=${note_meta_array[0]}	

	if [[ ! -f "$note" ]]; then 
		read -p "no note for target day, create? [y/n]: " answer
		[ "$answer" == "y" ] && make_note $1 || exit 0		
	fi

	case $GURU_EDITOR in
	
		subl)
			projectFolder=$GURU_NOTES/$GURU_USER/project 
			[ -f $projectFolder ] || mkdir -p $projectFolder
			
			projectFile=$projectFolder/notes.sublime-project
			[ -f $projectFile ] || printf "{\n\t"'"folders"'":\n\t[\n\t\t{\n\t\t\t"'"path"'": "'"'$GURU_NOTES/$GURU_USER'"'"\n\t\t}\n\t]\n}\n" >$projectFile
			
			subl --project "$projectFile" -a 
			subl "$note" --project "$projectFile" -a 		
			return $?
			;;
		*)
			$GURU_EDITOR "$note" 
			return $?
	esac			
	
}

# run main if this file is not imported

me=${BASH_SOURCE[0]}
if [[ "$me" == "${0}" ]]; then
	command=$1
	shift
	main $@
	exit $?
fi


