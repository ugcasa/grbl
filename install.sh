#!/bin/bash
# installer for grbl. ujo.guru casa@ujo.guru 2017-2024

modules_to_install=(doc lab onedrive spy phone ai android audio backup cal conda convert corsair display dokuwiki fingrid game mqtt note place print program project radio say scan ssh stamp tag telegram timer tmux tor trans tunnel vol vpn yle youtube)
code_modules=(cheatsheet config counter daemon flag help install keyboard mount net os prompt system uninstall unmount user )

[[ -f $HOME/.grblrc ]] && installed=true || installed=
TARGET_BIN="$HOME/bin"
TARGET_CFG="$HOME/.config/grbl"
bash_rc="$HOME/.bashrc"
core_rc="$HOME/.grblrc"
backup_rc="$HOME/.bashrc.backup-by-grbl"

export GRBL_CALL="grbl"
export GRBL_USER="$USER"
export GRBL_BIN="$TARGET_BIN"
export GRBL_CORE_FOLDER="`pwd`/core"
export GRBL_CFG="$HOME/.config/grbl"

source $GRBL_CORE_FOLDER/common.sh

# check if colors possible
if echo "$TERM" | grep "256" >/dev/null ; then
    if echo "$COLORTERM" | grep "true" >/dev/null ; then
        GRBL_FLAG_COLOR=true
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
    export GRBL_COLOR=true
fi

install.main () {
# Install main 
    date

    # Step 1) parse arguments
    install.arguments $@ || gr.msg -x 100 "argumentation error"

    # Step 2) check and uninstall previous version
    install.check || gr.msg -x 110 "check caused exit"
    gr.msg -v1 -c white "installing grbl v.$(head -n1 version)"

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
    if [[ $install_dev ]] ; then
        install.dev || gr.msg -x 160 "error during installing dev"
        #check.dev
    fi

    # Step 7) install modules
    install.modules && check.modules || gr.msg -x 170 "error when installing modules"

    # Step 8) set up launcher
    ln -f -s "$TARGET_BIN/core.sh" "$TARGET_BIN/$GRBL_CALL" || gr.msg -x 180 "core linking error"

    # Step 9) save statistics
    echo "${code_modules[@]}" > "$TARGET_CFG/installed.core"
    echo "${installed_modules[@]}" > "$TARGET_CFG/installed.modules"
    echo "${modified_files[@]}" > "$TARGET_CFG/modified.files"
    echo "${installed_files[@]}" > "$TARGET_CFG/installed.files"
    echo "${installed_folders[@]}" > "$TARGET_CFG/installed.folders"

    # Step 10) export user configuration
    install.config || gr.msg -x 180 "user configuration error"

    # Step 11) printout pass and statistics if verbose set
    gr.msg -c white "grbl v$($TARGET_BIN/core.sh version) installed"
    gr.msg -v1 -c light_blue "installed ${#installed_core[@]} core modules"
    gr.msg -v2 -c dark_grey "${installed_core[@]}"
    gr.msg -v1 -c light_blue "installed ${#installed_modules[@]} modules"
    gr.msg -v2 -c dark_grey "${installed_modules[@]}"
    gr.msg -v1 -c light_blue "modified ${#modified_files[@]} file(s)"
    gr.msg -v2 -c dark_grey "${modified_files[@]}"
    gr.msg -v1 -c light_blue "copied ${#installed_files[@]} files"
    gr.msg -v2 -c dark_grey "${installed_files[@]}"

    # Step 12) Release pause flag that may be set by uninstaller and return 
    if [[ $installed ]]; then 
        source flag.sh
        if flag.main running ; then
            flag.rm pause
            sleep 1
            gr.end caps
        fi
    fi
    return 0
}

install.help () {
    gr.msg -c white "grbl install help "
    gr.msg
    gr.msg "usage:    ./install.sh -f|-r|-d|-v|-V|-h|-p [desktop|laptop|server|phone] |-u <user>"
    gr.msg
    gr.msg -c white "flags:"
    gr.msg " -f               force re-install "
    gr.msg " -u <user>        set user name "
    # gr.msg " -p [platform]    select installation platform: desktop|laptop|server|phone "
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
# Process flags and arguments
    export GRBL_VERBOSE=0

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
            -v) export GRBL_VERBOSE=$2
                shift 2 ;;
            -u) export GRBL_USER=$2
                shift 2 ;;
             *) break
        esac
    done

    local _arg="$@"
    [[ "$_arg" != "--" ]] && ARGUMENTS="${_arg#* }"

    case "$1" in
       help)    
        install.help
        return 0
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
# Check installation, reinstall if -f or user input
    gr.msg -v1 "checking current installation.. "
    if grep -q "grblrc" "$bash_rc" ; then
        [[ $force_overwrite ]] && answer="y" || read -p "already installed, force re-install [y/n] : " answer

        if ! [[ "$answer" == "y" ]]; then
                gr.msg -c red -x 2 "aborting.."
            fi

        if [[ $LIGTH_INSTALL ]] ; then
            install.core || gr.msg -x 150 "error during installing core"
            check.core
            install.modules && check.modules || gr.msg -x 170 "error when installing modules"
            gr.end caps
            exit 0
        fi

        if ! [[ $configure_after_install ]] && [[ -f $core_rc ]]; then
            cp $core_rc /tmp/$USER/temp.rc
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
# take .bashrc backup and make .grblrc
    gr.msg -n -v1 "setting rcfiles "
    
    # make a backup of original .bashrc only if installed first time
    [[ -f "$backup_rc" ]] || cp -f "$bash_rc" "$backup_rc"

    if ! grep -q ".grblrc" "$bash_rc" >/dev/null ; then
        printf "# grbl launcher to bashrc \n\nif [[ -f ~/.grblrc ]] ; then \n    source ~/.grblrc\nfi\n" >>"$bash_rc"
    fi

    installed_files+=("$backup_rc")
    modified_files+=("$backup_rc")
    gr.msg -v1 -c green "done"
    return 0
}

check.rcfiles () {
    # check that rc files were installed
    gr.msg -n -v1 "checking rcfiles " ; gr.msg -v2

    gr.msg -n -v1 -V2 -c grey "." ; gr.msg -v2 -n -c grey "$bash_rc "
    if grep -q "grblrc" "$bash_rc" ; then
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
# create folder tree 
    gr.msg -n -v1 "setting up folder structure " ; gr.msg -v2

    # make bin folder for scripts, configs and and apps
    [[ -d "$TARGET_BIN" ]] || mkdir -p "$TARGET_BIN"
    gr.msg -n -v1 -V2 -c grey "." ; gr.msg -v2 -c grey "$TARGET_BIN"

    # personal configurations
    [[ -d "$TARGET_CFG/$GRBL_USER" ]] || mkdir -p "$TARGET_CFG/$GRBL_USER"
    gr.msg -n -v1 -V2 -c grey "." ; gr.msg -v2 -c grey "$TARGET_CFG/$GRBL_USER"

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


    gr.msg -n -v1 -V2 -c grey "." ; gr.msg -n -v2 -c grey "$TARGET_CFG/$GRBL_USER"
    if [[ -d "$TARGET_CFG/$GRBL_USER" ]] ; then

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
        
        #module_file=$(ls modules/${_module}.* 2>/dev/null |head -1 )

        module_file=modules/${_module}.sh

        if [[ -f modules/${_module}.sh ]]; then 
            module_file=modules/${_module}.sh
        elif [[ -f modules/${_module}.py ]]; then 
            module_file=modules/${_module}.py
        elif [[ -f modules/${_module} ]]; then 
            module_file=modules/${_module}
        fi

        gr.msg -n -v1 -V2 -c grey "."
        gr.msg -n -v2 -c grey "${module_file#*/} "

        if [[ -f $module_file ]] ; then
        # copy file modules (and adapters)
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

        else
            gr.msg -c dark_grey -v2 "core will build adapter file on first run"
            installed_files+=($TARGET_BIN/${module_file#*/})
            installed_modules+=(${_module})
        fi

        # copy folder modules
        if [[ -d modules/$_module ]] ; then
            [[ -d $TARGET_BIN/$_module ]] || mkdir "$TARGET_BIN/$_module"
            local module_files=( $(ls modules/$_module/*) )

            for _file in ${module_files[@]} ; do
                _target_file=${_file/"modules/"/"$TARGET_BIN/"}
                gr.msg -n -v2 -c grey "  ${_file#*/} "
                if cp -f "$_file" "$_target_file" ; then
                    installed_files=( ${installed_files[@]} $_target_file)
                    gr.msg -n -v1 -V2 -c grey "."
                    gr.msg -v2 -c green "done"
                else
                    gr.msg -c yellow "module $_module folder copying error"
                fi
            done
            installed_folders+=(${_module})
        fi
    done
    gr.msg -v1 -V2 -c green " done"
    return 0
}


make_adapter () {
# make adapter to multi file module

    local module=$1 ; shift
    local temp_script=$TARGET_BIN/$module.sh

    gr.msg -n -v2 -c dark_grey "generating adapter.. "

    cat > "$temp_script" <<EOL
#!/bin/bash
# grbl adapter generated by core $(date)
source "$TARGET_BIN/$module/$module.sh"
if [[ "\${BASH_SOURCE[0]}" == "\${0}" ]]; then
    gr.debug "\${0##*/}: adapting $module to $TARGET_BIN/$module/$module.sh with variables \$@"
    $module.main "\$@"
fi
EOL

    if [[ -f $TARGET_BIN/$module.sh ]] ; then
        chmod +x "$TARGET_BIN/$module.sh"
        gr.msg -v2 -c green "ok"
    else
        gr.msg -v2 -c error "failed"
        return 123
    fi
}



check.modules () {
# check installed modules (foray folder is not monitored)
    gr.msg -n -v1 "checking installed modules " ; gr.msg -v2
    for _module in  ${modules_to_install[@]} ; do
            gr.msg -n -v2 -c grey "$_module "
            gr.msg -n -v1 -V2 -c grey "."
   
            if [[ -f "$TARGET_BIN/$_module.sh" ]]; then
                gr.msg -v2 -c green "ok"
            else 
                if [[ -f "$TARGET_BIN/$_module/$_module.sh" ]] ; then
                    make_adapter $_module 
                else
                    gr.msg -c yellow "warning: module $_module missing"
                fi
            fi
        done
    # pass
    gr.msg -v1 -V2 -c green "ok"
    return 0
}

install.config () {
# copy default config files. Does not overwrite user settings 

    # this is not impelemted yet, causes installer to fail. ISSUE #181
    #if ! [[ -f "$TARGET_CFG/$GRBL_USER/user.cfg" ]] ; then
        # gr.msg -c yellow "user specific configuration not found, ask casa@ujo.guru for access to server"
        # cp -P 221 ujo.guru:/home/$GRBL_USER/grbl/config/$HOSTNAME/$GRBL_USER/* $TARGET_CFG/$GRBL_USER
    
    #if ! [[ -f "$TARGET_CFG/$GRBL_USER/user.cfg" ]] ; then
    #     gr.msg -c yellow "user specific configuration not found, using default.."
    #     cp -f $TARGET_CFG/user-default.cfg "$TARGET_CFG/$GRBL_USER/user.cfg" \
    #        || gr.msg -c red -x 181 "default user configuration failed"
    #fi

    # export default configuration if -c were used
    if [[ $configure_after_install ]] ; then
        gr.msg -c white "configuring $GRBL_USER.."

        source $GRBL_CORE_FOLDER/config.sh
        config.export "$GRBL_USER" || gr.msg -c red "user config export error"
        source "$core_rc" || gr.msg -c red "$core_rc error"

        gr.msg -n -v1 "setting keyboard shortcuts "
        source $GRBL_CORE_FOLDER/keyboard.sh
        keyboard.main add all || gr.msg -c yellow "error by setting keyboard shortcuts"
        installed_files+=($TARGET_CFG/kbbind.backup.cfg )
    else
        [[ -f /tmp/$USER/temp.rc ]] && mv -f /tmp/$USER/temp.rc $core_rc
    fi
    
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install.main $@
    exit "$?"
    gr.end caps
fi

