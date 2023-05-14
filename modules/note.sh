#!/bin/bash
# note tools for guru-client casa@ujo.guru 2017-2022

# source common.sh

note.help () {

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


note.main () {
# main command parser

    local command="$1" ; shift

    case "$command" in

        status|ls|add|open|rm|check|locate|config)
                note.$command "$@"
                return $?
                ;;

        # these note types are opened with obsidian
        memo*|idea|write*)

                note.open_obsidian_vault "$command"
                return $?
                ;;

        office|web)
                note.$command "$@"
                return $?
                ;;
        tag)
                source tag.sh
                tag.main "tag $note_file $user_input"
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
                note.open $@ #$(date +"$GURU_FORMAT_FILE_DATE" -d "$command")
                return $?
                ;;
    esac
}


note.rc () {
# configure module

    declare -g note_file
    declare -g note_date
    declare -g note_folder
    declare -g note_file_name

    # load mount configuration
    local mount_rc="/tmp/guru-cli_mount.rc"

    if  [[ ! -f $mount_rc ]] ; then
        source mount.sh
        mount.make_rc && gr.msg -v1 -c dark_gray "$mount_rc updated (by note.sh)"
    fi

    source $mount_rc

    # load note configuration
    declare -gA note

    # default config
    [[ -f "$GURU_CFG/note.cfg" ]] && source "$GURU_CFG/note.cfg"

    # user config
    if [[ $(stat -c %Y $GURU_CFG/$GURU_USER/note.cfg) -gt $(stat -c %Y /tmp/guru.daemon-pid) ]] ; then
        gr.msg -v1 -c dark_gray "$GURU_CFG/$GURU_USER/note.cfg updated"
    fi

    [[ -f "$GURU_CFG/$GURU_USER/note.cfg" ]] && source "$GURU_CFG/$GURU_USER/note.cfg"

}


note.config () {
# populates global note variables based on given date in format YYYMMDD or literal date like "next month"
    set -e
    local _input="${@}"
    local _year _month _day _datestamp

    gr.debug "$FUNCNAME: input=$_input"
    gr.debug "$FUNCNAME: date format=$GURU_FORMAT_FILE_DATE"

    if ! [[ $_input ]] ; then
        _year=$(date -d now +%Y)
        _month=$(date -d now +%m)
        _day=$(date -d now +%d)
        _datestamp=$(date -d now +$GURU_FORMAT_FILE_DATE)

    else
        local _re='^[0-9]+$'

        if [[ $_input =~ $_re ]] ; then
            gr.debug "got date stamp format"
            _year=${_input::-4}
            _month=${_input:4:2}
            _day=${_input:6:2}
            _datestamp="${_year}${_month}${_day}"
        else
            gr.debug "got literal date"
            _year=$(date -d "$_input" +%Y)
            _month=$(date -d "$_input" +%m)
            _day=$(date -d "$_input" +%d)
            _datestamp="$(date +$GURU_FORMAT_FILE_DATE -d "$_input" )"
        fi
    fi

    # fulfill note variables with given date in user config formats TBD bad naming ünd shit
    note_date=$(date -d $_datestamp +$GURU_FORMAT_DATE)
    note_folder=$GURU_MOUNT_NOTES/$GURU_USER_NAME/$_year/$_month
    note_file_name=$GURU_USER_NAME"_notes_"$_datestamp.md
    note_file="$note_folder/$note_file_name"
    template_file_name="template.$GURU_USER_NAME.$GURU_USER_TEAM.md"
    template="$GURU_MOUNT_TEMPLATES/$template_file_name"

    # debug shit
    gr.debug "$(declare -p | grep 'declare --' | cut -d ' ' -f3)"
}


note.check () {
    # check that given date note file exist

    if ! note.online ; then note.remount ; fi
    note.config "$1"
    gr.msg -n -v2 "checking note $note_date.. "
    if [[ -f "$note_file" ]] ; then
        gr.msg -v1 -c green "ok"
        return 0
    else
        gr.msg -c dark_gray "$note_file_name not found"
        return 41
    fi
}


note.locate () {
    # find notes based on timestamp

    note.locate_check () {
        # make variables

        note.config "$1"
        gr.msg -v1 "$note_file "

        if [[ -f $note_file ]] ; then
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

    source mount.sh

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

    source mount.sh
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

    [[  -d "$note_folder" ]] || mkdir -p "$note_folder"
    # TODO picture/ mounter/linker
    # [[ -f $note_folder/pictures ]] || guru mount pictures
    # ! [[ -d $note_folder/pictures ]] || ln -s $GURU_MOUNT_PICTURES/notes $note_folder/pictures

    #[[  -d "$GURU_MOUNT_TEMPLATES" ]] || mkdir -p "$GURU_MOUNT_TEMPLATES"

    if [[ ! -f "$note_file" ]]; then

        # print file location
        printf "$note_file\n" >$note_file

        # tag
        printf "tag: note $GURU_USER $(date -d now +$GURU_FORMAT_FILE_DATE)\n" >>$note_file

        # place template line 1 to third line
        [[ -f "$template" ]] && cat "$template" | head -n1 "$template" >>$note_file

        # add calendar blog
        if [[ -f cal.sh ]] ; then
                source cal.sh
                printf "\n"'```calendar'"\n" >>$note_file
                cal.main notes >>$note_file # | grep -v $(date -d now +%Y)
                printf '```'"\n" >>$note_file
            fi

        # header
        printf "\n\n# ${note[header]} $note_date\n\n" >>$note_file

        # template
        [[ -f "$template" ]] && cat "$template"  |tail -n+2 >>$note_file || printf "customize your template to $template" >>$note_file

        # changes table
        note.add_change "created"

        # tags
        #tag.main "$note_file" add "note $(date +$GURU_FORMAT_FILE_DATE)"
        return 0
    fi
}


note.open_obsidian_vault () {
# open idea gathering environment aka. obsidian vault memos in guru/notes
    # gr.msg "${FUNCNAME[0]} TBD"
    # xdg-open obsidian://open?vault=${1}
    local command="xdg-open obsidian://open?vault=${1}" #; while true ; do read -n1 ans ; case $ans in q) break ; esac ; done" # 2>/dev/null
    gnome-terminal --hide-menubar --geometry 130x6 --zoom 0.1 --title "obsidian launcher" -- bash -c "$command ; read "
}


# note.open () {
# # select note to open and call editor input date in format YYYYMMDD

#     # check is note and template folder mounted, mount if not
#     note.online || note.remount

#     local _date_list=(${@})
#     local _note_date=

#     for _note_date in ${_date_list[@]} ; do

#             note.config "$_note_date"
#             gr.debug "$_note_date"

#             if [[ -f "$note_file" ]]; then
#                     note.add_change "opened"
#                 else
#                     note.add "$_note_date"
#                 fi

#             gr.debug "opening $_note_date"
#             note.open_editor "$note_file"

#         done
# }

note.open () {
# select note to open and call editor input date in format YYYYMMDD

    # check is note and template folder mounted, mount if not
    note.online || note.remount

    local _note_date="$@"

    note.config "$_note_date"
    gr.debug "date: $_note_date"
    gr.debug "file: $note_file"

    if [[ -f "$note_file" ]]; then
        note.add_change "opened"
    else
        note.add "$_note_date"
    fi

    gr.debug "opening $_note_date"
    note.open_editor "$note_file"
    return $?
}


note.rm () {
# remove note of given date. input format YYYYMMDD

    # check is note and template folder mounted, mount if not
    note.online || note.remount

    note.config "$1"
    [[ -f $note_file ]] || gr.msg -x 1 -c white "no note for date $(date -d $1 +$GURU_FORMAT_DATE)"

    if gr.ask "remove $note_file" ; then
        rm -rf "$note_file" || gr.msg -c yellow "note remove failed"
    fi
    return 0
}


note.add_change () {
# add line to change log

    [[ ${note[change_log]} ]] || return 0

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
    if ! grep "**Change log**" "$note_file" >/dev/null ; then
        printf  "\n\n**Change log**\n\n" >>$note_file
        printf  "%-17s | %-10s | %-30s \n" "Date" "Author" "Changes" >>$note_file
        printf "%s|:%s:|%s\n" "$(_line 18)" "$(_line 10)" "$(_line 30)" >>$note_file
    fi

    printf  "%-17s | %-10s | %s \n" "$(date +$GURU_FORMAT_FILE_DATE)-$(date +$GURU_FORMAT_TIME)" "$_author" "$_change" >>$note_file
}



note.open_editor () {
# open note to preferred editor

    case "${note[editor]}" in # if was $GURU_PREFERRED_EDITOR

        obsidian|obs)
            xdg-open "obsidian://open?vault=${note[vault]}"
            #return $?
            ;;
        subl|sublime|sublime3|sublime2)
            local project_folder=$GURU_SYSTEM_MOUNT/project/projects/notes
            local sublime_project_file="$project_folder/$GURU_USER_NAME-notes.sublime-project"

            [[ -d $project_folder ]] || gr.msg -x 100 -c yellow "$project_folder not exist"
            [[ -f $sublime_project_file ]] || gr.msg -c yellow "sublime project file missing"

            subl "$note_file" -n --project "$sublime_project_file" -a
            return $?
            ;;
        *)
            joe "$note_file"
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

    gr.msg -c pink -v3 "$_date:$note_file_name:$note_file:${note_file%%.*}.odt"

    if [ -f "$note_file" ]; then
        template="ujo.guru"
        pandoc "$note_file" --reference-doc="$GURU_MOUNT_TEMPLATES/$template-template.odt" \
                -f markdown -o  "${note_file%%.*}.odt"
    else
        echo "no note for $(date +$GURU_FORMAT_DATE -d $1)"
        return 123
    fi

    $GURU_PREFERRED_OFFICE_DOC "${note_file%%.*}.odt" &
    echo "report file: ${note_file%%.*}.odt"


    # debug
    gr.msg -v4 -N -c green "$(declare -p | grep -e 'GURU_PREFERRED'  -e 'GURU_MOUNT'  | cut -d ' ' -f3)"
}


note.web () {
# create html of given day'note
    echo TBD
}


note.status () {
    # make status for daemon
    gr.msg -t -n "${FUNCNAME[0]}: "
    # check note is enabled
    if [[ ${note[enabled]} ]] ; then
        gr.msg -n -v1 -c green "enabled, "
    else
        gr.msg -v1 -c black "disabled" -k ${note[indicator_key]}
        return 1
    fi
    note.check
    return $?
}

note.rc

if [[ ${BASH_SOURCE[0]} == ${0} ]]; then
    source $GURU_RC
    note.main $@
    exit $?
fi

