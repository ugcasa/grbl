#!/bin/bash
# note generator 2.0 
# luokkamainen konstruktio, muuttujat glomaaleja tässä avaruudessa

#. $GURU_BIN/functions.sh

note_main () { 			# command parser

	#echo "$0 $@"		# debug
	
	command="$1"; shift		#; echo "command: $command"
	argument="$1"; shift 	#; echo "argument: $argument"
	user_input="$@"
	
	case "$command" in

				list|ls)
					list_notes "$argument $user_input"
					;;

				locate)
					get_from_array "$argument"
					;;

				check)
					[ -f $(get_from_array "$argument") ] && exit 0 || exit 127
					;;

				open|edit)
					just_created=""
					open_note "$argument"
					;;

				tag)
					file=$(get_from_array "$argument")
					[ -f "$file" ] && $GURU_CALL "tag $file $user_input" #|| echo "no such note"
					;;

				report)					
					report 
					;;

		        help)
					printf 'open|edit         open given date notes (use time format '$GURU_FILE_DATE_FORMAT' \n'
					printf 'list              list of notes. first parameter is month (MM), second year (YYYY) \n' 
					printf 'report            open note with template to '$GURU_OFFICE_DOC' \n' 
					printf '<yesteerday|yd>   open yesterdays notes \n' 
					printf '<weekday|wkd>     open last week day notes \n' 
					printf 'without command or input open todays notes, exist or not\n'
		            ;;

				*) 			
					if [ ! -z "$command" ]; then 
						echo "opening $(date +"$GURU_DATE_FORMAT" -d $"command") note"
						open_note $(date +"$GURU_FILE_DATE_FORMAT" -d "$command")
					else
						make_note
					fi
	esac
}



report () {

		[ "$argument" ] && notefile=$(get_from_array $(date +$GURU_FILE_DATE_FORMAT -d $argument)) || notefile=$(get_from_array $(date +$GURU_FILE_DATE_FORMAT)) 	#; echo "argument: "$argument"					
		if [ -f "$notefile" ]; then 
			$GURU_CALL document "$notefile $user_input"																					#; echo "note file: "$notefile"
			$GURU_OFFICE_DOC ${notefile%%.*}.odt & 																				
			echo "report file: ${notefile%%.*}.odt"
		else
			echo "no note for $(date +$GURU_DATE_FORMAT -d $argument)"
		fi
}


list_notes() {

		[ "$1" ] && month="$1" || month=$(date +%m)
		[ "$2" ] && year="$2" || year=$(date +%Y)

		noteDir="$GURU_NOTES/$GURU_USER/$year/$month"
		
		if [ -d "$noteDir" ]; then 
			ls "$noteDir" | grep .md | grep -v "~" 
		else
			printf "no folder exist" >>"$GURU_ERROR_MSG"		 
			exit 126
		fi
}


make_note() {
		
		if [ "$1" ]; then  		 							# given days note
			note_data="$(make_array $1)" 					#Ouput: [0]file [1]folder [2]filename [3]year [4]month [5]date
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
		    printf "\n\ndate                | author | change\n:------------------ | ------ |:------\n $(date +$GURU_FILE_DATE_FORMAT)-$(date +$GURU_TIME_FORMAT) | $GURU_USER | created\n" >>$note
			$GURU_CALL tag $note "note $GURU_PROJECT $(date +$GURU_FILE_DATE_FORMAT)"
			just_created="yep"
		fi
		#;echo "given day stamp "$note_date_stamp
		open_note "$note_date_stamp"
}


make_array () {
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


get_from_array () {
	# parses note_file location and name based on time stamp 
	# input target date and position of the array: [0]file [1]folder [2]filename [3]year [4]month [5]date"
	[ "$1" ] && target_date=$1 || target_date=$(date +$GURU_FILE_DATE_FORMAT) 	#; printf "$1, $2"	
	[ "$2" ] && position=$2 || position=0 										#; printf "$target_date, $position\n"	
	note_data="$(make_array $target_date)" 								  
	note_data=' ' read -r -a note_meta_array <<< "$note_data" 					#; echo "${note_meta_array[$position]}"																
	echo ${note_meta_array[$position]}	
}


open_note() {
	# open note to preferred editor 
	# input format YYYYMMDD 
	
	note_data="$(make_array $1)" 					
	note_data=' ' read -r -a note_meta_array <<< "$note_data" 	#; echo "${note_meta_array[2]}"																
	note=${note_meta_array[0]}									# Ouput: [0]file [1]folder [2]filename [3]year [4]month [5]date

	if [[ ! -f "$note" ]]; then 
		read -p "no note for target day, create? [y/n]: " answer
		[ "$answer" == "y" ] && make_note $1 || exit 0		
	else
		[ "$just_created" ] || echo " $(date +$GURU_FILE_DATE_FORMAT)-$(date +$GURU_TIME_FORMAT) | $GURU_USER | edited" >>$note		
	fi

	call_editor	"$note"											# variables are global dough
}

call_editor	() {

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
			$GURU_EDITOR "$1" 
			return $?
	esac	
}

# run note_main if this file is not imported


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	
	case "$1" in

		install|uninstall)

			case "$GURU_INSTALL" in 

				desktop)
					sudo apt "$1" sublime-text pandoc					
					;; 

				server)
					sudo apt "$1" joe 				
			esac
			;;		

		*)
			note_main "$@"
			exit $? 				# otherwice can be non zero even all fine TODO check why?
	esac
fi





# 				html2md|web)
# 					html2md "$argument $user_input"
# 					;;

# html2md() {

# 		[ "$1" ] && url=$1 || read -p "url: " url
# 		[ "$2" ] && filename=$2 || read -p "filename: " filename
# 		tempfile=/tmp/noter.temp
# 		[ -f $tempfile ] && rm -f $tempfile
		
# 		echo "converting $url to $filename"
# 		curl --silent $url | pandoc --from html --to markdown_strict -o $tempfile
# 		sed -e 's/<[^>]*>//g' $tempfile >$filename
# 		[ -f $tempfile ] && rm -f $tempfile
# }
