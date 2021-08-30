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
    gmsg -v1 "  add <name|id>           add new projects "
    gmsg -v1 "  open <name|id>          open project "
    gmsg -v1 "  close                   close project, keep data "
    gmsg -v1 "  change <name|id>        same as close and open  "
    #gmsg -v1 "  archive <name|id>       move to archive"
    #gmsg -v1 "  active <name|id>        return archived project "
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
    #gmsg -v2 " $GURU_CALL project archive        # list of archived projects "
    #gmsg -v1 " $GURU_CALL project archive demo   # archive demo "
    gmsg -v2 " $GURU_CALL project rm demo        # remove all demo project files "
    gmsg -v2
    return 0
}


project.main () {
    # main command parser
    local _cmd="$1" ; shift

    case "$_cmd" in
        check|exist|ls|info|add|status|open|change|close|toggle|rm|sublime|poll|help)
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
    gmsg -n -v1 -t "${FUNCNAME[0]}: "
    if [[ -d "$project_base" ]] ; then
            gmsg -v1 -n -c green "installed, " -k $project_indicator_key
        else
            gmsg -n -c red "$project_base not installed, " -k $project_indicator_key
            return 100
        fi

    # check are projects mounted
    if [[ -f "$project_mount/.online" ]] ; then
            gmsg -n -v1 -c green "mounted, "
        else
            gmsg -v1 -c yellow "not mounted" -k $project_indicator_key
            return 100
        fi

    if [[ -f $project_base/active ]]; then
            local active=$(cat $project_base/active)
            gmsg -n "active: "
            gmsg -v1 -c aqua "$active " -k $project_indicator_key
        else
            gmsg -v1 -c reset "no active projects "
        fi

    return 0
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
    gmsg -v2 -c aqua "active: $_active_project"

    # list of projects
    #gmsg -v1 "list of projects "
    for _project in ${_project_list[@]} ; do
        if [[ "$_project" == "$_active_project" ]] ; then
                gmsg -c aqua "$_project"
            else
                gmsg -c light_blue "$_project"
            fi
        done

    return 0
}


project.info () {
    # list of projects, active higlighted with lis of tmux sessions
    #source tmux.sh
    local project_base="$GURU_SYSTEM_MOUNT/project"
    local project_mount="$GURU_MOUNT_PROJECTS"

    # check system folder is mounted, almost futile
    gmsg -n -c white "system folder.. "
    if [[ -f $GURU_SYSTEM_MOUNT/.online ]] ; then
        gmsg -c green "mounted"
    else
        gmsg -c red "not mounted"
        gmsg "cannot continue, exiting"
        return 100
    fi
    # check is project file folder mounted
    gmsg -n -c white "project folder.. "
    if [[ -f $GURU_MOUNT_PROJECTS/.online ]] ; then
        gmsg -c green "mounted"
    else
        gmsg -c red "not mounted"
    fi

    # printout
    gmsg -n -c white "projects: "
    project.ls | tr '\n' ' ' ; echo

    if [[ -f $project_base/active ]] ; then
            local active=$(cat $project_base/active)
            gmsg -c white "active project '$active' "
        else
            gmsg -c reset "no active project "
            return 0
        fi

    gmsg -n -c white "$active data: "
    # active project information
    if [[ -f $project_base/$active/project.conf ]] ; then
            source $project_base/$active/project.conf
            gmsg -c grey " '$project_description' data location: '$project_data' mount point: '$project_folder'"
            #gmsg -c pink "$GURU_SYSTEM_MOUNT/project/$active/project.conf"
        else
            gmsg "no $active project data available"
        fi

    if module.installed tmux ; then
            source tmux.sh
            tmux.status
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
            gmsg -v2 "using $sublime_project_file"
            # TBD editor/subl.sh?  << subl --project "$sublime_project_file" -a
            subl --project "$sublime_project_file" -a
        else
            gmsg -c yellow "$sublime_project_file not found"
            return 132
        fi
}


project.open () {
    # open project, sublime + env variables+ tmux
    local project_indicator_key="f$(daemon.poll_order project)"

    # source project configuration file
    local project_base="$GURU_SYSTEM_MOUNT/project"

    # figure out project name
    local project_name=
    if [[ "$1" ]] ; then
            # is user has input project name to open
            project_name="$1"
        else
            # no user input, check last project
            if [[ -f $project_base/last ]] ; then
                    project_name="$(cat $project_base/last)"
                else
                    # not able to figure project name up
                    gmsg -c yellow "project name needed"
                    return 1
                fi
        fi

    # check that project is in projects list
    if ! project.exist $project_name ; then
            gmsg -c yellow "$project_name does not exist"
            return 3
        fi

    # check is given project alredy active
    if [[ "$project_name" == "$(cat $project_base/active)" ]] && ! [[ $GURU_FORCE ]]; then
            gmsg -c green "project $project_name is active"
            return 0
        fi

    # set active project
    echo $project_name > "$project_base/active"
    echo $project_name > "$project_base/last"
    local project_folder="$project_base/$project_name"

    # inform user and message bus
    gmsg -v1 -n "$GURU_USER working on "
    gmsg -v1 -c aqua "$project_name" -m "$GURU_USER/project" -k $project_indicator_key

    # open editor
    case $GURU_PREFERRED_EDITOR in

            sublime|subl|sub3|sub4)
                    project.sublime $project_name
                    ;;

            code|vcode|v-code|visual-code|vs)
                    gmsg "TBD add support for vcode project files" ;;
            vi|vim) gmsg "TBD add support for vim project files" ;;
            joe)    gmsg "TBD add support for joe project files" ;;
        esac

    # run project configs
    [[ -f $project_folder/config.sh ]] && source $project_folder/config.sh pre

    # open terminal
    case $GURU_PREFERRED_TERMINAL in
            tmux)   if module.installed tmux ; then
                            source tmux.sh
                            tmux.attach $project_name
                            return $?
                        else
                            /usr/bin/tmux attach -t $project_name
                            return $?
                        fi
                    ;;

            nemo)   if [[ $DISPLAY ]] ; then
                            nemo "$project_folder"
                        fi
                    ;;

            gnome-terminal)
                    if [[ $DISPLAY ]] ; then
                            if [[ $GURU_PROJECT_GIT ]] ; then
                                gnome-terminal --tab --title="project" --working-directory="$project_folder" \
                                               --tab --title="git"     --working-directory="$GURU_PROJECT_GIT"
                            else
                                gnome-terminal --working-directory="$project_folder"
                            fi
                        fi
                    ;;
            *)      gmsg "non supported terminal"
                    ;;
        esac

    return $?
}


project.close () {

    local project_name="$1" ; shift
    local project_base="$GURU_SYSTEM_MOUNT/project"

    # check is there active projects, exit if not
    [[ -f $project_base/active ]] || return 0

    local active_project=$(cat $project_base/active)
    [[ $project_name ]] || project_name=$active_project
    local project_indicator_key="f$(daemon.poll_order project)"

    # check that project is in projects list
    if ! project.exist $project_name ; then
            gmsg -c yellow "$project_name does not exist"
            return 3
        fi

    if [[ $GURU_TMUX_ENABLED ]] && module.installed tmux ; then
            tmux detach -s $project_name
        fi

    [[ -f $project_base/$project_name/config.sh ]] && source $project_base/$project_name/config.sh post $@

    # check active project
    if [[ -f $project_base/active ]] ; then
            mv -f $project_base/active $project_base/last
            gmsg -v1 -c reset "$active_project closed" -k $project_indicator_key
        fi
    GURU_VERBOSE=0
    project.status
}


project.toggle () {
    local project_base="$GURU_SYSTEM_MOUNT/project"
    [[ -f $project_base/active ]] && project.close || project.open $@
    sleep 2
    return 0
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
            if [[ "${project_list[$i]}" == "$project_name" ]] ; then
                    gmsg -v2 -c green "project $project_name exist"
                    return 0; fi
            ((i++))
        done
    gmsg -v1 -c yellow "project $project_name does not exist"
    return 100
}


project.change () {
    # just open sublime for now
    local project_name=$1
    local project_base="$GURU_SYSTEM_MOUNT/project"

    echo $project_name > "$project_base/active"
    echo $project_name > "$project_base/last"
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

