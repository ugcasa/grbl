#!/bin/bash
# guru-cli project tools 2023 casa@ujo.guru

declare -g project_rc="/tmp/guru-cli_project.rc"

project.main () {
# main command parser

    local _cmd="$1" ; shift

    case "$_cmd" in

        # list of commands
        exist|ls|info|\
        add|status|open|change|\
        close|toggle|rm|archive|\
        subl|poll|help|terminal|term|active|last)

            project.$_cmd "$@"
            return $?
        ;;

        "")
            project.open $(project.last)
            return $?
        ;;

        *)
            project.open "$_cmd" "$@"
            return $?
        ;;
    esac
}


project.help () {
# module help
    gr.msg -v1 -c white "guru-cli project module help "
    gr.msg -v2
    gr.msg -v1 "tools for project control"
    gr.msg -v2
    gr.msg -V2 -v0 "usage:    $GURU_CALL project ls|info|add|rm|open|close "
    gr.msg -v2 "usage:    $GURU_CALL project ls|new|open|status|close|rm|sublime|help  name/id"
    gr.msg -v2
    gr.msg -v1 -c white "commands:"
    gr.msg -v1 "  ls                      list of projects "
    gr.msg -v2 "  info                    more detailed information of projects "
    gr.msg -v1 "  add <name|id>           add new projects "
    gr.msg -v1 "  open <name|id>          open project "
    gr.msg -v2 "  edit <name>             edit project script and configuration TBD" -c todo
    gr.msg -v1 "  change <name>           change project"
    gr.msg -v1 "  close                   close project, keep data "
    gr.msg -v2 "  archive <name>          move to archive TBD"
    gr.msg -v2 "  active <name|id>        return archived project TBD" -c todo
    gr.msg -v3 "  rm <name|id>            remove project and files for good "
    gr.msg -v1 "  install                 install requirements "
    gr.msg -v3 "  remove                  remove requirements "
    gr.msg -v3 "  terminal <name>         open termional tools TBD" -c todo
    gr.msg -v3 "  sublime <name>          open sublime parts of project "
    gr.msg -v1 "  status                  status of project module"
    gr.msg -v3 "  poll start|stop         daemon poll function"
    gr.msg -v1 "  help                    this help "
    gr.msg -v1
    gr.msg -v1 -c white "example:"
    gr.msg -v1 "  $GURU_CALL project ls             # list of projects "
    gr.msg -v1 "  $GURU_CALL project add demo       # initialize new project called 'demo'"
    gr.msg -v2 "  $GURU_CALL project archive        # list of archived projects "
    gr.msg -v2 "  $GURU_CALL project edit demo      # edit 'demo' config and launcher script "
    gr.msg -v2 "  $GURU_CALL project archive demo   # archive 'demo', needs to be done before rm "
    gr.msg -v3 "  $GURU_CALL project rm demo        # remove all 'demo' project files "
    gr.msg -v2
    return 0
}


project.active () {
# printout active opened project and return 0 if exist
    if [[ -f "$module_data_folder/active" ]] ; then
        head -n1  "$module_data_folder/active"
        return 0
    else
        return 1
    fi
}


project.last () {
# printout last opened project and return 0 if exist
    if [[ -f "$module_data_folder/last" ]] ; then
        head -n1  "$module_data_folder/last"
        return 0
    else
        return 1
    fi
}


project.configure () {
# set global project variables

    if [[ $1 ]] ; then
        # configure project given by user
        local project_name=$1

    elif [[ -f "$module_data_folder/active" ]] ; then
        # configure current project
        local project_name=$(head -n1 "$module_data_folder/active")

    elif [[ -f "$module_data_folder/last" ]] ; then
        # configure project that was open last time
        local project_name=$(head -n1 "$module_data_folder/last")

    else
        # no project found
        gr.msg -c yellow "project name '$project_name' does not exist"
        return 2
    fi

    # fulfill pre
    declare -g project_folder="$module_data_folder/projects/$project_name"
    declare -g project_script="$project_folder/config.sh"
    declare -g project_git="$GURU_GIT_HOME/$project_name"
    # project_home="$GURU_MOUNT/projects/$project_name"

    gr.msg -v3 "$GURU_USER working on $project_name home folder:$project_git"
    declare -g sublime_project_file="$project_folder/$GURU_USER-$project_name.sublime-project"

    # check that project is in projects list
    if ! project.exist $project_name ; then
        gr.msg -c yellow "$project_name does not exist"
        return 3
    fi

    # run project user script
    [[ -f "$project_cfg" ]] && source "$project_cfg" #source $@

    # # export configs for other modules
    export GURU_PROJECT_NAME=$project_name
    export GURU_PROJECT_DESCRIPTION=$project_description
    export GURU_PROJECT_FOLDER=$project_folder
    export GURU_PROJECT_SCRIPT=$project_script
    export GURU_PROJECT_CFG=$project_cfg
    export GURU_PROJECT_GIT=$project_git
    [[ $project_color ]] && export GURU_PROJECT_COLOR=$project_color

    [[ -f $project_script ]] && source $project_script
}


project.info () {
# list of projects, active highlighted

    local project_name=$1
    project.configure $project_name

    gr.msg -n -h "system folder.. "
    if [[ -f $GURU_SYSTEM_MOUNT/.online ]] ; then
        gr.msg -c green "mounted"
    else
        gr.msg -c red "not mounted"
        gr.msg "cannot continue, exiting"
        return 100
    fi
    # check is project file folder mounted
    gr.msg -n -h "project folder.. "
    if [[ -f "$GURU_MOUNT_PROJECTS/.online" ]] ; then
        gr.msg -c green "mounted"
    else
        gr.msg -c red "not mounted"
    fi

    # printout
    gr.msg -n -h "projects: "
    project.ls | tr '\n' ' ' ; echo

    if [[ -f "$module_data_folder/active" ]] ; then
        local active=$(cat "$module_data_folder/active")
    else
        gr.msg -c reset "no active projects "
        return 0
    fi

    gr.msg -N -h "module variables"
    gr.msg -c light_blue -w19 -n "module enabled "; gr.msg -c aqua_marine "$GURU_PROJECT_ENABLED"
    gr.msg -c light_blue -w19 -n "module config:" ; gr.msg -c aqua_marine "$project_cfg"
    gr.msg -c light_blue -w19 -n "module data:" ; gr.msg -c aqua_marine "$module_data_folder"
    gr.msg -c light_blue -w19 -n "module git base "; gr.msg -c aqua_marine "$GURU_PROJECT_GIT_BASE"
    gr.msg -c light_blue -w19 -n "mount base folder: " ; gr.msg -c aqua_marine "$GURU_MOUNT_PROJECTS"
    gr.msg -c light_blue -w19 -n "project archive:" ; gr.msg -c aqua_marine "$project_archive"
    gr.msg -c light_blue -w19 -n "indicator key:" ; gr.msg -c aqua_marine "$GURU_PROJECT_INDICATOR"

    # active project information
    if [[ -f $GURU_PROJECT_CFG ]] ; then
        gr.msg -N -h "project '$active' variables"
        gr.msg -c light_blue -w19 -n "name:" ; gr.msg -c aqua_marine "$GURU_PROJECT_NAME"
        gr.msg -c light_blue -w19 -n "desription:" ; gr.msg -c aqua_marine "$GURU_PROJECT_DESCRIPTION"
        gr.msg -c light_blue -w19 -n "project data:" ; gr.msg -c aqua_marine "$project_folder"
        gr.msg -c light_blue -w19 -n "config script:" ; gr.msg -c aqua_marine "$GURU_PROJECT_SCRIPT"
        gr.msg -c light_blue -w19 -n "project files:" ; gr.msg -c aqua_marine "$GURU_PROJECT_FOLDER"
        gr.msg -c light_blue -w19 -n "git folder:" ; gr.msg -c aqua_marine "$GURU_PROJECT_GIT"
        gr.msg -c light_blue -w19 -n "sublime project:" ; gr.msg -c aqua_marine "$sublime_project_file"
        gr.msg -c light_blue -w19 -n "project color:" ; gr.msg -c $GURU_PROJECT_COLOR "$GURU_PROJECT_COLOR"
        gr.msg -c light_blue -w19 -n "environment: " ; gr.msg -c aqua_marine "$GURU_PROJECT_ENV"
        gr.msg -c light_blue -w19 -n "issues: " ; gr.msg -c aqua_marine "$GURU_PROJECT_ISSUES"
        gr.msg -c light_blue -w19 -n "project manager " ; gr.msg -c aqua_marine "$GURU_PROJECT_TICKET"
        gr.msg -c light_blue -w19 -n "documentation: " ; gr.msg -c aqua_marine "$GURU_PROJECT_WIKI"

    else
        gr.msg "no $active project data available"
    fi
}


project.sublime () {
# open sublime with project file

    project.configure $1

    if ! [[ -d $project_folder ]] ; then
            gr.msg -c yellow "project not exist"
            return 131
        fi

    if [[ -f "$sublime_project_file" ]] ; then
            gr.msg -v2 "using $sublime_project_file"
            # TBD edit/subl.sh?  << subl --project "$sublime_project_file" -a
            subl --project "$sublime_project_file" -a
        else
            gr.msg -c yellow "$sublime_project_file not found"
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

    local project_name=$1

    if ! project.configure $project_name ; then return 0 ; fi

    shift

    # if [[ -f $]]

    # check is given project already active
    if [[ -f "$module_data_folder/active" ]] \
            && [[ "$project_name" == "$(cat $module_data_folder/active)" ]] \
            && ! [[ $GURU_FORCE ]]
        then
            gr.msg -c green "project $project_name is active"
            return 0
        fi

    # set active project
    echo $project_name > "$module_data_folder/active"
    echo $project_name > "$module_data_folder/last"
    local project_folder="$module_data_folder/projects/$project_name"

    # run project configs. Make sure that config.sh is pass trough.
    if [[ -f "$project_folder/config.sh" ]] ; then
            #source "$project_folder/config.sh"
            $project_folder/config.sh pre $@
        fi

    # set keyboard key to project color, what?! five different "color" variables, clean!
    declare key_color="${project[color]}"
    [[ $GURU_PROJECT_COLOR ]] && key_color=$GURU_PROJECT_COLOR

    gr.msg -v1 -c $key_color "$project_name" -m "$GURU_USER/project" -k $GURU_PROJECT_INDICATOR

    # open editor
    [[ $GURU_PROJECT_EDITOR ]] && GURU_PREFERRED_EDITOR=$GURU_PROJECT_EDITOR
    gr.debug "editor: $GURU_PREFERRED_EDITOR"

    case $GURU_PREFERRED_EDITOR in

        sublime|subl|sub3|sub4)
            project.sublime $project_name
        ;;

        code|vcode|v-code|visual-code|vs)
            gr.msg "project '$project_name' mount point '$project_git' "
            [[ $GURU_FORCE ]] \
                && code $project_git \
                || gr.msg -v2 "let user launch editor $project_git"

            code $GURU_PROJECT_GIT
        ;;

        vi|vim)
            gr.msg "no support for vim project files"  # TBD
        ;;

        joe)
            gr.msg "no support for joe project files" # TBD
        ;;
        *)
            gr.msg -c red "unknown editor '$GURU_PREFERRED_EDITOR' project files"

    esac

    # continue to open terminal shit # TBD why here?
    project.terminal $project_name

    return $?
}


project.terminal () {
# open preferred terminal with configuration or command line setup

    local project_name=$1
    project.configure $project_name

    # gr.msg -c pink "$GURU_PROJECT_GIT:$GURU_PREFERRED_TERMINAL:$project_folder/config.sh"

    case $GURU_PREFERRED_TERMINAL in

            tmux)
                if gr.installed tmux ; then
                    source tmux.sh
                    tmux.attach $project_name
                    return $?
                else
                    /usr/bin/tmux attach -t $project_name
                    return $?
                fi
            ;;

            nemo)
                if [[ $DISPLAY ]] ; then
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

            *)
                gr.msg "non supported terminal"
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
# close project, config.sh will be called if exist

    # get config
    local project_name=$1
    project.configure $project_name

    # check is there active projects, exit if not
    [[ -f $module_data_folder/active ]] || return 0

    local active_project=$(cat $module_data_folder/active)
    [[ $project_name ]] || project_name=$active_project

    # check that project is in projects list
    if ! project.exist $project_name ; then
        gr.msg -c yellow "$project_name does not exist ${FUNCNAME[0]}"
        return 3
    fi

    # check active project
    if [[ -f $module_data_folder/active ]] ; then
        mv -f $module_data_folder/active $module_data_folder/last
        gr.msg -v1 -c reset "$active_project closed" -k $GURU_PROJECT_INDICATOR
    fi

    user_config="$module_data_folder/projects/$project_name/config.sh post"
    [[ -f $user_config ]] && .$user_config post

    project.status
}


project.toggle () {
# open last project if not open already and close if its open

    #local module_data_folder="$GURU_SYSTEM_MOUNT/project"
    [[ -f $module_data_folder/active ]] && project.close || project.open $@
    sleep 2
    return 0
}


project.ls () {
# list of projects

    #project.configure $1   # no point, only one variable needed
    # local module_data_folder="$GURU_SYSTEM_MOUNT/project"
    local project_folder="$module_data_folder/projects/$project_name"

    local _project_list=($(file "$module_data_folder/projects/"* \
        | grep directory \
        | cut -d ':' -f1 \
        | rev  \
        | cut -d "/" -f1 \
        | rev))


    # exit if there is no projects
    if (( ${#_project_list[$@]} < 1 )) ; then
        gr.msg -c dark_grey "no projects"
        return 1
    fi

    gr.msg -v2 -c white "project count: ${#_project_list[@]}"

    # check active project
    [[ -f "$module_data_folder/active" ]] && local _active_project=$(cat "$module_data_folder/active")
    # gr.msg -v2 -c aqua "active: $_active_project"

    # list of projects
    for _project in ${_project_list[@]} ; do
        if [[ "$_project" == "$_active_project" ]] ; then
            gr.msg -n -c aqua "$_project "
        else
            gr.msg -n -c dark_cyan "$_project "
        fi
    done

   #echo "$module_data_folder/archived/:${archived_project_list[@]}"

    # list archived projects
    local archived_project_list=($(ls "$module_data_folder/archived"))
    # local archived_project_list=($(file "$module_data_folder/archived/"* \
    #     | grep directory \
    #     | cut -d ':' -f1 \
    #     | rev  \
    #     | cut -d "/" -f1 \
    #     | rev))

    for _project in ${archived_project_list[@]} ; do
         gr.msg -n -c dark_grey "$_project "
    done

    echo


    return 0
}


project.list () {
# print out raw project list

    local _project_list=($(file "$module_data_folder/projects/"* \
        | grep directory \
        | cut -d ':' -f1 \
        | rev  \
        | cut -d "/" -f1 \
        | rev))


    # list of projects
    for _project in ${_project_list[@]} ; do
        printf "$_project "
    done

     # for _project in ${archived_project_list[@]} ; do
     #         gr.msg -n -c dark_grey "$_project "
     #     done

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

    local project_folder="$module_data_folder/projects/$project_name"
    local archive_folder="$module_data_folder/archived"
    local sublime_project_file="$project_folder/$GURU_USER-$project_name.sublime-project"

    if [[ -d "$archive_folder/$project_name" ]] ; then
        gr.msg -c yellow "project named $project_name exist in archive"
        return 1
    fi

    if [[ -d $project_folder ]] ; then
        gr.msg -c yellow "project $project_name exist"
        return 1
    fi

    mkdir -p "$project_folder"

    if [[ -f $sublime_project_file ]] ; then
        touch "$sublime_project_file"
    fi

    gr.msg -v3 -c dark_grey "${FUNCNAME[0]} TBD: add project details and copy default config.sh"
    cp $GURU_CFG/project-default.cfg $project_folder/config.sh
    gr.msg -c white "project added, config project $project_folder/config.sh "


}


project.archive () {
# move project archive

    local project_list=($@)

    for _proj in ${project_list[@]} ; do

        if ! project.configure $_proj ; then continue ; fi

        # make archive folder if not exist
        [[ -d $module_data_folder/archived ]] || mkdir -p "$module_data_folder/archived"

        # check that project to remove is not active, is so close it
        if [[ -f $module_data_folder/active ]] ; then
            # gr.msg -v0 -n "active project: "
            if cat $module_data_folder/active | grep $project_name ; then
                gr.msg -v0 "closing project $project_name"
                project.close $project_name
            fi
        fi

        # move
        if [[ -d $module_data_folder/projects/$project_name ]] ; then
            gr.msg "project $project_name moved to $module_data_folder/archived/$project_name"

            mv -b "$module_data_folder/projects/$project_name" "$module_data_folder/archived" && continue
            gr.msg -c yellow "error while movin project files $project_name"

        else
            gr.msg -c yellow "no project files found from $module_data_folder/projects/$project_name"
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
        #local module_data_folder="$GURU_SYSTEM_MOUNT/project"
        local project_folder="$module_data_folder/projects/$project_name"
        local archive_folder="$module_data_folder/archived/$project_name"

        # check project folder and archive
        if [[ -d $project_folder ]] ; then
            gr.msg -v0 -c white "project needs to be archived before removeing"
            gr.msg -v0 "to arvhive type: '$GURU_CALL project archive $project_name'"
            continue

        elif [[ -d $archive_folder ]] ; then
            gr.msg -v2 "project found in archive"
        else
            gr.msg -c yellow "no project '$project_name' found in archive"
            continue
        fi

        # ask final approve from customer
        if ! gr.ask "sure to remove project $project_name?" ; then
            gr.msg -v1 -c dark_grey "nothing changed"
            continue
        fi

        # remove project database
        if rm -fr $archive_folder ; then
            gr.msg -v1 -c dark_grey "$archive_folder removed"
            continue
        else
            gr.msg -v0 -c yellow "error while deleting $project_name "
            continue
        fi

    done
}


project.exist () {
# check that project exist

    local i=0
    local project_name=$1

    #module_data_folder="$GURU_SYSTEM_MOUNT/project"

    if [[ -d $module_data_folder/projects/$project_name ]] ; then
        gr.msg -v3 -c green "project $project_name exist"
          return 0
    else
        gr.msg -v2 -c yellow "project $project_name does not exist"
        return 100
    fi
}


project.change () {
# just open sublime for now

    local project_name=$1
    #local module_data_folder="$GURU_SYSTEM_MOUNT/project"

    echo $project_name > "$module_data_folder/active"
    echo $project_name > "$module_data_folder/last"
    gr.msg -v2 "$project_name" -m "$GURU_USER/project"
}


########################### daemon functions ##########################3

project.status () {
# indicate that project module is working correctly

    local project_name=$1
    [[ project_name ]] || project_name=$(project.last)
    project.configure $project_name

    gr.msg -v1 -n -t "${FUNCNAME[0]}: "

    if [[ $GURU_PROJECT_ENABLED ]] ; then
        gr.msg -v1 -n -c green "enabled, "  -k $GURU_PROJECT_INDICATOR
    else
        gr.msg -v1 -c black "disabled " -k $GURU_PROJECT_INDICATOR
        return 1
    fi

    if [[ -d "$module_data_folder" ]] ; then
        gr.msg -v1 -n -c green "installed, "  -k $GURU_PROJECT_INDICATOR
    else
        gr.msg -v1 -n -c red "$module_data_folder not installed, " -k $GURU_PROJECT_INDICATOR
        return 2
    fi

    # check are projects mounted
    if [[ -f "$project_folder/.online" ]] ; then
        gr.msg -v1 -n -c green "mounted "  -k $GURU_PROJECT_INDICATOR
    else
        gr.msg -v1 -c yellow "not mounted" -k $GURU_PROJECT_INDICATOR
        return 3
    fi

    # print
    [[ $GURU_VERBOSE -gt 0 ]] && project.ls

    if [[ -f $module_data_folder/active ]]; then
        local active=$(cat $module_data_folder/active)
        gr.msg -v4 -n -c ${project[color]} -k $GURU_PROJECT_INDICATOR
    else
        gr.msg -v3 -c reset "no active projects " -k $GURU_PROJECT_INDICATOR
    fi

    return 0
}


project.poll () {
# daemon required polling functions

    local _cmd="$1" ; shift

    case $_cmd in
        start)  gr.msg -v1 -t -c black \
                    -k $GURU_PROJECT_INDICATOR \
                    "${FUNCNAME[0]}: project status polling started"
            ;;
        end)    gr.msg -v1 -t -c reset \
                    -k $GURU_PROJECT_INDICATOR \
                    "${FUNCNAME[0]}: project status polling ended"
            ;;
        status) project.status
            ;;
        *)      project.help
            ;;
    esac
}


project.install () {
# install reguirements
    gr.msg -v0 -n -c dark_cyan "${FUNCNAME[0]}:"; gr.msg -n -c deep_pink "$@" ; gr.msg -n -c white ">"
    gr.msg "no special software needed"
}


project.remove () {
# remove projects reguirements
    gr.msg -v0 -n -c dark_cyan "${FUNCNAME[0]}:"; gr.msg -n -c deep_pink "$@" ; gr.msg -n -c white ">"
    gr.msg "no special software installed"
}


project.rc () {
# source module configs
    gr.debug "$FUNCNAME: $project_rc"

    if [[ ! -f $project_rc ]] \
        || [[ $(( $(stat -c %Y $GURU_CFG/$GURU_USER/project.cfg) - $(stat -c %Y $project_rc) )) -gt 0 ]] \
        || [[ $(( $(stat -c %Y $GURU_CFG/$GURU_USER/mount.cfg) - $(stat -c %Y $project_rc) )) -gt 0 ]]
    then
        project.make_rc && gr.msg -v1 -c dark_gray "$project_rc updated"
    fi

    source $project_rc
}


project.make_rc () {
# make rc out of project module configuration

    source config.sh

    if [[ -f $project_rc ]] ; then
        rm -f $project_rc
    fi

    config.make_rc "$GURU_CFG/$GURU_USER/mount.cfg" $project_rc
    config.make_rc "$GURU_CFG/$GURU_USER/project.cfg" $project_rc append
    chmod +x $project_rc

    source $project_rc

}


# fulfill basic variables from guru-client core configs
source "$GURU_RC"

# fulfill module variables based on configuration file $GURU_CFG/project.cfg with auto update
project.rc

# declare some module level globals
declare -g project_cfg="$GURU_CFG/$GURU_USER/project.cfg"
declare -g project_git=
declare -g module_data_folder="$GURU_SYSTEM_MOUNT/project"
declare -g project_archive="$GURU_SYSTEM_MOUNT/project/archived"

# soursing this file you will get preset functions in use
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
    # run entry function only is colled from terminal
    # other modules should source this first, then call <module>.main function
    project.main "$@"
fi
