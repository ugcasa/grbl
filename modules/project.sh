#!/bin/bash
# guru-client project tools
# ujo.guru 2020

# TBD project database of some kind
# TBD better intregration with tmux
# TBD do not generate project details, save those to base (of somekind)


source $GURU_BIN/common.sh
source $GURU_BIN/mount.sh
source $GURU_BIN/timer.sh

project.help () {
    gmsg -v1 -c white "guru-client project help "
    gmsg -v2
    gmsg -V2 -v0 "usage:    $GURU_CALL project ls|info|add|rm|open|close "
    gmsg -v2 "usage:    $GURU_CALL project ls|new|open|status|close|rm|sublime|help  name/id"
    gmsg -v2
    gmsg -v1 -c white "commands:"
    gmsg -v1 "  ls                      list of projects "
    gmsg -v1 "  info                    more detailed information of projects "
    gmsg -v1 "  new <name|id>           add new projects "
    gmsg -v1 "  open <name|id>          open project "
    gmsg -v1 "  close                   close project, keep data "
    gmsg -v1 "  change <name|id>        same as close and open  "
    gmsg -v1 "  archive <name|id>       move to archive"
    gmsg -v1 "  active <name|id>        return archived project "
    gmsg -v2 "  rm <name|id>            remove project and files for good "
    gmsg -v2 "  install                 install requirements "
    gmsg -v2 "  remove                  remove requirements "
    gmsg -v1 "  change <name>           change project"
    gmsg -v2 "  sublime <name>          open only sublime project "
    gmsg -v1 "  status                  status of project module"
    gmsg -v2 "  poll start|stop         damen poll function"
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
    # main command parser
    local _cmd="$1" ; shift

    case "$_cmd" in
        check|ls|info|new|open|change|status|archive|active|close|rm|sublime|poll|help)
                project.$_cmd "$@"
                return $? ;;

        *)      project.open "$_cmd"
                return $? ;;
        esac
}


project.status () {
    # check that project module is working correctly
    local project_base="$GURU_SYSTEM_MOUNT/project"
    local project_mount="$GURU_MOUNT_PROJECTS"
    local project_name="$1"
    local project_indicator_key="f$(daemon.poll_order project)"

    # check project file locaton is accessavle
    gmsg -t -n -v1 "cheking projects.. "
    if ! [[ -d "$project_base" ]] ; then
            gmsg -c red "$project_base not available" -k $project_indicator_key
            if [[ $GURU_FORCE ]] ; then
                    mount.main mount system || return $?
                else
                    gmsg -v1 -c white "try -f or '$GURU_CALL mount system'"
                    return 41
                fi
        fi

    # check are projects mounted
    if [[ -f "$project_mount/.online" ]] ; then
            gmsg -v1 -c green "available"  -k $project_indicator_key
        else
            gmsg -v1 -c yellow "not mounted"  -k $project_indicator_key

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
    if [[ -d "$project_mount/$project_name" ]] ; then
            gmsg -v1 -c green "ok" -k $project_indicator_key
            gmsg -v2 -c light_blue "$(ls $project_mount/$project_name)"
        else
            gmsg -v1 -c yellow "$project_name folder not found" -k $project_indicator_key
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
    #gmsg -v1 "list of projects "
    for _project in ${_project_list[@]} ; do
        if [[ "$_project" == "$_active_project" ]] ; then
                gmsg -c aqua_marine "$_project"
            else
                gmsg -c light_blue "$_project"
            fi
        done

    return 0
}


project.info () {
    # list of projects, active higlighted with lis of tmux sessions
    #source tmux.sh

    gmsg -n -c white "system folder.. "
    if [[ -f $GURU_SYSTEM_MOUNT/.online ]] ; then
        gmsg -c green "mounted"
    else
        gmsg -c red "not mounted"
        gmsg "cannot continue, exiting"
        return 100
    fi

    gmsg -n -c white "project folder.. "
    if [[ -f $GURU_MOUNT_PROJECTS/.online ]] ; then
        gmsg -c green "mounted"
    else
        gmsg -c red "not mounted"
    fi

    gmsg -n -c white "projects: "
    project.ls | tr '\n' ' ' ; echo

    if module.installed tmux ; then
            gmsg -n -c white "tmux sessions: "
            local sessions=($(tmux ls |cut -f 1 -d ':'))
            local active=$(tmux ls | grep '(attached)' | cut -f 1 -d ':')
            local _id=""

            for _id in ${sessions[@]} ; do
                    if [[ $_id == $active ]] ; then
                            gmsg -n -c aqua_marine "$_id "
                        else
                            gmsg -n -c light_blue "$_id "
                        fi
                    #gmsg -c pink "$_id : $active"
                done
            echo
        fi

    local active=$(cat $GURU_SYSTEM_MOUNT/project/active)
    gmsg -n -c white "active project '$active' "

    # active project ingformation
    if [[ -f $GURU_SYSTEM_MOUNT/project/$active/project.conf ]] ; then
            source $GURU_SYSTEM_MOUNT/project/$active/project.conf
            gmsg -n -c aqua_marine "$project_name"
            gmsg -c grey " '$project_description' data: '$project_data' mountpoint: '$project_folder'"
            #gmsg -c pink "$GURU_SYSTEM_MOUNT/project/$active/project.conf"
        else
            gmsg "no $active project data available"
        fi
}


project.add () {
    # add project to projects
    [[ "$1" ]] || gmsg -x 100 -c yellow "project name needed"

    local project_name="$1"
    local project_base="$GURU_SYSTEM_MOUNT/project"
    local project_folder="$project_base/$project_name"
    local sublime_project_file="$project_folder/$GURU_USER-$project_name.sublime-project"

    [[ -d $project_folder ]] || mkdir -p "$project_folder"
    [[ -f $sublime_project_file ]] || touch "$sublime_project_file"

}


project.rm () {

    [[ $1 ]] || gmsg -x 1 "project name is reguired"
    local project_name="$1"
    local project_base="$GURU_SYSTEM_MOUNT/project"
    local project_folder="$project_base/$project_name"
    local sublime_project_file="$project_folder/$GURU_USER-$project_name.sublime-project"

    [[ -d $project_folder ]] || gmsg -x 100 "project $project_name not exist"

    if gask "sure to remove $project_name?" ; then
            # remove sublime project file if exist
            [[ -f $sublime_project_file ]] && rm -f $sublime_project_file || gmsg "sublime project $project_name not exist"
            # remove project database
            rm -fr $project_folder && gmsg -v1 "project folder $project_folder removed"
            return $?
        else
            gmsg -v1 -c dark_golden_rod "nothing changed"
            return 0
        fi
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
            # TBD editor/subl.sh?  << subl --project "$sublime_project_file" -a
            subl --project "$sublime_project_file" -a
        else
            gmsg -c yellow "$sublime_project_file not found"
            return 132
        fi
}


project.open () {
    # open project, sublime + env variables+ tmux

    if ! [[ "$1" ]] ; then
        gmsg -c yellow "project name needed"
        return 1
    fi

    local project_name="$1"

    # check that prroject is in projects list
    if ! project.exist $project_name ; then
            gmsg -c yellow "$project_name does not exist"
            return 3
        fi

    # source project configuration file
    local project_base="$GURU_SYSTEM_MOUNT/project"
    # check that project folder exist

    # set active project
    echo $project_name > "$project_base/active"

    local project_folder="$project_base/$project_name"

    # inform user and message bus
    gmsg -v1 "working on $project_name" -m "$GURU_USER/status"
    mqtt.main pub "$GURU_USER/project" "$project_name"


    # open editor
    case $GURU_PREFERRED_EDITOR in

            sublime|subl|sub3|sub4)
                    project.sublime $project_name
                    ;;

            code|v-code|visual-code|vs)
                    code $project_name
                    ;;
        esac

    # open terminal
    case $GURU_PREFERRED_TERMINAL in
            tmux)   if module.installed tmux ; then
                            source tmux.sh
                            tmux.attach $project_name
                        else
                            tmux attach $project_name
                        fi
                    ;;

            nemo)   nemo "$project_folder"
                    ;;

            gnome-terminal)
                    gnome-terminal --working-directory="$project_folder"
                    ;;
            *)      gmsg "non supported terminal"
                    ;;
        esac


    # stays here till session deatteched
    gmsg -v2 "after deattach do here"
    return 0

}

project.exist () {

    local i=0
    local project_name="$1"
    local project_base="$GURU_SYSTEM_MOUNT/project"
    #local project_list=$(ls $project_base/project_list)

    local project_list=($(file "$project_base/"* \
        | grep directory \
        | cut -d ':' -f1 \
        | rev  \
        | cut -d "/" -f1 \
        | rev))

    while [[ "$i" -lt "${#project_list[@]}" ]] ; do
            if [[ "${project_list[$i]}" == "$project_name" ]] ; then return 0; fi
            ((i++))
        done
    return 100
}

project.change () {
    # just open sublime for now
    local project_name=$1
    local project_base="$GURU_SYSTEM_MOUNT/project"

    echo $project_name > "$project_base/active"
    gmsg -v2 "$project_name" -m "$GURU_USER/project"
}


project.poll () {
    # daemon required polling functions
    local _cmd="$1" ; shift
    local project_indicator_key="f$(daemon.poll_order project)"
    case $_cmd in
        start )
            gmsg -v1 -t -c black \
                -k $project_indicator_key \
                "${FUNCNAME[0]}: project status polling started"
            ;;
        end )
            gmsg -v1 -t -c reset \
                -k $project_indicator_key \
                "${FUNCNAME[0]}: project status polling ended"
            ;;
        status )
            project.status
            ;;
        *)  project.help
            ;;
        esac
}



if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
        source "$GURU_RC"
        project.main "$@"
    fi

