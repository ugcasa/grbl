# guru-client os functions for installer casa@ujo.guru 2020
# echo "common.sh: included by: $0"

compatible_with(){
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


check_distro() {
    # returns least some standasrt type linux distributuin name
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        echo "$ID"
        return 0
    else
        echo "other"
        return 100
    fi
}


check_python_module () {                                      # Does work, but returns funny (futile: not called from anywhere)
   python -c "import $1"
   return "$?"
}


check_space () {
    # check free space of server disk

    declare -l mount_point=$GURU_SYSTEM_MOUNT
    [[ $1 ]] && mount_point=$1
    declare -l column=4
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
