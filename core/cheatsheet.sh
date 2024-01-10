#!/bin/bash

cheatsheet.main () {

    case $1 in 

        colors|errors|modules|files|configs|projects)
            cheatsheet.$1
            ;;
        color|error|module|file|config|project)
            cheatsheet.$1s
            ;;
        all|*|"")
            cheatsheet.projects
            cheatsheet.errors
            cheatsheet.modules
            cheatsheet.files
            cheatsheet.configs
            cheatsheet.colors
            read
            ;;
    esac
}


cheatsheet.colors () {

    gr.msg -N -h "Color naming"
    gr.colors
    gr.msg -n
}


cheatsheet.errors () {

    gr.msg -h "Error levels"
    names=(notification error warning alert fault undefined)
    for (( i = 0; i < 6; i++ )); do
        gr.msg -n -h "e$i: "
        gr.msg -e$i "${names[$i]} "
    done
}


cheatsheet.modules() {

    gr.msg -N -h "Installed modules"
    cat $GURU_CFG/installed.modules

    gr.msg -N -h "Core modules"
    cat $GURU_CFG/installed.core
}


cheatsheet.files () {

    gr.msg -N -h "Temp files"
    ls /tmp/guru* | grep -v .rc

    gr.msg -N -h "RC files"
    ls /tmp/guru* | grep .rc
}


cheatsheet.configs () {

    gr.msg -N -n -h "Default configurations "
    gr.msg "$GURU_CFG"
    ls $GURU_CFG/*.cfg

    gr.msg -N -n -h "User configurations "
    gr.msg "$GURU_CFG/$GURU_USER"
    ls $GURU_CFG/$GURU_USER/*.cfg
}


cheatsheet.projects() {

    [[ -f $(cat $GURU_DATA/project/active) ]] && project=$(cat $GURU_DATA/project/active) || project=$(cat $GURU_DATA/project/last)

    gr.msg -N -h "Project files "
    ls $GURU_DATA/project/*

    gr.msg -N -h "Last active project '$project' "
    ls $GURU_DATA/project/projects/$project/*
    source $GURU_DATA/project/projects/$project/config.sh source

    gr.msg -N -h -n "Git folder "
    gr.msg $GURU_PROJECT_GIT
    ls $GURU_PROJECT_GIT/*

    gr.msg -N -h -n "Project folder "
    gr.msg $GURU_PROJECT_FOLDER
    ls $GURU_PROJECT_FOLDER/*
    echo
}


if [[ ${BASH_SOURCE[0]} == ${0} ]]; then
    cheatsheet.main $@
    exit $?
fi

