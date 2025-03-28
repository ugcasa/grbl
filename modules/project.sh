#!/bin/bash
# grbl project tools 2023 casa@ujo.guru

declare -g project_rc="/tmp/$USER/grbl_project.rc"

project.main () {
# main command parser

    local _cmd="$1" ; shift

    case "$_cmd" in

        # list of commands
        run|exist|ls|info|\
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
# verbose level based help output with decorations

    gr.msg -v1 -c white "grbl project module help "
    gr.msg -v2
    gr.msg -v1 "tools for project control"
    gr.msg -v2
    gr.msg -V2 -v0 "usage:    $GRBL_CALL project ls|info|add|rm|open|close "
    gr.msg -v2 "usage:    $GRBL_CALL project ls|new|open|status|close|rm|sublime|help  name/id"
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
    gr.msg -v3 "  terminal <name>         open terminal tools TBD" -c todo
    gr.msg -v3 "  sublime <name>          open sublime parts of project "
    gr.msg -v1 "  status                  status of project module"
    gr.msg -v3 "  poll start|stop         daemon poll function"
    gr.msg -v1 "  help                    this help "
    gr.msg -v1
    gr.msg -v1 -c white "example:"
    gr.msg -v1 "  $GRBL_CALL project ls             # list of projects "
    gr.msg -v1 "  $GRBL_CALL project add demo       # initialize new project called 'demo'"
    gr.msg -v2 "  $GRBL_CALL project archive        # list of archived projects "
    gr.msg -v2 "  $GRBL_CALL project edit demo      # edit 'demo' config and launcher script "
    gr.msg -v2 "  $GRBL_CALL project archive demo   # archive 'demo', needs to be done before rm "
    gr.msg -v3 "  $GRBL_CALL project rm demo        # remove all 'demo' project files "
    gr.msg -v2
    return 0
}


project.print_module_variables () {
    gr.kvp "GRBL_PROJECT_ENABLED" \
           "project_cfg" \
           "module_data_folder" \
           "project_archive" \
           "GRBL_PROJECT_INDICATOR" \
           "GRBL_PROJECT_GIT_BASE" \
           "GRBL_MOUNT_PROJECTS"
}


project.print_project_variables () {

        gr.kvp "project_folder" \
               "GRBL_PROJECT_NAME" \
               "GRBL_PROJECT_DESCRIPTION" \
               "GRBL_PROJECT_COLOR" \
               "GRBL_PROJECT_MOUNT" \
               "GRBL_PROJECT_TICKET" \
               "GRBL_PROJECT_WIKI" \
               "GRBL_PROJECT_SCRIPT" \
               "GRBL_PROJECT_FOLDER" \
               "GRBL_PROJECT_GIT" \
               "GRBL_PROJECT_ENV" \
               "GRBL_PROJECT_ISSUES"
}


project_print_variables () {
    gr.msg -N -h "module variables"
    project.print_module_variables
    gr.msg -N -h "project '$active' variables"
    project.print_project_variables
}


project.info () {
# list of projects, active highlighted

    local project_name=$1
    project.configure $project_name

    gr.msg -n -h "system folder.. "
    if [[ -f $GRBL_SYSTEM_MOUNT/.online ]] ; then
        gr.msg -c green "mounted"
    else
        gr.msg -c red "not mounted"
        gr.msg "cannot continue, exiting"
        return 100
    fi
    # check is project file folder mounted
    gr.msg -n -h "project folder.. "
    if [[ -f "$GRBL_MOUNT_PROJECTS/.online" ]] ; then
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

    project.print_module_variables

    # active project information
    if [[ -f $GRBL_PROJECT_CFG ]]
    then
        source $GRBL_PROJECT_SCRIPT
        project.print_project_variables
    else
        gr.msg "no $active project data available"
    fi
}


project.active () {
# printout active opened project and return 0 if exist
gr.kvt $module_data_folder
    if [[ -f "$module_data_folder/active" ]] ; then
        head -n1 "$module_data_folder/active"
        return 0
    else
        return 1
    fi
}


project.last () {
# printout last opened project and return 0 if exist
    if [[ -f "$module_data_folder/last" ]] ; then
        head -n1 "$module_data_folder/last"
        return 0
    else
        return 1
    fi
}


project.configure () {
# set global project variables

# vittumikä härdelli projektin muuttujien täyttö.
# projektimoduli on selkeästi ensimmäisten joukossa jotka uudelleenkirjoitetaan pythonisaation alkuhämärissä.
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
    declare -g project_git="$GRBL_GIT_HOME/$project_name"
    # project_home="$GRBL_MOUNT/projects/$project_name"

    gr.msg -v3 "$GRBL_USER working on $project_name home folder:$project_git"

    # check that project is in projects list
    if ! project.exist $project_name ; then
        gr.msg -c yellow "$project_name does not exist"
        return 3
    fi

    #[[ $GRBL_DEBUG ]] && gr.kvp "GRBL_PROJECT_NAME GRBL_PROJECT_DESCRIPTION GRBL_PROJECT_FOLDER GRBL_PROJECT_SCRIPT GRBL_PROJECT_CFG GRBL_PROJECT_GIT"
    # # run project user script
    [[ -f $project_script ]] && source $project_script  #source $@

    #[[ $GRBL_DEBUG ]] && gr.kvp "GRBL_PROJECT_NAME GRBL_PROJECT_DESCRIPTION GRBL_PROJECT_FOLDER GRBL_PROJECT_SCRIPT GRBL_PROJECT_CFG GRBL_PROJECT_GIT"

    # [[ $GRBL_DEBUG ]] && gr.kvp "project_name project_description project_folder project_script project_cfg project_git"
    # export configs for other modules // CHANCE RM this method will be removed some day make ready to chance
    export GRBL_PROJECT_NAME=$project_name
    export GRBL_PROJECT_DESCRIPTION=$project_description
    export GRBL_PROJECT_FOLDER=$project_folder
    export GRBL_PROJECT_SCRIPT=$project_script
    export GRBL_PROJECT_CFG=$project_cfg
    export GRBL_PROJECT_GIT=$project_git
    [[ $project_color ]] && export GRBL_PROJECT_COLOR=$project_color

    #[[ $GRBL_DEBUG ]] && gr.kvp "GRBL_PROJECT_NAME GRBL_PROJECT_DESCRIPTION GRBL_PROJECT_FOLDER GRBL_PROJECT_SCRIPT GRBL_PROJECT_CFG GRBL_PROJECT_GIT"
}


project.run () {
# open project terminal and run given command in it
    gnome-terminal -- "$@"
    return $?
}


project.sublime () {
# open sublime with project file

    local project_file="$project_folder/$GRBL_USER-$project_name.sublime-project"

    if ! [[ -d $project_folder ]] ; then
            gr.msg -c yellow "project not exist"
            return 131
        fi

    if [[ -f "$project_file" ]] ; then
            gr.msg -v2 "using $project_file"
            # TBD edit/subl.sh?  << subl --project "$project_file" -a
            subl --project "$project_file" -a
        else
            gr.msg -c yellow "$project_file not found"
            return 132
        fi
}


project.code () {
# open code with project file

    local project_file="$project_folder/$project_name.code-workspace"

    if ! [[ -d $project_folder ]] ; then
            gr.msg -c yellow "project not exist"
            return 131
        fi

    if [[ -f "$project_file" ]] ; then
            gr.msg -v2 "using $project_file"
            # TBD edit/subl.sh?  << subl --project "$project_file" -a
            code --profile "$project_file" -r
        else
            gr.msg -c yellow "$project_file not found"
            return 132
        fi
}


project.subl () {
# aliases
    project.configure $1
    shift
    project.sublime $@
    return $?
}


project.open () {
# open project, sublime + env variables+ tmux

    local project_name=$1
    gr.debug "$FUNCNAME got: $project_name"
    [[ $GRBL_DEBUG ]] && project.print_module_variables
    [[ $GRBL_DEBUG ]] && project_print_variables
    # set project variables
    if ! project.configure $project_name ; then return 0 ; fi

    shift

    #[[ -f $project_script ]] && source $project_script

    # TBD add if [[ -f $ ]]

    # check is given project already active
    if [[ -f "$module_data_folder/active" ]] \
            && [[ "$project_name" == "$(cat $module_data_folder/active)" ]] \
            && ! [[ $GRBL_FORCE ]]
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
    [[ $GRBL_PROJECT_COLOR ]] && key_color=$GRBL_PROJECT_COLOR

    # set corsair keyboard RGB settings to indicate module state
    gr.msg -v1 -c $key_color "$project_name" -m "$GRBL_USER/project" -k $GRBL_PROJECT_INDICATOR

    # open editor
    [[ $GRBL_PROJECT_EDITOR ]] && GRBL_PREFERRED_EDITOR=$GRBL_PROJECT_EDITOR
    gr.debug "editor: $GRBL_PREFERRED_EDITOR"

    case $GRBL_PREFERRED_EDITOR in

        sublime|subl|sub3|sub4)
            project.sublime
        ;;

        code|vscode)
            gr.msg "project '$project_name' code folder '$project_git' "
            [[ $GRBL_FORCE ]] \
                && code $project_git \
                || gr.msg -v2 "let user launch editor $project_git"

            project.code
        ;;

        vi|vim)
            gr.msg "no support for vim project files"  # TBD
        ;;

        joe)
            gr.msg "no support for joe project files" # TBD
        ;;
        *)
            gr.msg -c red "unknown editor '$GRBL_PREFERRED_EDITOR' project files"

    esac

    # continue to open terminal shit # TBD why here?
    project.terminal $project_name

    return $?
}


project.terminal () {
# open preferred terminal with configuration or command line setup

    local project_name=$1
    project.configure $project_name
    gr.debug "$FUNCNAME: $project_name "
    [[ $GRBL_DEBUG ]] && project.print_module_variables

    if [[ -f "$project_folder/config.sh" ]] ; then
        source "$project_folder/config.sh"
        # $project_folder/config.sh terminal $@
    fi

    case $GRBL_PREFERRED_TERMINAL in

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

                    if [[ $GRBL_PROJECT_GIT ]] ; then
                        gnome-terminal --tab --title="config" \
                                       --working-directory="$GRBL_PROJECT_FOLDER" \
                                       --tab --title="git" \
                                       --working-directory="$GRBL_PROJECT_GIT" \
                                       --tab --title="project" \
                                       --working-directory="$GRBL_PROJECT_MOUNT" \
                                       --tab --title="issues" \
                                       --working-directory="$GRBL_PROJECT_ISSUES"
                    else
                        gnome-terminal --working-directory="$GRBL_PROJECT_FOLDER"
                    fi
                fi
            ;;

            *)
                gr.msg "non supported terminal"
            ;;
    esac
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
        gr.msg -v1 -c reset "$active_project closed" -k $GRBL_PROJECT_INDICATOR
    fi

    user_config="$module_data_folder/projects/$project_name/config.sh post"
    [[ -f $user_config ]] && .$user_config post

    project.status
}


project.toggle () {
# open last project if not open already and close if its open

    #local module_data_folder="$GRBL_SYSTEM_MOUNT/project"
    [[ -f $module_data_folder/active ]] && project.close || project.open $@
    sleep 2
    return 0
}


project.ls () {
# list of projects

    #project.configure $1   # no point, only one variable needed
    # local module_data_folder="$GRBL_SYSTEM_MOUNT/project"
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
    local sublime_project_file="$project_folder/$GRBL_USER-$project_name.sublime-project"

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
    cp $GRBL_CFG/project-default.cfg $project_folder/config.sh
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
        #local module_data_folder="$GRBL_SYSTEM_MOUNT/project"
        local project_folder="$module_data_folder/projects/$project_name"
        local archive_folder="$module_data_folder/archived/$project_name"

        # check project folder and archive
        if [[ -d $project_folder ]] ; then
            gr.msg -v0 -c white "project needs to be archived before removeing"
            gr.msg -v0 "to arvhive type: '$GRBL_CALL project archive $project_name'"
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

    #module_data_folder="$GRBL_SYSTEM_MOUNT/project"

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
    #local module_data_folder="$GRBL_SYSTEM_MOUNT/project"

    echo $project_name > "$module_data_folder/active"
    echo $project_name > "$module_data_folder/last"
    gr.msg -v2 "$project_name" -m "$GRBL_USER/project"
}


########################### daemon functions ##########################3

project.status () {
# indicate that project module is working correctly

    local project_name=$1
    [[ $project_name ]] || project_name=$(project.last)
    project.configure $project_name

    gr.msg -v1 -n -t "${FUNCNAME[0]}: "

    if [[ $GRBL_PROJECT_ENABLED ]] ; then
        gr.msg -v1 -n -c green "enabled, "  -k $GRBL_PROJECT_INDICATOR
    else
        gr.msg -v1 -c black "disabled " -k $GRBL_PROJECT_INDICATOR
        return 1
    fi

    if [[ -d "$module_data_folder" ]] ; then
        gr.msg -v1 -n -c green "installed, "  -k $GRBL_PROJECT_INDICATOR
    else
        gr.msg -v1 -n -c red "$module_data_folder not installed, " -k $GRBL_PROJECT_INDICATOR
        return 2
    fi

    # check are projects mounted
    if [[ -f "$project_folder/.online" ]] ; then
        gr.msg -v1 -n -c green "mounted "  -k $GRBL_PROJECT_INDICATOR
    else
        gr.msg -v1 -c yellow "not mounted" -k $GRBL_PROJECT_INDICATOR
    fi

    # print
    [[ $GRBL_VERBOSE -gt 0 ]] && project.ls

    if [[ -f $module_data_folder/active ]]; then
        local active=$(cat $module_data_folder/active)
        gr.msg -v4 -n -c aqua_marine -k $GRBL_PROJECT_INDICATOR
    else
        gr.msg -v3 -c reset "no active projects " -k $GRBL_PROJECT_INDICATOR
    fi

    return 0
}


project.poll () {
# daemon required polling functions

    local _cmd="$1" ; shift

    case $_cmd in
        start)  gr.msg -v1 -t -c black \
                    -k $GRBL_PROJECT_INDICATOR \
                    "${FUNCNAME[0]}: project status polling started"
            ;;
        end)    gr.msg -v1 -t -c reset \
                    -k $GRBL_PROJECT_INDICATOR \
                    "${FUNCNAME[0]}: project status polling ended"
            ;;
        status) project.status
            ;;
        *)      project.help
            ;;
    esac
}


project.install () {
# install requirements
    gr.msg -v0 -n -c dark_cyan "${FUNCNAME[0]}:"; gr.msg -n -c deep_pink "$@" ; gr.msg -n -c white ">"
    gr.msg "no special software needed"
}


project.remove () {
# remove projects requirements
    gr.msg -v0 -n -c dark_cyan "${FUNCNAME[0]}:"; gr.msg -n -c deep_pink "$@" ; gr.msg -n -c white ">"
    gr.msg "no special software installed"
}


project.rc () {
# source module configs
    gr.debug "$FUNCNAME: $project_rc"

    if [[ ! -f $project_rc ]] \
        || [[ $(( $(stat -c %Y $GRBL_CFG/$GRBL_USER/project.cfg) - $(stat -c %Y $project_rc) )) -gt 0 ]] \
        || [[ $(( $(stat -c %Y $GRBL_CFG/$GRBL_USER/mount.cfg) - $(stat -c %Y $project_rc) )) -gt 0 ]]
    then
        project.make_rc && gr.msg -v1 -c dark_gray "$project_rc updated"
    fi

    # fulfill project mounting variables
    source mount.sh

    # source project as library
    source $project_rc
}


project.make_rc () {
# make rc out of project module configuration

    source config.sh

    if [[ -f $project_rc ]] ; then
        rm -f $project_rc
    fi

    config.make_rc "$GRBL_CFG/$GRBL_USER/mount.cfg" $project_rc
    config.make_rc "$GRBL_CFG/$GRBL_USER/project.cfg" $project_rc append
    chmod +x $project_rc

    source $project_rc

}


# fulfill basic variables from grbl core configs // may overwrite user configs, should be sourced by core
# source "$GRBL_RC"

# fulfill module variables based on configuration file $GRBL_CFG/project.cfg with auto update
project.rc

# declare some module level globals
declare -g project_cfg="$GRBL_CFG/$GRBL_USER/project.cfg"
declare -g project_git=
declare -g module_data_folder="$GRBL_SYSTEM_MOUNT/project"
declare -g project_archive="$GRBL_SYSTEM_MOUNT/project/archived"

[[ $GRBL_DEBUG ]] && gr.kvp "project_cfg project_git module_data_folder project_archive"

# source this file as library by sourcing module functions in use for other modules
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
# run entry function only is called from terminal
    project.main "$@"
fi
