#!/bin/bash
# guru-client project tools
# casa@ujo.guru 2020

source $GURU_BIN/common.sh
source $GURU_BIN/mount.sh
source $GURU_BIN/timer.sh

project.main () {
    # main command parser

    local _cmd="$1" ; shift

    case "$_cmd" in
            # list of commands
            check|exist|ls|info|\
            add|status|open|change|\
            close|toggle|rm|sublime|archive|\
            subl|poll|help|terminal|term)

            project.$_cmd "$@"
            return $?
            ;;

        *)  project.open "$_cmd" "$@"
            return $?
            ;;
        esac
}


project.help () {
    # help
    gmsg -v1 -c white "guru-cli project module help "
    gmsg -v2
    gmsg -v1 "tools for project control"
    gmsg -v2
    gmsg -V2 -v0 "usage:    $GURU_CALL project ls|info|add|rm|open|close "
    gmsg -v2 "usage:    $GURU_CALL project ls|new|open|status|close|rm|sublime|help  name/id"
    gmsg -v2
    gmsg -v1 -c white "commands:"
    gmsg -v1 "  ls                      list of projects "
    gmsg -v2 "  info                    more detailed information of projects "
    gmsg -v1 "  add <name|id>           add new projects "
    gmsg -v1 "  open <name|id>          open project "
    gmsg -v2 "  edit <name>             edit project script and configuration TBD" -c todo
    gmsg -v1 "  change <name>           change project"
    gmsg -v1 "  close                   close project, keep data "
    gmsg -v2 "  archive <name>          move to archive TBD"
    gmsg -v2 "  active <name|id>        return archived project TBD" -c todo
    gmsg -v3 "  rm <name|id>            remove project and files for good "
    gmsg -v1 "  install                 install requirements "
    gmsg -v3 "  remove                  remove requirements "
    gmsg -v3 "  terminal <name>         open termional tools TBD" -c todo
    gmsg -v3 "  sublime <name>          open sublime project "
    gmsg -v1 "  status                  status of project module"
    gmsg -v3 "  poll start|stop         daemon poll function"
    gmsg -v1 "  help                    this help "
    gmsg -v1
    gmsg -v1 -c white "example:"
    gmsg -v1 "  $GURU_CALL project ls             # list of projects "
    gmsg -v1 "  $GURU_CALL project add demo       # initialize new project called 'demo'"
    gmsg -v2 "  $GURU_CALL project archive        # list of archived projects "
    gmsg -v2 "  $GURU_CALL project edit demo      # edit 'demo' config and launcher script "
    gmsg -v2 "  $GURU_CALL project archive demo   # archive 'demo', needs to be done before rm "
    gmsg -v3 "  $GURU_CALL project rm demo        # remove all 'demo' project files "
    gmsg -v2
    return 0
}


project.configure () {
    # set global project variables

    declare -g project_base="$GURU_SYSTEM_MOUNT/project"
    declare -g project_arhive="$GURU_SYSTEM_MOUNT/project/arhive"
    declare -g project_indicator_key="f$(daemon.poll_order project)"
    declare -g project_mount="$GURU_MOUNT_PROJECTS"

    if [[ $1 ]] ; then
        project_name=$1

    elif [[ -f $project_base/active ]] ; then
        project_name=$(cat $project_base/active)

    elif [[ -f $project_base/last ]] ; then
        project_name=$(cat $project_base/last)

    else
        gmsg -c yellow "project name '$project_name' does not exist"
        return 100
    fi

    gmsg -v3 "$GURU_USER working on $project_name"

    declare -g project_folder="$project_base/projects/$project_name"
    declare -g project_cfg="$project_folder/config.sh"
    declare -g sublime_project_file="$project_folder/$GURU_USER-$project_name.sublime-project"

    # check that project is in projects list
    if ! project.exist $project_name ; then
            gmsg -c yellow "$project_name does not exist"
            return 3
        fi

    [[ -f $project_folder/config.sh ]] && source $project_folder/config.sh source $@

    [[ $GURU_PROJECT_COLOR ]] && declare -g project_key_color=$GURU_PROJECT_COLOR || declare -g project_key_color="aqua"

    # gmsg -c deep_pink "$GURU_PROJECT_GIT:$GURU_PREFERRED_TERMINAL:$project_folder/config.sh"

}


project.info () {
    # list of projects, active higlighted with lis of tmux sessions

    project.configure $1

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
            gmsg -c white "active project: '$active' "
        else
            gmsg -c reset "no active projects "
            return 0
        fi

    gmsg -c white "project $active data "
    # active project information
    if [[ -f $project_cfg ]] ; then
            gmsg -c light_blue -w17 -n "name: " ; gmsg -c light_blue "$GURU_PROJECT_NAME"
            gmsg -c light_blue -w17 -n "desription:" ; gmsg -c light_blue "$GURU_PROJECT_DESCRIPTION"
            gmsg -c light_blue -w17 -n "folder:" ; gmsg -c light_blue "$GURU_PROJECT_FOLDER"
            gmsg -c light_blue -w17 -n "git folder:" ; gmsg -c light_blue "$GURU_PROJECT_GIT"
            gmsg -c light_blue -w17 -n "project color:" ; gmsg -c light_blue "$GURU_PROJECT_COLOR"
            gmsg -c light_blue -w17 -n "indicator key:" ; gmsg -c light_blue "$project_indicator_key"
            gmsg -c light_blue -w17 -n "base folder:" ; gmsg -c light_blue "$project_base"
            gmsg -c light_blue -w17 -n "mount point:" ; gmsg -c light_blue "$project_mount"
            gmsg -c light_blue -w17 -n "project folder:" ; gmsg -c light_blue "$project_folder"
            gmsg -c light_blue -w17 -n "cfg location:" ; gmsg -c light_blue "$project_cfg"
            gmsg -c light_blue -w17 -n "sublime project:" ; gmsg -c light_blue "$sublime_project_file"
        else
            gmsg "no $active project data available"
        fi

    if module.installed tmux ; then
            source tmux.sh
            tmux.status
        fi
}


###################### opening and closing ###########################


project.sublime () {
    # open sublime with project file

    project.configure $1

    if ! [[ -d $project_folder ]] ; then
            gmsg -c yellow "project not exist"
            return 131
        fi

    if [[ -f "$sublime_project_file" ]] ; then
            gmsg -v2 "using $sublime_project_file"
            # TBD edit/subl.sh?  << subl --project "$sublime_project_file" -a
            subl --project "$sublime_project_file" -a
        else
            gmsg -c yellow "$sublime_project_file not found"
            return 132
        fi
}


project.subl () {
    # alias for above

    project.sublime $@
    return $?
}


project.open () {
    # open project, sublime + env variables+ tmux

    if ! project.configure $1 ; then return 0 ; fi
    shift

    # check is given project alredy active
    if [[ -f $project_base/active ]] \
            && [[ "$project_name" == "$(cat $project_base/active)" ]] \
            && ! [[ $GURU_FORCE ]]
        then
            gmsg -c green "project $project_name is active"
            return 0
        fi

    # set active project
    echo $project_name > "$project_base/active"
    echo $project_name > "$project_base/last"
    # local project_folder="$project_base/projects/$project_name"

    # run project configs. Make sure that config.sh is pass trough.
    [[ -f $project_folder/config.sh ]] && source $project_folder/config.sh pre $@

    # set keyboard key to project color
    declare -l key_color="aqua"
    [[ $GURU_PROJECT_COLOR ]] && key_color=$GURU_PROJECT_COLOR

    gmsg -v1 -c $key_color "$project_name" -m "$GURU_USER/project" -k $project_indicator_key

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

    project.terminal $project_name

    return $?
}


project.terminal () {
    # open preferred terminal with configuration or command line setup

    project.configure $1

    # gmsg -c pink "$GURU_PROJECT_GIT:$GURU_PREFERRED_TERMINAL:$project_folder/config.sh"

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
                                gnome-terminal --tab --title="project" \
                                               --working-directory="$project_folder" \
                                               --tab --title="git" \
                                               --working-directory="$GURU_PROJECT_GIT"
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


project.term () {
    # alias for above

    project.terminal $@
    return $?

}


project.close () {
    # close project, config.sh will be called if exisats

    # get config
    project.configure $1
    shift

    # check is there active projects, exit if not
    [[ -f $project_base/active ]] || return 0

    local active_project=$(cat $project_base/active)
    [[ $project_name ]] || project_name=$active_project

    # check that project is in projects list
    if ! project.exist $project_name ; then
            gmsg -c yellow "$project_name does not exist ${FUNCNAME[0]}"
            return 3
        fi

    [[ -f "$project_base/projects/$project_name/config.sh" ]] && source "$project_base/projects/$project_name/config.sh" post $@

    # check active project
    if [[ -f $project_base/active ]] ; then
            mv -f $project_base/active $project_base/last
            gmsg -v1 -c reset "$active_project closed" -k $project_indicator_key
        fi
    GURU_VERBOSE=0
    project.status
}


project.toggle () {
    # open last project if not open already and close if its open

    local project_base="$GURU_SYSTEM_MOUNT/project"
    [[ -f $project_base/active ]] && project.close || project.open $@
    sleep 2
    return 0
}


############# Project list, add rm, exist check and chage functions ###################

project.ls () {
    # list of projects

    #project.configure $1   # no point, only one variable needed
    local project_base="$GURU_SYSTEM_MOUNT/project"
    local project_folder="$project_base/projects/$project_name"

    local _project_list=($(file "$project_base/projects/"* \
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
    for _project in ${_project_list[@]} ; do
        if [[ "$_project" == "$_active_project" ]] ; then
                gmsg -n -c aqua "$_project "
            else
                gmsg -n -c light_blue "$_project "
            fi
        done

#echo "$project_base/archived/:${archived_project_list[@]}"
    # list arvhived projects
    local archived_project_list=($(ls "$project_base/archived/"))
    # local archived_project_list=($(file "$project_base/archived/"* \
    #     | grep directory \
    #     | cut -d ':' -f1 \
    #     | rev  \
    #     | cut -d "/" -f1 \
    #     | rev))

     for _project in ${archived_project_list[@]} ; do
             gmsg -n -c dark_grey "$_project "
         done

    echo


    return 0
}


project.add () {
    # add project to projects

    if [[ "$1" ]] ; then
            local project_name="$1"
        else
            read -p "project name needed: " project_name
        fi

    # set manually cause it is a new project
    local project_base="$GURU_SYSTEM_MOUNT/project"
    local project_folder="$project_base/projects/$project_name"
    local archive_folder="$project_base/archived"
    local sublime_project_file="$project_folder/$GURU_USER-$project_name.sublime-project"

    if [[ -d "$archive_folder/$project_name" ]] ; then
            gmsg -c yellow "project named $project_name exist in archive"
            return 1
        fi

    if [[ -d $project_folder ]] ; then
            gmsg -c yellow "project $project_name exist"
            return 1
        fi

    mkdir -p "$project_folder"

    if [[ -f $sublime_project_file ]] ; then
            touch "$sublime_project_file"
        fi

    gmsg -v3 -c dark_grey "${FUNCNAME[0]} TBD: add project details and copy default config.sh"
    cp $GURU_CFG/project-default.cfg $project_folder/config.sh
    gmsg -c white "project added, config project $project_folder/config.sh "


}


project.archive () {
    # move project archive

    local project_list=($@)

    for _proj in ${project_list[@]} ; do

            if ! project.configure $_proj ; then continue ; fi

            # make archive foilder if not exist
            [[ -d $project_base/archived ]] || mkdir -p "$project_base/archived"

            # check that project to remove is not active, is so close it
            if [[ -f $project_base/active ]] ; then
                    # gmsg -v0 -n "active project: "
                    if cat $project_base/active | grep $project_name ; then
                        gmsg -v0 "closing project $project_name"
                        project.close $project_name
                    fi
                fi

            # move
            if [[ -d $project_base/projects/$project_name ]] ; then
                    gmsg "project $project_name moved to $project_base/archived/$project_name"

                    mv -b "$project_base/projects/$project_name" "$project_base/archived" && continue
                    gmsg -c yellow "error while movin project files $project_name"

                else
                    gmsg -c yellow "no project files found from $project_base/projects/$project_name"
                    continue
            fi
        done

}


project.rm () {
    # remove project

    if [[ $1 ]] ; then
            local project_list=($@)
        else
            read -p "project name to remove: " project_list
        fi

    for project_name in ${project_list[@]} ; do

            # set manually cause project.configure tries to gues the project name
            local project_base="$GURU_SYSTEM_MOUNT/project"
            local project_folder="$project_base/projects/$project_name"
            local archive_folder="$project_base/archived/$project_name"

            # check project forlder and arhive
            if [[ -d $project_folder ]] ; then
                    gmsg -v0 -c white "project needs to be archived before removeing"
                    gmsg -v0 "to arvhive type: '$GURU_CALL project archive $project_name'"
                    continue

            elif [[ -d $archive_folder ]] ; then
                    gmsg -v2 "project found in archive"
                else
                    gmsg -c yellow "no project '$project_name' found in archive"
                    continue
                fi

            # ask final approve from customer
            if ! gask "sure to remove project $project_name?" ; then
                    gmsg -v1 -c dark_grey "nothing changed"
                    continue
                fi

            # remove project database
            if rm -fr $archive_folder ; then
                gmsg -v1 -c dark_grey "$archive_folder removed"
                continue
            else
                gmsg -v0 -c yellow "error while deleting $project_name "
                continue
            fi

        done
}


project.exist () {
    # check that project exist

    local i=0
    project_name="$1"
    project_base="$GURU_SYSTEM_MOUNT/project"

    if [[ -d $project_base/projects/$project_name ]] ; then
            gmsg -v3 -c green "project $project_name exist"
              return 0
        else
            gmsg -v2 -c yellow "project $project_name does not exist"
            return 100
        fi
}


project.change () {
    # just open sublime for now

    local project_name=$1
    local project_base="$GURU_SYSTEM_MOUNT/project"

    echo $project_name > "$project_base/active"
    echo $project_name > "$project_base/last"
    gmsg -v2 "$project_name" -m "$GURU_USER/project"
}


########################### daemon functions ##########################3

project.status () {
    # check that project module is working correctly

    project.configure $1

    # check project file locaton is accessavle
    gmsg -v1 -n -t "${FUNCNAME[0]}: "
    if [[ -d "$project_base" ]] ; then
            gmsg -v1 -n -c green "installed, "
        else
            gmsg -v1 -n -c red "$project_base not installed, " -k $project_indicator_key
            return 100
        fi

    # check are projects mounted
    if [[ -f "$project_mount/.online" ]] ; then
            gmsg -v1 -n -c green "mounted "
        else
            gmsg -v1 -c yellow "not mounted" -k $project_indicator_key
            return 100
        fi

    # print
    [[ $GURU_VERBOSE -gt 0 ]] && project.ls

    if [[ -f $project_base/active ]]; then
            local active=$(cat $project_base/active)
            #gmsg -v2 -n "active: "
            gmsg -v4 -n -c $project_key_color -k $project_indicator_key
        else
            gmsg -v3 -c reset "no active projects "  -k $project_indicator_key
        fi

    return 0
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


project.install () {

gmsg -v0 -n -c dark_cyan "${FUNCNAME[0]}:"; gmsg -n -c deep_pink "$@" ; gmsg -n -c white ">"
    gmsg "no special software needed"
}


project.rewmove () {

gmsg -v0 -n -c dark_cyan "${FUNCNAME[0]}:"; gmsg -n -c deep_pink "$@" ; gmsg -n -c white ">"
    gmsg "no special software installed"
}



if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
        source "$GURU_RC"
        project.main "$@"
    fi

