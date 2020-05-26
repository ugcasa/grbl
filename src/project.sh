#!/bin/bash
# guru tool-kit project tools
# ujo.guru 2020

source $GURU_BIN/lib/common.sh

if ! [[ $GURU_PROJECT ]] ; then echo "no project" ; fi

project.main() {
    # command paerser

    local _cmd="$1" ; shift

    case "$_cmd" in
        add|open|rm|sublime)  project.$_cmd $@           ;;
                       help)  project.help               ;;
                          *)  project.open "$_cmd"
        esac
}


project.help () {
    echo "-- guru tool-kit project help -----------------------------------------------"
    printf "usage:\t\t %s project [command] project_name \n\n" "$GURU_CALL"
    printf "commands:\n"
    printf " add             add new projects \n"
    printf " open            open project \n"
    printf " close           close project, keep data \n"
    printf " rm              move project files to trash \n"
    printf " delete          remove project and files for good \n"
    printf " help            this help \n\n"
    printf "project module works only with sublime.\n"
    printf "set preferred editor by '%s set editor subl'\n" "$GURU_CALL"
    printf "\nexample:"
    printf "\t %s project add projet_name \n" "$GURU_CALL"
    printf "\t\t %s project open project_name \n" "$GURU_CALL"

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

project.add () {

    [[ "$1" ]] && _project_name="$1" ||read -p "plase enter project name : " _project_name
    shift

    if [[ -d "$GURU_PROJECT/$_project_name" ]] ; then
            EXIST "$_project_name"
            (( GURU_VERBOSE==2 )) && msg " try another name\n"
            return 43
        fi

    mkdir -p $GURU_PROJECT/$_project_name

}

project.open () {
    # open project with preferred editor
    [[ "$1" ]] && _project_name="$1" ||read -p "plase enter project name : " _project_name
    shift

    if ! [[ -d "$GURU_PROJECT/$_project_name" ]] ; then
            NOTEXIST "$_project_name"
            return 43
        fi

    case "$GURU_EDITOR" in
         subl|sublime|sublime-text|subl2|subl3|subl4)
                                project.sublime $_project_name   ;;
                            *)  project.help
        esac
}


project.sublime () {

    local _project_name="$1"                                                              ; echo "$_project_name"
    local _project_file=$GURU_LOCAL_TRACK/sublime-projects/$GURU_USER-$_project_name.sublime-project  ; echo "$_project_file"

    if [[ -f "$_project_file" ]] ; then
            subl --project "$_project_file" -a
            subl --project "$_project_file" -a                              # Sublime how to open workpace?, this works anyway
        else
            WARNING "no sublime project found" #>"$GURU_ERROR_MSG"
            return 132
        fi
}


# if not runned from terminal, use as library
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
        if [[ "$1" == "test" ]] ; then shift ; ./test/test.sh project $1 ; fi
        project.main "$@"
    fi

