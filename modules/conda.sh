#!/bin/bash
# anaconda installer

source $GURU_BIN/common.sh

conda.main () {     # anaconda main (do I really need this.. i doupt)

    local _cmd="$1" ; shift

    case $_cmd in
            update|install)  conda.$_cmd ; return $? ;;
                   project)  case $1 in add|active|rm) conda.$1_project ;; *) echo "uknown command" ; esac ; return $? ;;
                run|launch)  conda.launch $@ ; return $? ;;
                      help)  echo "usage:    conda [project|update|install|run|help]" ;;
                         *)  printf "uknown command, try install or launch"
        esac
}

conda.install () {  # install anaconda

    conda list && return 13 || echo "no conda installed"

    sudo apt-get install -y libgl1-mesa-glx libegl1-mesa libxrandr2 libxrandr2 libxss1 libxcursor1 libxcomposite1 libasound2 libxi6 libxtst6 && OK || WARNING

    conda_version="2019.03"
    conda_installer="Anaconda3-$conda_version-Linux-x86_64.sh"
    conda_sum=45c851b7497cc14d5ca060064394569f724b67d9b5f98a926ed49b834a6bb73a

    curl -O https://repo.anaconda.com/archive/$conda_installer
    sha256sum $conda_installer >installer_sum && OK || ERROR
    printf "checking sum, if exit it's invalid: "
    cat installer_sum |grep $conda_sum && OK || ERROR

    chmod +x $conda_installer
    bash $conda_installer -u && rm $conda_installer installer_sum && OK || ERROR
    source ~/.bashrc
    printf "conda install done, next run by typing: '%s conda launch'\n" "$GURU_CALL"
    return 0
}

conda.add_project () {

    local _project="$1" ; shift
    conda create --name $_project python=3 || ERROR "something went wrong"
}


conda.active_project () {
    local _project="$1" ; shift
    conda activate $_project || WARNING "project not found"
}


conda.launch () {
    conda_setup="$('$GURU_BIN/conda/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$conda_setup"
    else
        if [ -f "$GURU_BIN/conda/etc/profile.d/conda.sh" ]; then
            source "$GURU_BIN/conda/etc/profile.d/conda.sh"
        else
            export PATH="$GURU_BIN/conda/bin:$PATH"
        fi
    fi
}

conda.update () {
    HEADER "updating anaconda.."
    conda update -n base -c defaults conda && OK || ERROR
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then    # if sourced only import functions
        if [[ "$1" == "test" ]] ; then shift ; bash /test/test.sh conda $1 ; fi
        source "$HOME/.gururc2"
        conda.main "$@"
        exit "$?"
    fi
