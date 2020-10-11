#!/bin/bash
# installer for guru-client. ujo.guru casa@ujo.guru 2017-2020
GURU_CALL="guru"
GURU_USER="$USER"
# make allf function/module calls point to installer's version
export GURU_BIN="./core"
GURU_CFG=$HOME/.config/guru
TARGET_BIN=$HOME/bin

# check if colors possible
if echo "$TERM" | grep "256" >/dev/null ; then
    if echo "$COLORTERM" | grep "true" >/dev/null ; then
            GURU_FLAG_COLOR=true
        fi
    fi

# set only needed colors
if [[ "$GURU_FLAG_COLOR" ]] ; then
pass
    fi

# use new modules durin installation
source core/common.sh
source core/config.sh
source core/keyboard.sh
# to where add gururc call
bash_rc="$HOME/.bashrc"
core_rc="$HOME/.gururc2"    # TODO change name to '.gururc' when cleanup next time

# modify this when module is ready to publish. flag -d will overwrite this list and install all present modules
modules_to_install=(mount mqtt note android print project scan ssh stamp tag timer tor trans user vol yle news)
# default install platform available: desktop|laptop|server|phone
install_platform="desktop"


install.main () {

    # Step 1) parse arguments
    install.arguments $@ || gmsg -x 100 "argumentation error"

    # Step 2) check previous installation
    install.check || gmsg -x 110 "check caused exit"
    gmsg -v0 -c white "installing guru-client"
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
            install.phone && check.phone || gmsg -x 210 "error during installing phone"
        fi

    # Step 7) install modules
    install.modules && check.modules || gmsg -x 170 "error when installing modules"

    # Step 8) set up launcher
    ln -f -s "$TARGET_BIN/core.sh" "$TARGET_BIN/$GURU_CALL" || gmsg -x 180 "core linking error"

    # Step 9) export user configuration
    install.config || gmsg -x 180 "user configuration error"

    # Step 10) save information and done
    # TODO: now modules list is mest up when dev installed

    gmsg -c white "$($TARGET_BIN/core.sh version) installed"


    # printout and save core statistics
    gmsg -v1 -c light_blue "installed ${#installed_core[@]} core scripts"
    gmsg -v2 -c grey "${installed_core[@]}"
    echo "${installed_core[@]}" > "$GURU_CFG/installed.core"

    # printout and save module statistics
    gmsg -v1 -c light_blue "installed ${#installed_modules[@]} modules"
    gmsg -v2 -c grey "${installed_modules[@]}"
    echo "${installed_modules[@]}" > "$GURU_CFG/installed.modules"

    # printout and save modified files
    gmsg -v1 -c light_blue "modified ${#modified_files[@]} file(s)"
    gmsg -v2 -c grey "${modified_files[@]}"
    echo "${modified_files[@]}" > "$GURU_CFG/modified.files"

    # printout file statistics
    gmsg -v1 -c light_blue "copied ${#installed_files[@]} files"
    gmsg -v2 -c grey "${installed_files[@]}"
    echo "${installed_files[@]}" > "$GURU_CFG/installed.files"

    # pass
    return 0
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


install.copy () {
    # copy folders witout subfolders from source to target and keep track of copied files
    local _from="$1" ; shift
    local _to="$1" ; shift
    gmsg -n -v1 "$@ " ; gmsg -v2
    _file_list=( $(ls $_from/*) )
    for _file_to_copy in "${_file_list[@]}" ; do
            if cp -r -f "$_file_to_copy" "$_to" ; then
                gmsg -v1 -V2 -n -c grey "."
                gmsg -v2 -c grey "$_file_to_copy"
                installed_files=( ${installed_files[@]} ${_file_to_copy//$_from/$_to} )
            else
                gmsg -N -c yellow "$_file_to_copy copy failed"
             fi
        done
    gmsg -v1 -V2 -c green " done"
    return 0
}


install.check () {
    ## Check installation, reinstall if -f or user input
    gmsg  -v1 "checking current installation.. "
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
    gmsg -n -v1 "setting up launchers "
    # Check is .gururc called in .bashrc, add call if not # /etc/skel/.bashrc
    [[ -f "$HOME/.bashrc.giobackup" ]]  || cp -f "$bash_rc" "$HOME/.bashrc.giobackup"
    # make a backup of original .bashrc only if installed first time
    if ! grep -q ".gururc" "$bash_rc" ; then
            printf "# guru-client launcher to bashrc \n\nif [[ -f ~/.gururc2 ]] ; then \n    source ~/.gururc2\nfi\n" >>"$bash_rc"
        fi
    # pass
    installed_files=(${installed_files[@]} "$HOME/.bashrc.giobackup")
    gmsg -v1 -c green "done"
    return 0
}


check.rcfiles () {
    # check that rc files were installed
    gmsg -n -v1 "checking launchers " ; gmsg -v2

    gmsg -n -v1 -V2 -c grey "." ; gmsg -v2 -n -c grey "$bash_rc"
    if grep -q "gururc" "$bash_rc" ; then
            modified_files=(${modified_files[@]} "$bash_rc")
            gmsg  -v2 -c green " ok"
        else
            gmsg -c red -x 122 ".bashrc modification error"
        fi

    gmsg -n -v1 -V2 -c grey "." ; gmsg -v2 -n -c grey "$HOME/.bashrc.giobackup"
    if [[ -f "$HOME/.bashrc.giobackup" ]] ; then
            gmsg -v2 -c green " ok"
        else
            gmsg "warning: .bashrc backup file creation failure"
        fi

    # pass
    gmsg -V2 -v1 -c green " ok"
    return 0
}


install.folders () {
    # create forlders
    gmsg -n -v1 "setting up folder structure " ; gmsg -v2

    # make bin folder for scripts, configs and and apps
    [[ -d "$TARGET_BIN" ]] || mkdir -p "$TARGET_BIN"
    gmsg -n -v1 -V2 -c grey "." ; gmsg -v2 -c grey "$GURU_CFG/$TARGET_BIN"

    # personal configurations
    [[ -d "$GURU_CFG/$GURU_USER" ]] || mkdir -p "$GURU_CFG/$GURU_USER"
    gmsg -n -v1 -V2 -c grey "." ; gmsg -v2 -c grey "$GURU_CFG/$GURU_USER"

    # pass
    gmsg -V2 -v1 -c green " done"
    return 0
}


check.folders () {
    # check that folders were created
    gmsg -n -v1 "checking created folders " ; gmsg -v2

    gmsg -n -v1 -V2 -c grey "." ; gmsg -n -v2 -c grey "$TARGET_BIN"
    if [[ -d "$TARGET_BIN" ]] ; then
            gmsg -v2 -c green " ok"
        else
            gmsg -x 141 -c red "failed: bin folder creation error"
        fi


    gmsg -n -v1 -V2 -c grey "." ; gmsg -n -v2 -c grey "$GURU_CFG/$GURU_USER"
    if [[ -d "$GURU_CFG/$GURU_USER" ]] ; then
            gmsg  -v2 -c green " ok"
        else
            gmsg -x 143 -c red "failed: configuration folder creation error"
        fi
    # pass
    gmsg -V2 -v1 -c green " ok"
    return 0
}



install.core () {
    # install core files
    install.copy cfg $GURU_CFG "copying configurations"
    install.copy core $TARGET_BIN "copying core files"
    installed_core=( ${installed_core[@]} $(ls core | cut -f1 -d '.') )
    installed_modules=( ${installed_modules[@]} core )
    return 0
}

check.core () {
    # check core were installed
    gmsg -n -v1 "checking core modules" ; gmsg -v2
    for _file in $(ls core) ; do
            gmsg -v1 -V2 -n -c grey "."
            gmsg -n -v2 -c grey "$_file"
            if [[ -f $TARGET_BIN/$_file ]] ; then
                gmsg -v2 -c green " ok"
            else
                gmsg -c red "warning: core module $_file missing"
            fi
        done
    gmsg -v1 -V2 -c green " ok"

    gmsg -n -v1 "checking configuration files " ; gmsg -v2
    for _file in $(ls cfg) ; do
            gmsg -v1 -V2 -n -c grey "."
            gmsg -n -v2 -c grey "$_file"
            if [[ -f $GURU_CFG/$_file ]] ; then
                gmsg -v2 -c green " ok"
            else
                gmsg -c yellow "warning: configuration file $_file missing"
            fi
        done
    # pass
   gmsg -v1 -V2 -c green " ok"
   return 0

}

install.dev () {
    # install foray, test and all modules

    # include all modules to install list, do not copy yet
    gmsg -v1 "adding dev files to copy list "
    modules_to_install=( $(ls modules | cut -f1 -d '.') )

    # copy foray modules
    install.copy "foray" "$TARGET_BIN" "copying trial scripts"
    installed_modules=( ${installed_modules[@]} $(ls foray | cut -f1 -d '.') )

    # copy test system
    test_modules=$(ls test | cut -f1 -d ".")
    install.copy "test" "$TARGET_BIN" "copying test system"
    installed_modules=( ${installed_modules[@]} test )
    return 0
}


check.dev () {
    # check installed tester files
    gmsg -v1 "checking tester module"
    for _file in $(ls test) ; do
            gmsg -n -v2 -c grey "$_file.. "
            if [[ -f $TARGET_BIN/$_file ]] ; then
                gmsg -v2 -c green "ok"
            else
                gmsg -c yellow "warning: tester file $_file missing"
            fi
        done
    # pass
    return 0
}


install.server () {
    # install server files
    server_modules=()
    install.copy "server" "$TARGET_BIN" "copying server files"
    installed_modules=( ${installed_modules[@]} $(ls server | cut -f1 -d '.') )
    return 0
}


check.server () {
    # check installed server files
    gmsg -v1 "checking server files"
    for _file in "${server_modules[@]}" ; do
            gmsg -n -v2 -c grey  "$_file.. "
            if ls $TARGET_BIN/$_file* >/dev/null; then
                gmsg -v2 -c green "ok"
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
    gmsg -n -v1 "installing modules " ; gmsg -v2

    for _module in ${modules_to_install[@]} ; do
        gmsg -n -v1 -V2 -c grey "."
        gmsg -n -v2 -c grey "$_module "
        module_file=$(ls modules/$_module.*)

        if [[ -f $module_file ]] ; then

                if cp -f -r modules/$_module.* "$TARGET_BIN" ; then
                        gmsg -v2 -c green "done"
                    else
                        gmsg -c yellow "module copy error"
                    fi

                [[ $install_requiremets ]] && gask "install module $_module requirements" && $module_file install
                installed_files=("${installed_files[@]} ${_module_file}")
                installed_modules=( ${installed_modules[@]} ${_module} )
            fi
        done
    # pass
    gmsg -v1 -V2 -c green " done"
    return 0
}


check.modules () {
    # check installed modules (foray folder is not monitored)
    gmsg -n -v1 "checking installed modules " ; gmsg -v2
    for _file in  ${modules_to_install[@]} ; do
            gmsg -n -v2 -c grey "$_file"
            gmsg -n -v1 -V2 -c grey "."
            if ls $TARGET_BIN/$_file* >/dev/null ; then
                gmsg -v2 -c green " ok"
            else
                gmsg -c yellow "warning: module $_file missing"
            fi
        done
    # pass
    gmsg -v1 -V2 -c green " ok"
    return 0
}


install.config () {
    # config
    gmsg -v1 -c white "user configurations "
    if ! [[ -f "$GURU_CFG/$GURU_USER/user.cfg" ]] ; then
         gmsg -c yellow "user specific configuration not found, using default.."
         cp -f $GURU_CFG/user-default.cfg "$GURU_CFG/$GURU_USER/user.cfg" || gmsg -c red -x 181 "default user configuration failed"
    fi
    config.export "$GURU_USER" || gmsg -c red -x 182 "user config export error"
    source "$HOME/.gururc2" || gmsg -c red -x 183 ".gururc2 file error"
    #config.main pull || gmsg -x 182 "remote user configuration failed" Not yet guru.server needs to exist first

    # set keyboard shortcuts
    gmsg -n -v1 "setting keyboard shortcuts "
    keyboard.main add all || gmsg -c yellow "error by setting keyboard shortcuts"

    return 0
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        install.main $@
        exit "$?"
fi

