# guru-client os functions for installer casa@ujo.guru 2020
# echo "common.sh: included by: $0"
os_indicator_key=f8
system_indicator_key=caps
os_rc=/tmp/guru-cli_os.rc

__os_color="light_blue"
__os=$(readlink --canonicalize --no-newline $BASH_SOURCE)


os.help () {
# Operating system functions help
    gr.msg -n -v4 -c $__os_color "$__os [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

    gr.msg -v1 -c white "guru-client installer help "
    gr.msg -v2
    gr.msg -v0  "usage:    $GURU_CALL status|info|poll|get|capslock|upgrade|update|usermerge "
    gr.msg -v2
    gr.msg -v1 -c white  "commands:"
    gr.msg -v1 " status             operating system info with kernel version"
    gr.msg -v1 " info               operating system info"
    gr.msg -v2 " poll               daemon compatibility functions"
    gr.msg -v1 " get <var_name>     get os information by variable name or all if empty"
    gr.msg -v2 "     available      list variables variables"
    gr.msg -v1 " capslock           capslock state and control"
    gr.msg -v2 "     state          printout capslock status "
    gr.msg -v2 "     on/off         enable / disable capslock "
    gr.msg -v1 " upgrade            upgrade operating system"
    gr.msg -v1 " update             printout updateable and ask to upgrade "
    gr.msg -v1 " usermerge          support for the merged /usr directories scheme"
    gr.msg -v1 "                    https://wiki.debian.org/UsrMerge"
    gr.msg -v2 "                    /bin → /usr/bin,"
    gr.msg -v2 "                    /sbin → /usr/sbin,"
    gr.msg -v2 "                    /lib → /usr/lib and"
    gr.msg -v2 "                    /lib64 → /usr/lib64"
    gr.msg -v2
    gr.msg -v1 "increase verbosity to get more information"
}


os.main () {
# main command parser
    gr.msg -n -v4 -c $__os_color "$__os [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2
    local command=$1 ; shift
    case $command in
        status|info|poll|capslock|upgrade|update|usermerge|help|get)
        os.$command $@
        return $?
        ;;

    esac
}


os.compatible_with () {
# check that current os is compatible with input [ID] {VERSION_ID}
    gr.msg -n -v4 -c $__os_color "$__os [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2
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


os.status () {
# returns least linux distribution name
    gr.msg -n -v4 -c $__os_color "$__os [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2
    gr.msg -n && alias 'gr.msg'='echo'
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        gr.msg -t -v1 -V2 "$FUNCNAME: $NAME $VERSION_ID '$VERSION_CODENAME' Kernel $(uname -r)"
        gr.msg -t -v2 "$FUNCNAME: $NAME $VERSION_ID '$VERSION_CODENAME'/$ID_LIKE '$UBUNTU_CODENAME' $(uname -v)/Linux kernel $(uname -r)"
    fi
}


os.information () {
# printout
    gr.msg -n -v4 -c $__os_color "$__os [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2
    local variable=$1
    shift
    local dmi_var_list=(bios-vendor bios-version bios-release-date baseboard-manufacturer baseboard-product-name baseboard-version chassis-type processor-family processor-manufacturer processor-version processor-frequency)

    case $variable in

        cpu)
            lscpu
            ;;

        architechture|arch)
            case $(uname -m) in
                aarch64|arm64) echo "arm64" ;;
                amd64|x86_64) echo "amd64" ;;
                # TODO add rest later
            esac
            ;;

        bios|system|baseboard|chassis|processor|memory|cache|connector|slot)
            sudo dmidecode -t $variable
            ;;

        help)
            gr.msg -h "type keywords"
            gr.msg -c list "bios system baseboard chassis processor memory cache connector slot"
            gr.msg -h "variables"
            gr.msg -c list "${dmi_var_list[@]}"
            gr.msg -h "cpu variables"
            gr.msg -c list "${dmi_var_list[@]}"

            ;;

        "")
            sudo true
            for var in ${dmi_var_list[@]} ; do
                gr.msg -n -c light_blue "$var: "
                gr.msg -c aqua_marine "$(sudo dmidecode -s $var)"
            done
            ;;
        *)
            sudo true
            for var in ${dmi_var_list[@]} ; do
                if [[ $var == $variable ]] ; then
                    sudo dmidecode -s $var
                    return 0
                fi
            done
            ;;
    esac
}


# os.df () {
#      local home_use_percent=$(df /home --output=pcent -h | tail -n+2 | xargs)
#      local system_use_percent=$(df / --output=pcent -h | tail -n+2 | xargs)
#      local store_use_percent=$(df /media/casa/store --output=pcent -h | tail -n+2 | xargs)
#      gr.msg "home: $home_use_percent"
#      gr.msg "system: $system_use_percent"
#      gr.msg "store: $store_use_percent"

#      # local home_usedf=$(df /home --output=ipcent -h | tail -n+2 | xargs)
#      # local system_use=$(df / --output=ipcent -h | tail -n+2 | xargs)
#      # local store_use=$(df /media/casa/store --output=ipcent -h | tail -n+2 | xargs)
#      # gr.msg "home: $home_use"
#      # gr.msg "system: $system_use"
#      # gr.msg "store: $store_use"



# }


os.variables () {
# list of os variables
    gr.msg -n -v4 -c $__os_color "$__os [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2
    variables=($(cat /etc/os-release | cut -d'=' -f1))
    variables=(${variables[@]} $(cat /etc/upstream-release/lsb-release | cut -d'=' -f1))
    echo ${variables[@]}
}


os.get () {
# printout os variables
    gr.msg -n -v4 -c $__os_color "$__os [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

    local variable="$1"

    source /etc/os-release
    source /etc/upstream-release/lsb-release

    case $variable in

        architechture|arch)
            os.information $variable
            ;;
        available)
            local list=$(os.variables)
            gr.msg -c list "${list[@],,}"
            return 0
            ;;
        "")
            gr.kvp $(os.variables)
            ;;
        *)
            local got="$(eval echo '$'${variable^^})"
            echo ${got,,}
            ;;
    esac

}


os.info () {
# returns least linux distribution name
    gr.msg -n -v4 -c $__os_color "$__os [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

    source /etc/os-release
    source /etc/upstream-release/lsb-release

    case $GURU_VERBOSE in
        0) gr.msg "$NAME $VERSION_ID/$DISTRIB_ID $DISTRIB_RELEASE" ;;
        1) gr.msg "$NAME $VERSION_ID '$VERSION_CODENAME' based on $DISTRIB_ID $DISTRIB_RELEASE '$DISTRIB_CODENAME' $HOME_URL" ;;
        2) gr.kvp NAME VERSION SUPPORT_URL  DISTRIB_ID DISTRIB_RELEASE DISTRIB_CODENAME ;;
        3|*) gr.kvp $(os.variables) ;;
    esac


}


os.update () {
# update operating system
    gr.msg -n -v4 -c $__os_color "$__os [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2
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
    gr.msg -n -v4 -c $__os_color "$__os [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

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
    gr.msg -n -v4 -c $__os_color "$__os [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2
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
    gr.msg -n -v4 -c $__os_color "$__os [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

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
    gr.msg -n -v4 -c $__os_color "$__os [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2
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
    gr.msg -n -v4 -c $__os_color "$__os [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

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
# toggle capslock status
    gr.msg -n -v4 -c $__os_color "$__os [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

    capslock_state() {
    # return true is capslock is set
        gr.msg -n -v4 -c $__os_color "$__os [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2
        case $(xset -q | sed -n 's/^.*Caps Lock:\s*\(\S*\).*$/\1/p') in
            off) return 1 ;;
            on) return 0 ;;
            *) gr.msg -c yellow "got non valid capslock state"
               return 1
           esac
    }


    case $1 in
            check|state|status)

                gr.msg -n -v2 "capslock is: "
                if capslock_state ; then
                    gr.msg -c green -v1 "active"
                    return 0
                else
                    gr.msg -c black -v1 "disabled"
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


os.rc () {
# source module rc file if exist, generate it from configurations if not
# this could be in core/config.sh but in here soursing of config.sh is not done every time module is run
    # debug function view
    gr.msg -n -v4 -c $__os_color "$__os [$LINENO] $FUNCNAME: " >&2 ; [[ $GURU_DEBUG ]] && echo "'$@'" >&2

    # files
    local config_file=$GURU_CFG/$GURU_USER/os.cfg
    local rc_file="/tmp/guru-cli_os.rc"

    if [[ -f $config_file ]]; then
    # use user configuration
        true
        #gr.msg -v3 -c dark_gray "using user config $config_file"

    elif [[ -f $GURU_CFG/os.cfg ]]; then
    # Use default configuration
        config_file=$GURU_CFG/os.cfg
        #gr.msg -v3 -c dark_gray "using default config $config_file"
    else
    # configuration missing
        gr.msg -e1 "config file $config_file missing, aborting"
        return 123
    fi

    # check module rc file exists
    if [[ -f $rc_file ]] ; then
        local config_file_age_difference=$(( $(stat -c %Y $config_file) - $(stat -c %Y $rc_file) ))
       # gr.varlist "debug config_file rc_file config_file_age_difference"

        # check is configuration updated since last time
        if [[ $config_file_age_difference -gt 1 ]]; then
            rm -f $rc_file
            source config.sh
            config.make_rc "$config_file" $rc_file && gr.msg -v2 -c dark_gray "$rc_file updated"
        fi

    # module rc file does not exist, make it
    else
        source config.sh
        config.make_rc "$config_file" $rc_file && gr.msg -v2 -c dark_gray "$rc_file created"
    fi

    # source configuration
    source $rc_file
}

# os.check_python_module () {                                      # Does work, but returns funny (futile: not called from anywhere)
#    python -c "import $1"
#    return "$?"
# }


if [[ $GURU_CFG/$GURU_USER/os.cfg ]]; then
    config_file=$GURU_CFG/$GURU_USER/os.cfg
else
    config_file=$GURU_CFG/os.cfg
fi


if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
    os.rc
    os.main "$@"
    exit $?
else
    gr.msg -v4 -c $__os_color "$__os [$LINENO] sourced" >&2
    os.rc
fi

