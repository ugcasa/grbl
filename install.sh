#!/bin/bash
# installer for guru-client. ujo.guru casa@ujo.guru 2017-2020

# default environment variables and included functions
GURU_CALL="guru"
GURU_USER="$USER"
GURU_BIN=$HOME/bin
GURU_CFG=$HOME/.config/guru
# include decorative functions
source core/deco.sh
# include os functions
source core/os.sh
source core/config.sh

# Environmental values rc file
target_rc="$HOME/.bashrc"
# Flag for disabling the rc file
disabler_flag_file="$HOME/.gururc.disabled"

# modify this when module is ready to publish. flag -d will overwrite this list and install all present modules
modules_to_install=(corsair counter mount mqtt note phone poller print project remote scan ssh stamp tag timer tor trans user news vol yle)


install.main () {
    gmsg -v1 -c white "installing guru-client.."
    # Step 1) parse arguments
    install.arguments $@ || gmsg -x 100 "argumentation error"

    # Step 2) check previous installation
    install.check || gmsg -x 110 "check caused exit"

    # Step 3) modify and add .rc files
    install.rcfiles && install.check_rcfiles || gmsg -x 120 "rc file modification error"

    # Step 4) create folder structure
    install.folders && install.check_folders || gmsg -x 140 "error during creating folders"

    # Step 5) install core
    install.core_files && install.check_core || gmsg -x 150 "error during installing core"

    # Step 6) install modules
    install.modules && install.check_modules || gmsg -x 160 "error when installing modules"

    # Step 7) set up launcher
    ln -f -s "$GURU_BIN/core.sh" "$GURU_BIN/$GURU_CALL" || gmsg -x 170 "core linking error"

    # Step 8) export user configuration
    install.config || gmsg -x 180 "user configuration error"

    # Step 9) save information and done
    echo "${modules_to_install[@]}" > $GURU_CFG/installed.modules
    echo "$($GURU_BIN/core.sh version) installed"
}


install.help () {
    gmsg -c white "guru-client install help "
    gmsg
    gmsg "usage:    ./install.sh -f|-r|-d|-v|-V|-h|-u <user> "
    gmsg
    gmsg -c white "flags:"
    gmsg " -f               force re-install "
    gmsg " -v               low verbose (normally quite silent) "
    gmsg " -V               high verbose "
    gmsg " -h               print this help "
    gmsg " -u <user>        set user name "
    gmsg " -d               install also development stuff "
    gmsg " -r               install all module requirements (experimental)"
    gmsg
    gmsg -c white "example:"
    gmsg "          ./install.sh -dfV -u $USER"
    gmsg -x 0
}


install.arguments () {
    ## Process flags and arguments
    TEMP=`getopt --long -o "dfrvVhu:" "$@"`
    eval set -- "$TEMP"
    while true ; do
        case "$1" in
            -d )       development=true         ; shift ;;
            -f )       force_overwrite=true     ; shift ;;
            -r )       install_requiremets=true ; shift ;;
            -v )       export GURU_VERBOSE=1    ; shift ;;
            -V )       export GURU_VERBOSE=2    ; shift ;;
            -h )       install.help             ; shift ;;
            -u )       export GURU_USER=$2      ; shift 2 ;;
             * ) break
        esac
    done
    _arg="$@"
    [[ "$_arg" != "--" ]] && ARGUMENTS="${_arg#* }"

    ## Command parser (if any needed)
    case "$1" in
           help)    install.help ;;
    esac

}


install.check () {
    ## Check installation, reinstall if -f or user input
    gmsg  -v1 -c white "checking current installation.. "
    if grep -q ".gururc2" "$target_rc" ; then
        [[ $force_overwrite ]] && answer="y" ||read -p "already installed, force re-install [y/n] : " answer

        if ! [[ "$answer" == "y" ]]; then
                gmsg -c yellow -x 2 "aborting.."
            fi

        if [[ -f "$GURU_BIN/uninstall.sh" ]] ; then
                $GURU_BIN/uninstall.sh
            else
                gmsg -c yellow "some un-installer problems.."
            fi
        fi
    return 0
}


install.rcfiles () {
    ## Set up dot rc files
    gmsg -n -v1 -c white "setting up launchers.. "
    # Check is .gururc called in .bashrc, add call if not
    [[ -f "$HOME/.bashrc.giobackup" ]]  || cp -f "$target_rc" "$HOME/.bashrc.giobackup"

    # make a backup of original .bashrc only if installed first time
    grep -q ".gururc" "$target_rc"      || cat core/tobashrc.sh >>"$target_rc"

    # todo: remove disabler function, just un install if need to disable the shit
    [[ -f "$disabler_flag_file" ]]      && rm -f "$disabler_flag_file"

    # pass
    gmsg -v1 -c green "DONE"
    return 0

}


install.folders () {
    gmsg -n -v1 -c white "setting up folder structure.. "
    # make bin folder for scripts, configs and and apps
    [[ -d "$GURU_BIN" ]] || mkdir -p "$GURU_BIN"
    [[ -d "$GURU_APP" ]] || mkdir -p "$GURU_APP"
    # personal configurations
    [[ -d "$GURU_CFG/$GURU_USER" ]] || mkdir -p "$GURU_CFG/$GURU_USER"

    gmsg -v1 -c green "DONE"
    return 0
}


install.core_files () {

    gmsg -n -v1 -c white "installing core.. "
    # copy configuration files to configuration folder
    cp -f cfg/* "$GURU_CFG"
    # copy script files to bin folder
    cp -f -r core/* -f "$GURU_BIN"
    # copy tester folder
    cp -f -r test -f "$GURU_BIN"

    gmsg -v1 -c green "DONE"

    # if development, install trials and all modules
    if [[ $development ]] ; then
            gmsg -n -v1 -c white "installing development trials.."
            modules_to_install=$(ls modules |cut -f1 -d ".")
            cp -f -r foray/* -f "$GURU_BIN" && gmsg -v1 -c green "DONE"
        fi

    return 0
}


install.modules () {
    # install modules
    gmsg  -v1 -c white "installing modules"
    for _module in ${modules_to_install[@]} ; do
            gmsg -n -v2 "installing $_module.. "
            module_file=$(ls modules/$_module.*)
            if [[ -f $module_file ]] ; then
                cp -f -r modules/$_module.* "$GURU_BIN" && gmsg -v2 -c green "DONE"
                [[ $install_requiremets ]] && gask "install module $_module requirements" && $module_file install
            fi
        done

    return 0
}


install.check_rcfiles () {
    # test
    gmsg -n -v1 -c white "checking launchers.. "
    grep -q "guru" "$target_rc"         || gmsg -c red -x 122 ".bashrc modification error"
    [[ -f "$HOME/.bashrc.giobackup" ]]  || gmsg "warning: .bashrc backup file creation failure"
    [[ -f "$disabler_flag_file" ]]      && gmsg "warning: disabler flag file creation failure"

    gmsg -v1 -c green "PASSED"
    return 0
}


install.check_folders () {
    # test
    gmsg -n -v1 -c white "checking created folders.. "
    [[ -d "$GURU_BIN" ]] || gmsg -x 141 -c red "bin folder creation error"
    [[ -d "$GURU_APP" ]] || gmsg -x 142 -c red "app folder creation error"
    [[ -d "$GURU_CFG/$GURU_USER" ]] || gmsg -x 143 -c red "configuration folder creation error"

    gmsg -v1 -c green "PASSED"
    return 0
}


install.check_core () {

    gmsg -v1 -c white "checking installed core modules"
    for _file in $(ls core) ; do
            gmsg -n -v2 "$_file.. "
            if [[ -f $GURU_BIN/$_file ]] ; then
                gmsg -v2 -c green "OK"
            else
                gmsg -c red "core module $_file missing"
            fi
        done

    gmsg -v1 -c white "checking installed configuration files"
    for _file in $(ls cfg) ; do
            gmsg -n -v2 "$_file.. "
            if [[ -f $GURU_CFG/$_file ]] ; then
                gmsg -v2 -c green "OK"
            else
                gmsg -c yellow "configuration file $_file missing"
            fi
        done

    # check installed tester files
    gmsg -v1 -c white "checking tester module"
    for _file in $(ls test) ; do
            gmsg -n -v2 "$_file.. "
            if [[ -f $GURU_BIN/test/$_file ]] ; then
                gmsg -v2 -c green "OK"
            else
                gmsg -c yellow "tester file $_file missing"
            fi
        done

    # pass
    return 0
}

install.check_modules () {

    # check installed modules (foray folder is not monitored)
    gmsg -v1 -c white "checking installed modules"
    for _file in  ${modules_to_install[@]} ; do
            gmsg -n -v2 "$_file.. "
            if ls $GURU_BIN/$_file* >/dev/null ; then
                gmsg -v2 -c green "OK"
            else
                gmsg -c yellow "module $_file missing"
            fi
        done
    # pass
    return 0
}


install.config () {

    gmsg -v1 -c white "setting user configurations "
    if ! [[ -f "$GURU_CFG/$GURU_USER/user.cfg" ]] ; then
         gmsg -c yellow "user specific configuration not found, using default.."
         cp -f $GURU_CFG/$GURU_USER/user-default.cfg "$GURU_CFG/$GURU_USER/user.cfg" || gmsg -c red -x 181 "default user configuration failed"
    fi
    config.export && source $HOME/.gururc2 || gmsg -c red -x 182 ".gururc2 file error"
    #config.main pull || gmsg -x 182 "remote user configuration failed"
    return 0
}



if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        install.main $@
        exit "$?"
fi






