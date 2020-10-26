#!/bin/bash
# guru-client project tools
# ujo.guru 2020

# todo: this bs is. rewrite somehow soon

source $GURU_BIN/common.sh
source $GURU_BIN/mount.sh

project.help () {
    gmsg -v1 -c white "guru-client project help "
    gmsg -v2
    gmsg -v0 "usage:    $GURU_CALL project [ls|new|open|status|archive|active|close|rm|sublime|help] <name|id>"
    gmsg -v2
    gmsg -v1 -c white "commands:"
    gmsg -v1 "  ls                      list of archived projects "
    gmsg -v1 "  new <name|id>           add new projects "
    gmsg -v1 "  open <name|id>          open project "
    gmsg -v1 "  close                   close project, keep data "
    gmsg -v1 "  status <name|id|"">     project status"
    gmsg -v2 "                          if empty, all project status view"
    gmsg -v1 "  change <name|id>        same as close and open  "
    gmsg -v1 "  archive <name|id>       move to archive"
    gmsg -v2 "                          empty input lists archived projects "
    gmsg -v1 "  active <name|id>        return archived project "
    gmsg -v2 "  rm <name|id>            remove project and files for good "
    gmsg -v2 "  install                 install requirements "
    gmsg -v2 "  remove                  remove requirements "
    gmsg -v2 "  sublime <name>          open only sublime project "
    gmsg -v1 "  help                    this help "

    gmsg -v1
    gmsg -v1 "most of commands takes project name (or id) as an variable "
    gmsg -v2
    gmsg -v1 -c white "example:"
    gmsg -v1 " $GURU_CALL project new demo       # init new project called 'demo'"
    gmsg -v2 " $GURU_CALL project archive        # list of archived projects "
    gmsg -v1 " $GURU_CALL project archive demo   # archive demo "
    gmsg -v2 " $GURU_CALL project rm demo        # remove all demo project files "
    gmsg -v2

}


project.main() {
    # command paerser
    local _cmd="$1" ; shift
    case "$_cmd" in
        ls|new|status|archive|active|close|rm|help)
                project.$_cmd $@
                return $? ;;
        open)   project.sublime $@
                return $? ;;
        *)      project.open "$_cmd"
                return $? ;;
        esac
}


project.check() {
    gmsg -n -v1 "project database.. "
    mount.online "$GURU_SYSTEM_MOUNT"
    if [[ -d "$GURU_SYSTEM_MOUNT/project" ]] ; then
            gmsg -c green "mounted"
            return 0
        else
            gmsg -c red "not mounted"
            return 41
        fi
    }


project.ls () {
    gmsg -c light_blue "$(ls $GURU_SYSTEM_MOUNT/project)"
}


project.status () {
    project.check
    project.ls
    [[ -f $GURU_PROJECT/active ]] && gmsg -c cyan "currently active $(cat $GURU_PROJECT/active)" || gmsg -c black "no active projects"
}


project.sublime () {

    local _project_name="$1"
    local _project_file=$GURU_SYSTEM_MOUNT/sublime-projects/$GURU_USER-$_project_name.sublime-project
    # echo "$_project_name"
    # echo "$_project_file"

    if [[ -f "$_project_file" ]] ; then
            subl --project "$_project_file" -a
            subl --project "$_project_file" -a                              # Sublime how to open workpace?, this works anyway
        else
            WARNING "no sublime project found"
            return 132
        fi
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
        source "$GURU_RC"
        project.main "$@"
    fi

