#!/bin/bash
# note tool for guru tool-kit

source $GURU_BIN/lib/common.sh
source $GURU_BIN/lib/deco.sh
source $GURU_BIN/mount.sh


note.main () {
    # command parser
    unset command argument user_input
    command="$1"; shift
    case "$command" in
        list|ls)    note.list "$1" "$2" ;;
        report)     note.report ;;
        open|edit)  just_created=""     ; note.open "$1" ;;
        locate)     note.gen_var "$1"   ; echo "$note" ;;
        exist)      note.gen_var "$1"   ; [ -f "$note" ] && return 0 || return 127 ;;
        tag)        note.gen_var "$1"   ; [ -f "$note" ] && $GURU_CALL "tag $note $user_input"  ;;
        help)       echo "-- guru tool-kit note help -----------------------------------------------"
                    printf "Usage:\t\t %s note [command] <date> \nCommands:                       \n" "$GURU_CALL"
                    printf " check          check do note exist, returns 0 if i do                \n"
                    printf " list           list of notes. first month (MM), then year (YYYY)     \n"
                    printf " open|edit|*    open given date notes (use time format %s)            \n" "$GURU_FILE_DATE_FORMAT"
                    printf "  <yesterday>    - open yesterdays notes                              \n"
                    printf "  <tuesday>...   - open last week day notes                           \n"
                    printf " tag            read or add tags to note file                         \n"
                    printf " locate         returns file location of note given YYYYMMDD          \n"
                    printf " report         open note with template to %s                         \n" "$GURU_OFFICE_DOC"
                    ;;
        *)
                    note.remount
                    if [ "$command" ]; then
                        note.open $(date +"$GURU_FILE_DATE_FORMAT" -d "$command")
                    else
                        note.contruct $(date +"$GURU_FILE_DATE_FORMAT")
                        note.open $(date +"$GURU_FILE_DATE_FORMAT")
                    fi
    esac
    counter.main add note-runned >/dev/null                                          # Usage statistics
}

note.check() {
    msg "check note mount.. "
    mount.online "$GURU_NOTES" #& ONLINE || OFFLINE
    msg "check template mount.. "
    mount.online "$GURU_TEMPLATES" #& ONLINE || OFFLINE
    return 0
}


note.remount() {
    mount.online "$GURU_NOTES"      || mount.remote "$GURU_CLOUD_NOTES" "$GURU_NOTES"
    mount.online "$GURU_TEMPLATES"  || mount.remote "$GURU_CLOUD_TEMPLATES" "$GURU_TEMPLATES"
}


note.list() {
    # List of notes on this month and year or given in order and format YYYY MM
    [ "$1" ] && month=$(date -d 2000-"$1"-1 +%m) || month=$(date +%m)             #; echo "month: $month"
    [ "$2" ] && year=$(date -d "$2"-1-1 +%Y) || year=$(date +%Y)                  #; echo "year: $year"
    directory="$GURU_NOTES/$GURU_USER/$year/$month"

    if [ -d "$directory" ]; then
        ls "$directory" | grep ".md" | grep -v "~" | grep -v "conflicted"
    else
        printf "no folder exist" >>"$GURU_ERROR_MSG"
        return 126
    fi
}


note.gen_var () {
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

    short_datestamp=$(date -d $year-$month-$day +$GURU_FILE_DATE_FORMAT)    # hmm.. > issue #19 workaround needed before this can be set by user
    nice_datestamp=$(date -d $year-$month-$day +$GURU_DATE_FORMAT)          # nice date format

    note_dir=$GURU_NOTES/$GURU_USER/$year/$month
    note_file=$GURU_USER"_notes_"$short_datestamp.md
    note="$note_dir/$note_file"                                      #; echo "note file "$note

    template_file_name="template.$GURU_USER.$GURU_TEAM.md"           #; echo "temp file name "$template_file_name
    template="$GURU_TEMPLATES/$template_file_name"                   #; echo "template file "$template
    }


note.contruct() {
    # creates notes and opens them to default editor
    note.gen_var "$1"                                               # set basic variables    for functions
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


note.open() {
    # input format YYYYMMDD
    note.gen_var "$1"                                               # set basic variables for functions

    if [[ -f "$note" ]]; then
        [ "$just_created" ] || echo " $(date +$GURU_FILE_DATE_FORMAT)-$(date +$GURU_TIME_FORMAT) | $GURU_USER | edited" >>$note
    else
        read -p "no note for target day, create? [y/n]: " answer
        [ "$answer" == "y" ] && note.generate "$1" || exit 0
    fi
    note.editor "$note"                                             # variables are global dough
}


note.generate() {
    # creates and opens notes (often limited call options, combo needed)
    note.contruct "$1"
    note.open "$1"
}


note.editor () {
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


note.report () {
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


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then            # stand alone vs. include. main wont be called if included
    source "$HOME/.gururc"
    source "$GURU_BIN/functions.sh"
    note.main "$@"
    exit $?                                     # otherwise can be non zero even all fine TODO check why, case function feature?
fi

