#!/bin/bash
# note tools for guru-client casa@ujo.guru 2017-2021
source $GURU_BIN/common.sh
source $GURU_BIN/mount.sh
source $GURU_BIN/tag.sh

note.main () {
    # main command parser

    local command="$1" ; shift

    case "$command" in
            status|ls|add|open|rm|check|locate)
                    note.$command "$@"
                    return $?
                    ;;

            office|web)
                    note.$command "$@"
                    return $?
                    ;;
            tag)
                    tag.main "tag $note $user_input"
                    ;;
            help)
                    note.help
                    ;;
             "")
                    note.open $(date +"$GURU_FORMAT_FILE_DATE")
                    ;;
              *)
                    note.open $(date +"$GURU_FORMAT_FILE_DATE" -d "$command")
                    ;;
        esac
}


note.help () {
    # general help

    gmsg -v1 -c white "guru-client note help "
    gmsg -v2
    gmsg -v0 "Usage:    $GURU_CALL note [ls|add|open|rm|check|report|locate|tag] <date> "
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


note.config () {
    # populates needed variables based on given date in format YYYMMDD

    input=$1

    if [ "$input" ]; then
        # crashes here if date input is not in correct format YYYYMMDD
        year=${input::-4}
        month=${input:4:2}
        day=${input:6:2}
    else
        # current day if no input
        year=$(date +%Y)
        month=$(date +%m)
        day=$(date +%d)
    fi

    short_datestamp=$(date -d $year-$month-$day +$GURU_FORMAT_FILE_DATE)
    nice_datestamp=$(date -d $year-$month-$day +$GURU_FORMAT_DATE)

    note_dir=$GURU_MOUNT_NOTES/$GURU_USER_NAME/$year/$month
    note_file=$GURU_USER_NAME"_notes_"$short_datestamp.md
    note="$note_dir/$note_file"

    template_file_name="template.$GURU_USER_NAME.$GURU_USER_TEAM.md"
    template="$GURU_MOUNT_TEMPLATES/$template_file_name"
}


note.check () {
    # chech that given date note file exist

    if ! note.online ; then note.remount ; fi
    note.config "$1"
    gmsg -n -v1 "checking note file.. "
    if [[ -f "$note" ]] ; then
            gmsg -v1 -c green "$note found"
            return 0
        else
            gmsg -v1 -c yellow "$note not found"
            return 41
        fi
}


note.locate () {
    # find notes based on timestamp

    note.locate_check () {
        # make variables

        note.config "$1"
        gmsg -v1 "$note "        
        if [[ -f $note ]] ; then
                # gmsg -v1 -c green "exist"
                return 0
            else
                #gmsg -v1 -c red "non exist"
                return 1
            fi
    }

    # check is note and template folder mounted, mount if not
    note.online || note.remount

    case $1 in
        all)
            start=$(date -d 20170101 +%s)
            end=$(date +%s)
            d="$start"

            while [[ $d -le $end ]] ; do
                note.locate_check "$(date -d @$d +%Y%m%d)"
                d=$(( $d + 86400 ))
            done
            ;;
        *)
            note.locate_check $@
            ;;
        esac
}


note.online () {
    # check that needed folders are mounted

    if ! [[ "$GURU_MOUNT_NOTES" ]] && [[ "$GURU_MOUNT_TEMPLATES" ]] ; then
            gmsg -c yellow "empty variable: '$GURU_MOUNT_NOTES' or '$GURU_MOUNT_TEMPLATES'"
            return 100
        fi

    if mount.online "$GURU_MOUNT_NOTES" && mount.online "$GURU_MOUNT_TEMPLATES" ; then
            gmsg -v2 -c green "note database mounted"
            return 0
        else
            gmsg -v2 -c red "note database not mounted"
            return 1
        fi
}


note.remount () {
    # mount needed folders

    mount.known_remote notes || return 43
    mount.known_remote templates || return 43
    return 0
}


note.ls () {
    # list of notes given month/year

    # check is note and template folder mounted, mount if not
    note.online || note.remount

    # List of notes on this month and year or given in order and format YYYY MM
    [[ "$1" ]] && month=$(date -d 2000-"$1"-1 +%m) || month=$(date +%m)             #; echo "month: $month"
    [[ "$2" ]] && year=$(date -d "$2"-1-1 +%Y) || year=$(date +%Y)                  #; echo "year: $year"
    directory="$GURU_MOUNT_NOTES/$GURU_USER_NAME/$year/$month"

    if [[ -d "$directory" ]] ; then
        gmsg -c light_blue "$(ls "$directory" | grep ".md" | grep -v "~" | grep -v "conflicted")"
        return 0
    else
        gmsg "no folder exist"
        return 45
    fi
}


note.add () {
    # creates notes

    # check is note and template folder mounted, mount if not
    note.online || note.remount
    note.config "$1"

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


note.open () {
    # select note to open and call editor input date in format YYYYMMDD

    # check is note and template folder mounted, mount if not
    note.online || note.remount

    local _date_list=(${@})
    local _note_date=

    for _note_date in ${_date_list[@]} ; do

        note.config "$_note_date"
        gmsg -v3 -c pink "$_note_date"

        if [[ -f "$note" ]]; then
                note.add_change "opened"
            else
                note.add "$_note_date"
            fi

        gmsg -v3 -c pink "opening $_note_date"
        note.open_editor "$note"

    done
}


note.rm () {
    # remove note of given date. input format YYYYMMDD

    # check is note and template folder mounted, mount if not
    note.online || note.remount

    note.config "$1"
    [[ -f $note ]] || gmsg -x 1 -c white "no note for date $(date -d $1 +$GURU_FORMAT_DATE)"

    if gask "remove $note" ; then
        rm -rf "$note" || gmsg -c yellow "note remove failed"
    fi
    return 0
}


note.add_change () {
    # add line to change log

    _line () {
        _len=$1
        for ((i=1;i<=_len;i++)); do
            printf '-'
        done
    }

    # check is note and template folder mounted, mount if not
    note.online || note.remount

    # printout change table
    local _change="edited"
    [[ "$1" ]] && _change="$1"

    local _author="$GURU_USER_NAME"
    [[ "$2" ]] && _author="$2"

    # add header if not exist
    if ! grep "**Change log**" "$note" >/dev/null ; then
            printf  "\n\n**Change log**\n\n" >>$note
            printf  "%-17s | %-10s | %-30s \n" "Date" "Author" "Changes" >>$note
            printf "%s|:%s:|%s\n" "$(_line 18)" "$(_line 10)" "$(_line 30)" >>$note
        fi

    printf  "%-17s | %-10s | %s \n" "$(date +$GURU_FORMAT_FILE_DATE)-$(date +$GURU_FORMAT_TIME)" "$_author" "$_change" >>$note
}


note.open_editor () {
    # open note to preferred editor

    case "$GURU_PREFERRED_EDITOR" in
        subl)
            local project_folder=$GURU_SYSTEM_MOUNT/project/projects/notes
            local sublime_project_file="$project_folder/$GURU_USER_NAME-notes.sublime-project"

            [[ -d $project_folder ]] || gmsg -x 100 -c yellow "$project_folder not exist"
            [[ -f $sublime_project_file ]] || gmsg -c yellow "sublime project file missing"

            subl "$note" -n --project "$sublime_project_file" -a
            return $?
            ;;
        *)
            $GURU_PREFERRED_EDITOR "$1"
            return $?
    esac
}


note.office () {
    # created odt with team template out of given days note

    # check is note and template folder mounted, mount if not
    note.online || note.remount

    if [[ "$1" ]] ; then
            _date=$(date +$GURU_FORMAT_FILE_DATE -d $1)
        else
            _date=$(date +$GURU_FORMAT_FILE_DATE)
        fi

    note.config "$_date"

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


note.web () {
    # created html of given days note

    # check is note and template folder mounted, mount if not
    note.online || note.remount

    if [[ "$1" ]] ; then
            _date=$(date +$GURU_FORMAT_FILE_DATE -d $1)
        else
            _date=$(date +$GURU_FORMAT_FILE_DATE)
        fi

    note.config "$_date"

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

################## daemon functions #####################

# TDB poller

note.status () {
    # make status for daemon

    note.online && note.ls
    return 0
}



if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        source "$GURU_RC"
        note.main "$@"
        exit $?
    fi

