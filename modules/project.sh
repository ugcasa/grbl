#!/bin/bash
# guru-client project tools
# ujo.guru 2020
# todo: this bs is. rewrite somehow soon
source $GURU_BIN/common.sh
source $GURU_BIN/mount.sh
source $GURU_BIN/timer.sh


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
    gmsg -v1 "  change <name>           change project"
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
    return 0
}


project.main () {

    local _cmd="$1" ; shift

    case "$_cmd" in
        check|ls|new|open|change|status|archive|active|close|rm|sublime|help)
                project.$_cmd "$@"
                return $? ;;

        *)      project.open "$_cmd"
                return $? ;;
        esac
}


project.check () {

    local project_base="$GURU_SYSTEM_MOUNT/project"
    local project_mount="$GURU_MOUNT_PROJECTS"
    local project_name="$1"

    # check project file locaton is accessavle
    gmsg -n -v1 "cheking projects.. "
    if ! [[ -d "$project_base" ]] ; then
            gmsg -c red "$project_base not available"
            if [[ $GURU_FORCE ]] ; then
                    mount.main mount system || return $?
                else
                    gmsg -v1 -c white "try -f or '$GURU_CALL mount system'"
                    return 41
                fi
        fi

    # check are projects mounted
    if [[ -f "$project_mount/.online" ]] ; then
            gmsg -v1 -c green "available"
        else
            gmsg -v1 -c yellow "not mounted"

            if [[ $GURU_FORCE ]] ; then
                    mount.main mount projects || return $?
                else
                    gmsg -v1 -c white "try -f or '$GURU_CALL mount projects'"
                    return 41
                fi
        fi

    [[ $project_name ]] || return 0

    gmsg -n -v1 "$project_name.. "
    # check does project have a folder
    if [[ -s "$project_mount/$project_name" ]] ; then
            gmsg -v1 -c green "ok"
            gmsg -v2 -c light_blue "$(ls $project_mount/$project_name)"
        else
            gmsg -v1 -c yellow "$project_name folder not found"
            return 41
        fi
}


project.ls () {

    local project_base="$GURU_SYSTEM_MOUNT/project"
    # gmsg -v3 -c pink "$project_base"

    local _project_list=($(file "$project_base/"* \
        | grep directory \
        | cut -d ':' -f1 \
        | rev  \
        | cut -d "/" -f1 \
        | rev))

    # is there projects
    if (( ${#_project_list[$@]} < 1 )) ; then
            gmsg -c dark_grey "no projects"
            return 1
        fi

    gmsg -v2 -c white "project count: ${#_project_list[@]}"

    # check active project
    [[ -f $project_base/active ]] && local _active_project=$(cat $project_base/active)
    gmsg -v2 -c aqua_marine "active: $_active_project"

    # list of projects
    gmsg -v1 "list of projects "
    for _project in ${_project_list[@]} ; do
        if [[ "$_project" == "$_active_project" ]] ; then
                gmsg -c aqua_marine "$_project"
            else
                gmsg -c light_blue "$_project"
            fi
        done

    return 0
}


project.status () {
    project.check
    project.ls
}


project.add () {

    [[ "$1" ]] || gmsg -x 100 -c yellow "project name needed"

    local project_name="$1"
    local project_base="$GURU_SYSTEM_MOUNT/project"
    local project_folder="$project_base/$project_name"
    local sublime_project_file="project_folder/$GURU_USER-$project_name.sublime-project"

    [[ -d $project_folder ]] || mkdir -p "$project_folder"
    [[ -f $sublime_project_file ]] || touch "$sublime_project_file"
}


project.sublime () {

    [[ "$1" ]] || gmsg -x 100 -c yellow "project name needed"

    local project_name="$1"
    local project_base="$GURU_SYSTEM_MOUNT/project"
    local project_folder="$project_base/$project_name"
    local sublime_project_file="$project_folder/$GURU_USER-$project_name.sublime-project"

    if ! [[ -d $project_folder ]] ; then
            gmsg -c yellow "project not exist"
            return 131
        fi

    if [[ -f "$sublime_project_file" ]] ; then
            gmsg -v2 -c dark_grey "using $sublime_project_file"
            subl --project "$sublime_project_file" -a
            subl --project "$sublime_project_file" -a # Sublime how to open workpace?, this works anyway
        else
            gmsg -c yellow "$sublime_project_file not found"
            return 132
        fi
}


project.open () {
    # just open sublime for now
    local project_name=$1
    local project_base="$GURU_SYSTEM_MOUNT/project"

    echo $project_name > "$project_base/active"
    gmsg -v1 -m "$GURU_USER/status" "currenlty working on $project_name"
    project.sublime $@
}


project.change () {
    # just open sublime for now
    local project_name=$1
    local project_base="$GURU_SYSTEM_MOUNT/project"

    echo $project_name > "$project_base/active"
    gmsg -v2 "$project_name" -m "$GURU_USER/project"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
        source "$GURU_RC"
        project.main "$@"
    fi

