#!/bin/bash
# guru tool-kit project tools
# ujo.guru 2020

project.main() {
    # command paerser
    command="$1" ; shift

    case "$command" in
        open) project.open $@            ;;
        test) project.test $@            ;;
        help) project.help               ;;
           *) project.open "$command $@" ;;
    esac
}


project.help () {
    printf "project module works only with sublime.\n"
    printf "Set preferred editor by typing: %s set editor subl, or edit '~/.gururc'. \n" "$GURU_CALL"
}


project.open () {
    # open project with preferred editor
    [[ "$1" ]] && _project_name="$1" ||read -p "plase enter project name : " _project_name
    shift

    [[ -d "$GURU_PROJECT" ]] ||mkdir -p "$GURU_PROJECT"

    case "$GURU_EDITOR" in
         subl|sublime|sublime-text|subl2|subl3|subl4)
                                project.sublime $_project_name   ;;
                            *)  project.help
    esac
}

project.sublime () {

    local _project_name="$1"                                          ; echo "$_project_name"
    local _project_file=$GURU_PROJECT/$_project_name.sublime-project  ; echo "$_project_file"

    if [ -f "$project_file" ]; then
        subl --project "$_project_file" -a
        subl --project "$_project_file" -a                              # Sublime how to open workpace?, this works anyway
    else
        printf "no sublime project found" >"$GURU_ERROR_MSG"
        return 132
    fi
}


# if not runned from terminal, use as library
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
    source "$HOME/.gururc"
    project.main "$@"
    exit 0
fi

