#!/bin/bash
# installer for guru-client. ujo.guru casa@ujo.guru 2017-2020
export GURU_CALL="guru"
export GURU_USER="$USER"
TARGET_BIN="$HOME/bin"
TARGET_CFG="$HOME/.config/guru"

# check if colors possible
if echo "$TERM" | grep "256" >/dev/null ; then
    if echo "$COLORTERM" | grep "true" >/dev/null ; then
        GURU_FLAG_COLOR=true
            # set only needed colors
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
    fi


# use new modules durin installation
export GURU_BIN="core"
#source core/common.sh
source $GURU_BIN/config.sh
source $GURU_BIN/keyboard.sh
source $GURU_BIN/system.sh
# set target locations for uninstaller
export GURU_CFG="$HOME/.config/guru"
export GURU_BIN="$HOME/bin"
# to where add gururc call
bash_rc="$HOME/.bashrc"
core_rc="$HOME/.gururc"    # TODO change name to '.gururc' when cleanup next time
backup_rc="$HOME/.bashrc.backup-by-guru"
# modules where user have direct access
core_module_access=(net counter install uninstall config mount unmount daemon keyboard system path)
# modify this when module is ready to publish. flag -d will overwrite this list and install all present modules
modules_to_install=(mqtt fingrid note android print project scan audio display vpn ssh stamp tag timer tor trans user vol yle news program tmux tunnel corsair backup convert telegram cal place)

# TBD
# client_modules=
# server_modules=(towsdf)

install.main () {

    # Step 1) parse arguments
    install.arguments $@ || gr.msg -x 100 "argumentation error"

    # store current core rc if not no port install configure

    # Step 2) check and uninstall previous version
    install.check || gr.msg -x 110 "check caused exit"

    # return
    gr.msg -v1 -c white "installing $(core/core.sh version)"

    # Step 3) modify and add .rc files
    install.rcfiles || gr.msg -x 120 "rc file modification error"
    check.rcfiles

    # Step 4) create folder structure
    install.folders || gr.msg -x 140 "error during creating folders"
    check.folders

    # Step 5) install core
    install.core || gr.msg -x 150 "error during installing core"
    check.core

    # Step 6) install options

    # development stuff (flag: -d)
    if [[ $install_dev ]] ; then
            install.dev || gr.msg -x 160 "error during installing dev"
            #check.dev
        fi

    # platform related stuff (flag: -p <platform>)
    case $install_platform in
            server|phone|raspi)
                    install.$install_platform \
                        || gr.msg -c yellow "warning: something went wrong while installing $install_platform" ;;
            *)      install.desktop \
                        || gr.msg -c yellow "warning: something went wrong while installing $install_platform" ;;
        esac

    # Step 7) install modules
    install.modules && check.modules || gr.msg -x 170 "error when installing modules"

    # Step 8) set up launcher
    ln -f -s "$TARGET_BIN/core.sh" "$TARGET_BIN/$GURU_CALL" || gr.msg -x 180 "core linking error"

    # Step 9) save information

    # save core statistics
    # instead of including all modules include only where user needs to have access.
    # this avoid need to write main, help and status functions what are needed to perform mass function calls
    echo "${core_module_access[@]}" > "$TARGET_CFG/installed.core"

    # save module statistics
    echo "${installed_modules[@]}" > "$TARGET_CFG/installed.modules"

    # save modified files
    echo "${modified_files[@]}" > "$TARGET_CFG/modified.files"

    # save file statistics
    echo "${installed_files[@]}" > "$TARGET_CFG/installed.files"

    # Step 10) export user configuration
    install.config || gr.msg -x 180 "user configuration error"

    # printout pass and statistics if verbose set
    gr.msg -c white "guru-cli v$($TARGET_BIN/core.sh version) installed"

    gr.msg -v1 -c light_blue "installed ${#installed_core[@]} core modules"
    gr.msg -v2 -c dark_grey "${installed_core[@]}"

    gr.msg -v1 -c light_blue "installed ${#installed_modules[@]} modules"
    gr.msg -v2 -c dark_grey "${installed_modules[@]}"

    gr.msg -v1 -c light_blue "modified ${#modified_files[@]} file(s)"
    gr.msg -v2 -c dark_grey "${modified_files[@]}"

    gr.msg -v1 -c light_blue "copied ${#installed_files[@]} files"
    gr.msg -v2 -c dark_grey "${installed_files[@]}"

    if system.flag running ; then
            system.flag rm pause
            sleep 1
        fi
    # pass
    return 0
}


install.desktop () {
    gr.msg -v2 -c navy "$FUNCNAME TBD"
    return 0
}


install.server () {
    # add server module to install list
    modules_to_install=( ${modules_to_install[@]} "server" )
    return 0
}


check.server () {
    # check installed server files
    gr.msg -v1 "checking server files"
    local _server_files=($(ls modules/server/*))

    for _file in "${_server_files[@]//'modules/'/$TARGET_BIN}" ; do
            gr.msg -n -v2 -c grey  "$_file.. "
            if [[ $_file ]]; then
                    gr.msg -v2 -c green "ok"
                else
                    gr.msg -c yellow "warning: server file $_file missing"
                    # continue anuweay
            fi
        done
    # pass
    return 0
}


install.phone () {
    gr.msg -v2 -c navy "$FUNCNAME TBD"
    return 0
}


check.phone () {
    gr.msg -v2 -c navy "$FUNCNAME TBD"
    return 0
}


install.help () {
    gr.msg -c white "guru-client install help "
    gr.msg
    gr.msg "usage:    ./install.sh -f|-r|-d|-v|-V|-h|-p [desktop|laptop|server|phone] |-u <user>"
    gr.msg
    gr.msg -c white "flags:"
    gr.msg " -f               force re-install "
    gr.msg " -u <user>        set user name "
    gr.msg " -p [platform]    select installation platform: desktop|laptop|server|phone "
    gr.msg " -d               install also dev stuff "
    gr.msg " -r               install all module requirements (experimental)"
    gr.msg " -v 0..3          set verbose level "
    gr.msg " -h               print this help "
    gr.msg
    gr.msg -c white "example:"
    gr.msg "          ./install.sh -dfV -u $USER"
    return 0
}


install.arguments () {
    ## Process flags and arguments
    export GURU_VERBOSE=0

    TEMP=`getopt --long -o "dfcrhlsv:u:p:" "$@"`
    eval set -- "$TEMP"
    while true ; do
        case "$1" in
            -d) install_dev=true
                shift ;;
            -f) force_overwrite=true
                shift ;;
            -c) configure_after_install=true
                shift ;;
            -r) install_requiremets=true
                shift ;;
            -s) gr.msg "TBD"
                shift ;;
            -h) install.help
                shift ;;
            -l) export LIGTH_INSTALL=true
                shift ;;
            -v) export GURU_VERBOSE=$2
                shift 2 ;;
            -u) export GURU_USER=$2
                shift 2 ;;
            -p) export install_platform=$2
                shift 2 ;;
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
    gr.msg -n -v1 "$@ " ; gr.msg -v2

    _file_list=( $(ls $_from/*) )
    for _file_to_copy in "${_file_list[@]}" ; do
            if cp -rf "$_file_to_copy" "$_to" ; then
                    gr.msg -v1 -V2 -n -c grey "."
                    gr.msg -v2 -c grey "${_file_to_copy/$_from/$_to}"
                    installed_files=( ${installed_files[@]} ${_file_to_copy/$_from/$_to} )
                else
                    gr.msg -N -c yellow "$_file_to_copy copy failed"
                 fi
        done
    gr.msg -v1 -V2 -c green " done"
    return 0
}


install.check () {
    ## Check installation, reinstall if -f or user input
    gr.msg -v1 "checking current installation.. "
    if grep -q "gururc" "$bash_rc" ; then
        [[ $force_overwrite ]] && answer="y" ||read -p "already installed, force re-install [y/n] : " answer

        if ! [[ "$answer" == "y" ]]; then
                gr.msg -c red -x 2 "aborting.."
            fi

        if [[ $LIGTH_INSTALL ]] ; then
            install.core || gr.msg -x 150 "error during installing core"
            check.core
            install.modules && check.modules || gr.msg -x 170 "error when installing modules"
            exit 0
        fi

        if ! [[ $configure_after_install ]] && [[ -f $core_rc ]]; then
            cp $core_rc /tmp/temp.rc
        fi


        if [[ -f "$TARGET_BIN/uninstall.sh" ]] ; then
                $TARGET_BIN/uninstall.sh
            else
                gr.msg "using package uninstaller"
                ./core/uninstall.sh
            fi
    fi
    return 0
}


install.rcfiles () {

    gr.msg -n -v1 "setting rcfiles "
    #Check is .gururc called in .bashrc, add call if not # /etc/skel/.bashrc
    [[ -f "$backup_rc" ]] || cp -f "$bash_rc" "$backup_rc"
    # make a backup of original .bashrc only if installed first time
    if ! grep -q ".gururc" "$bash_rc" >/dev/null ; then
            printf "# guru-client launcher to bashrc \n\nif [[ -f ~/.gururc ]] ; then \n    source ~/.gururc\nfi\n" >>"$bash_rc"
        fi
    # pass
    installed_files=(${installed_files[@]} "$backup_rc")
    modified_files=(${modified_files[@]} "$backup_rc")
    gr.msg -v1 -c green "done"
    return 0
}


check.rcfiles () {
    # check that rc files were installed
    gr.msg -n -v1 "checking rcfiles " ; gr.msg -v2

    gr.msg -n -v1 -V2 -c grey "." ; gr.msg -v2 -n -c grey "$bash_rc "
    if grep -q "gururc" "$bash_rc" ; then
            modified_files=(${modified_files[@]} "$bash_rc")
            gr.msg  -v2 -c green "ok"
        else
            gr.msg -c red -x 122 ".bashrc modification error"
        fi

    gr.msg -n -v1 -V2 -c grey "." ; gr.msg -v2 -n -c grey "$backup_rc"
    if [[ -f "$backup_rc" ]] ; then
            gr.msg -v1 -c green " ok"
        else
            gr.msg "warning: .bashrc backup file creation failure"
        fi

    return 0
}


install.folders () {
    # create forlders
    gr.msg -n -v1 "setting up folder structure " ; gr.msg -v2

    # make bin folder for scripts, configs and and apps
    [[ -d "$TARGET_BIN" ]] || mkdir -p "$TARGET_BIN"
    gr.msg -n -v1 -V2 -c grey "." ; gr.msg -v2 -c grey "$TARGET_BIN"


    # personal configurations
    [[ -d "$TARGET_CFG/$GURU_USER" ]] || mkdir -p "$TARGET_CFG/$GURU_USER"
    gr.msg -n -v1 -V2 -c grey "." ; gr.msg -v2 -c grey "$TARGET_CFG/$GURU_USER"



    # pass
    gr.msg -V2 -v1 -c green " done"
    return 0
}


check.folders () {
    # check that folders were created
    gr.msg -n -v1 "checking created folders " ; gr.msg -v2

    gr.msg -n -v1 -V2 -c grey "." ; gr.msg -n -v2 -c grey "$TARGET_BIN"
    if [[ -d "$TARGET_BIN" ]] ; then
            gr.msg -v2 -c green " ok"
        else
            gr.msg -x 141 -c red "failed: bin folder creation error"
        fi


    gr.msg -n -v1 -V2 -c grey "." ; gr.msg -n -v2 -c grey "$TARGET_CFG/$GURU_USER"
    if [[ -d "$TARGET_CFG/$GURU_USER" ]] ; then

            gr.msg  -v2 -c green " ok"

        else
            gr.msg -x 143 -c red "failed: configuration folder creation error"
        fi
    # pass
    gr.msg -V2 -v1 -c green " ok"
    return 0
}


install.core () {
    # install core files
    install.copy cfg $TARGET_CFG "copying configurations"
    install.copy core $TARGET_BIN "copying core files"

    cp version $TARGET_BIN

    installed_core=( ${installed_core[@]} $(ls core | cut -f1 -d '.') )
    return 0
}


check.core () {
    # check core were installed
    gr.msg -n -v1 "checking core modules" ; gr.msg -v2
    for _file in $(ls core) ; do
            gr.msg -v1 -V2 -n -c grey "."
            gr.msg -n -v2 -c grey "$_file"
            if [[ -f $TARGET_BIN/$_file ]] ; then
                gr.msg -v2 -c green " ok"
            else
                gr.msg -c red "warning: core module $_file missing"
            fi
        done
    gr.msg -v1 -V2 -c green " ok"

    gr.msg -n -v1 "checking configuration files " ; gr.msg -v2
    for _file in $(ls cfg) ; do
            gr.msg -v1 -V2 -n -c grey "."
            gr.msg -n -v2 -c grey "$_file"
            if [[ -f $TARGET_CFG/$_file ]] ; then
                gr.msg -v2 -c green " ok"

            else
                gr.msg -c yellow "warning: configuration file $_file missing"
            fi
        done
    # pass
   gr.msg -v1 -V2 -c green " ok"
   return 0

}


install.dev () {
    # install foray, test and all modules

    # include all modules to install list, do not copy yet
    gr.msg -v1 "adding development files to copy list "
    modules_to_install=($(ls modules -p | grep -v / | cut -f1 -d '.'))

    # copy foray modules
    # install.copy "foray" "$TARGET_BIN" "copying trial scripts"
    return 0
}


# check.dev () {
#     # check installed tester files
#     gr.msg -v1 "checking development files"
#     local _modules_to_install=($(ls foray -p | grep -v /))

#     for _file in ${_modules_to_install[@]} ; do

#             gr.msg -n -v2 -c grey "$_file.. "
#             if [[ -f $TARGET_BIN/$_file ]] ; then
#                 gr.msg -v2 -c green "ok"
#             else
#                 gr.msg -c yellow "warning: development file $_file missing"
#             fi
#         done
#     # pass
#     return 0
# }


install.modules () {
    # install modules
    gr.msg -n -v1 "installing modules " ; gr.msg -v2

    for _module in ${modules_to_install[@]} ; do
        module_file=$(ls modules/$_module.* 2>&1 |head -1 )
        gr.msg -n -v1 -V2 -c grey "."
        gr.msg -n -v2 -c grey "${module_file#*/} "

        if [[ -f $module_file ]] ; then
                # copy adapter
                if cp -f -r $module_file "$TARGET_BIN" ; then
                        gr.msg -v2 -c green "done"
                    else
                        gr.msg -c yellow "module $_module adapter copy error"
                    fi

                # install module requirements
                [[ $install_requiremets ]] && gr.ask "install module $_module requirements" && $module_file install

                # add to file list, replace source folder to target folder
                installed_files=( ${installed_files[@]} $TARGET_BIN/${module_file#*/} )
                installed_modules=( ${installed_modules[@]} ${_module} )
                #gr.msg -c deep_pink "${installed_files[@]}"
            else
                gr.msg -n -v2 -c yellow "error "
                gr.msg -v2 "module adapter '$_module.sh' missing or module not exist"
            fi


        # copy workers
        if [[ -d modules/$_module ]] ; then
                #gr.msg -n -v2 -c grey " copying $_module files.. "
                [[ -d $TARGET_BIN/$_module ]] || mkdir "$TARGET_BIN/$_module"
                local module_files=( $(ls modules/$_module/*) )

                for _file in ${module_files[@]} ; do
                    _target_file=${_file/"modules/"/"$TARGET_BIN/"}
                    gr.msg -n -v2 -c grey "  ${_file#*/} "
                    if cp -f "$_file" "$_target_file" ; then
                            installed_files=( ${installed_files[@]} $_target_file)
                            #gr.msg -c deep_pink "${installed_files[@]}"
                            gr.msg -n -v1 -V2 -c grey "."
                            gr.msg -v2 -c green "done"
                        else
                            gr.msg -c yellow "module $_module folder copying error"
                        fi
                done
            fi
        done
    # pass
    gr.msg -v1 -V2 -c green " done"
    return 0
}


check.modules () {
    # check installed modules (foray folder is not monitored)
    gr.msg -n -v1 "checking installed modules " ; gr.msg -v2
    for _module in  ${modules_to_install[@]} ; do
            gr.msg -n -v2 -c grey "$_module "
            gr.msg -n -v1 -V2 -c grey "."
            if ls $TARGET_BIN/$_module* >/dev/null ; then
                gr.msg -v2 -c green "ok"
            else
                gr.msg -c yellow "warning: module $_module missing"
            fi
        done
    # pass
    gr.msg -v1 -V2 -c green "ok"
    return 0
}


install.config () {
    # config
    if ! [[ -f "$TARGET_CFG/$GURU_USER/user.cfg" ]] ; then
         gr.msg -c yellow "user specific configuration not found, using default.."
         cp -f $TARGET_CFG/user-default.cfg "$TARGET_CFG/$GURU_USER/user.cfg" \
            || gr.msg -c red -x 181 "default user configuration failed"
    fi

    # post install configure
    if [[ $configure_after_install ]] ; then
            gr.msg -c white "configuring $GURU_USER.."
            config.export "$GURU_USER" || gr.msg -c red "user config export error"
            source "$core_rc" || gr.msg -c red "$core_rc error"
            #config.main pull || gr.msg -x 182 "remote user configuration failed" Not yet guru.server needs to exist first

            # set keyboard shortcuts
            gr.msg -n -v1 "setting keyboard shortcuts "
            keyboard.main add all || gr.msg -c yellow "error by setting keyboard shortcuts"
            installed_files=( ${installed_files[@]} $TARGET_CFG/kbbind.backup.cfg )
        else
            [[ -f /tmp/temp.rc ]] && mv -f /tmp/temp.rc $core_rc
        fi

    return 0

}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        install.main $@
        exit "$?"
fi

