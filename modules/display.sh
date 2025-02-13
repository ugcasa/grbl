#!/bin/bash
# grbl display control commands
# casa@ujo.guru 2022

#source common.sh

redshift_flag="/tmp/$USER/grbl-redshift.flag"
last_brigh="/tmp/$USER/grbl-display.bright"
toggle_flag="/tmp/$USER/grbl-display.toggle.flag"


display.help () {
    # help print depending of verbose level
    gr.msg -v1 "grbl display help " -c white
    gr.msg -v2
    gr.msg -v0 "usage:    $GRBL_CALL display ls|set|reset] "
    gr.msg -v2
    gr.msg -v1 -c white  "commands:"
    gr.msg -v1 " ls                      list of connected monitors"
    gr.msg -v1 " set <value>             set brightness and contrast to all displays"
    gr.msg -v2 "                         value between 0.1 .. 2.0"
    gr.msg -v1 "     contrast <value>    set contrast to all displays"
    gr.msg -v1 "     brighness <value>   set brightness to all displays"
    gr.msg -v1 " set br|co               short for brightness and contrast"
    gr.msg -v1 " reset                   reset values to 1 and re-lauch redshift"
    gr.msg -v1 " dimm                    set dimmed display settings"
    gr.msg -v2 " help                    printout this help"
    gr.msg -v2
    gr.msg -v1 "example:" -c white
    gr.msg -v1 "    $GRBL_CALL display set 0.75 "
    gr.msg -v1 "    $GRBL_CALL display set brightness 0.8 "
    gr.msg -v1 "    $GRBL_CALL display set co 1.5 "
    gr.msg -v2
    gr.msg -v2 "WARNING: values below 0.2 are almost black" -c white
}

display.main () {
    # command parser
    local cmd=$1
    shift

    case $cmd in
        reset|set|ls|help|card|status)
            display.$cmd $@
            return $?
        ;;

        toggle)
            if [[ -f $toggle_flag ]] ; then
                display.reset
            else
                display.set 0.6
            fi
        ;;

        dimm)
            display.set_brightness 0.6
            display.set_contrast 0.7
        ;;
        *)
            #gr.msg "'$cmd' is not valid command for monitor module"
            display.reset
            return 1
        ;;
    esac
}


display.set () {
# set parser
    local cmd=$1
    shift

    touch $toggle_flag

    case $cmd in
        brightness|contrast)
            display.set_$cmd $@
        ;;

        br*)
            display.set_brightness $@
        ;;

        co*|gamma|ga)
            display.set_contrast $@
        ;;

        *)
            display.set_brightness $cmd
            display.set_contrast $cmd
        ;;
    esac
    return 0
}


display.card () {
# printout gpu information
    case $1 in
        driver)
            lspci -k | grep  -e VGA -A 3
            ;;
            *)
            lspci $_options | grep VGA | cut -d':' -f 3 | xargs
        esac
}


display.check () {
# check mow many displays availabe
    local ifs=$IFS
    declare -g monitors=0

    IFS=$'\n'
    connected=($(xrandr | grep " connected"))
    disconnected=($(xrandr | grep " disconnected"))
    IFS=$ifs

    for (( i = 0; i < ${#connected[@]}; i++ )); do
        
        declare -gA "monitor_$i=()"
    
        # printout all data got from xrandr
        gr.msg -v3 -c light_blue "[$i]: ${connected[$i]}"

        # get display variables in array
        stuff="monitor_$i[number]"
        printf -v "$stuff" '%s' $i
        gr.msg -n -v3 "[${!stuff}] "

        # get monitor name
        stuff="monitor_$i[name]"
        printf -v "$stuff" '%s' $(cut -d ' ' -f 1 <<<${connected[$i]})
        gr.msg -n -v3 "${!stuff} "
        
        # check it display primary
        stuff="monitor_$i[primary]"
        if grep -q 'primary' <<<${connected[$i]} ; then
                gr.msg -n -v2 "(primary) "
                printf -v "$stuff" '%s' "true"
            else
                printf -v "$stuff" '%s' "false"
            fi

        gr.msg -v3
    done

    monitors=$i
}


display.status () {
    gr.msg -t -n "${FUNCNAME[0]}: "
    display.check $@ && gr.msg -c green "least one display connected" || gr.msg -c dark_grey "no displays detected"
}


display.ls () {

    local name=
    local number=
    local primary=

    # get display date
    display.check

    for (( i = 0; i < $monitors; i++ )); do

        # set variable names for pointers
        name="monitor_$i[name]"
        number="monitor_$i[number]"
        primary="monitor_$i[primary]"

        # do verbose
        case $GRBL_VERBOSE in

            0)  printf "%s " "${!name}"
                (( i >= (monitors - 1) )) && echo
                ;;
            1)  echo "[${!number}] ${!name} ${!primary}"
                ;;
            2)  gr.msg -c light_blue "[${!number}] name: ${!name} primary: ${!primary}"
                ;;

            esac
    done

    return 0
}


display.set_contrast () {
# set display contrast (gamma value)
    local value=1
    [[ $1 ]] && value=$1

    if [[ $GRBL_VERBOSE -gt 1 ]] ; then
        xgamma -gamma $value
    else
        xgamma -gamma $value 2>/dev/null
    fi

    return $?
}


display.set_brightness () {
# set brightness
    local value=1
    [[ $1 ]] && value=$1

    # case $value in
    #         up)
    #             last_value=$(cat $last_brigh)
    #             value=$(let last_value++)

    #             ;;
    #         down)
    #             last_value=$(cat $last_brigh)
    #             value=$(let last_value)

    #             ;;
    #     esac

    while ps auxf | grep redshift | grep -q -v grep ; do
        pkill redshift
        sleep 1
    done

    [[ -f $redshift_flag ]] || touch $redshift_flag

    echo "$value" >$last_brigh

    sleep 0.5
    # gsettings set org.gnome.settings-daemon.plugins.power ambient-enabled false

    display.check

    # set value to connected all displays
    for (( i = 0; i < $monitors; i++ )); do
        stuff="monitor_$i[name]"
        xrandr --output ${!stuff} --brightness $value
        sleep 0.5
    done

}


display.reset () {

    # gsettings set org.gnome.settings-daemon.plugins.power ambient-enabled true
    display.check

    for (( i = 0; i < $monitors; i++ )); do
        stuff="monitor_$i[name]"
        xrandr --output ${!stuff} --brightness 1.0
        sleep 0.5
    done

    display.set_contrast 1.0

    echo "1" >$last_brigh

    while ps auxf | grep redshift | grep -q -v grep ; do
        pkill redshift
        sleep 1
    done

    if [[ -f $redshift_flag ]] ; then
        /usr/bin/redshift >/dev/null 2>/dev/null &
    fi

    [[ -f $toggle_flag ]] && rm $toggle_flag
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    #source $GRBL_RC
    display.main "$@"
    exit $?
fi


# creeds:
# https://stackoverflow.com/users/4615179/ma%c3%ablan
# https://stackoverflow.com/questions/16553089/dynamic-variable-names-in-bash
# https://vitux.com/control-screen-brightness-from-ubuntu-terminal/
