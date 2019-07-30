#!/bin/bash
# note generator

main () {
	
	case $command in

				report)					
					notefile=$(note_file $1)					
					$GURU_CALL document $notefile $2
					$GURU_OFFICE_DOC ${notefile%%.*}.odt
					;;

				list|ls)
					list_notes $@
					;;
				
				open|edit)
					open_note $1
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
				 	printf 'Usage: $GURU_CALL notes [command] <date> \n'            
		            echo "Commands:"            
					printf 'open|edit         open given date notes use time format YYYYMMDD \n'
					printf 'list              first parameter is month, second year (POC) \n' 
					printf 'ŕeport            open note to temp template on $GURU_OFFICE_DOC \n' 
					printf '<weekday|wkd>     open last week day notes (POC) \n' 
					printf 'without command or input open todays notes, exist or not\n'
		            ;;
				*)
					make_note 
	esac
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

		templateDir="$GURU_NOTES/$GURU_USER/template"
		templateFile="template.$GURU_USER.$GURU_TEAM.md"
		template="$templateDir/$templateFile"
		noteDir=$GURU_NOTES/$GURU_USER/$(date +%Y/%m)
		noteFile=$GURU_USER"_notes_"$(date +%Y%m%d).md
		note="$noteDir/$noteFile"

		[[  -d "$noteDir" ]] || mkdir -p "$noteDir"

		if [[ ! -f "$note" ]]; then 	    
			    printf "$noteFile $(date +%H:%M:%S)\n\n# $GURU_NOTE_HEADER $(date +%-d.%-m.%Y)\n\n" >$note			    
			    [[ -f "$template" ]] && cat "$template" >>$note || echo "Template file missing"			    
		fi

		open_note "$(date +%Y%m%d)"
}

note_file () {

	input=$1
	
	if [ "$input" ]; then 		# YYYYMMDD only
		year=${input::-4}		# Tässä paukkuu jos open parametri ei ole oikeassa formaatissa
		date=${input:6:2}
		month=${input:4:2}
		noteDir=$GURU_NOTES/$GURU_USER/$year/$month
		noteFile=$GURU_USER"_notes_"$year$month$date.md

	else
		printf "no date given"
		exit 124
	fi

	echo "$noteDir/$noteFile"

}

open_note() {

	note="$(note_file $1)"

	if [[ ! -f "$note" ]]; then 
		printf  "no note for given day. "
		exit 125
	fi

	case $GURU_EDITOR in
	
		subl)
			subl --project "$GURU_NOTES/$GURU_USER/project/notes.sublime-project" -a 
			subl "$note" --project "$GURU_NOTES/$GURU_USER/project/notes.sublime-project" -a 		
			return $?
			;;
		*)
			$GURU_EDITOR "$note" 
			return $?
	esac			
	
}

command=$1
shift
main $@
exit $?


