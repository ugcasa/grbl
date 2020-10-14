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
        C_NORMAL='\033[0m'
        C_GRAY='\033[38;2;169;169;169m'
        C_GREY='\033[38;2;169;169;169m'
        C_DARK_GRAY='\033[38;2;128;128;128m'
        C_DARK_GREY='\033[38;2;128;128;128m'
        C_GREEN='\033[38;2;0;128;0m'
        C_RED='\033[38;2;255;0;0m'
        C_LIGHT_BLUE='\033[38;2;173;216;230m'
        C_WHITE='\033[38;2;255;255;255m'
    fi

# use new modules durin installation
source core/common.sh
source core/config.sh
source core/keyboard.sh
# to where add gururc call
bash_rc="$HOME/.bashrc"
core_rc="$HOME/.gururc2"    # TODO change name to '.gururc' when cleanup next time
backup_rc="$HOME/.bashrc.backup-by-guru"

# modules where user have direct access
core_module_access=(counter install uninstall config corsair daemon keyboard remote system)

# modify this when module is ready to publish. flag -d will overwrite this list and install all present modules
modules_to_install=(mount mqtt note android print project scan ssh stamp file timer tor trans user vol yle news)

install.main () {

    # Step 1) parse arguments
    install.arguments $@ || gmsg -x 100 "argumentation error"

    # Step 2) check previous installation
    install.check || gmsg -x 110 "check caused exit"
    gmsg -v0 -c white "installing guru-client"
    gmsg -v2 "user: $GURU_USER"

    # Step 3) modify and add .rc files
    install.rcfiles || gmsg -x 120 "rc file modification error"
    check.rcfiles

    # Step 4) create folder structure
    install.folders || gmsg -x 140 "error during creating folders"
    check.folders

    # Step 5) install core
    install.core || gmsg -x 150 "error during installing core"
    check.core

    # Step 6) install options

    # development stuff (flag: -d)
    if [[ $install_dev ]] ; then
            install.dev || gmsg -x 160 "error during installing dev"
            check.dev
        fi

    # platform related stuff (flag: -p <platform>)
    case $install_platform in
            server|phone|raspi)
                    install.$install_platform || gmsg -c yellow "warning: something went wrong while installing $install_platform" ;;
            *)      install.desktop          || gmsg -c yellow "warning: something went wrong while installing $install_platform" ;;
        esac

    # Step 7) install modules
    install.modules && check.modules || gmsg -x 170 "error when installing modules"

    # Step 8) set up launcher
    ln -f -s "$TARGET_BIN/core.sh" "$TARGET_BIN/$GURU_CALL" || gmsg -x 180 "core linking error"


    # Step 9) save information

    # save core statistics
    # instead of including all modules include only where user needs to have access.
    # this avoid need to write main, help and status functions what are needed to perform mass function calls
    echo "${core_module_access[@]}" > "$GURU_CFG/installed.core"

    # save module statistics
    echo "${installed_modules[@]}" > "$GURU_CFG/installed.modules"

    # save modified files
    echo "${modified_files[@]}" > "$GURU_CFG/modified.files"

    # save file statistics
    echo "${installed_files[@]}" > "$GURU_CFG/installed.files"

    # Step 10) export user configuration
    install.config || gmsg -x 180 "user configuration error"


    # printout pass and statistics if verbose set
    gmsg -c white "$($TARGET_BIN/core.sh version) installed"

    gmsg -v1 -c light_blue "installed ${#installed_core[@]} core modules"
    gmsg -v2 -c dark_grey "${installed_core[@]}"

    gmsg -v1 -c light_blue "installed ${#installed_modules[@]} modules"
    gmsg -v2 -c dark_grey "${installed_modules[@]}"

    gmsg -v1 -c light_blue "modified ${#modified_files[@]} file(s)"
    gmsg -v2 -c dark_grey "${modified_files[@]}"

    gmsg -v1 -c light_blue "copied ${#installed_files[@]} files"
    gmsg -v2 -c dark_grey "${installed_files[@]}"

    # pass
    return 0
}


install.desktop () {
    gmsg -v2 -c navy "$FUNCNAME TBD"
    return 0
}

install.server () {
    # add server module to install list
    modules_to_install=( ${modules_to_install[@]} "server" )
    return 0
}


check.server () {
    # check installed server files
    gmsg -v1 "checking server files"
    local _server_files=($(ls modules/server/*))

    for _file in "${_server_files[@]//'modules/'/$TARGET_BIN}" ; do
            gmsg -n -v2 -c grey  "$_file.. "
            if [[ $_file ]]; then
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
    gmsg -v2 -c navy "$FUNCNAME TBD"
    return 0
}


check.phone () {
    gmsg -v2 -c navy "$FUNCNAME TBD"
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

    local _arg="$@"
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
                installed_files=( ${installed_files[@]} ${_file_to_copy/$_from/$_to} )
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

    gmsg -n -v1 "setting rcfiles "
    #Check is .gururc called in .bashrc, add call if not # /etc/skel/.bashrc
    [[ -f "$backup_rc" ]] || cp -f "$bash_rc" "$backup_rc"
    # make a backup of original .bashrc only if installed first time
    if ! grep -q ".gururc" "$bash_rc" >/dev/null ; then
            printf "# guru-client launcher to bashrc \n\nif [[ -f ~/.gururc2 ]] ; then \n    source ~/.gururc2\nfi\n" >>"$bash_rc"
        fi
    # pass
    installed_files=(${installed_files[@]} "$backup_rc")
    modified_files=(${modified_files[@]} "$backup_rc")
    gmsg -v1 -c green "done"
    return 0
}


check.rcfiles () {
    # check that rc files were installed
    gmsg -n -v1 "checking rcfiles " ; gmsg -v2

    gmsg -n -v1 -V2 -c grey "." ; gmsg -v2 -n -c grey "$bash_rc "
    if grep -q "gururc" "$bash_rc" ; then
            modified_files=(${modified_files[@]} "$bash_rc")
            gmsg  -v2 -c green "ok"
        else
            gmsg -c red -x 122 ".bashrc modification error"
        fi

    gmsg -n -v1 -V2 -c grey "." ; gmsg -v2 -n -c grey "$backup_rc"
    if [[ -f "$backup_rc" ]] ; then
            gmsg -v1 -c green " ok"
        else
            gmsg "warning: .bashrc backup file creation failure"
        fi

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
    gmsg -v1 "adding development files to copy list "
    modules_to_install=($(ls modules -p | grep -v / | cut -f1 -d '.'))

    # copy foray modules
    install.copy "foray" "$TARGET_BIN" "copying trial scripts"
    return 0
}


check.dev () {
    # check installed tester files
    gmsg -v1 "checking development files"
    local _modules_to_install=($(ls foray -p | grep -v /))

    for _file in ${_modules_to_install[@]} ; do

            gmsg -n -v2 -c grey "$_file.. "
            if [[ -f $TARGET_BIN/$_file ]] ; then
                gmsg -v2 -c green "ok"
            else
                gmsg -c yellow "warning: development file $_file missing"
            fi
        done
    # pass
    return 0
}



install.modules () {
    # install modules
    gmsg -n -v1 "installing modules " ; gmsg -v2

    for _module in ${modules_to_install[@]} ; do
        module_file=$(ls modules/$_module.* 2>&1 |head -1 )
        gmsg -n -v1 -V2 -c grey "."
        gmsg -n -v2 -c grey "${module_file#*/} "

        if [[ -f $module_file ]] ; then
                # copy adapter
                if cp -f -r $module_file "$TARGET_BIN" ; then
                        gmsg -v2 -c green "done"
                    else
                        gmsg -c yellow "module $_module adapter copy error"
                    fi

                # install module requirements
                [[ $install_requiremets ]] && gask "install module $_module requirements" && $module_file install

                # add to file list, replace source folder to target folder
                installed_files=( ${installed_files[@]} $TARGET_BIN/${module_file#*/} )
                installed_modules=( ${installed_modules[@]} ${_module} )
                #gmsg -c deep_pink "${installed_files[@]}"
            else
                gmsg -n -v2 -c yellow "error "
                gmsg -v2 "module adapter '$_module.sh' missing or module not exist"
            fi


        # copy workers
        if [[ -d modules/$_module ]] ; then
                #gmsg -n -v2 -c grey " copying $_module files.. "
                [[ -d $TARGET_BIN/$_module ]] || mkdir "$TARGET_BIN/$_module"
                local module_files=( $(ls modules/$_module/*) )

                for _file in ${module_files[@]} ; do
                    _target_file=${_file/"modules/"/"$TARGET_BIN/"}
                    gmsg -n -v2 -c grey "  ${_file#*/} "
                    if cp -f "$_file" "$_target_file" ; then
                            installed_files=( ${installed_files[@]} $_target_file)
                            #gmsg -c deep_pink "${installed_files[@]}"
                            gmsg -n -v1 -V2 -c dark_grey "."
                            gmsg -v2 -c green "done"
                        else
                            gmsg -c yellow "module $_module folder copying error"
                        fi
                done


            fi

        done
    # pass
    gmsg -v1 -V2 -c green " done"
    return 0
}


check.modules () {
    # check installed modules (foray folder is not monitored)
    gmsg -n -v1 "checking installed modules " ; gmsg -v2
    for _module in  ${modules_to_install[@]} ; do
            gmsg -n -v2 -c grey "$_module "
            gmsg -n -v1 -V2 -c grey "."
            if ls $TARGET_BIN/$_module* >/dev/null ; then
                gmsg -v2 -c green "ok"
            else
                gmsg -c yellow "warning: module $_module missing"
            fi
        done
    # pass
    gmsg -v1 -V2 -c green "ok"
    return 0
}


install.config () {
    # config
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

