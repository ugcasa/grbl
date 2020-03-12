#!/bin/bash
# guru tool-kit project tools
# ujo.guru 2020 

project.main() {

    command="$1"; shift
    
    case "$command" in

        open)
            project.open "$@"
            ;;

        test)
            project.test "$@"
            ;;

        help)
            printf "\nguru tool-kit project tools - help \n"
            printf "\nUsage:\n\t %s [command] <project_name> \n" "$GURU_CALL" 
            printf "\nCommands:\n"
            printf " open            Open named projec \n" 
            printf "\nExample:\n"
            printf "\t %s project open guru.ui \n" "$GURU_CALL" 
            echo
            ;;

        *)
            project.open "$command"
            ;;
    esac

    return 0
}


project.open () {

    [ "$1" ] && project_name="$1" ||read -p "plase enter project name : " project_name 
    shift

    [ -d "$GURU_PROJECT_META" ] ||mkdir -p "$GURU_PROJECT_META"

    case "$GURU_EDITOR" in 
    
            subl|sublime|sublime-text)
                subl_project_file=$GURU_PROJECT_META/$project_name.sublime-project              
                if [ -f "$subl_project_file" ]; then                    
                    subl --project "$subl_project_file" -a 
                    subl --project "$subl_project_file" -a                              # Sublime how to open workpace?, this works anyway
                else
                    printf "no sublime project found" >"$GURU_ERROR_MSG"
                    return 132
                fi  
                ;;
            *)
                printf "projects work only with sublime. Set preferred editor by typing: %s set editor subl, or edit '~/.gururc'. " "$GURU_CALL" >"$GURU_ERROR_MSG"
                return 133
    esac

    return 0
}


project.test() {

    echo "TEST"
    project.open "guru-ui" && echo "PASSED" || echo "FAILED"
}


# if not runned from terminal, use as library
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$HOME/.gururc"
    project.main "$@"
    exit 0
fi

