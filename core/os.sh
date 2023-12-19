# guru-client os functions for installer casa@ujo.guru 2020
# echo "common.sh: included by: $0"
os_indicator_key=f8
system_indicator_key="esc"

source net.sh

os.main () {

    local command=$1 ; shift
    case $command in
        status|info|poll|capslock|upgrade|update|usermerge)
        os.$command $@
        return $?
        ;;

    esac
}

os.compatible_with(){
    # check that current os is compatible with input [ID] {VERSION_ID}
    source /etc/os-release
    #[ "$ID" == "$1" ] && return 0 || return 255
    if [ "$ID" == "$1" ]; then
        if [ "$VERSION_ID" == "$2" ] || ! [ "$2" ]; then
            return 0
        else
            echo "${0} is not compatible with $NAME $VERSION_ID, expecting $2 "
            return 255
        fi
    else
        echo "${0} is not compatible with $PRETTY_NAME, expecting $1 $2"
        return 255
    fi
}


os.status() {
    # returns least linux distribution name
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        gr.msg -t -v1 -V2 "$FUNCNAME: $NAME $VERSION_ID '$VERSION_CODENAME' Kernel $(uname -r)"
        gr.msg -t -v2 "$FUNCNAME: $NAME $VERSION_ID '$VERSION_CODENAME'/$ID_LIKE '$UBUNTU_CODENAME' $(uname -v)/Linux kernel $(uname -r)"
    fi
}


os.info() {
    # returns least linux distribution name
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        gr.msg "$NAME $VERSION_ID '$VERSION_CODENAME' based on $ID_LIKE '$UBUNTU_CODENAME'"
        return 0
    else
        echo "cannot stat"
        return 100
    fi
}


os.update () {

    aptitude search '%p' '~U' 2>/dev/null

    # dpkg --get-selections \
    #     | xargs apt-cache policy {} \
    #     | grep -1 Installed \
    #     | sed -r 's/(:|Installed: |Candidate: )//' \
    #     | uniq -u \
    #     | tac \
    #     | sed '/--/I,+1 d' \
    #     | tac \
    #     | sed '$d' \
    #     | sed -n 1~2p

    # apt-get upgrade --dry-run
    # gr.msg -v2 -h "upgradable source list: "
    # gr.msg -v2 -c light_blue "$(sudo apt-get list --upgradable)"
    gr.ask -d n -t 10 "run upgrade?" && os.upgrade
}


os.upgrade () {
# upgrade system

    local _return=
    source net.sh
    #gr.ind doing -k $system_indicator_key

    # verbose level
    local apt_options=""
    local pip_options=""

    #gr.msg -v2 -h "upgrading system.." -k $system_indicator_key

    case $GURU_VERBOSE in

     ""|0)
        # log="$GURU_DATA/system.upgrade.log"
        # echo "guru-client system upgrade by $GURU_USER $(date)" >>$log
        # apt_options='>>'"$log"
        # pip_options='>>'"$log"
        false
        ;;
     1)
        apt_options="-qq "
        pip_options="-q -q -q"
        ;;
    esac

    gr.msg -v1 -V2 -n "checking network.. "
    gr.msg -v2 -h "checking network.. "
    if ! net.check ; then
            gr.msg -c error "check network" -k $system_indicator_key
            return 73
        fi

    # ask root password
    sudo true || gr.msg -c fail -x 99 "no root privileges"

    gr.msg -v1 -V2 -n "updating.. "
    gr.msg -v2 -h "updating resources "

    if [[ $GURU_VERBOSE -lt 2 ]] ; then
            sudo apt-get update >/dev/null
            _return=$?
        else
            sudo apt-get update
            _return=$?
        fi

    if [[ $_return -lt 1 ]] ; then
            gr.msg -v1 -c green "updated"
        else
            gr.msg -c fail "update failed" -k $system_indicator_key
            return 100
        fi

    gr.msg -v1 -V2 -n "upgrading.. "
    gr.msg -v2 -h "upgrading system "
    if sudo apt-get upgrade -y $apt_options ; then
            gr.msg -v1 -c green "upgraded"
        else
            gr.msg -c fail "upgrade failed" -k $system_indicator_key
            return 101
        fi

    gr.msg -v1 -V2 -n "purging.. "
    gr.msg -v2 -h "removing non needed software"
    if sudo apt-get autoremove --purge $apt_options ; then
            gr.msg -v1 -c green "purged"
        else
            gr.msg -c yellow "purge failed" -k $system_indicator_key
        fi

    gr.msg -v1 -V2 -n "cleaning.. "
    gr.msg -v2 -h "cleaning up"
    if sudo apt-get autoclean $apt_options ; then
            gr.msg -v1 -c green "cleaned"
        else
            gr.msg -c yellow "autoclean failed" -k $system_indicator_key
        fi

    gr.msg -v1 -V2 -n "updating pip.. "
    gr.msg -v2 -h "updating pip libs  "
    if /usr/bin/python3 -m pip install --upgrade pip $apt_options ; then
            gr.msg -c green "pip upgraded"
        else
            gr.msg -c fail "pip upgrade failed $?" -k $system_indicator_key
        fi

    #gr.end -k $system_indicator_key

    gr.msg -v1 -V2 -n "testing.. "
    gr.msg -v2 -h "checking all vent fine "
    if sudo apt-get check $apt_options ; then
            gr.msg -v1 -c green "check passed" -k $system_indicator_key
        else
            gr.msg -c fail "check failed" -k $system_indicator_key
            return 102
        fi

}


os.usermerge () {
# merge /bin → /usr/bin, /sbin → /usr/sbin, /lib → /usr/lib, /lib64 → /usr/lib64
# https://wiki.debian.org/UsrMerge
# https://www.freedesktop.org/wiki/Software/systemd/TheCaseForTheUsrMerge/
# HOX: not run ever!

    source /etc/os-release

    #check is 64 bit system
    case $(dpkg --print-architecture) in
        *64)
            gr.msg -c green "ok to continue"
            ;;
        *)  gr.msg -c yellow "not 64 system, unable to continue"
    esac

    # check is mint
    if [[ $ID -ne 'linuxmint' ]]; then
        gr.msg -c error "not a mint"
        return 1
    fi


    # mint 20.1 > is already merged
    case $VERSION_ID in
        20*)
            apt install usrmerge

            if gr.ask "consider to upgrade to mint 20.3. open instructions?"  ; then
                firefox https://blog.linuxmint.com/?p=4216
            fi

            ;;
        21.*)
            gr.msg -c green "already merged"
        esac
}


os.poll () {
# daemon poller interface

    local _cmd="$1" ; shift

    case $_cmd in

        # start|end) #
        #     gr.msg -v1 -t -c $_cmd "${FUNCNAME[0]}: $_cmded" -k $os_indicator_key
        #     ;;

        start )
            gr.msg -v1 -t -c black "${FUNCNAME[0]}: started" -k $os_indicator_key

            ;;
        end )
            gr.msg -v1 -t -c reset "${FUNCNAME[0]}: ended" -k $os_indicator_key

            ;;
        status )
            os.status $@
            return $?
            ;;
        *)  os.help
            ;;
    esac
}


os.check_distro() {
    # returns least linux distribution name
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        echo "$ID"
        return 0
    else
        echo "other"
        return 100
    fi
}


# os.check_branch() {
#     # returns debian, mandriva..
#     echo TBD
# }


# os.check_kernel() {
#     # returns kernel version
#     echo TBD
# }


# os.check_shell() {
#     # returns bash, sh, zsh..
#     echo TBD
# }


# os.check_x() {
#     # returns cinnamon..
#     echo TBD
# }


os.check_space () {
    # check free space of server disk

    local mount_point=$GURU_SYSTEM_MOUNT
    [[ $1 ]] && mount_point=$1
    local column=4
    if [[ $2 ]] ; then
        case $2 in
            u|used)
            column=3
            ;;
            '%'|usage)
            column=5
            ;;
            a|available|free|*)
            column=4
            ;;
        esac
    fi

    # df with parameters
    declare -g server_free_space=$(df \
        | grep $GURU_SYSTEM_MOUNT \
        | tr -s " " \
        | cut -d " " -f $column \
        | sed 's/[^0-9]*//g')

    # printout
    echo "$server_free_space"
}


os.capslock() {

    capslock_state() {
    # return true is capslock is set
        case $(xset -q | sed -n 's/^.*Caps Lock:\s*\(\S*\).*$/\1/p') in
            off) return 1 ;;
            on) return 0 ;;
            *) gr.msg -c yellow "got non valid capslock state"
               return 1
           esac
    }


    case $1 in
            check|state)

                if capslock_state ; then
                    gr.msg -v2 "capslock is active"
                    return 0
                else
                    return 1
                fi
                ;;
            on|ON)
                capslock_state || xdotool key Caps_Lock
                ;;
            off|OFF)
                capslock_state && xdotool key Caps_Lock
                ;;
            toggle)
                xdotool key Caps_Lock
                ;;
        esac
}



# os.check_python_module () {                                      # Does work, but returns funny (futile: not called from anywhere)
#    python -c "import $1"
#    return "$?"
# }


if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
    os.main "$@"
    exit $?
fi

