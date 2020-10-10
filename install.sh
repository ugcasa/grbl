#!/bin/bash
# installer for guru-client. ujo.guru casa@ujo.guru 2017-2020
GURU_CALL="guru"
GURU_USER="$USER"
# make allf function/module calls point to installer's version
export GURU_BIN="./core"
GURU_CFG=$HOME/.config/guru
TARGET_BIN=$HOME/bin
# use new modules durin installation
source core/common.sh
source core/config.sh
source core/keyboard.sh
# to where add gururc call
bash_rc="$HOME/.bashrc"
core_rc="$HOME/.gururc2"    # TODO change name to '.gururc' when cleanup next time
# core modules what need sto access by user from terminal
core_modules=(corsair config remote counter core daemon install system uninstall)
# modify this when module is ready to publish. flag -d will overwrite this list and install all present modules
modules_to_install=(mount mqtt note android print project scan ssh stamp tag timer tor trans user vol yle news)
# default install platform available: desktop|laptop|server|phone
install_platform="desktop"


install.main () {

    # Step 1) parse arguments
    install.arguments $@ || gmsg -x 100 "argumentation error"

    # Step 2) check previous installation
    install.check || gmsg -x 110 "check caused exit"
    gmsg -v1 -c white "installing guru-client"
    gmsg -v2 "user: $GURU_USER"

    # Step 3) modify and add .rc files
    install.rcfiles && check.rcfiles || gmsg -x 120 "rc file modification error"

    # Step 4) create folder structure
    install.folders && check.folders || gmsg -x 140 "error during creating folders"

    # Step 5) install core
    install.core && check.core || gmsg -x 150 "error during installing core"

    # Step 6) install ..stuff

    # Step 6.1) install dev files
    if [[ $install_dev ]] ; then
            install.dev && check.dev || gmsg -x 160 "error during installing dev"
        fi

    # Step 6.2) install server files
    if [[ "$install_platform" == "server" ]] ; then
            install.server && check.server || gmsg -x 200 "error during installing server"
        fi

    # Step 6.3) install phone files
    if [[ "$install_platform" == "phone" ]] ; then
            install.phone && check.phone || gmsg -x 210 "error during installing server"
        fi

    # Step 7) install modules
    install.modules && check.modules || gmsg -x 170 "error when installing modules"

    # Step 8) set up launcher
    ln -f -s "$TARGET_BIN/core.sh" "$TARGET_BIN/$GURU_CALL" || gmsg -x 180 "core linking error"

    # Step 9) export user configuration
    install.config || gmsg -x 180 "user configuration error"

    # Step 10) save information and done

    # TODO: collect all files with locations copied to system
    installed_files=()
    echo "${installed_files[@]}" > "$GURU_CFG/installed.files"

    # list of installed modules
    # TODO: now modules list is mest up when dev installed
    installed_modules=("${modules_to_install[@]}" "${core_modules[@]}" "${server_modules[@]}" "${test_modules[@]}" "${foray_modules[@]}")
    echo "${installed_modules[@]}" > "$GURU_CFG/installed.modules"
    gmsg -v1 -c light_blue "installed ${#installed_modules[@]} modules: $(echo ${installed_modules[@]})"
    # pass
    echo "$($TARGET_BIN/core.sh version) installed"
}


install.help () {
    gmsg -c white "guru-client install help "
    gmsg
    gmsg "usage:    ./install.sh -f|-r|-d|-v|-V|-h|-p [desktop|laptop|server|phone] |-u <user>"
    gmsg
    gmsg -c white "flags:"
    gmsg " -f               force re-install "
    gmsg " -u <user>        set user name "
    gmsg " -p [platform]    select installation platform: desktop|laptop|server|phone "
    gmsg " -d               install also dev stuff "
    gmsg " -r               install all module requirements (experimental)"
    gmsg " -v               low verbose (normally quite silent) "
    gmsg " -V               high verbose "
    gmsg " -h               print this help "
    gmsg
    gmsg -c white "example:"
    gmsg "          ./install.sh -dfV -u $USER"
    return 0
}


install.arguments () {
    ## Process flags and arguments
    install_platform=$2
    TEMP=`getopt --long -o "dfrvVhu:p:" "$@"`
    eval set -- "$TEMP"
    while true ; do
        case "$1" in
            -d) install_dev=true           ; shift ;;
            -f) force_overwrite=true       ; shift ;;
            -r) install_requiremets=true   ; shift ;;
            -v) export GURU_VERBOSE=1      ; shift ;;
            -V) export GURU_VERBOSE=2      ; shift ;;
            -h) install.help               ; shift ;;
            -u) export GURU_USER=$2        ; shift 2 ;;
            -p) export install_platform=$2 ; shift 2 ;;
             *) break
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
    if grep -q "gururc" "$bash_rc" ; then
        [[ $force_overwrite ]] && answer="y" ||read -p "already installed, force re-install [y/n] : " answer

        if ! [[ "$answer" == "y" ]]; then
                gmsg -c red -x 2 "aborting.."
            fi

        if [[ -f "$TARGET_BIN/uninstall.sh" ]] ; then
                $TARGET_BIN/uninstall.sh
            else
                gmsg "using package uninstaller"
                ./core/uninstall.sh
            fi
    fi
    return 0
}


install.rcfiles () {
    ## Set up dot rc files
    gmsg -n -v1 "setting up launchers.. "
    # Check is .gururc called in .bashrc, add call if not # /etc/skel/.bashrc
    [[ -f "$HOME/.bashrc.giobackup" ]]  || cp -f "$bash_rc" "$HOME/.bashrc.giobackup"
    # make a backup of original .bashrc only if installed first time
    if ! grep -q ".gururc" "$bash_rc" ; then
            printf "# guru-client launcher to bashrc \n\nif [[ -f ~/.gururc2 ]] ; then \n    source ~/.gururc2\nfi\n" >>"$bash_rc"
        fi
    # pass
    gmsg -v1 -c green "DONE"
    return 0

}


check.rcfiles () {
    # check that rc files were installed
    gmsg -n -v1 "checking launchers.. "
    grep -q "gururc" "$bash_rc"       || gmsg -c red -x 122 ".bashrc modification error"
    [[ -f "$HOME/.bashrc.giobackup" ]]  || gmsg "warning: .bashrc backup file creation failure"
    # pass
    gmsg -v1 -c green "PASSED"
    return 0
}


install.folders () {
    # create forlders
    gmsg -n -v1 "setting up folder structure.. "
    # make bin folder for scripts, configs and and apps
    [[ -d "$TARGET_BIN" ]] || mkdir -p "$TARGET_BIN"
    # personal configurations
    [[ -d "$GURU_CFG/$GURU_USER" ]] || mkdir -p "$GURU_CFG/$GURU_USER"
    # pass
    gmsg -v1 -c green "DONE"
    return 0
}


check.folders () {
    # check that folders were created
    gmsg -n -v1 "checking created folders.. "
    [[ -d "$TARGET_BIN" ]] || gmsg -x 141 -c red "failed: bin folder creation error"
    [[ -d "$GURU_CFG/$GURU_USER" ]] || gmsg -x 143 -c red "failed: configuration folder creation error"
    # pass
    gmsg -v1 -c green "PASSED"
    return 0
}


install.core () {
    # install core files
    gmsg -n -v1 "copying core files.. "
    # copy configuration files to configuration folder
    cp -f cfg/* "$GURU_CFG"
    # copy script files to bin folder
    cp -f -r core/* -f "$TARGET_BIN"

    gmsg -v1 -c green "DONE"
    return 0
}


check.core () {
    # check core were installed
    gmsg -v1 -c white "checking core modules"
    for _file in $(ls core) ; do
            gmsg -n -v2 "$_file.. "
            if [[ -f $TARGET_BIN/$_file ]] ; then
                gmsg -v2 -c green "OK"
            else
                gmsg -c red "warning: core module $_file missing"
            fi
        done

    gmsg -v1 -c white "checking configuration files"
    for _file in $(ls cfg) ; do
            gmsg -n -v2 "$_file.. "
            if [[ -f $GURU_CFG/$_file ]] ; then
                gmsg -v2 -c green "OK"
            else
                gmsg -c yellow "warning: configuration file $_file missing"
            fi
        done
    # pass
   return 0

}


install.dev () {
    # if dev, install trials and all modules

    # include all modules to install list, do not copy yet
    gmsg -n -v1 -c white "adding dev files to copy list"
    modules_to_install=$(ls modules | cut -f1 -d ".")

    # copy foray modules
    foray_modules=$(ls foray | cut -f1 -d ".")
    cp -f -r foray/* -f "$TARGET_BIN" && gmsg -v1 -c green "DONE"

    # copy test system
    gmsg -n -v1 -c white "copying test system.."
    test_modules=$(ls test | cut -f1 -d ".")
    cp -f -r test -f "$TARGET_BIN" && gmsg -v1 -c green "DONE"
    return 0
}


check.dev () {



    # check installed tester files
    gmsg -v1 -c white "checking tester module"
    for _file in $(ls test) ; do
            gmsg -n -v2 "$_file.. "
            if [[ -f $TARGET_BIN/test/$_file ]] ; then
                gmsg -v2 -c green "OK"
            else
                gmsg -c yellow "warning: tester file $_file missing"
            fi
        done
    # pass
    return 0
}


install.server () {
    # install server files
    gmsg -n -v1 -c white "copying server files.. "
    # make list of modules
    server_modules=($(ls server | cut -f1 -d "."))
    # # include all modules to install list
    cp -f -r server/* -f "$TARGET_BIN" && gmsg -v1 -c green "DONE" #|| return 100
    return 0
}


check.server () {
    # check installed server files
    gmsg -v1 -c white "checking server files"
    for _file in "${server_modules[@]}" ; do
            gmsg -n -v2 "$_file.. "
            if ls $TARGET_BIN/$_file* >/dev/null; then
                gmsg -v2 -c green "OK"
            else
                gmsg -c yellow "warning: server file $_file missing"
                # continue anuweay
            fi
        done
    # pass
    return 0
}


install.phone () {
    gmsg -c blue "$FUNCNAME TBD"
    return 0
}


check.phone () {
    gmsg -c blue "$FUNCNAME TBD"
    return 0
}



install.modules () {
    # install modules
    gmsg  -v1 -c white "installing modules"
    for _module in ${modules_to_install[@]} ; do
        gmsg -n -v2 "installing $_module.. "
        module_file=$(ls modules/$_module.*)
        if [[ -f $module_file ]] ; then
                cp -f -r modules/$_module.* "$TARGET_BIN" && gmsg -v2 -c green "DONE"
                [[ $install_requiremets ]] && gask "install module $_module requirements" && $module_file install
            fi
        done
    # pass
    return 0
}


check.modules () {

    # check installed modules (foray folder is not monitored)
    gmsg -v1 -c white "checking installed modules"
    for _file in  ${modules_to_install[@]} ; do
            gmsg -n -v2 "$_file.. "
            if ls $TARGET_BIN/$_file* >/dev/null ; then
                gmsg -v2 -c green "OK"
            else
                gmsg -c yellow "warning: module $_file missing"
            fi
        done
    # pass
    return 0
}


install.config () {

    gmsg -v1 -c white "setting user configurations "
    if ! [[ -f "$GURU_CFG/$GURU_USER/user.cfg" ]] ; then
         gmsg -c yellow "user specific configuration not found, using default.."
         cp -f $GURU_CFG/user-default.cfg "$GURU_CFG/$GURU_USER/user.cfg" || gmsg -c red -x 181 "default user configuration failed"
    fi
    config.export "$GURU_USER" || gmsg -c red -x 182 "user config export error"
    source "$HOME/.gururc2" || gmsg -c red -x 183 ".gururc2 file error"
    #config.main pull || gmsg -x 182 "remote user configuration failed" Not yet guru.server needs to exist first
    # set keyboard shortcuts
    keyboard.main add all
    return 0
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        install.main $@
        exit "$?"
fi






