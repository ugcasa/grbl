#!/bin/bash
# note tools for grbl casa@ujo.guru 2017-2022
source mount.sh

__note=$(readlink --canonicalize --no-newline $BASH_SOURCE)
__note_color="light_blue"

declare -g note_file
declare -g note_date
declare -g note_file_name
declare -g note_rc=/tmp/$USER/grbl_note.rc
declare -g require=(nacal pandoc gnome-terminal)


note.help () {
# notes help printout
    gr.msg -v4 -n -c $__note_color "$__note [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2
    gr.msg -v1 -c white "grbl note help "
    gr.msg -v2
    gr.msg -v0 "Usage:    $GRBL_CALL note ls|add|open|rm|check|report|locate|tag <date> "
    gr.msg -v1 -c white "Commands:"
    gr.msg -v2
    gr.msg -v1 " check          check do note exist, returns 0 if i do "
    gr.msg -v1 " list           list of notes. first month (MM), then year (YYYY) "
    gr.msg -v1 " open|edit      open given date notes (use time format $GRBL_FORMAT_FILE_DATE "
    gr.msg -v1 "  <yesterday>   literal date pointing available"
    gr.msg -v1 "  <next month>  ... "
    gr.msg -v1 " install        install required software: ${require[@]}"
    gr.msg -v2 " uninstall      remove required software: ${require[@]}"
    gr.msg -v1 " tag            read from or add tags to note file "
    gr.msg -v1 " locate         returns file location of note given YYYYMMDD "
    gr.msg -v1 " office         compile to .odt format open it"
    gr.msg -v2 "   <date>       change note date"
    gr.msg -v2 "   <team_name>  change template file"
    gr.msg -v1 " html <date>    compile and open note with $GRBL_PREFERRED_BROWSER "
    gr.msg -v2
}

note.main () {
# main command parser
    gr.msg -v4 -n -c $__note_color "$__note [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    local command="$1" ; shift

    case "$command" in

        find|status|ls|add|open|rm|check|locate|config|tag|install|uninstall)
                note.$command "$@"
                return $?
                ;;

        # these note types are opened with obsidian
        memo*|idea|write*)
                note.open_obsidian_vault "$command"
                return $?
                ;;

        office|html)
                note.$command "$@"
                return $?
                ;;
        help)
                note.help
                return $?
                ;;
         "")
                note.open $(gr.datestamp)
                return $?
                ;;
          *)
                note.open "$command $@"
                return $?
                ;;
    esac
}

note.rc () {
# source configurations (to be faster)
    gr.msg -v4 -n -c $__note_color "$__note [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    if [[ ! -f $note_rc ]] \
        || [[ $(( $(stat -c %Y $GRBL_CFG/$GRBL_USER/note.cfg) - $(stat -c %Y $note_rc) )) -gt 0 ]] \
        || [[ $(( $(stat -c %Y $GRBL_CFG/$GRBL_USER/mount.cfg) - $(stat -c %Y $note_rc) )) -gt 0 ]]
        then
            note.make_rc && \
                gr.msg -v1 -c dark_gray "$note_rc updated"
        fi

    source $note_rc
}

note.make_rc () {
# configure note module
    gr.msg -v4 -n -c $__note_color "$__note [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    source config.sh

    # make rc out of config file and run it
    if [[ -f $note_rc ]] ; then
            rm -f $note_rc
        fi

    config.make_rc "$GRBL_CFG/$GRBL_USER/mount.cfg" $note_rc
    config.make_rc "$GRBL_CFG/$GRBL_USER/note.cfg" $note_rc append
    chmod +x $note_rc
    source $note_rc
}

note.config () {
# populates global note variables based on given date in format YYYMMDD or literal date like "next month"
    gr.msg -v4 -c blue "$__note [$LINENO] $FUNCNAME '$@'" >&2

    local _input="$(echo ${@}| xargs)"
    [[ $1 ]] || _input="today"
    local _year _month _day _datestamp
    local _re='^[0-9]+$'
    # gr.debug "date_format: $GRBL_FORMAT_FILE_DATE"

    case $_input in
        *.*)
            # gr.debug "got date with dots"
            _day=$(cut -d "." -f1 <<<$_input)
            _day=$(printf "%02d" "$_day")
            _month=$(cut -d"." -f2 <<<$_input)
            _month=$(printf "%02d" "$_month")
            _year=$(cut -d"." -f3 <<<$_input)

            if date -d "$_year$_month$_day" >/dev/null; then
                true
                # gr.debug "Finnish date DDMMYYYY $_day.$_month.$_year"
            elif date -d "$_day$_month$_year" >/dev/null; then
                gr.debug "UK date YYYYMMDD $_year.$_month.$_day"
                local temp=$_year
                _year=$_day
                _day=$temp
            elif date -d "$_year$_day$_month" >/dev/null; then
                # gr.debug "US date MMDDYYYY $_month.$_day.$_year"
                local temp=$_month
                _month=$_day
                _day=$temp
            fi
            _datestamp="${_year}${_month}${_day}"

            # this cannot be done
            # # check is four digit year
            # if [[ ${#_year} -lt 4 ]]; then
            #     # check is year less than 1000
            #     if [[ ${#_year} -gt 2 ]] || [[ ${#_year} -lt 2 ]]; then
            #         gr.msg -e1 "please enter year in two or four digits"
            #         exit 2
            #     else
            #     # two digit year assume all before 50 to be 1950 and mote than that 2050
            #     if [[ $_year -ge 50 ]]; then
            #         _year="19$_year"
            #         else
            #         _year="20$_year"
            #         fi
            #     fi
            # fi

        ;;
        "")
            # gr.debug "got empty input, using today"
            _datestamp=$(date -d now $GRBL_FORMAT_FILE_DATE)
            _year=$(date -d $_datestamp +%Y)
            _month=$(date -d $_datestamp +%m)
            _day=$(date -d $_datestamp +%d)
        ;;
        *)
            # check it contain numbers
            if [[ $_input =~ $_re ]] ; then
                # gr.debug "got date stamp format"
                _year=${_input::-4}
                _month=${_input:4:2}
                _day=${_input:6:2}
                _datestamp="${_year}${_month}${_day}"
            else
                # gr.debug "got textual input"
                _datestamp=$(date -d "${_input[@]}" +%Y%m%d)

                if ! [[ $_datestamp ]]; then
                    gr.msg -e1 "unknown date '${_input[@]}'"
                    exit 122
                fi
                _year=$(date -d $_datestamp +%Y)
                _month=$(date -d $_datestamp +%m)
                _day=$(date -d $_datestamp +%d)
            fi
        ;;
    esac

    # test variables
    gr.varlist "debug _day _month _year _datestamp"
    # date -d "$_year" +%Y  >/dev/null || exit 112
    # date -d "$_month" +%m >/dev/null || exit 113
    # date -d "$_day" +%d >/dev/null || exit 114
    # date -d "$_datestamp" >/dev/null || exit 115

    # fulfill note variables with given date in user config formats TBD bad naming ünd shit
    note_date=$(date -d $_datestamp +$GRBL_FORMAT_DATE)
    note_folder=$GRBL_MOUNT_NOTES/$GRBL_USER_NAME/$_year/$_month
    note_file_name=$GRBL_USER_NAME"_notes_"$_datestamp.md
    note_file="$note_folder/$note_file_name"
    template_file_name="template.$GRBL_USER_NAME.$GRBL_USER_TEAM.md"
    template="$GRBL_MOUNT_TEMPLATES/$template_file_name"
    gr.varlist "debug note_date note_folder note_file_name note_file template_file_name template"
}

note.check () {
# check that given date note file exist
    gr.msg -v4 -n -c $__note_color "$__note [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    local input="$@"

    [[ $input ]] || input="today"
    if ! note.online ; then note.remount ; fi


    note.config "$input"
    gr.msg -n -v2 "checking note $note_date.. "
    if [[ -f "$note_file" ]] ; then
        gr.msg -v1 -c green "$note_file_name exist"
        return 0
    else
        gr.msg -c dark_gray "$note_file_name not found"
        return 41
    fi
}

note.locate () {
# find notes based on timestamp
    gr.msg -v4 -n -c $__note_color "$__note [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    note.locate_check () {
        # make variables
        gr.msg -v4 -n -c $__note_color "$__note [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

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
    gr.msg -v4 -n -c $__note_color "$__note [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    if ! [[ "$GRBL_MOUNT_NOTES" ]] && [[ "$GRBL_MOUNT_TEMPLATES" ]] ; then
        gr.msg -e1 "empty variable: '$GRBL_MOUNT_NOTES' or '$GRBL_MOUNT_TEMPLATES'"
        return 100
    fi

    # if not going to write to server do continue to able coding..
    [[ $GRBL_DEBUG ]] && return 0

    if mount.online "$GRBL_MOUNT_NOTES" && mount.online "$GRBL_MOUNT_TEMPLATES" ; then
        gr.msg -v3 -c green "note database mounted"
        return 0
    else
        gr.msg -v2 -c red "note database not mounted"
        return 1
    fi
}

note.remount () {
# mount needed folders
    gr.msg -v4 -n -c $__note_color "$__note [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2
    [[ $GRBL_DEBUG ]] && return 0
    mount.known_remote notes || return 43
    mount.known_remote templates || return 44
    return 0
}

note.ls () {
# list of notes given month/year
    gr.msg -v4 -n -c $__note_color "$__note [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    # check is note and template folder mounted, mount if not
    note.online || note.remount

    # List of notes on this month and year or given in order and format YYYY MM
    [[ "$1" ]] && month=$(date -d 2000-"$1"-1 +%m) || month=$(date +%m)
    [[ "$2" ]] && year=$(date -d "$2"-1-1 +%Y) || year=$(date +%Y)
    directory="$GRBL_MOUNT_NOTES/$GRBL_USER_NAME/$year/$month"

    if [[ -d "$directory" ]] ; then
        gr.msg -c light_blue "$(ls "$directory" | grep ".md" | grep -v "~" | grep -v "conflicted")"
        return 0
    else
        gr.msg -e2 "folder does not exist"
        return 45
    fi
}

note.add () {
# creates notes
    gr.msg -v4 -n -c $__note_color "$__note [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    # check is note and template folder mounted, mount if not
    note.online || note.remount
    note.config "$1"

    [[  -d "$note_folder" ]] || mkdir -p "$note_folder"

    # TODO picture/ mounter/linker
    # [[ -f $note_folder/pictures ]] || grbl mount pictures
    # ! [[ -d $note_folder/pictures ]] || ln -s $GRBL_MOUNT_PICTURES/notes $note_folder/pictures

    if [[ ! -f "$note_file" ]]; then

        # print file location
        printf "$note_file\n" >$note_file

        # tag

        printf "tag: note $GRBL_USER $(gr.datestamp)\n" >>$note_file

        # place template line 1 to third line
        [[ -f "$template" ]] && cat "$template" | head -n1 "$template" >>$note_file

        # add calendar blog
        if source cal.sh ; then
                printf "\n"'```calendar'"\n" >>$note_file
                cal.main notes >>$note_file # | grep -v $(date -d now +%Y)
                printf '```'"\n" >>$note_file
            fi

        # header
        printf "\n\n# ${GRBL_NOTE_HEADER}\n\n" >>$note_file

        # template
        [[ -f "$template" ]] && cat "$template"  |tail -n+2 >>$note_file || printf "customize your template to $template" >>$note_file

        # changes table
        note.add_change "created"

        return 0
    fi
}

note.open_obsidian_vault () {
# open idea gathering environment aka. obsidian vault memos in grbl/notes
    gr.msg -v4 -n -c $__note_color "$__note [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2
    # gr.msg "${FUNCNAME[0]} TBD"
    # xdg-open obsidian://open?vault=${1}
    local command="xdg-open obsidian://open?vault=${1}" #; while true ; do read -n1 ans ; case $ans in q) break ; esac ; done" # 2>/dev/null
    gnome-terminal --hide-menubar --geometry 130x6 --zoom 0.1 --title "obsidian launcher" -- bash -c "$command ; read "
}

note.open () {
# select note to open and call editor input date in format YYYYMMDD
    gr.msg -v4 -n -c $__note_color "$__note [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    # check is note and template folder mounted, mount if not
    note.online || note.remount

    local _note_date="$@"

    note.config "$_note_date"

    if [[ -f "$note_file" ]]; then
        note.add_change "opened"
    else
        note.add "$_note_date"
    fi

    note.open_editor "$note_file"
    return $?
}

note.rm () {
# remove note of given date. input format YYYYMMDD
    gr.msg -v4 -n -c $__note_color "$__note [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    # check is note and template folder mounted, mount if not
    note.online || note.remount

    note.config "$1"
    if ! [[ -f $note_file ]] ; then
        gr.msg -e1 "no note for date $(gr.datestamp $1)"
        return 11
    fi

    if gr.ask "remove $note_file" ; then
        rm -rf "$note_file" || gr.msg -e3 "note remove failed"
    fi
    return 0
}

note.tag () {
# add/read/rm tag from note files
    gr.msg -v4 -n -c $__note_color "$__note [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    source tag.sh
    note.online || note.remount

    # get date for note
    if date +$GRBL_FORMAT_FILE_DATE -d $1 >/dev/null ; then
        _note_date=$(date +$GRBL_FORMAT_FILE_DATE -d $1)
        shift
    else
        _note_date=$(date +$GRBL_FORMAT_FILE_DATE)
    fi

    local user_input="$@"

    note.config $_note_date

    gr.debug "_note_date: '$_note_date', user_input: '$user_input', note_file: '$note_file'"

    tag.main add $note_file $user_input
}


note.change_log () {
# add line to any file change log. input <file_name> <message>
    gr.msg -v4 -n -c $__note_color "$__note [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    _line () {
        for ((i=1;i<=$1;i++)); do
            printf '-'
        done
    }

    local _note_file="$1" ; shift
    local _change_message="edited"
    [[ "$1" ]] && _change_message="$@"
    local _author="$GRBL_USER_NAME"

    # add header if not exist
    if ! grep -q "**Change log**" "$_note_file" ; then
        # generate change table
        printf  "\n\n**Change log**\n\n" >>$_note_file
        printf  "%-17s | %-10s | %-30s \n" "Date" "Author" "Changes" >>$_note_file
        printf "%s|:%s:|%s\n" "$(_line 18)" "$(_line 10)" "$(_line 30)" >>$_note_file
    fi

    printf  "%-17s | %-10s | %s \n" "$(date +$GRBL_FORMAT_FILE_DATE)-$(date +$GRBL_FORMAT_TIME)" "$_author" "$_change_message" >>$_note_file
}


note.add_change () {
# add line to configured note file change log
    gr.msg -v4 -n -c $__note_color "$__note [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    [[ ${GRBL_NOTE_CHANGE_LOG} ]] || return 0

    _line () {
        gr.msg -v4 -n -c $__note_color "$__note [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2
        _len=$1
        for ((i=1;i<=_len;i++)); do
            printf '-'
        done
    }

    # check is note and template folder mounted, mount if not
    note.online || note.remount

    # printout change table
    local _change="edited"
    [[ "$1" ]] && _change="$@"

    note.change_log "$note_file" "$_change"
}



note.open_editor () {
# open note to preferred editor
    gr.msg -v4 -n -c $__note_color "$__note [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    local _options

    case "${GRBL_NOTE_EDITOR}" in # if was $GRBL_PREFERRED_EDITOR

        obsidian|obs)

            GRBL_NOTE_EDITOR="xdg-open"
            _options="obsidian://open?vault=${GRBL_NOTE_VAULT }"
            #return $?
            ;;
        subl|sublime|sublime3|sublime2)
            local project_folder=$GRBL_SYSTEM_MOUNT/project/projects/notes
            local sublime_project_file="$project_folder/$GRBL_USER_NAME-notes.sublime-project"

            [[ -d $project_folder ]] || gr.msg -x 100 -e3 "$project_folder not exist"
            [[ -f $sublime_project_file ]] || gr.msg -e1 "sublime project file missing"

            GRBL_NOTE_EDITOR="subl"
            _options="-n --project "$sublime_project_file" -a"
            ;;
        *)
            GRBL_NOTE_EDITOR="joe"
            ;;
    esac

    # make command as variable for debugging purposes
    _command="${GRBL_NOTE_EDITOR} $note_file $_options"
    if [[ $GRBL_DEBUG ]]; then echo $_command >&2 ; fi
    # run command
    if $_command; then
        return 0
    else
        return 123
    fi
}

note.office () {
# create .odt from team template out of given day's note
    gr.msg -v4 -n -c $__note_color "$__note [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    # check is note and template folder mounted, mount if not
    note.online || note.remount

    # get date for note
    if [[ "$1" ]] ; then
        _date="$1"
        shift
    else
        _date=$(date +$GRBL_FORMAT_FILE_DATE)
    fi

    # fulfill note file variables
    note.config "$_date"

    # template group name
    if [[ "$1" ]] ; then
        local _template=$1
    else
        local _template=$GRBL_USER_TEAM
    fi

    local odt_file="${note_file%%.*}.odt"
    local odt_template="$GRBL_MOUNT_TEMPLATES/template-$_template.ott"

    # make css option only if css. file exist
    if [[ -f $odt_template ]]; then
        gr.msg "using $_template template.. "
        gr.debug "template options: '$template_option'"
        template_option="--reference-doc=$odt_template " #--data-dir=$GRBL_MOUNT_TEMPLATES
    else
        gr.msg -e0 "template document does not exist, to avoid this error create $odt_template"
        template_option=
    fi

    if [[ -f "$odt_file" ]]; then
        odt_file="${odt_file%%.*}.$RANDOM.odt"
    fi

    # printout variables for debug purposes
    gr.debug "date:'$_date', \
          note_file_name: '$note_file_name', \
          note_file: '$note_file', \
          odt_template: '$odt_template', \
          odt_file: '$odt_file'"

    # check file exist
    if ! [ -f "$note_file" ]; then
        gr.msg -e1 "no note for $(date +$GRBL_FORMAT_DATE -d $_date)"
        return 123
    fi

    # add change log line
    note.add_change "odt export"

    # make command as variable for debugging purposes
    _command="pandoc $note_file -f markdown -o $odt_file $template_option"

    if [[ $GRBL_DEBUG ]]; then echo $_command ; fi

    # compile markdown to open office file format
    $_command

    # printout output file location
    gr.msg -v1 "$odt_file"

    # make command as variable for debugging purposes
    _command="$GRBL_PREFERRED_OFFICE_DOC $odt_file"
    if [[ $GRBL_DEBUG ]]; then echo $_command >&2; fi

    # open office program
    $_command &

    # $GRBL_PREFERRED_OFFICE_DOC "${note_file%%.*}.odt" &

}

note.html () {
# create html of given day's note
    gr.msg -v4 -n -c $__note_color "$__note [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2

    # check is note and template folder mounted, mount if not
    note.online || note.remount

    # get date for note
    if [[ "$1" ]] ; then
        _date=$1
        shift
    else
        _date=$(date +$GRBL_FORMAT_FILE_DATE)
    fi

    # fulfill note file variables
    note.config "$_date"

   # template group name
    if [[ "$1" ]] ; then
        _template=$1
    else
        _template=$GRBL_USER_TEAM
    fi

    local html_file="${note_file%%.*}.html"
    local css_file="$GRBL_MOUNT_TEMPLATES/template-$_template.css"

    # make css option only if css. file exist
    if [[ -f $css_file ]]; then
        gr.msg "using $_template template.. "
        css_option="--css=$css_file"
        #css_option="-c $css_file"
        gr.debug "template options: '$css_option'"
    else
        gr.msg -e0 "default css does not exist, to avoid this error create default css file to $css_file"
        css_option=
    fi

    if [[ -f "$html_file" ]]; then
        html_file="${html_file%%.*}.$RANDOM.html"
    fi

    # printout variables for debug purposes
    gr.debug "date:'$_date', \
              note_file_name: '$note_file_name', \
              note_file: '$note_file', \
              css_file: '$css_file', \
              html_file: '$html_file'"

    # check file exist
    if ! [ -f "$note_file" ]; then
        gr.msg -e1 "no note for $(date +$GRBL_FORMAT_DATE -d $_date)"
        return 123
    fi

    # add line to change log
    note.add_change "html export"

    # make command as variable for debugging purposes
    _command="pandoc -f markdown $note_file -o $html_file --to=html5 $css_option"

    if [[ $GRBL_DEBUG ]]; then echo $_command ; exit 0; fi

    # run command
    $_command

    #printout output file location
    gr.msg -v1 "$html_file"

    # open browser
    if [[ -f $html_file ]]; then
        $GRBL_PREFERRED_BROWSER $html_file &
    else
        gr.msg -e1 "$html_file not found"
    fi
}


note.search_tag2 () {
# read note file tag line

    local target_file="$1"
    #[[ -f $target_file ]] || return 1
    local target_file=
    [[ -f $target_file ]] && tagline=$(grep '{{tag>' "$target_file")

    # first remove '}}' at the end and cut out before '>'
    local tags=$(cut -d '>' -f2 <<<${tagline//'}'/})
    echo "$tags"
}


note.search_tag1 () {
# read note file tag line

    local target_file="$1"
    #[[ -f $target_file ]] || return 1
    local tagline=
    #grep 'tag:' "$target_file" >> tagi
    [[ -f $target_file ]] && tagline=$(grep 'tag:' "$target_file")
    #echo "$target_file:$tagline" >> tagi
    gr.msg -w 80 -v1 -n -r -c dark_gray "$target_file" >&2
    local tags=$(cut -d ':' -f2 <<<$tagline)
    echo "$tags"
}


note.search_tag () {
# get tag from note file and check does it contain given word
    local search_terms=($@)
    local matches=()
    local and=
    local match_count=

    # check is and term given
    for term in ${search_terms[@]} ; do

        if [[ ${term,,} == "and" ]]; then
            and=true
            continue
        fi
    done

    for file in ${files[@]} ; do

        # find version 1 tags
        tags=($(note.search_tag1 $file))

        # jump to next file if no tags found
        [[ $tags ]] || continue
        match_count=0


        # go trough all found tags
        for tag in ${tags[@]} ; do

            for term in ${search_terms[@]} ; do

                # skip control words
                if [[ ${term,,} == "and" ]]; then
                    and=true
                    continue
                fi

                if [[ ${term,,} == ${tag,,} ]]; then
                    ((match_count++))
                    if [[ $and ]] ; then
                        if [[ $match_count -ge $((${#search_terms[@]} -1)) ]]; then
                            gr.msg -c white "$file" >&2
                            echo $file
                        fi
                    else
                        gr.msg -c white "'$term' $file" >&2
                        echo $file
                    fi
                fi
            done
        done
        # exit search loop
        read -rsn1 -t0.00001 ans; case $ans in q) break; esac
    done
    gr.msg -w 80 -v1 -n -r " " >&2
}


note.find () {
# find keywords from tags in notes

# known issues: loop stops for no raeson
#               can produce false matches
#               slow, mainly cause tag are not indexed

    files=()
    local year="all"
    local file_pattern="${GRBL_USER_NAME}_notes_????????.md"
    local file_list="/tmp/$USER/note_search.list"
    # will be empty if no database exist
    local last_index=$(cat "${file_list}_year" 2>/dev/null)
    local location=$GRBL_MOUNT_NOTES/$GRBL_USER_NAME
    local matches=()

    # check is year given (1000 - 9999)
    case $1 in
        [1-9][0-9][0-9][0-9])
            year=$1
            shift
            file_pattern="${GRBL_USER_NAME}_notes_${year}????.md"
    esac

    local search_terms=($@)

    if [[ $last_index == $year ]] || [[ $last_index == "all" ]] && [[ -f $file_list ]] ; then

        files=($(cat $file_list))

        # remove other years for speed up search
        if [[ $year != "all" ]] ; then
            for _file in ${files[@]}; do
                [[ $_file =~ $year ]] && _files+=($_file)
            done
            files=(${_files[@]})
        fi

    else
        gr.msg -v1 "building file list ${year}.."
        files=($(find "$location" -type f -iname $file_pattern 2>/dev/null | grep -v '#'))

        if [[ ${#files[@]} -lt 1 ]] ; then
            gr.msg -e1 "note files not found"
            return 100
        fi

        # write index to file
        [[ -f $file_list ]] && rm $file_list
        for filename in ${files[@]}; do
            echo ${filename} >> $file_list
        done
        # write index meta to file
        echo $year > "${file_list}_year"

        # sort file list by age
        sort -r -o $file_list $file_list
        files=($(cat $file_list))

    fi

    gr.debug "${FUNCNAME[0]} files: ${#files[@]}"


    gr.msg -v1 "searching '${search_terms[@],,}' from ${year}.."
    matches+=($(note.search_tag ${search_terms[@]}))


    gr.debug "matches: ${#matches[@]}: '${matches[@]}'"

    # silent mode
    [[ $GRBL_VERBOSE -lt 1 ]] && return 0

    # verbose and question
    if [[ ${#matches[@]} -gt 0 ]]; then

        if gr.ask "open found files with $GRBL_PREFERRED_EDITOR?" ; then

            if [[ ${GRBL_NOTE_CHANGE_LOG} ]]; then
                for match in ${matches[@]}; do
                    note.change_log $match "opened by finder"
                done
            fi

            $GRBL_PREFERRED_EDITOR ${matches[@]}
        # else
        #     for filename in ${matches[@]}; do
        #         gr.msg -v-c list "$filename"
        #     done
        fi
    else
        gr.msg -v1 "no matches found"
    fi
}

note.status () {
    # make status for daemon
    gr.msg -v4 -n -c $__note_color "$__note [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2
    gr.msg -t -n "${FUNCNAME[0]}: "
    # check note is enabled
    if [[ ${GRBL_NOTE_ENABLED} ]] ; then
        gr.msg -n -v1 -c green "enabled, "
    else
        gr.msg -v1 -c black "disabled" -k ${GRBL_NOTE_INDICATOR_KEY}
        return 1
    fi
    note.check "$@"
    return $?
}

note.install () {
# Install needed tools
    gr.msg -v4 -n -c $__note_color "$__note [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2
    local require=(ncal pandoc gnome-terminal libreoffice-java-common default-jre moreutils)
    for install in ${require[@]} ; do
        hash $install 2>/dev/null && continue
        gr.ask -h "going to install $install" || continue
        sudo apt-get -y install $install
    done

    source tag.sh
    tag.main install
}

note.uninstall () {
# Install needed tools
    gr.msg -v4 -n -c $__note_color "$__note [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2
    local require=(ncal pandoc)
    for install in ${require[@]} ; do
        hash $install 2>/dev/null || continue
        gr.ask -h "going to remove $install" || continue
        sudo apt-get -y purge $install
    done
}

note.rc

if [[ ${BASH_SOURCE[0]} == ${0} ]]; then
    note.main $@
    exit $?
fi

