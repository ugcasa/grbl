#!/bin/bash
# note tools for guru-client casa@ujo.guru 2017-2022
source $GURU_BIN/common.sh
source $GURU_BIN/mount.sh
source $GURU_BIN/tag.sh

declare -gx note=
declare -gx note_date=
declare -gx note_dir=
declare -gx note_file=

note.main () {
    # main command parser

    local command="$1" ; shift

    case "$command" in
            status|ls|add|open|rm|check|locate|config)
                    note.$command "$@"
                    return $?
                    ;;

            office|web)
                    note.$command "$@"
                    return $?
                    ;;
            tag)
                    tag.main "tag $note $user_input"
                    return $?
                    ;;
            help)
                    note.help
                    return $?
                    ;;
             "")
                    note.open $(date +"$GURU_FORMAT_FILE_DATE")
                    return $?
                    ;;
              *)
                    note.open $(date +"$GURU_FORMAT_FILE_DATE" -d "$command")
                    return $?
                    ;;
        esac
}


note.help () {
    # general help

    gr.msg -v1 -c white "guru-client note help "
    gr.msg -v2
    gr.msg -v0 "Usage:    $GURU_CALL note ls|add|open|rm|check|report|locate|tag <date> "
    gr.msg -v1 -c white "Commands:"
    gr.msg -v2
    gr.msg -v1 " check          check do note exist, returns 0 if i do "
    gr.msg -v1 " list           list of notes. first month (MM), then year (YYYY) "
    gr.msg -v1 " open|edit      open given date notes (use time format $GURU_FORMAT_FILE_DATE "
    gr.msg -v1 "  <yesterday>   literal date pointing available"
    gr.msg -v1 "  <next month>  ... "
    gr.msg -v1 " tag            read from or add tags to note file "
    gr.msg -v1 " locate         returns file location of note given YYYYMMDD "
    gr.msg -v1 " report         open note with template with $GURU_PREFERRED_OFFICE_DOC "
    gr.msg -v2
}


note.config () {
# populates global note variables based on given date in format YYYMMDD or literal date like "next month"
    set -e
    local _input="${@}"
    local _year _month _day _datestamp

    gr.msg -v4 "_input=$_input"
    gr.msg -v4 "GURU_FORMAT_FILE_DATE='$GURU_FORMAT_FILE_DATE'"

    if ! [[ $_input ]] ; then
        _year=$(date -d now +%Y)
        _month=$(date -d now +%m)
        _day=$(date -d now +%d)
        _datestamp=$(date -d now +$GURU_FORMAT_FILE_DATE)

    else
        local _re='^[0-9]+$'

        if [[ $_input =~ $_re ]] ; then
            gr.msg -v4 "got date stamp format"
            _year=${_input::-4}
            _month=${_input:4:2}
            _day=${_input:6:2}
            _datestamp="${_year}${_month}${_day}"
        else
            gr.msg -v4 "got literal date"
            _year=$(date -d "$_input" +%Y)
            _month=$(date -d "$_input" +%m)
            _day=$(date -d "$_input" +%d)
            _datestamp="$(date +$GURU_FORMAT_FILE_DATE -d "$_input" )"
        fi
    fi

    # fulfill note variables with given date in user config formats TBD bad naming ünd shit
    note_date=$(date -d $_datestamp +$GURU_FORMAT_DATE)
    note_dir=$GURU_MOUNT_NOTES/$GURU_USER_NAME/$_year/$_month
    note_file=$GURU_USER_NAME"_notes_"$_datestamp.md
    note="$note_dir/$note_file"
    template_file_name="template.$GURU_USER_NAME.$GURU_USER_TEAM.md"
    template="$GURU_MOUNT_TEMPLATES/$template_file_name"

    # debug shit
    gr.msg -v4 -c light_blue "$(declare -p | grep 'declare --' | cut -d ' ' -f3)"
}


note.check () {
    # check that given date note file exist

    if ! note.online ; then note.remount ; fi
    note.config "$1"
    gr.msg -n -v1 -V3 "checking note $note_date.. "
    if [[ -f "$note" ]] ; then
            gr.msg -v1 -c green "$note found"
            return 0
        else
            gr.msg -v0 -V1 "$note"
            gr.msg -v1 -V2 -c white "not found"
            gr.msg -v2 -V4 -c yellow "$note_file not found"
            gr.msg -v4 -c yellow "$note not exist"
            return 41
        fi
}


note.locate () {
    # find notes based on timestamp

    note.locate_check () {
        # make variables

        note.config "$1"
        gr.msg -v1 "$note "
        if [[ -f $note ]] ; then
                return 0
            else
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
            gr.msg -c yellow "empty variable: '$GURU_MOUNT_NOTES' or '$GURU_MOUNT_TEMPLATES'"
            return 100
        fi

    if mount.online "$GURU_MOUNT_NOTES" && mount.online "$GURU_MOUNT_TEMPLATES" ; then
            gr.msg -v2 -c green "note database mounted"
            return 0
        else
            gr.msg -v2 -c red "note database not mounted"
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
        gr.msg -c light_blue "$(ls "$directory" | grep ".md" | grep -v "~" | grep -v "conflicted")"
        return 0
    else
        gr.msg "no folder exist"
        return 45
    fi
}


note.add () {
# creates notes

    # check is note and template folder mounted, mount if not
    note.online || note.remount
    note.config "$1"

    [[  -d "$note_dir" ]] || mkdir -p "$note_dir"
    # TODO picture/ mounter/linker
    # [[ -f $note_dir/pictures ]] || guru mount pictures
    # ! [[ -d $note_dir/pictures ]] || ln -s $GURU_MOUNT_PICTURES/notes $note_dir/pictures

    #[[  -d "$GURU_MOUNT_TEMPLATES" ]] || mkdir -p "$GURU_MOUNT_TEMPLATES"

    if [[ ! -f "$note" ]]; then

            # print file location
            printf "$note\n" >$note

            # tag
            printf "tag: note $GURU_USER $(date -d now +$GURU_FORMAT_FILE_DATE)\n" >>$note

            # place template line 1 to third line
            [[ -f "$template" ]] && cat "$template" | head -n1 "$template" >>$note

            # add calendar blog
            if [[ -f $GURU_BIN/cal.sh ]] ; then
                    source cal.sh
                    printf "\n"'```calendar'"\n" >>$note
                    cal.main notes >>$note # | grep -v $(date -d now +%Y)
                    printf '```'"\n" >>$note
                fi

            # header
            printf "\n\n# $GURU_NOTE_HEADER $note_date\n\n" >>$note

            # template
            [[ -f "$template" ]] && cat "$template"  |tail -n+2 >>$note || printf "customize your template to $template" >>$note

            # changes table
            note.add_change "created"

            # tags
            #tag.main "$note" add "note $(date +$GURU_FORMAT_FILE_DATE)"
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
        gr.msg -v3 -c pink "$_note_date"

        if [[ -f "$note" ]]; then
                note.add_change "opened"
            else
                note.add "$_note_date"
            fi

        gr.msg -v3 -c pink "opening $_note_date"
        note.open_editor "$note"

    done

}


note.rm () {
# remove note of given date. input format YYYYMMDD

    # check is note and template folder mounted, mount if not
    note.online || note.remount

    note.config "$1"
    [[ -f $note ]] || gr.msg -x 1 -c white "no note for date $(date -d $1 +$GURU_FORMAT_DATE)"

    if gr.ask "remove $note" ; then
        rm -rf "$note" || gr.msg -c yellow "note remove failed"
    fi
    return 0
}


note.add_change () {
# add line to change log

    [[ $GURU_NOTE_CHANGE_LOG ]] || return 0

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

    case "$GURU_NOTE_EDITOR" in # if was $GURU_PREFERRED_EDITOR

        obsidian|obs)
            xdg-open "obsidian://open?vault=$GURU_NOTE_VAULT" &
            return $?
            ;;
        subl|sublime|sublime3|sublime2)
            local project_folder=$GURU_SYSTEM_MOUNT/project/projects/notes
            local sublime_project_file="$project_folder/$GURU_USER_NAME-notes.sublime-project"

            [[ -d $project_folder ]] || gr.msg -x 100 -c yellow "$project_folder not exist"
            [[ -f $sublime_project_file ]] || gr.msg -c yellow "sublime project file missing"

            subl "$note" -n --project "$sublime_project_file" -a
            return $?
            ;;
        *)
            joe "$note"
            return $?
    esac
}


note.office () {
# create odt from team template out of given day note

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
            pandoc "$note" --reference-doc="$GURU_MOUNT_TEMPLATES/$template-template.odt" \
                    -f markdown -o  "${note%%.*}.odt"
        else
            echo "no note for $(date +$GURU_FORMAT_DATE -d $1)"
            return 123
        fi

    $GURU_PREFERRED_OFFICE_DOC "${note%%.*}.odt" &
    echo "report file: ${notefile%%.*}.odt"


    # debug
    gr.msg -v4 -N -c green "$(declare -p | grep -e 'GURU_PREFERRED'  -e 'GURU_MOUNT'  | cut -d ' ' -f3)"
}


note.web () {
# create html of given day'note
    echo TBD
}

# daemon functions #####################

# TDB poller

note.status () {
    # make status for daemon

    note.online && note.ls
    return 0
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        source "$GURU_RC"
        note.main "$@"
        gr.msg -v4 -N -c green "$(declare -p | grep -e 'GURU_NOTE' -e 'GURU_FORMAT'   | cut -d ' ' -f3)"
        exit $?
    fi

