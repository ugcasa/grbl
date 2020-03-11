#!/bin/bash
# note generator 2.0 

source "$(dirname "$0")/lib/common.sh"
source "$(dirname "$0")/mount.sh"


note_main () {                                                                  
    # command parser        
        unset command argument user_input        
        command="$1"; shift                                                        
        
        re-mount "$GURU_NOTES"

        case "$command" in

                    list|ls )
                        list_notes "$1" "$2"
                        ;;

                    locate )
                        set_for_date "$1"                                    # set basic variables for functions
                        echo "$note"
                        ;;

                    check )
                        set_for_date "$1"                                    # set basic variables for functions
                        [ -f "$note" ] && return 0 || return 127
                        ;;

                    open|edit )
                        just_created=""
                        open_note "$1"
                        ;;

                    tag )
                        set_for_date "$1"                                    # set basic variables for functions
                        [ -f "$note" ] && $GURU_CALL "tag $note $user_input"        #|| echo "no such note"
                        ;;

                    re-mount|re-connect)
                        re-mount 
                        ;;
    
                    report )                 
                        report 
                        ;;

                    help )
                        printf "\nUsage:\n\t %s note [command] <date> \n\nCommands:\n\n" "$GURU_CALL"
                        printf 'check             check do note exist, returns 0 if i do \n' 
                        printf 'list              list of notes. first parameter is month (MM), second year (YYYY) \n' 
                        printf "open|edit|*       open given date notes (use time format %s) \n" "$GURU_FILE_DATE_FORMAT"
                        printf ' <yesterday>        - open yesterdays notes \n' 
                        printf ' <tuesday>...       - open last week day notes \n' 
                        printf 'tag               read or add tags to note file \n' 
                        printf 'locate            returns file location of note given YYYYMMDD \n' 
                        printf "report            open note with template to %s \n" "$GURU_OFFICE_DOC"

                        printf '\nWithout command or input open todays notes, creates if if is not exist\n\n'
                        ;;

                    test )
                        test_note "$@"
                        ;;

                    *)          
                        try-mount && re-mount                         
                        if [ "$command" ]; then                         
                            open_note $(date +"$GURU_FILE_DATE_FORMAT" -d "$command")
                        else
                            make_note $(date +"$GURU_FILE_DATE_FORMAT")
                            open_note $(date +"$GURU_FILE_DATE_FORMAT")
                        fi
        esac
        counter_main add note-runned >/dev/null                                          # Usage statistics
}


try-mount() {
   [ -d "$1/$GURU_USER" ] && mount_point="$1/$GURU_USER" || return 123
}


re-mount() {

    [ -d "$1/$GURU_USER" ] && return 123 || mount_point="$1/$GURU_USER"
    mount_main mount "$GURU_CLOUND_NOTES" "$GURU_NOTES" || return $?
    sleep 1
    mount_main mount "$GURU_CLOUND_TEMPLATES" "$GURU_TEMPLATES" || return $?
    return 0
}


list_notes() {
    # List of notes on this month and year or given in order and format YYYY MM
        [ "$1" ] && month=$(date -d 2000-"$1"-1 +%m) || month=$(date +%m)             #; echo "month: $month"
        [ "$2" ] && year=$(date -d "$2"-1-1 +%Y) || year=$(date +%Y)                  #; echo "year: $year"
        directory="$GURU_NOTES/$GURU_USER/$year/$month"
        
        if [ -d "$directory" ]; then 
            ls "$directory" | grep ".md" | grep -v "~" | grep -v "conflicted"
        else
            printf "no folder exist" >>"$GURU_ERROR_MSG"         
            exit 126
        fi
}


set_for_date () {   
    # populates needed variables based on given date in format YYYMMDD
        input=$1
        
        if [ "$input" ]; then                                           # User inputs, no crash handling, mostly input is from other functions not from user
            year=${input::-4}                                           # crashes here if date input is not in correct format YYYYMMDD
            month=${input:4:2} 
            day=${input:6:2}
        else
            month=$(date +%m)                                           # current day if no input 
            year=$(date +%Y)
            day=$(date +%d)
        fi

        short_datestamp=$(date -d $year-$month-$day +$GURU_FILE_DATE_FORMAT)            # hmm.. > issue #19 workaround needed before this can be set by user
        nice_datestamp=$(date -d $year-$month-$day +$GURU_DATE_FORMAT)  # nice date format 

        note_dir=$GURU_NOTES/$GURU_USER/$year/$month
        note_file=$GURU_USER"_notes_"$short_datestamp.md    
        note="$note_dir/$note_file"                                     #; echo "note file "$note
        
        template_file_name="template.$GURU_USER.$GURU_TEAM.md"          #; echo "temp file name "$template_file_name
        template="$GURU_TEMPLATES/$template_file_name"                  #; echo "template file "$template

        #echo "$note $note_dir $note_file $year $month $date"           # uncomment if need output for array, should not affect current usage
    }


make_note() {
    # creates notes and opens them to default editor
        set_for_date "$1"                                               # set basic variables    for functions
        [[  -d "$note_dir" ]] || mkdir -p "$note_dir"
        [[  -d "$GURU_TEMPLATES" ]] || mkdir -p "$GURU_TEMPLATES"
        
        if [[ ! -f "$note" ]]; then                     
            # header
            printf "$note_file\n\n# $GURU_NOTE_HEADER $nice_datestamp\n\n" >$note                       

            # template  
            [[ -f "$template" ]] && cat "$template" >>$note || printf "customize your template to $template" >>$note    
            
            # change table
            printf "\n\n## Change log\n\n date               | author | change\n:----------------- | ------ |:------\n $(date +$GURU_FILE_DATE_FORMAT)-$(date +$GURU_TIME_FORMAT) | $GURU_USER | created\n" >>$note 
            
            # tags 
            $GURU_CALL tag $note "note $GURU_PROJECT $(date +$GURU_FILE_DATE_FORMAT)"                                   
            
            # flags
            just_created="yep"                                                                                          
        fi
}


open_note() {
    # input format YYYYMMDD     
        set_for_date "$1"                                               # set basic variables for functions
        
        if [[ -f "$note" ]]; then 
            [ "$just_created" ] || echo " $(date +$GURU_FILE_DATE_FORMAT)-$(date +$GURU_TIME_FORMAT) | $GURU_USER | edited" >>$note 
        else
            read -p "no note for target day, create? [y/n]: " answer
            [ "$answer" == "y" ] && make_and_open_note "$1" || exit 0       
        fi
        call_editor "$note"                                             # variables are global dough
}


make_and_open_note() {
    # creates and opens notes (often limited call options, combo needed) 
        make_note "$1"
        open_note "$1"
}


call_editor () {
    # open note to preferred editor 
        case "$GURU_EDITOR" in
            subl)
                projectFolder=$GURU_NOTES/$GURU_USER/project 
                [ -f $projectFolder ] || mkdir -p $projectFolder
                
                projectFile=$projectFolder/notes.sublime-project
                [ -f $projectFile ] || printf "{\n\t"'"folders"'":\n\t[\n\t\t{\n\t\t\t"'"path"'": "'"'$GURU_NOTES/$GURU_USER'"'"\n\t\t}\n\t]\n}\n" >$projectFile # Whatta ..?! TODO fix omg
                
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
    # created odt with team template out of given days note 
        [ "$argument" ] && notefile=$(get_from_array $(date +$GURU_FILE_DATE_FORMAT -d $argument)) || notefile=$(get_from_array $(date +$GURU_FILE_DATE_FORMAT))    
        
        if [ -f "$notefile" ]; then 
            $GURU_CALL document "$notefile $user_input"                                                                                 
            $GURU_OFFICE_DOC ${notefile%%.*}.odt &                                                                              
            echo "report file: ${notefile%%.*}.odt"
        else
            echo "no note for $(date +$GURU_DATE_FORMAT -d $argument)"
        fi
}


check_debian_repository () {
    # add sublime to repository list 
        echo "cheking installation.."
        subl -v && return 1

        wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
        sudo apt-get install apt-transport-https
        echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
        sudo apt-get update
        return $?   
}




test_note() {

    mount_test() {
        printf "check mount point is free.. " | tee -a "$GURU_LOG"
        try-mount "$GURU_NOTES" && printf "not free: " || printf "is free: "
        PASSED

        printf "mounting to $GURU_TEST.. " | tee -a "$GURU_LOG"
        mount_main mount "/home/$GURU_USER/usr/test" "$GURU_TEST" && PASSED || FAILED

        printf "un-mount $GURU_TEST.. " | tee -a "$GURU_LOG"
        mount_main unmount "$GURU_TEST" && PASSED || FAILED

        printf "re-mount note mountpoints.. " | tee -a "$GURU_LOG"
        re-mount "$GURU_NOTES" && PASSED || FAILED 
    }

    case "$1" in     # does not what i want when tunned vut level 3, "mount"
        1)
            mount_test 
            return $?
            ;;

        all)
            mount_test 
            return $?
            ;;

        help)
            ;;
        *) echo "note.sh: No test case for $1"
    esac

}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then            # stand alone vs. include. main wont be called if included
    source "$HOME/.gururc"
    source "$GURU_CFG/$GURU_USER/deco.cfg"
    source "$GURU_BIN/functions.sh"
    note_main "$@"
    exit $?                                     # otherwise can be non zero even all fine TODO check why, case function feature?
fi

