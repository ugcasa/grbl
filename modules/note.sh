#!/bin/bash
# note tool for guru-client
#source ~/.gururc
source ~/.gururc2
source $GURU_BIN/common.sh
source $GURU_BIN/deco.sh
source $GURU_BIN/mount.sh
source $GURU_BIN/tag.sh
source $GURU_BIN/corsair.sh
#echo "$GURU_USER_NAME : ${GURU_MOUNT_NOTES[1]}"

note.main () {                                  # command parser

    command="$1" ; shift                        # ; echo "input: $command"

    if ! note.online ; then note.remount ; fi

    case "$command" in
       ls|add|open|rm|check)  note.$command $@  ;  return $? ;;
                     report)  note.make_odt $@  ;  return $? ;;
                     locate)  note.gen_var "$1" ;  echo "$note" ;;
                        tag)  [ -f "$note" ]    && tag.main "tag $note $user_input" ;;
                       help)  note.help ;;
                         "")  note.open $(date +"$GURU_FORMAT_FILE_DATE") ;;
                          *)  note.open $(date +"$GURU_FORMAT_FILE_DATE" -d "$command")
    esac
    counter.main add note-runned >/dev/null     # Usage statistics
}


note.help () {                                  # printout help
    gmsg -v1 -c white "guru-client note help -----------------------------------------------"
    gmsg -v2
    gmsg -v0 "Usage:     $GURU_CALL note [command] <date> "
    gmsg -v1 -c white "Commands:"
    gmsg -v2
    gmsg -v1 " check          check do note exist, returns 0 if i do "
    gmsg -v1 " list           list of notes. first month (MM), then year (YYYY "
    gmsg -v1 " open|edit|*    open given date notes (use time format $GURU_FORMAT_FILE_DATE "
    gmsg -v1 "  <yesterday>    - open yesterdays notes "
    gmsg -v1 "  <tuesday>...   - open last week day notes "
    gmsg -v1 " tag            read or add tags to note file "
    gmsg -v1 " locate         returns file location of note given YYYYMMDD "
    gmsg -v1 " report         open note with template to $GURU_OFFICE_DOC "
    gmsg -v2
}


note.gen_var() {                                # fill variables for rest of functions
    # populates needed variables based on given date in format YYYMMDD
    input=$1                                                        #; echo "input: $1"

    if [ "$input" ]; then                                           # User inputs, no crash handling, mostly input is from other functions not from user
        year=${input::-4}                                           # crashes here if date input is not in correct format YYYYMMDD
        month=${input:4:2}
        day=${input:6:2}
    else
        year=$(date +%Y)
        month=$(date +%m)                                           # current day if no input
        day=$(date +%d)
    fi

    short_datestamp=$(date -d $year-$month-$day +$GURU_FORMAT_FILE_DATE)    # hmm.. > issue #19 workaround needed before this can be set by user
    nice_datestamp=$(date -d $year-$month-$day +$GURU_FORMAT_DATE)          # nice date format

    note_dir=$GURU_MOUNT_NOTES/$GURU_USER_NAME/$year/$month
    note_file=$GURU_USER_NAME"_notes_"$short_datestamp.md
    note="$note_dir/$note_file"                                      #; echo "note file "$note

    template_file_name="template.$GURU_USER_NAME.$GURU_USER_TEAM.md"           #; echo "temp file name "$template_file_name
    template="$GURU_MOUNT_TEMPLATES/$template_file_name"             #; echo "template file "$template
}


note.check() {                                  # chech that given date note file exist
    note.gen_var "$1"
    msg "checking note file.. "
    if [[ -f "$note" ]] ; then
            EXIST "$note"
            return 0
        else
            NOTFOUND "$note"
            return 41
        fi
}


note.online() {                                 # check that needed folders are mounted

    if ! [[ "$GURU_MOUNT_NOTES" ]] && [[ "$GURU_MOUNT_TEMPLATES" ]] ; then
            ERROR "variable emty: '$GURU_MOUNT_NOTES' , '$GURU_MOUNT_TEMPLATES'"
            return 100
        fi

    if mount.online "$GURU_MOUNT_NOTES" && mount.online "$GURU_MOUNT_TEMPLATES" ; then
            return 0
        else
            return 1
        fi
}


note.remount() {                                # mount needed folders
    mount.known_remote notes || return 43
    mount.known_remote templates || return 43
    return 0
}


note.ls() {                                     # list of notes given month/year
    note.remount
    # List of notes on this month and year or given in order and format YYYY MM
    [ "$1" ] && month=$(date -d 2000-"$1"-1 +%m) || month=$(date +%m)             #; echo "month: $month"
    [ "$2" ] && year=$(date -d "$2"-1-1 +%Y) || year=$(date +%Y)                  #; echo "year: $year"
    directory="$GURU_MOUNT_NOTES/$GURU_USER_NAME/$year/$month"
    echo $directory

    if [ -d "$directory" ]; then
        ls "$directory" | grep ".md" | grep -v "~" | grep -v "conflicted"
        return 0
    else

        msg "no folder exist\n"
        return 45
    fi
}


note.add() {                                    # make a note for given date
    # creates notes and opens them to default editor
    note.gen_var "$1"                   #; echo "$1" # set basic variables for functions

    [[  -d "$note_dir" ]] || mkdir -p "$note_dir"
    [[  -d "$GURU_MOUNT_TEMPLATES" ]] || mkdir -p "$GURU_MOUNT_TEMPLATES"

    if [[ ! -f "$note" ]]; then
            # header
            printf "$note\n\n# $GURU_NOTE_HEADER $nice_datestamp\n\n" >$note
            # template
            [[ -f "$template" ]] && cat "$template" >>$note || printf "customize your template to $template" >>$note
            # changes table
            note.add_change "created"
            # tags
            tag.main "$note" add "note $(date +$GURU_FORMAT_FILE_DATE)"
            return 0
        fi
}


note.open() {
    # select note to open and call editor input date in format YYYYMMDD
    local _date=$1
    note.gen_var "$_date"

    if [[ -f "$note" ]]; then
            note.add_change "opened"
        else
                if gask "remove $note" ; then
                    gmsg -N -v1 "no note for target day, create"
                    note.add "$_date"
                else
                    return 0
                fi
            note.editor "$note"
        fi
}


note.rm () {                                    # remove note of given date
    # input format YYYYMMDD
    note.gen_var "$1"
    [[ -f $note ]] || gmsg -x 1 -c white "no note for date $(date -d $1 +$GURU_FORMAT_DATE)"

    if gask "remove $note" ; then
        rm -rf "$note" || msg -c yellow "note remove failed"
    fi
    return 0
}


note.add_change () {                            # add line to chenge list

    _line(){ _len=$1 ; for ((i=1;i<=_len;i++)); do printf '-' ; done }

    # printout change table
    local _change="edited"      ; [[ "$1" ]] && _change="$1"
    local _author="$GURU_USER_NAME"  ; [[ "$2" ]] && _author="$2"

    if ! grep "## Change log" "$note" >/dev/null ; then                        # TODO make better someday or better, pyhtonize notes
            printf  "\n\n## Change log\n\n" >>$note
            printf  "%-17s | %-10s | %-30s \n" "Date" "Author" "Changes" >>$note
            printf "%s|:%s:|%s\n" "$(_line 18)" "$(_line 10)" "$(_line 30)" >>$note
        fi

    printf  "%-17s | %-10s | %s \n" "$(date +$GURU_FORMAT_FILE_DATE)-$(date +$GURU_FORMAT_TIME)" "$_author" "$_change" >>$note
}


note.editor () {                                # open default/project default editor
    # open note to preferred editor
    case "$GURU_PREFERRED_EDITOR" in
        subl)
            projectFolder=$GURU_NOTE_PROJECTS
            [ -f $projectFolder ] || mkdir -p $projectFolder

            projectFile=$projectFolder/$GURU_USER_NAME.notes.sublime-project
            [ -f $projectFile ] || printf "{\n\t"'"folders"'":\n\t[\n\t\t{\n\t\t\t"'"path"'": "'"'$GURU_MOUNT_NOTES/$GURU_USER_NAME'"'"\n\t\t}\n\t]\n}\n" >$projectFile # Whatta ..?! TODO fix omg

            subl --project "$projectFile" -a
            subl "$note" --project "$projectFile" -a
            return $?
            ;;
        *)
            $GURU_PREFERRED_EDITOR "$1"
            return $?
    esac
}


note.make_odt () {                              # open note on team office template
    # created odt with team template out of given days note
    if [[ "$1" ]] ; then
            _date=$(date +$GURU_FORMAT_FILE_DATE -d $1)
        else
            _date=$(date +$GURU_FORMAT_FILE_DATE)
        fi

    note.gen_var "$_date"

    echo "$_date:$note_file:$note:${note%%.*}.odt"

    if [ -f "$note" ]; then
            template="ujo.guru"
            pandoc "$note" --reference-odt="$GURU_MOUNT_TEMPLATES/$template-template.odt" \
                    -f markdown -o  "${note%%.*}.odt"
        else
            echo "no note for $(date +$GURU_FORMAT_DATE -d $1)"
            return 123
        fi

    $GURU_OFFICE_DOC "${note%%.*}.odt" &
    echo "report file: ${notefile%%.*}.odt"
}


check_debian_repository () {                    # old way to install sublime
    # add sublime to repository list
    echo "cheking installation.."
    subl -v && return 1

    wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
    sudo apt-get install apt-transport-https
    echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
    sudo apt-get update
    return $?
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then    # stand alone vs. include. main wont be called if included
        if [[ "$1" == "test" ]] ; then shift ; bash /test/test.sh note $1 ; fi
        note.main "$@"
        exit $?                                     # otherwise can be non zero even all fine TODO check why, case function feature?
    fi

