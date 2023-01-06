#!/bin/bash
# guru-client display control commands
# casa@ujo.guru 2022

source common.sh
redshift_flag="/tmp/guru-redshift.flag"
last_brigh="/tmp/guru-display.bright"

display.main () {
    # command parser
    local cmd=$1
    shift

    case $cmd in
         reset|set|ls|help|card)
            display.$cmd $@
            return $?
            ;;
            *)
            gr.msg "'$cmd' is not valid command for monitor module"
            return 1
            ;;
    esac
}


display.help () {
    # help print depending of verbose level
    gr.msg -v1 -c white "guru-client display help "
    gr.msg -v2
    gr.msg -v0 "usage:    $GURU_CALL display ls|set|reset] "
    gr.msg -v2
    gr.msg -v1 -c white  "commands:"
    gr.msg -v1 " ls             list of connected monitors"
    gr.msg -v1 " set <value>    set brightness to all displays"
    gr.msg -v2 "                value between 0.1 .. 1.0"
    gr.msg -v1 " reset          set to brightest "
    gr.msg -v2 "                and restart redshift, if were in use"
    gr.msg -v2 " help           printout this help"
    gr.msg -v2
    gr.msg -v1 -c white  "example:"
    gr.msg -v1 "    $GURU_CALL display set 0.75 "
    gr.msg -v2
    gr.msg -v2 -c white  "WARNING: values below 0.2 are almost black"
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
        case $GURU_VERBOSE in

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


display.set () {
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

    if ps u | grep redshift | grep -v grep ; then
        pkill redshift
        # indicate user were using redshift
        [[ -f $redshift_flag ]] || touch $redshift_flag
    fi

    echo "$value" >$last_brigh

    sleep 1
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

    echo "1" >$last_brigh

    sleep 1

    if [[ $redshift_flag ]] && ! ps u | grep redshift | grep -v grep ; then
        /usr/bin/redshift >/dev/null 2>/dev/null &
    fi

}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    #source $GURU_RC
    display.main "$@"
    exit $?
fi


# creeds:
# https://stackoverflow.com/users/4615179/ma%c3%ablan
# https://stackoverflow.com/questions/16553089/dynamic-variable-names-in-bash
# https://vitux.com/control-screen-brightness-from-ubuntu-terminal/
