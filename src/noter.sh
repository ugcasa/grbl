#!/bin/bash
# note generator

subl -v >/dev/null || sudo apt install sublime-text		
pandoc -v >/dev/null || sudo apt install pandoc

main () {
	
	variable=$1
	
	case $command in

				make|mk)
					make_note $variable
					;;

				list|ls)
					list_notes $@
					;;

				open|edit)
					open_note "$variable"
					;;

				fromweb|web)
					md_to_html $@
					;;

				report)					
					[ $1 ] && notefile=$(note_file_name $variable) || notefile=$(note_file_name $(date +%Y%m%d))										
					#echo "notefile:"$notefile
					if [ -f $notefile ]; then 
						$GURU_CALL document $notefile $2					
						$GURU_OFFICE_DOC ${notefile%%.*}.odt &
					else
						echo "no sutch note"
					fi
					;;

				yesterday|yd)
					open_note $(date +%Y%m%d -d "yesterday")
					;;

				monday|mon|maanantai|ma)
					open_note $(date +%Y%m%d -d "last-monday")
					;;

				tuesday|tue|tiistai|ti)
					open_note $(date +%Y%m%d -d "last-tuesday")
					;;

				wednesday|wed|kerskiviikko|ke)
					open_note $(date +%Y%m%d -d "last-wednesday")
					;;

				thursday|thu|torstai|to)
					open_note $(date +%Y%m%d -d "last-thursday")
					;;

				friday|fri|perjantai|pe)
					open_note $(date +%Y%m%d -d "last-friday")
					;;

				saturday|sat|lauvantai|lauantai|la)
					open_note $(date +%Y%m%d -d "last-saturday")
					;;

				sunday|sun|sunnuntai|su)
					open_note $(date +%Y%m%d -d "last-sunday")
					;;

		        help)
				 	printf 'Usage: '$GURU_CALL' notes [command] <date> \n'            
		            echo "Commands:"            
					printf 'open|edit         open given date notes (use time format YYYYMMDD) \n'
					printf 'list              list of notes. first parameter is month (MM), second year (YYYY) \n' 
					printf 'report            open note with template to '$GURU_OFFICE_DOC' \n' 
					printf '<yesteerday|yd>   open yesterdays notes \n' 
					printf '<weekday|wkd>     open last week day notes \n' 
					printf 'without command or input open todays notes, exist or not\n'
		            ;;

				*) 			
					if [ ! -z "$command" ]; then 
						open_note "$command"
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
			printf "no folder exist. "			 
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
			noteFile=$GURU_USER"_notes_"$(date +%Y%m%d).md		
			note_date=$(date +%-d.%-m.%Y)
			note_date_stamp=$(date +%Y%m%d)
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
		    printf "\n\ndate                | author | change\n:------------------ | ------ |:------\n $(date +%-d.%-m.%Y-%H:%M:%S) | $GURU_USER  | created\n" >>$note
		fi
		#;echo "given day stamp "$note_date_stamp
		open_note "$note_date_stamp"
}


note_file_details () {
	# inoput format YYYYMMDD only, no format checking
	input=$1

	if [ "$input" ]; then 		# YYYYMMDD only
		year=${input::-4}		# Tässä paukkuu jos open parametri ei ole oikeassa formaatissa
		month=${input:4:2}
		date=${input:6:2}
		noteDir=$GURU_NOTES/$GURU_USER/$year/$month
		noteFile=$GURU_USER"_notes_"$year$month$date.md
	else
		printf "no date given"
		exit 124
	fi

	echo "$noteDir/$noteFile $noteDir $noteFile $year $month $date"
}


note_file_name () {
	note_data="$(note_file_details $1)" 					# Ouput: [0]file [1]folder [2]filename [3]year [4]month [5]date
	note_data=' ' read -r -a note_meta_array <<< "$note_data" 	#; echo "${note_meta_array[2]}"																
	echo ${note_meta_array[0]}	
}


open_note() {

	note_data="$(note_file_details $1)" 					# Ouput: [0]file [1]folder [2]filename [3]year [4]month [5]date
	note_data=' ' read -r -a note_meta_array <<< "$note_data" 	#; echo "${note_meta_array[2]}"																
	note=${note_meta_array[0]}	

	if [[ ! -f "$note" ]]; then 
		printf  "no note for given day. "
		exit 125
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

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	command=$1
	shift
	main $@
	exit $?
fi


