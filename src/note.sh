#!/bin/bash
# note generator 2.0 

note_main () { 			# command parser

	#echo "$0 $@"		# debug
	
	command="$1"; shift		#; echo "command: $command"
	argument="$1"; shift 	#; echo "argument: $argument"
	user_input="$@"
	
	case "$command" in

				list|ls)
					list_notes "$argument" "$user_input"
					;;

				locate)
					set_for_date "$argument"
					echo "$note"
					;;

				check)
					set_for_date "$argument"
					[ -f "$note" ] && exit 0 || exit 127
					;;

				open|edit)
					just_created=""
					open_note "$argument"
					;;

				tag)
					set_for_date "$argument"
					[ -f "$note" ] && $GURU_CALL "tag $note $user_input" #|| echo "no such note"
					;;

				report)					
					report 
					;;

		        help)
					printf 'check   		  check do note exist, returns 0 if i do \n' 
					printf 'list              list of notes. first parameter is month (MM), second year (YYYY) \n' 
					printf 'open|edit|*       open given date notes (use time format '$GURU_FILE_DATE_FORMAT' \n'
					printf '<yesterday>         open yesterdays notes \n' 
					printf '<tuesday>...        open last week day notes \n' 
					printf 'tag   			  read or add tags to note file \n' 
					printf 'locate   		  returns file location of note given YYYYMMDD \n' 
					printf 'report            open note with template to '$GURU_OFFICE_DOC' \n' 
					printf 'Without command or input open todays notes, creates if if is not exist \n'
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


list_notes() {

		# List of notes on this month and year or given in order and format YYYY MM

		[ "$1" ] && month="$1" || month=$(date +%m) 	#; echo "month: $month"
		[ "$2" ] && year="$2" || year=$(date +%Y) 		#; echo "year: $year"
		
		directory="$GURU_NOTES/$GURU_USER/$year/$month"
		
		if [ -d "$directory" ]; then 
			ls "$directory" | grep ".md" | grep -v "~" 
		else
			printf "no folder exist" >>"$GURU_ERROR_MSG"		 
			exit 126
		fi
}


set_for_date () {

		# populates needed variables based on given date in format YYYMMDD

		input=$1
		
		if [ "$input" ]; then 		# YYYYMMDD only
			year=${input::-4}		# Tässä paukkuu jos open parametri ei ole oikeassa formaatissa
			month=${input:4:2}
			day=${input:6:2}
		else
			month=$(date +%m)
			year=$(date +%Y)
			day=$(date +%d)
		fi

		note_date_stamp=$(date -d $year-$month-$day +%Y%m%d)		
		note_date=$(date -d $year-$month-$day +%-m.%-d.%Y)

		
		note_dir=$GURU_NOTES/$GURU_USER/$year/$month
		note_file=$GURU_USER"_notes_"$year$month$day.md	
		note="$note_dir/$note_file"							#; echo "note file "$note
		
		template_file="template.$GURU_USER.$GURU_TEAM.md"	#; echo "temp file name "$template_file
		template="$GURU_TEMPLATES/$template_file"			#; echo "template file "$template

		#echo "$note $note_dir $note_file $year $month $date"
	}


make_note() {
		
		set_for_date "$1" 					

		[[  -d "$note_dir" ]] || mkdir -p "$note_dir"
		[[  -d "$GURU_TEMPLATES" ]] || mkdir -p "$GURU_TEMPLATES"

		if [[ ! -f "$note" ]]; then 	    
	    # header
		    printf "$note_file\n\n# $GURU_NOTE_HEADER $GURU_REAL_NAME $note_date\n\n" >$note			    
		# template 
		    [[ -f "$template" ]] && cat "$template" >>$note || printf "customize your template to $template" >>$note			    
		# change table
		    printf "\n\ŋ## Change log\n\n date               | author | change\n:----------------- | ------ |:------\n $(date +$GURU_FILE_DATE_FORMAT)-$(date +$GURU_TIME_FORMAT) | $GURU_USER | created\n" >>$note
		# tags 
			$GURU_CALL tag $note "note $GURU_PROJECT $(date +$GURU_FILE_DATE_FORMAT)"
		# flags
			just_created="yep"
		fi
		
		open_note "$note_date_stamp"
}


open_note() {
	# open note to preferred editor 
	# input format YYYYMMDD 
	
	set_for_date "$1" 

	if [[ -f "$note" ]]; then 
		[ "$just_created" ] || echo " $(date +$GURU_FILE_DATE_FORMAT)-$(date +$GURU_TIME_FORMAT) | $GURU_USER | edited" >>$note	
	else
		read -p "no note for target day, create? [y/n]: " answer
		[ "$answer" == "y" ] && make_note $1 || exit 0		
	fi

	call_editor	"$note"											# variables are global dough
}


call_editor	() {

	case "$GURU_EDITOR" in
	
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



if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then 			# stand alone vs. include. main wont be called if included
	
	case "$1" in

		install|uninstall) 								# user needs to install first

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
			exit $? 									# otherwise can be non zero even all fine TODO check why?
	esac
fi

