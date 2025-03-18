#!/bin/bash
# lab tools for GRBL casa@ujo.guru 2025

#GRBL_COLOR=true # DEBUG
#GRBL_VERBOSE=2 # DEBUG
#GRBL_DEBUG=true # DEBUG
declare -g __lab=$(readlink --canonicalize --no-newline $BASH_SOURCE) # DEBUG
declare -g __lab_color="light_blue" # DEBUG
declare -g lab_rc=/tmp/$USER/gtbl_lab.rc
declare -g lab_config="$GRBL_CFG/$GRBL_USER/lab.cfg"
declare -g lab_require=()

lab.help () {
# lab help printout

    gr.msg -v1 "GRBL lab help " -h
    gr.msg -v2
    gr.msg -v0 "Usage:    $GRBL_CALL lab check|status|help|poll|start|end|install|uninstall" -c white
    gr.msg -v2
    gr.msg -v1 "Commands:" -c white
    gr.msg -v2 " check <something>    check stuff "
    gr.msg -v2 " status               one line status information of module "
    gr.msg -v1 " install <resource>   install required software: ${lab_require[@]}"
    gr.msg -v1 " uninstall            remove required software: ${lab_require[@]}"
    gr.msg -v1 " help                 get more detailed help by increasing verbose level '$GRBL_CALL lab -v2' "
    gr.msg -v3
    gr.msg -v3 "Options:" -c white
    gr.msg -v3 "  -v 1..4             set module verbose level"
    gr.msg -v3 "  -d                  set module to debug mode"
    gr.msg -v4
    gr.msg -v4 " when module called trough GRBL core.sh module options are given with double hyphen '--'"
    gr.msg -v4 " and bypassed by GRBL core.sh witch removes one hyphen to avoid collision with core.sh options. "
    gr.msg -v3
    gr.msg -v3 "Internal functions: " -c white
    gr.msg -v3
    gr.msg -v3 " Following functions can be used when this file is sourced by command: 'source lab.sh' "
    gr.msg -v3 " Any of external 'commands' are available after sourcing by name 'lab.<function> arguments -options' "
    gr.msg -v3
    gr.msg -v3 " lab.main         main command parser "
    gr.msg -v3 " lab.check        check all is fine, return 0 or error number "
    gr.msg -v3 " lab.status       printout one line module status output "
    gr.msg -v3 " lab.rc           lift environmental variables for module functions "
    gr.msg -v3 "                  check changes in user config and update RC file if needed "
    gr.msg -v3 "                  this enables fast user configuration and keep everything up to date "
    gr.msg -v3 " lab.make_rc      generate RC file to /tmp out of $GRBL_CFG/$GRBL_USER/lab.cfg "
    gr.msg -v3 "                  or if not exist $GRBL_CFG/lab.cfg"
    gr.msg -v3 " lab.install      install all needed software"
    gr.msg -v3 "                  stuff that can be installed by apt-get package manager are listed in  "
    gr.msg -v3 "                  'lab_require' list variable, add them there. Other software that is not "
    gr.msg -v3 "                  available in package manager, or is too old can be installed by this function. "
    gr.msg -v3 "                  Note that install.sh can proceed multi_module call for this function "
    gr.msg -v3 "                  therefore what to install (and uninstall) should be described clearly enough. "
    gr.msg -v3 " lab.uninstall    remove installed software. Do not uninstall software that may be needed "
    gr.msg -v3 "                  by other modules or user. Uninstaller asks user every software that it  "
    gr.msg -v3 "                  going to uninstall  "
    gr.msg -v3 " lab.poll         daemon interface " # TODO remove after checking need from daemon.sh
    gr.msg -v3 " lab.start        daemon interface: things needed to do when daemon request module to start "
    gr.msg -v3 " lab.stop         daemon interface: things needed to do when daemon request module to stop "
    gr.msg -v3 " lab.status       one line status printout "
    gr.msg -v2
    gr.msg -v1 "Resources:" -c white
    gr.msg -v1 "  blender             '$GRBL_CALL lab install blender'"
    gr.msg -v1 "  kicad               '$GRBL_CALL lab install kicad'"
    gr.msg -v1 "  unity               '$GRBL_CALL lab install unity'"
    gr.msg -v1 "  spacemouse          '$GRBL_CALL lab install spacemouse'"
    gr.msg -v2
    # gr.msg -v2
    # gr.msg -v2 "Examples:" -c white
    # gr.msg -v2 "  $GRBL_CALL lab install   # install required software "
    # gr.msg -v2 "  $GRBL_CALL lab status    # print status of this module  "
    # gr.msg -v3 "  lab.main status          # print status of lab  "
    # gr.msg -v2
}

lab.main () {
# lab main command parser
    [[ $GRBL_DEBUG ]] && gr.msg -n -c $__lab_color "$__lab [$LINENO] $FUNCNAME: ">&2; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # DEBUG

    local _first="$1"
    shift

    case "$_first" in
        check|status|help|poll|start|end|install|uninstall)
            lab.$_first "$@"
            return $?
            ;;

       *)   gr.msg -e1 "${FUNCNAME[0]}: unknown command: '$_first'"
            return 2
    esac
}

lab.rc () {
# source configurations (to be faster)
    [[ $GRBL_DEBUG ]] && gr.msg -n -c $__lab_color "$__lab [$LINENO] $FUNCNAME: ">&2; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # DEBUG

    # check is user config changed
    if [[ ! -f $lab_rc ]] \
        || [[ $(( $(stat -c %Y $GRBL_CFG/$GRBL_USER/lab.cfg) - $(stat -c %Y $lab_rc) )) -gt 0 ]]
    # if module needs more than one config file here it can be done here
    #     || [[ $(( $(stat -c %Y $GRBL_CFG/$GRBL_USER/lab.cfg) - $(stat -c %Y $lab_rc) )) -gt 0 ]] \
    #     || [[ $(( $(stat -c %Y $GRBL_CFG/$GRBL_USER/mount.cfg) - $(stat -c %Y $lab_rc) )) -gt 0 ]]
    then
        lab.make_rc && \
            gr.msg -v2 -c dark_gray "$lab_rc updated"
    fi


    # source current RC file to lift user configurations to environment
    source $lab_rc
}

lab.make_rc () {
# make RC file out of config file
    [[ $GRBL_DEBUG ]] && gr.msg -n -c $__lab_color "$__lab [$LINENO] $FUNCNAME: ">&2; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # DEBUG

    # remove old RC file
    if [[ -f $lab_rc ]] ; then
            rm -f $lab_rc
        fi

    source config.sh
    config.make_rc "$GRBL_CFG/$GRBL_USER/lab.cfg" $lab_rc

    # config.make_rc "$GRBL_CFG/$GRBL_USER/mount.cfg" $lab_rc
    # config.make_rc "$GRBL_CFG/$GRBL_USER/lab.cfg" $lab_rc append

    # make RC executable
    chmod +x $lab_rc
}

lab.status () {
# module status one liner
    [[ $GRBL_DEBUG ]] && gr.msg -n -c $__lab_color "$__lab [$LINENO] $FUNCNAME: ">&2; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # DEBUG

    # printout timestamp without newline
    gr.msg -t -n "${FUNCNAME[0]}: "

    # check lab is enabled and printout status
    if [[ $GRBL_LAB_ENABLED ]] ; then
        gr.msg -n -v1 -c lime "enabled, " -k $GRBL_LAB_INDICATOR_KEY
    else
        gr.msg -v1 -c black "disabled" -k $GRBL_LAB_INDICATOR_KEY
        return 1
    fi

    gr.msg -c green "ok"
}

lab.install() {
# install required software
    [[ $GRBL_DEBUG ]] && gr.msg -n -c $__lab_color "$__lab [$LINENO] $FUNCNAME: ">&2; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # DEBUG

    local _errors=()
    local item=$1
    shift

    gr.msg -c white "installation requires sudo privileges"

    if ! groups | grep -q "sudo"; then
        return 2
    fi

    case $item in
        blender|unity|kicad|eagle|mblab|spacemouse)
            lab.install_$item $@
            return $?
            ;;
        "")
        # install software that is available distro's package manager repository
            sudo apt-get update
            for install in ${lab_require[@]} ; do
                hash $install 2>/dev/null && continue
                gr.ask -h "install $install" || continue
                sudo apt-get -y install $install || _errors+=($?)
            done
            ;;
        *)
            gr.msg -e1 "no install method for $item"
            return 1
            ;;
    esac

    if [[ ${_error_count[0]} ]]; then
        gr.msg -e1 "${#_error_count} errors or warnings recorded: ${_error_count[@]}"
        return ${_error_count[${#_error_count[@]}]}
    fi
    return 0
}

lab.check_kicad (){
# check is already installed and works
    return 0
    return 1
}

lab.install_kicad (){
# install kicad

    gr.msg "try manually: '$__lab' function '$FUNCNAME' line: $(($LINENO -3)) "

    sudo add-apt-repository --yes ppa:kicad/kicad-9.0-releases
    sudo apt update
    sudo apt install --install-recommends kicad

    if [[ $? -gt 0 ]]; then
        gr.msg -v1 "something went wrong"
        gr.msg "if get error: ub-process /usr/bin/dpkg returned an error code (1)"
        gr.msg "see in what deb package fails and type: "
        gr.msg -c white "  sudo apt -f install sudo dpkg -i --force-overwrite <deb name with path>"
        gr.msg -c white "  sudo apt -f install"
        return 128
    fi

    gr.msg -h "manual for kicad https://docs.kicad.org/7.0/en/getting_started_in_kicad/getting_started_in_kicad.pdf"
    gr.msg -c white "run by: 'kicad'"
}

lab.check_blender () {
# check is already installed and works
    return 0
    return 1
}

lab.install_blender () {
# install blender (manual)

    gr.msg "try manually: '$__lab' function '$FUNCNAME' line: $(($LINENO -3)) "
    # [[ $blender_folder ]] || mkdir -p $blender_folder
    # cd $blender_folder
    # wget https://builder.blender.org/download/daily/blender-3.3.2-stable+v33.bd3a7b41e2b3-linux.x86_64-release.tar.xz
    # skipped: unable to know current version

    # build from source
    # https://ubuntuhandbook.org/index.php/2021/10/install-blender-ubuntu-complete-guide/
    # skipped: may not work, takes time to test and may need multiple requirement install script runs

    # from universe: +easy +multi arch -very old -no updates
    # skipped: old, no update anymore
    # sudo apt update && sudo apt install blender

    # trying to build it
    # page=$(curl https://download.blender.org/source/ | tr -s ' ')

    # declare -a zips=()
    # ifs=$IFS
    # (
    # IFS="$(printf '\n')"
    # echo -n "$IFS" | od -t x1
    # # list=$(echo ${page[@]} | sed -e 's/<\/b>/-/g' -e 's/<[^>]*>//g')
    # for line in $(echo ${page[@]} | sed -e 's/<\/b>/-/g' -e 's/<[^>]*>//g'blen) ;do

    #         echo $line | grep -v 'md5' | cut -d' ' -f1 >>/tmp/$USER/list
    #         zips+=("$(echo $line | grep -v 'md5' | cut -d' ' -f1 )" )


    #     # zips+=("$(echo $line | grep -v 'md5' | cut -d' ' -f1)")
    #     # versions+=()
    #     done
    # )
    # IFS=$ifs

    # for zip in ${zips[@]}; do
    #     echo $zip
    # done
    # echo $page
    # versions=
    # url=
    # fuck it..

    # lets go with old version and upgrade it later by blender it self (if it's possible)
    # only version to get from apt is v2.82.7 WAY too old. lts stable is 2.93.13 and there is even stable 3.3.2 and 3.4.1 and alpha 3.5.0!
    # current recommended if 3.4.1
    # sudo apt update && sudo apt install blender
    # # "there is no in-software option to update" fuck..
    # # fuck this too then
    # sudo apt purge blender -y
    # sudo apt autoremove -y

    # the best method
    # download and unzip Blender
    gr.msg "Download from https://www.blender.org/download/ "
}

lab.check_spacemouse () {
# check is already installed and works
    spacenavd 2>/dev/null >/dev/null
    if [[ $? -lt 127 ]] ; then
        gr.msg "already installed"
        return 0
    fi
    return 1
}

lab.install_spacemouse () {
# install labmouse drivers

    gr.msg "try manually: '$__lab' function '$FUNCNAME' line: $(($LINENO -3)) "


    lab.check_spacemouse && return 0

    # libraries for spacemouse

    sudo apt-get update
    sudo apt-get install libxm4 -f
    # download setup tool (and daemon)
    wget https://download.3dconnexion.com/drivers/linux/3dxware-linux-v1-8-0.x86_64.tar.gz
    tar –xvzf 3dxware-linux-v1-8-0.x86_64.tar.gz
    sudo ./install-3dxunix.sh linux

    # run setup tool (and exit)
    sudo /etc/3DxWare/daemon/3dxsrv -d usb

    # setup in blender
    # https://www.youtube.com/watch?v=bJ2aJ8rlgKg

    # driver for spacemouse for blender / unity support
    # https://robots.uc3m.es/installation-guides/install-spacenav.html
    sudo apt-get install libspnav-dev spacenavd -f

    # https://wiki.archlinux.org/title/3D_Mouse
    # http://www.spacemice.org/index.php?title=Blender
    # https://spacenav.sourceforge.net/
    # https://spacenav.sourceforge.net/man_libspnav/
}

lab.check_unity () {
# check is already installed and works
    return 0
    return 1
}

lab.install_unity () {
# install unity hub

    gr.msg "try manually: '$__lab' function '$FUNCNAME' line: $(($LINENO -3)) "

    sudo sh -c 'echo "deb https://hub.unity3d.com/linux/repos/deb stable main" > /etc/apt/sources.list.d/unityhub.list'
    wget -qO - https://hub.unity3d.com/linux/keys/public | sudo apt-key add -
    sudo apt update
    sudo apt-get install unityhub

}

lab.uninstall() {
# uninstall required software
    [[ $GRBL_DEBUG ]] && gr.msg -n -c $__lab_color "$__lab [$LINENO] $FUNCNAME: ">&2; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # DEBUG

    local _errors=()

    # remove software that is needed ONLY of this module
    for remove in ${lab_require[@]} ; do
        hash $remove 2>/dev/null || continue
        gr.ask -h "remove $remove" || continue
        sudo apt-get -y purge $remove || _errors+=($?)
    done


    if [[ $_error_count ]]; then
        gr.msg -e1 "${#_error_count} errors of warnings recorded: ${_error_count[@]}"
        return $_error_count
    fi
}

lab.option() {
    # process module options
    [[ $GRBL_DEBUG ]] && gr.msg -n -c $__lab_color "$__lab [$LINENO] $FUNCNAME: ">&2; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # DEBUG

    local options=$(getopt -l "debug;verbose:" -o "dv:" -a -- "$@")

    if [[ $? -ne 0 ]]; then
        echo "option error"
        return 101
    fi

    eval set -- "$options"

    while true; do
        case "$1" in
            -d|debug)
                GRBL_DEBUG=true
                shift
                ;;
            -v|verbose)
                GRBL_VERBOSE=$2
                shift 2
                ;;
            --)
                shift
                break
                ;;
        esac
    done

    lab_command_str=($@)
}

lab.poll () {
# daemon required polling functions
    [[ $GRBL_DEBUG ]] && gr.msg -n -c $__lab_color "$__lab [$LINENO] $FUNCNAME: ">&2; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # DEBUG

    local _cmd="$1" ; shift

    case $_cmd in
        start )
            gr.msg -v1 -t -c black \
                -k $GRBL_LAB_INDICATOR_KEY \
                "${FUNCNAME[0]}: lab status polling started"
            ;;
        end )
            gr.msg -v1 -t -c reset \
                -k $GRBL_LAB_INDICATOR_KEY \
                "${FUNCNAME[0]}: lab status polling ended"
            ;;
        status )
            lab.status
            ;;
        esac
}

# update rc and get variables to environment
lab.rc

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    lab.option $@
    lab.main ${lab_command_str[@]}
    exit "$?"
else
    [[ $GRBL_DEBUG ]] && gr.msg -c $__lab_color "$__lab [$LINENO] sourced " >&2
fi

