#!/bin/bash
# guru tool-kit project tools
# ujo.guru 2020

source $GURU_BIN/lib/common.sh

project.main() {
    # command paerser
    local _cmd="$1" ; shift

    case "$_cmd" in
        add|open|rm|sublime|installed)  project.$_cmd $@           ;;
                                 help)  project.help               ;;
                                    *)  project.open "$command $@" ;;
    esac
}


project.help () {
    printf "project module works only with sublime.\n"
    printf "Set preferred editor by typing: %s set editor subl, or edit '~/.gururc'. \n" "$GURU_CALL"
}


project.check() {
    mount.online "$GURU_LOCAL_TRACK"
    if [[ -d "$GURU_LOCAL_TRACK/project" ]] ; then
            EXIST "project database"
            return 0
        else
            NOTEXIST "project database"
            return 41
        fi
    }


project.open () {
    # open project with preferred editor
    [[ "$1" ]] && _project_name="$1" ||read -p "plase enter project name : " _project_name
    shift

    if ! [[ -d "$GURU_PROJECT/$_project_name" ]] ; then
        NOTEXIST "_project_name"
        return 43
    fi

    case "$GURU_EDITOR" in
         subl|sublime|sublime-text|subl2|subl3|subl4)
                                project.sublime $_project_name   ;;
                            *)  project.help
    esac
}


project.sublime () {

    local _project_name="$1"                                          ; echo "$_project_name"
    local _project_file=$GURU_PROJECT/$_project_name.sublime-project  ; echo "$_project_file"

    if [ -f "$project_file" ]; then
        subl --project "$_project_file" -a
        subl --project "$_project_file" -a                              # Sublime how to open workpace?, this works anyway
    else
        printf "no sublime project found" >"$GURU_ERROR_MSG"
        return 132
    fi
}


# if not runned from terminal, use as library
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
    if [[ "$1" == "test" ]] ; then shift ; echo "test $1" ; ./test/test.sh project $1 ; fi
    project.main "$@"
fi

