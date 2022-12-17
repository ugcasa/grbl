#!/bin/bash
# guru shell work time tracker
# casa@ujo.guru 2019-2020|
# TODO timer module neewds to be write again.. this is useless, still partly working and in use. yes useless.. rotten
# python might be better than bash for mathematics

declare -g timer_rc="/tmp/guru-cli_timer.rc"

timer.main () {
    # main command parser

    command="$1" ; shift
    case "$command" in

        toggle|check|status|start|change|cancel|end|stop|report|log|edit|last|poll)
                timer.$command "$@"
                return $? ;;
        help|*)
                timer.help
                return 0 ;;
    esac
}


timer.help () {
    # general help

    gr.msg -v1 -c white "guru-client timer help "
    gr.msg -v2
    gr.msg -v0 "usage:    $GURU_CALL timer [start|end|cancel|log|edit|report] <task> <project> <customer> "
    gr.msg -v2
    gr.msg -v1 " start <task>         start timer for target with last customer and project"
    gr.msg -v1 " start at [TIME]      start timer at given time in format HH:MM"
    gr.msg -v1 " end|stop             end current task"
    gr.msg -v1 " end at [TIME]        end current task at given time in format HH:MM"
    gr.msg -v1 " cancel               cancel the current task"
    gr.msg -v1 " log                  print out 10 last records"
    gr.msg -v1 " edit                 open work time log with $GURU_EDITOR"
    gr.msg -v1 " report               create report in .csv format and open it with $GURU_OFFICE_DOC"
    gr.msg -v3 " poll start|end       start or end module status polling "
    gr.msg -v2
    gr.msg -v1 "example:  $GURU_CALL timer start config_stuff projectA customerB "
}



timer.rc () {
# source configurations

    if  [[ ! -f $timer_rc ]] || \
        [[ $(( $(stat -c %Y $GURU_CFG/$GURU_USER/timer.cfg) - $(stat -c %Y $timer_rc) )) -gt 0 ]]
        then
            timer.make_rc && \
                gr.msg -v1 -c dark_gray "$timer_rc updated"
        fi

    source $timer_rc
}


timer.make_rc () {
# make core module rc file out of configuration file

    if ! source config.sh ; then
            gr.msg -c yellow "unable to load configuration module"
            return 100
        fi

    if [[ -f $timer_rc ]] ; then
            rm -f $timer_rc
        fi

    if ! config.make_rc "$GURU_CFG/$GURU_USER/timer.cfg" $timer_rc ; then
            gr.msg -c yellow "configuration failed"
            return 101
        fi

    chmod +x $timer_rc

    if ! source $timer_rc ; then
            gr.msg -c red "unable to source configuration"
            return 202
        fi
}



timer.toggle () {
    # key press action

    if timer.status >/dev/null ; then
        timer.end
    else
        timer.start
    fi
    sleep 4
}


timer.check () {
    # check timer state

    timer.status human && return 0 || return 100
    }


timer.status () {
    # output timer status

    gr.msg -n -t -v1 "${FUNCNAME[0]}: "

    # enabled?
    if [[ $GURU_TIMER_ENABLED ]] ; then
            gr.msg -n -v1 -c green "enabled, " -k $GURU_TIMER_INDICATOR_KEY
        else
            gr.msg -v1 -c black "disabled" -k $GURU_TIMER_INDICATOR_KEY
            return 1
        fi

    # check is timer set
    if [[ ! -f "$GURU_FILE_TRACKSTATUS" ]] ; then
        gr.msg -v1 -c reset "no timer tasks" -k $GURU_TIMER_INDICATOR_KEY
        return 2
    fi

    # get timer variables
    source "$GURU_FILE_TRACKSTATUS"

    # fill variables
    timer_now=$(date +%s)
    timer_state=$(($timer_now-$timer_start))
    nice_start_date=$(date -d $start_date '+%d.%m.%Y')
    # static for mathematics
    hours=$(($timer_state/3600))
    minutes=$(($timer_state%3600/60))
    seconds=$(($timer_state%60))

    # format output
    [[ $hours > 0 ]] && print_h=$(printf "%0.2f hours " $hours) || print_h=""
    [[ $minutes > 0 ]] && print_m=$(printf "%0.2f minutes " $minutes) || print_m=""
    [[ $hours > 0 ]] && print_s="" || print_s=$(printf "%0.2f seconds" $seconds)

    # select output format
    case "$1" in

        -h|human)
            gr.msg "working for $customer from $start_time $nice_start_date, now spend:$print_h$print_m$print_s to $project $task "
            ;;

        -t|table)
            gr.msg " Start date      | Start time  | Hours  | Minutes  | Seconds  | Customer  | Project  | Task "
            gr.msg " --------------- | ----------- | ------ | -------- | -------- | --------- | -------- | ------------ "
            gr.msg " $nice_start_date | $start_time | $hours | $minutes | $seconds | $customer | $project | $task"
            ;;

        -c|csv)
            gr.msg "Start date;Start time;Hours;Minutes;Seconds;Sustomer;Project;Task "
            gr.msg "$nice_start_date;$start_time;$hours;$minutes;$seconds;$customer;$project;$task"
            ;;

        old)
            gr.msg "$nice_start_date $start_time > $hours:$minutes:$seconds c:$customer p:$project t:$task"
            ;;

        simple|*)
            gr.msg -v1 -c aqua "$customer $project $task spend: $hours:$minutes" -k $GURU_TIMER_INDICATOR_KEY
            ;;
    esac

    return 0
}


timer.last () {
    # get last timer state

    if [[ -f $GURU_FILE_TRACKLAST ]] ; then
            gr.msg -c light_blue "$(cat $GURU_FILE_TRACKLAST)"
        else
            gr.msg -c yellow "no last tasks"
        fi
}


timer.start () {
    # Start timer TBD rewrite this thole module

    GURU_TIMER_INDICATOR_KEY="f$(gr.poll timer)"
    [[ -d "$GURU_LOCAL_WORKTRACK" ]] || mkdir -p "$GURU_LOCAL_WORKTRACK"

    # check is timer alredy set
    if [[ -f "$GURU_FILE_TRACKSTATUS" ]] ; then
        timer.main end at $(date -d @$(( (($(date +%s)) / 900) * 900)) "+%H:%M")
    fi

    # parse given arguments
    case "$1" in

        at|from)
            shift
            if ! [[ "$1" ]] ; then
                    echo "input start time"
                    return 124
                fi

            if date -d "$1" '+%H:%M' >/dev/null 2>&1; then
                    time=$(date -d "$1" '+%H:%M')
                    shift
                else
                    time=$(date -d @$(( (($(date +%s)) / 900) * 900)) "+%H:%M")
                fi

            if date -d "$1" '+%Y%m%d' >/dev/null 2>&1; then
                    date=$(date -d "$1" '+%Y%m%d')
                    shift
                else
                    date=$(date -d "today" '+%Y%m%d')
                fi
            ;;
        *)
            date=$(date -d "today" '+%Y%m%d')
            time=$(date -d @$(( (($(date +%s)) / 900) * 900)) "+%H:%M")
            ;;
    esac

    # is this really needed? Don't think so
    start_date="$date"
    start_time="$time"
    nice_date=$(date -d $start_date '+%d.%m.%Y')
    timer_start=$(date -d "$start_date $start_time" '+%s')

    [[ -f $GURU_FILE_TRACKLAST ]] && source $GURU_FILE_TRACKLAST
    [[ "$1" ]] && task="$1" || task="$last_task"
    [[ "$2" ]] && project="$2" || project="$last_project"
    [[ "$3" ]] && customer="$3" || customer="$last_customer"

    # update work files TODO some other method, soon please
    printf "timer_start=$timer_start\nstart_date=$start_date\nstart_time=$start_time\n" >$GURU_FILE_TRACKSTATUS
    printf "customer=$customer\nproject=$project\ntask=$task\n" >>$GURU_FILE_TRACKSTATUS

    # signal user and others
    gr.msg -v1 -c aqua -k $GURU_TIMER_INDICATOR_KEY "$start_time $customer $project $task"
    gr.msg -v4 -m $GURU_USER/message $GURU_TIMER_START_MESSAGE
    gr.msg -v4 -m $GURU_USER/status $GURU_TIMER_START_STATUS
    return 0
}


timer.end () {
    # end timer and save to database (file)

    if [ -f $GURU_FILE_TRACKSTATUS ]; then
        source $GURU_FILE_TRACKSTATUS
    else
        gr.msg -v1 "timer not started"
        return 13
    fi

    GURU_TIMER_INDICATOR_KEY="f$(gr.poll timer)"
    local command=$1 ; shift

    case "$command" in
        at|to|till)
            if ! [[ "$1" ]] ; then
                    gr.msg "input end time"
                    return 124
                fi

            # Some level of format check
            if date -d "$1" '+%H:%M' >/dev/null 2>&1; then
                    time=$(date -d "$1" '+%H:%M')
                    shift

                else
                    time=$(date -d @$(( (($(date +%s)) / 900) * 900)) "+%H:%M")
                fi

            if date -d "$1" '+%Y%m%d' >/dev/null 2>&1; then
                    date=$(date -d "$1" '+%Y%m%d')
                    shift
                else
                    date=$(date -d "today" '+%Y%m%d')
                fi
            ;;
        *)
            date=$(date -d "today" '+%Y%m%d')
            time=$(date -d @$(( (($(date +%s) + 900) / 900) * 900)) "+%H:%M")
            ;;
    esac

    end_date=$date
    end_time=$time
    timer_end=$(date -d "$end_date $end_time" '+%s')
    dot_start_date=$(date -d $start_date '+%Y.%m.%d')
    dot_end_date=$(date -d $end_date '+%Y.%m.%d')
    nice_start_date=$(date -d $start_date '+%d.%m.%Y')
    nice_end_date=$(date -d $end_date '+%d.%m.%Y')

    (( spend_sec = timer_end - timer_start ))
    (( spend_min = spend_sec / 60 ))
    (( spend_hour = spend_min / 60 ))
    (( spend_min_div = spend_min % 60 ))

    # round were pain in the bee with bash
    spend_min_dec=$(python3 -c "print(int(round($spend_min_div * 1.6666, 0)))")

    if [[ "$nice_start_date" == "$nice_end_date" ]]; then
        option_end_date=""
    else
        option_end_date=" ($nice_end_date)"
    fi

    # close track file
    if ! [[ -f $GURU_FILE_TRACKDATA ]] ; then
            printf "Start date  ;Start time ;End date ;End time ;Hours ;Customer ;Project ;Task \n" >$GURU_FILE_TRACKDATA
        fi

    hours="$spend_hour.$spend_min_dec"
    #if (( spend_min_dec > 11 )) ; then
            printf "$dot_start_date;$start_time;$dot_end_date;$end_time;$hours;$customer;$project;$task\n" >>$GURU_FILE_TRACKDATA
    #    fi

    printf "last_customer=$customer\nlast_project=$project\nlast_task=$task\n" >$GURU_FILE_TRACKLAST

    rm $GURU_FILE_TRACKSTATUS

    # inform
    gr.msg -v1 -c reset -k $GURU_TIMER_INDICATOR_KEY "$start_time - $end_time$option_end_date $customer $project $task spend $hours"
    gr.msg -v4 -m $GURU_USER/message $GURU_TIMER_END_MESSAGE
    gr.msg -v4 -m $GURU_USER/status $GURU_TIMER_END_STATUS
    return 0
}


timer.stop () {
    # alias stop for end

    timer.end "$@"
    return 0
}


timer.change () {
    # alias change for start


    timer.start "$@"
    gr.msg -v1 -c dark_golden_rod "work topic changed"
    return $?
}


timer.cancel () {
    # cancel exits timer

    GURU_TIMER_INDICATOR_KEY="f$(gr.poll timer)"

    if [ -f $GURU_FILE_TRACKSTATUS ]; then
            rm $GURU_FILE_TRACKSTATUS
            gr.msg -v1 -t -c reset -k $GURU_TIMER_INDICATOR_KEY "work canceled"
            gr.msg -v4 -m $GURU_USER/message "glitch in the matrix, something changed"
            gr.msg -v4 -m $GURU_USER/status "available"
        else
            gr.msg -v1 "not active timer"
        fi
    return 0
}


timer.log () {
    # printout short list of recent records

    printf "last logged records:\n$(tail $GURU_FILE_TRACKDATA | tr ";" "  ")\n"
    return 0
}


timer.edit () {
    # edit data csv file

    $GURU_PREFERRED_EDITOR "$GURU_FILE_TRACKDATA" &
    return 0
}


timer.report() {
    # make a report

    [ "$1" ] && team="$1" || team="$GURU_TEAM"
    report_file="work-track-report-$(date +%Y%m%d)-$team.csv"
    output_folder=$HOME/Documents
    [ "$team" == "all" ] && team=""
    [ -f $GURU_FILE_TRACKDATA ] || return 13

    cat $GURU_FILE_TRACKDATA |grep "$team" |grep -v "invoiced" >"$output_folder/$report_file"
    $GURU_PREFERRED_OFFICE_DOC $output_folder/$report_file &
    timer.end $""
}


timer.poll () {
    # daemon interface

    GURU_TIMER_INDICATOR_KEY="f$(gr.poll timer)"

    local _cmd="$1" ; shift
    case $_cmd in
        start )
            gr.msg -v1 -t -c black "${FUNCNAME[0]}: timer status polling started" -k $GURU_TIMER_INDICATOR_KEY
            ;;
        end )
            gr.msg -v1 -t -c reset "${FUNCNAME[0]}: timer status polling ended" -k $GURU_TIMER_INDICATOR_KEY
            ;;
        status )
            timer.status $@
            ;;
        *)  timer.help
            ;;
        esac
}

timer.rc

if [[ ${BASH_SOURCE[0]} == ${0} ]]; then
    source $GURU_RC
    timer.main $@
    exit $?
fi

