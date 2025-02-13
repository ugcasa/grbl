#!/bin/bash
# anaconda installer

source $GRBL_BIN/common.sh
conda_folder="$HOME/anaconda3"
conda_bin="$conda_folder/bin/conda"

conda.main () {     # anaconda main (do I really need this.. i doupt)

    local _cmd="$1" ; shift

    case $_cmd in
        project)
            case $1 in
                add|active|rm)
                    conda.$1_project
                    ;;
                *)  echo "uknown command"
            esac
            return $?
            ;;
        run|launch)
            conda.launch $@
            return $?
            ;;
        help)
            echo "usage:    conda [project|update|install|run|help]"
            ;;
        update|install|remove|status)
            conda.$_cmd
            return $?
            ;;
        *)
            gr.msg -c error "uknown command '$_cmd'"
        esac
}

conda.install () {  # install anaconda

    conda_version="2022.05"

    if [[ -f $HOME/anaconda3/bin/conda ]] ; then
        gr.msg "already installed"
        return 0
    fi

    gr.msg "installing version v$conda_version"

    sudo apt-get install -y libgl1-mesa-glx libegl1-mesa libxrandr2 libxrandr2 libxss1 libxcursor1 libxcomposite1 libasound2 libxi6 libxtst6 && gr.msg -c green "ok" || gr.msg -c red
    conda_installer="Anaconda3-$conda_version-Linux-x86_64.sh"
    #conda_sum=45c851b7497cc14d5ca060064394569f724b67d9b5f98a926ed49b834a6bb73a

    curl -O https://repo.anaconda.com/archive/$conda_installer
    #sha256sum $conda_installer >installer_sum && gr.msg -c green "ok" || gr.msg -c red "failed"
    #printf "checking sum, if exit it's invalid: "
    #cat installer_sum |grep $conda_sum && gr.msg -c green "ok" || gr.msg -c red "failed"

    chmod +x $conda_installer
    bash $conda_installer -u && rm $conda_installer && gr.msg -c green "ok" || gr.msg -c red "failed"
    source ~/.bashrc
    printf "conda install done, next run by typing: '%s conda launch'\n" "$GRBL_CALL"
    return 0
}


conda.status () {
    gr.msg -n -v1 -t "${FUNCNAME[0]}: conda "

    if [[ -d $HOME/anaconda3 ]] ; then
        gr.msg -c green "installed"
        return 0
    else
        gr.msg -c dark_grey "installation not found"
        return 1
    fi
}


conda.remove () {  # install anaconda

    if ! [[ -d $HOME/anaconda3 ]] ; then
        gr.msg "installation not found"
        return 0

    fi

    gr.msg "removing current installation"
    rm "$HOME/anaconda3" -r
}


conda.add_project () {

    local _project="$1" ; shift
    $conda_bin create --name $_project python=3 || gr.msg -c red "failed" "something went wrong"
}


conda.active_project () {
    local _project="$1" ; shift
    $conda_bin activate $_project || gr.msg -c red "project not found"S
}


conda.launch () {

    conda_setup="$($conda_bin "shell.bash" 'hook' 2> /dev/null)"

    echo $PATH | grep $conda_folder/bin >/dev/null || export PATH="$conda_folder/bin:$PATH"
    gr.msg -h "set to .bashrc 'export PATH=$conda_folder/bin:"'$PATH'"'"

    if [ $? -eq 0 ]; then
        eval "$conda_setup"
    else
        if [ -f "$conda_folder/etc/profile.d/conda.sh" ]; then
            source "$conda_folder/etc/profile.d/conda.sh"
        fi
    fi
}


conda.update () {
    echo "updating anaconda.."
    $conda_bin update -n base -c defaults conda && gr.msg -c green "ok" || gr.msg -c red "failed"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then    # if sourced only import functions
        if [[ "$1" == "test" ]] ; then shift ; bash /test/test.sh conda $1 ; fi
        #source "$GRBL_RC"
        conda.main "$@"
        exit "$?"
    fi
