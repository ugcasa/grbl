# guru-client os functions for installer casa@ujo.guru 2020
# echo "common.sh: included by: $0"

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
        gr.msg -v1 -V2 "$NAME $VERSION_ID '$VERSION_CODENAME' Kernel $(uname -r)"
        gr.msg -v2 "$NAME $VERSION_ID '$VERSION_CODENAME'/$ID_LIKE '$UBUNTU_CODENAME' $(uname -v)/Linux kernel $(uname -r)"
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
                    gr.msg "on"
                    return 0
                else
                    gr.msg "off"
                    return 1
                fi
                ;;
            on)
                capslock_state || xdotool key Caps_Lock
                ;;
            off)
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