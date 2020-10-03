#!/bin/bash
# guru-client project tools
# ujo.guru 2020

source $GURU_BIN/common.sh
source $GURU_BIN/mount.sh
source ~/.gururc2
# echo "TEST: $GURU_SYSTEM_MOUNT"



project.main() {
    # command paerser

    local _cmd="$1" ; shift

    case "$_cmd" in
        add|open|rm|sublime)  project.$_cmd $@           ;;
                       help)  project.help               ;;
                     status)  project.status             ;;
                          *)  project.open "$_cmd"
        esac
}


project.help () {
    gmsg -v1 -c white "guru-client project module help -----------------------------------------------"
    gmsg -v2
    gmsg -v0 "usage:    $GURU_CALL project [add|open|rm|sublime] <project_name>"
    gmsg -v2
    gmsg -v1 -c white "commands:"
    gmsg -v1 "  add             add new projects "
    gmsg -v1 "  open            open project "
    gmsg -v1 "  close           close project, keep data "
    gmsg -v1 "  rm              move project files to trash "
    gmsg -v1 "  delete          remove project and files for good "
    gmsg -v1 "  help            this help "
    gmsg -v1
    gmsg -v1 "project module works only with sublime."
    gmsg -v1 "set preferred editor by '%s set editor subl'" "$GURU_CALL"
    gmsg -v2
    gmsg -v1 -c white "example:"
    gmsg -v1 " $GURU_CALL project add projet_name "
    gmsg -v1 " $GURU_CALL project open project_name "
    gmsg -v2

}


project.check() {
    gmsg -n -v1 "project database.. "
    mount.online "$GURU_SYSTEM_MOUNT"
    if [[ -d "$GURU_SYSTEM_MOUNT/project" ]] ; then
            gmsg -c green "MOUNTED"
            return 0
        else
            gmsg -c red "NOT MOUNTED"
            return 41
        fi
    }


project.ls () {
    gmsg -c cyan "$(ls $GURU_SYSTEM_MOUNT/project)"
}


project.status () {
    project.check
    project.ls
    [[ -f $GURU_PROJECT/active ]] && gmsg -c lcyan "currently active $(cat $GURU_PROJECT/active)"  || gmsg -c black "no active projects"
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
    local _project_file=$GURU_SYSTEM_MOUNT/sublime-projects/$GURU_USER-$_project_name.sublime-project  ; echo "$_project_file"

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

