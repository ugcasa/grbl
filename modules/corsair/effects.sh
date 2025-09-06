############################ corsair indication efects ###############################
# relies on corsair variables, source only from corsair module

corsair.blink_all () {
# set blink animation to whole key map
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    for key in ${corsair_keytable[@]} ; do
        # corsair.set $key $color
        corsair.indicate panic $key
    done

    sleep 3

    for key in ${corsair_keytable[@]} ; do
        # corsair.set $key $color
        gr.end $key
    done

    sleep 3
    corsair.init olive
}


corsair.end () {
# reserve some keys for future purposes by coloring them now
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    corsair.blink_kill $@
    return $?
}


corsair.indicate () {
# indicate state to given key. input mode_name and key_name
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    # corsair.check is too slow to go trough here
    if ! [[ $GRBL_CORSAIR_ENABLED ]] ; then
        gr.msg -v2 -c dark_grey "corsair disabled"
        return 1
    fi

    # default values
    local concern="warning"
    local key="esc"
    local color="aqua_marine"
    local blink="white black 0.2 1"

    # user input
    [[ $1 ]] && concern=$1 ; shift
    [[ $1 ]] && key=$1 ; shift
    [[ $GRBL_PROJECT_COLOR ]] && color=$GRBL_PROJECT_COLOR

    case $concern in
        # positions: fg color bg_color blink_interval timeout leave_color
        ok)             blink="green slime 0.5 3 green" ;;
        available)      blink="green aqua_marine 0.2 1 green" ;;
        yes)            blink="green black 0.75 10 " ;;
        no)             blink="red black 0.75 10 " ;;
        cancel)         blink="orange $GRBL_CORSAIR_MODE 0.2 3 " ;;
        init)           blink="blue dark_blue 0.1 5 " ;;
        pass*)          blink="slime $GRBL_CORSAIR_MODE 1 300 green" ;;
        fail*)          blink="red $GRBL_CORSAIR_MODE 1 300 red" ;;
        done)           blink="green slime 4 $GRBL_DAEMON_INTERVAL green" ;;
        do*)            blink="aqua aqua_marine 1 $GRBL_DAEMON_INTERVAL" ;;
        work*)          blink="aqua aqua_marine 5 $GRBL_DAEMON_INTERVAL" ;;
        recovery)       blink="blue black 5 $GRBL_DAEMON_INTERVAL blue" ;;
        grinding)       blink="blue aqua_marine 1 $GRBL_DAEMON_INTERVAL" ;;
        play*)          blink="aqua aqua_marine 2 $GRBL_DAEMON_INTERVAL" ;;
        active)         blink="aqua aqua_marine 0.5 5" ;;
        pause)          blink="black $GRBL_CORSAIR_MODE 1 3600";;
        error)          blink="orange yellow 1 5 yellow" ;;
        message)        blink="deep_pink dark_orchid 2 1200 dark_orchid" ;;
        call)           blink="deep_pink black 0.75 30 deep_pink" ;;
        customer)       blink="deep_pink white 0.75 30 deep_pink" ;;
        offline)        blink="blue orange 1.25 $GRBL_DAEMON_INTERVAL orange" ;;
        secred)         blink="deep_pink blue 1.25 $GRBL_DAEMON_INTERVAL orange" ;;
        partly)         blink="aqua blue 1.25 $GRBL_DAEMON_INTERVAL orange" ;;
        warn*)          blink="red orange 0.75 3600 orange" ;;
        alert)          blink="red black 0.5 $GRBL_DAEMON_INTERVAL" ;;
        blue)           blink="blue black 0.5 $GRBL_DAEMON_INTERVAL" ;;
        notice)         blink="orange_red black 0.75 $GRBL_DAEMON_INTERVAL " ;;
        panic)          blink="red white 0.2 $GRBL_DAEMON_INTERVAL red" ;;
        breath|calm)    blink="dark_cyan dark_turquoise 6 600" ;;
        cops|police)    blink="medium_blue red 0.75 60" ;;
        hacker)         blink="white black 0.2 3600 red" ;;
        important)      blink="red yellow 0.75 3600" ;;
    esac

    (corsair.blink_set $key $blink) >/dev/null 2>/dev/null
    return 0
}


corsair.blink_set () {
# start to blink input: key_name base_color high_color delay_sec timeout_sec leave_color
# leave color is color what shall be left on key shen stoppend or killed.
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    # all options are optional but position is critical cause read from left to right default setting below:
    local key="esc"
    local base_c="red"
    local high_c="orange"
    local delay=0
    local timeout=0
    local leave_color=$GRBL_CORSAIR_MODE

    [[ $1 ]] && key=$1 ; shift
    [[ $1 ]] && base_c=$1 ; shift
    [[ $1 ]] && high_c=$1 ; shift
    [[ $1 ]] && delay=$1 ; shift
    [[ $1 ]] && timeout=$1 ; shift
    [[ $1 ]] && leave_color=$1 ; shift

    # TBD slow method, do better
    if [[ -f /tmp/$USER/blink_pid ]] && cat /tmp/$USER/blink_pid | grep "\b$key\b" 2>/dev/null ; then
        corsair.blink_kill $key 2>/dev/null
    fi

    touch /tmp/$USER/blink_$key
    time_out=$(date +%s)
    time_out=$(( time_out + timeout ))

    # https://stackoverflow.com/questions/11097761/is-there-a-way-to-make-bash-job-control-quiet
    ## note: () encapsulation will brake pid save - removed
    while true ; do

        time_now=$(date +%s)

        if ! [[ -f /tmp/$USER/blink_$key ]] || (( time_now > time_out )) ; then
            corsair.set $key $leave_color
            grep -v "\b$key\b" /tmp/$USER/blink_pid >/tmp/$USER/tmp_blink_pid
            mv -f /tmp/$USER/tmp_blink_pid /tmp/$USER/blink_pid
            break
        else
            corsair.set $key $base_c
            [[ $delay ]] && (sleep $delay)
            corsair.set $key $high_c
            [[ $delay ]] && (sleep $delay)
        fi
    done &
    pid=$!

    gr.debug "$pid;$key"
    echo "$pid;$key" >>/tmp/$USER/blink_pid
}

corsair.blink_stop () {
# stop blinking in next cycle
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    local key="esc"
    [[ $1 ]] && key=$1 ; shift

    [[ -f "/tmp/$USER/blink_$key" ]] && rm "/tmp/$USER/blink_$key"
}

corsair.blink_kill () {
# stop blinking process now, input keyname
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    [[ -f /tmp/$USER/blink_pid ]] && pids_to_kill=($(cat /tmp/$USER/blink_pid))

    local pid=""
    local key=""
    local _pid=""
    local leave_color="$GRBL_CORSAIR_MODE"

    for _to_kill in ${pids_to_kill[@]} ; do

        if [[ $1 ]] ; then
            key=$1
            _pid=$(cat /tmp/$USER/blink_pid | grep "\b$key\b")
            pid=$(echo ${_pid} | cut -d ';' -f1)
        else
            key=$(echo ${_to_kill[@]} | cut -d ';' -f2)
            pid=$(echo ${_to_kill[@]} | cut -d ';' -f1)
        fi

        [[ $pid ]] || return 0

        [[ -f "/tmp/$USER/blink_$key" ]] && rm "/tmp/$USER/blink_$key"

        gr.varlist "debug key pid _pid"

        if kill -15 $pid 2>/dev/null ; then
            # gr.msg -n -c reset -k $key
            corsair.set $key $leave_color
            #echo "$pid;$key" >>/tmp/$USER/blink_pid
            grep -v "\b$key\b" /tmp/$USER/blink_pid >/tmp/$USER/tmp_blink_pid
            mv -f /tmp/$USER/tmp_blink_pid /tmp/$USER/blink_pid
            [[ $1 ]] && return 0

        else
            kill -9 $pid 2>/dev/null || \
                gr.msg -v1 -c yellow "failed to kill $pid" -k $key
                return 100
        fi
    done
    return 0
}

corsair.type_end () {
# end current type process
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug

    if [[ -f /tmp/$USER/grbl_corsair-typing ]] ; then
        rm /tmp/$USER/grbl_corsair-typing
        #kill /tmp/$USER/grbl_corsair.pid
        #rm /tmp/$USER/grbl_corsair.pid
    fi
}

corsair.type () {
# blink string characters by key lights. input color of keys and then string
    gr.msg -v4 -n -c $__corsair_color "$__corsair [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo "'$@'" >&2 # debug


    string=${@,,}

    # set color (optional)
    color=white
    #colors=($(gr.colors))

    touch /tmp/$USER/grbl_corsair-typing

    for (( i=0 ; i < ${#string} ; i++ )) ; do

        # TBD following does not work when called from script, dunno why
        [[ -f /tmp/$USER/grbl_corsair-typing ]] || break

        key="${string:$i:1}"

        case $key in
          '\' ) # CHECK: is this really like that?
            gr.msg -n -v3  " "
            key="space"
            ;;

          "."|":")
            gr.msg -n -v3 "$key"
            key="perioid"
            ;;

          ","|":")
            gr.msg -n -v3 "$key"
            key="comma"
            ;;

          "-"|"_")
            gr.msg -n -v3 "$key"
            key="minus"
            ;;

          "/")
            gr.msg -n -v3 "/"
            key="7"
            ;;

          "!")
            gr.msg -n -v3 ""
            key="1"
            ;;

          "?"|"+")
            gr.msg -n -v3 "$key"
            key="plus"
            ;;

          "'"|'"'|'('|')')
            continue
            ;;

          *)
            gr.msg -n -v3 $key
        esac

        #color=${GRBL_COLOR_LIST[$i]}
        # if color given in upcase, leave letters to shine
        #[[ ${color:0:1} == [A-Z] ]] && continue
        corsair.main set $key $color
        sleep 0.4
        corsair.main reset $key
        sleep 0.2

    done & 2>/dev/null
    #echo $! >/tmp/$USER/grbl_corsair.pid
    gr.msg -v3
}


