#!/bin/bash
# guru-client core
# casa@ujo.guru 2020 - 2023


help.main() {

    local chapter=$1
    shift

    case $chapter in

        common|capslauncher)
            help.$chapter $@
            ;;
        *)
            help.usage
            help.arguments
            help.examples
            help.newbie
            ;;
    esac

    gr.msg -v2 "documentation: $GURU_DOCUMENTATION:$chapter:start" -c white
    gr.msg -v2

}


help.usage () {
    gr.msg -v1 "guru-cli main help $GURU_VERSION_NAME v$GURU_VERSION " -h
    gr.msg -v2
    gr.msg -v0 "usage:  $GURU_CALL -arguments --module_arguments <module_name> <command> "-c white
    gr.msg -v1 "        $GURU_CALL -arguments core_command" -c white
    gr.msg -v2 "        '-' and '--' arguments are not place oriented"
}

help.arguments () {
    gr.msg -v1 "arguments:" -c white
    # gr.msg -v2 " -a               record audio command and run it (TBD!)"
    gr.msg -v1 " -q               be quiet as possible, no audio or text output "
    gr.msg -v1 " -s               speak out command return messages and data "
    gr.msg -v1 " -v 1..4          verbose level, adds headers and some details"
    gr.msg -v1 " -u <user_name>   change guru user name temporary  "
    gr.msg -v1 " -h <host_name>   change computer host name name temporary "
    gr.msg -v1 " -f               set force mode on to be bit more aggressive "
    gr.msg -v1 " -c               disable colors in terminal "
    gr.msg -v3 " -d               run in debug mode, lot of colorful text (TBD!) "
    gr.msg -v1
    gr.msg -v1 "to refer module help, type '$GURU_CALL <module_name> help'"
    gr.msg -v2
}

help.system () {
    gr.msg -v2 "system tools:" -c white
    gr.msg -v2 "  install         install tools "
    gr.msg -v2 "  uninstall       remove guru toolkit "
    gr.msg -v1 "  list            list of stuff "
    gr.msg -v1 "    core          core modules "
    gr.msg -v1 "    modules       installed modules "
    gr.msg -v1 "    available     all modules "
    gr.msg -v1 "    commands      list of available commands "
    gr.msg -v2 " all <command>    run command with all avalable modules"
    gr.msg -v2 "  upgrade         upgrade guru toolkit "
    # gr.msg -v3 "  status          status of stuff (TBD return this function) "
    # gr.msg -v3 "  shell           start guru shell (TBD return this function )"
    gr.msg -v2 "  --ver           printout version "
    gr.msg -v2 "  --help          printout help "
}

help.examples () {
    gr.msg -v2 "examples:" -c white
    gr.msg -v2 "  $GURU_CALL ssh key add github       add ssh keys to github server"
    gr.msg -v2 "  $GURU_CALL timer start at 12:00     start work time timer"
    gr.msg -v2 "  $GURU_CALL note yesterday           open yesterdays notes"
    gr.msg -v2 "  $GURU_CALL install mqtt-server      install mqtt server"
    gr.msg -v2 "  $GURU_CALL radio radiorock          listen radio station"
    gr.msg -v2 "  $GURU_CALL active                   active guru-cli"
    gr.msg -v2 "  $GURU_CALL start                    start daemon"

    gr.msg
}

help.newbie () {
    if [[ -f $HOME/guru/.data/.newbie ]] ; then
        gr.msg -v0 "if problems after installation" -c white
        gr.msg -v0 "  1) logout and login to set path by .profiles or set path:"
        gr.msg -v0 '       PATH=$PATH:$HOME/bin'
        gr.msg -v0 "  2) if no access to ujo.guru access point, create fake data mount"
        gr.msg -v0 '      mkdir $HOME/guru/.data ; touch $HOME/guru/.data/.online'
        gr.msg -v0 "  3) to edit user configurations run:"
        gr.msg -v0 "      $GURU_CALL config user"
        gr.msg -v0 "  4) remove newbie help view by: "
        gr.msg -v0 "       rm $HOME/guru/.data/.newbie"
        gr.msg -v1
    fi
}

help.capslauncher () {
    IFS=$'\n'
    gr.kvt "sdd" "datetime stamp" \
         "sd" "timestamp stamp" \
         "ds" "datestamp stamp" \
         "ws" "weekplan stamp" \
         "ss" "signature stamp" \
         "ca" "capslock toggle " \
         "cs" "project cheatsheet" \
         "cc" "capscode cheatsheet" \
         "tt" "start timer" \
         "to" "stop timer" \
         "tc" "cancel timer" \
         "r*" "play radio (number)" \
         "as" "stop audio" \
         "ts" "short date timestamp " \
         "tn" "readable date timestamp" \
         "n"  "open daily notes" \
         "ni" "idea notes" \
         "nm" "memo notes" \
         "nw" "writing notes" \
         "ny" "yesterdays notes" \
         "nt" "tomorrows notes" \
         "mm" "start minecraft" \
         "clo" "close project" \
         "sto" "open stonks project"
         read -n1 -s
}

help.common() {
# common.sh help parser

    common.msg(){

        gr.msg -v1 'message function' -h
        gr.msg -v1
        gr.msg -v1 "print out text, colors and mqtt messages. Supports verbose leveling, text color column width, "
        gr.msg -v1 "speak out, control line width, blink indication keys on keyboard, timestamps etc."
        gr.msg -v1
        gr.msg -v0 'usage   gr.msg -v|-V|-e|-d|-c|-C|-n|-N|-h|-t|-w|-k|-m|-l|-s|-q|-x  "message string" ' -c white
        gr.msg -v1
        gr.msg -v1 "    -v <1..4>       verbose_trigger, print after given verbose level"
        gr.msg -v1 "    -V <1..4>       verbose limiter, do not print higher than this verbose level"
        gr.msg -v1 "    -e <1..5>       error codes to stderr"
        gr.msg -v1 "    -d              debug messages to stderr"
        gr.msg -v1
        gr.msg -v1 "formatting" -c white
        gr.msg -v1
        gr.msg -v1 "    -c <color>      text and key color"
        gr.msg -v1 "    -C <color>      change line color"
        gr.msg -v1 "    -n              add newline after string"
        gr.msg -v1 "    -N              add newline before string"
        gr.msg -v1 "    -h              header formatting"
        gr.msg -v1 "    -t              timestamp"
        gr.msg -v1 "    -w <width>      column width"
        gr.msg -v1
        gr.msg -v1 "indications and locations" -c white
        gr.msg -v1
        gr.msg -v1 "    -k <key_name>   keyboard key="
        gr.msg -v1 "    -m <topic>      MQTT server topic "
        gr.msg -v1 "    -l              write to log"
        gr.msg -v1 "    -s              speaks message out "
        gr.msg -v1 "    -q              quick message to default MQTT topic "
        gr.msg -v1 "    -x <exit_code>  exit after message with error code"
        gr.msg -v1
        gr.msg -v1 "known issues" -c white
        gr.msg -v1 "  iss1214) message string cannot start with a line '-'"
        gr.msg -v1

    }

    common.ask() {

        gr.msg -v1 'yes/no question function' -h
        gr.msg -v2
        gr.msg -v1 "Simple yes no question selector. Returns 'true' if answer is yes. "
        gr.msg -v2
        gr.msg -v0 'usage   gr.ask -t|-s|-d "questing string?" ' -c white
        gr.msg -v2
        gr.msg -v1 "    -t <n>          timeout in seconds "
        gr.msg -v1 "    -s              speaks message out "
        gr.msg -v1 "    -d <y/n>        default answer"
        gr.msg -v2
        gr.msg -v1 "known issues"
        gr.msg -v1 "  iss1214) message string cannot start with a line '-'"
        gr.msg -v2
    }

    common.ind () {

        gr.msg -v1 "Keyboard, text and audio indication actions"
        gr.msg -v2
        gr.msg -v0 'usage   gr.ind <options> <action> ' -c white
        gr.msg -v2
        gr.msg -v1 "  -m     message string"
        gr.msg -v1 "  -k     keyboard key"
        gr.msg -v1 "  -c     color name"
        gr.msg -v1 "  -t     timestamp  "
        gr.msg -v2
        gr.msg -v1 "currently available actions: keyboard and audio indications "
        gr.msg -v1 "   done, available, recovery, working, pause, cancel, error, offline, "
        gr.msg -v1 "   warning, alert, panic, pass, failed, message, flash, cops, police, "
        gr.msg -v1 "   calm, hacker, russia, china, call and customer"
        gr.msg -v2
    }

     common.end () {

        gr.msg -v1 'Way end animations of keyboard indication leds ' -h
        gr.msg -v2
        gr.msg -v0 'usage   gr.end <keyboard_key> ' -c white
        gr.msg -v2
        gr.msg -v1 "Ends blink animation on keys of corsair keyboard"
        gr.msg -v2
    }

    common.dump () {

        gr.msg -v1 'Core dump function' -h
        gr.msg -v2
        gr.msg -v0 'usage   gr.dump ' -c white
        gr.msg -v2
        gr.msg -v1 "export current environment to file '$GURU_CORE_DUMP' and exit"
        gr.msg -v2
    }

    common.debug () {

        gr.msg -v1 "Printout pink debug stuff"
        gr.msg -v2
        gr.msg -v0 'usage   gr.debug <string> ' -c white
        gr.msg -v2
    }

    common.ts () {

        gr.msg -v1 'Alternative timestamp function' -h
        gr.msg -v2
        gr.msg -v0 'usage   gr.ts <format> ' -c white
        gr.msg -v2
        gr.msg -v1 "Timestamp printout in different formats + place to clipboard. "
        gr.msg -v1 "Another way to produce timestamps is to use stamp.sh."
        gr.msg -v2
        gr.msg -v1 "    epoch|-e    epoch format: $(date -d now +"%s")"
        gr.msg -v1 "    file|-f     file name compatible: $(date -d now +$GURU_FORMAT_FILE_DATE-$GURU_FORMAT_FILE_TIME)"
        gr.msg -v1 "    human|-h    human readable: $(date -d now +$GURU_FORMAT_DATE $GURU_FORMAT_TIME)"
        gr.msg -v1 "    nice|-n     nice TBD: $(date -d now +$GURU_FORMAT_NICE)"
        gr.msg -v1 "                default is: $(date -d now +$GURU_FORMAT_TIMESTAMP)"
        gr.msg -v2
    }

    common.poll () {

        gr.msg -v1 'Get processing order for daemon polling function ' -h
        gr.msg -v2
        gr.msg -v0 'usage   gr.poll <module_name> ' -c white
        gr.msg -v2
        gr.msg -v1 "returns module polling order from user configurations for daemon.sh "
        gr.msg -v2
    }

    common.source () {

        gr.msg -v1 "Source only wanted functions from module"
        gr.msg -v2
        gr.msg -v0 'usage   gr.source <module_name> [list on wanted functions] ' -c white
        gr.msg -v2
        gr.msg -v1 'Way to reduce environment usage when no need to source all functions ' -h
        gr.msg -v2
    }

    common.installed () {

        gr.msg -v1 "Check is module installed"
        gr.msg -v2
        gr.msg -v0 'gr.installed <module> ' -c white
        gr.msg -v2
    }

    common.presence () {

        gr.msg -v1 "User presence check based on phone wifi"
        gr.msg -v2
        gr.msg -v0 'usage   gr.presence <action> ' -c white
        gr.msg -v2
        gr.msg -v1 "actions: stop|end stop polling phone"
        gr.msg -v2
    }

    common.kv () {

        gr.msg -v1 "print one line of variable value list. "
        gr.msg -v2
        gr.msg -v0 'usage   gr.kv <variable> <value> ' -c white
        gr.msg -v2
    }

    common.kvt () {

        gr.msg -v1 "Format list of sting pairs to two column list view"
        gr.msg -v2
        gr.msg -v0 'usage   gr.kvt <variable> <value> <variable> <value> ... ' -c white

    common.kvp () {
        gr.msg -v1 "print key value pairs based list of variable names"    gr.msg -v2
        gr.msg -v2
        gr.msg -v0 'usage   gr.kvt variable name   ... ' -c white
    }


gr.kv() {
# print key value pair

gr.kvt () {
# print key value pair list

gr.kvp () {
# print key value pairs based list of variable names

    local function=$1
    shift

    case $function in
        msg|ask|dump|ts|poll|source|end|ind|installed|presence|debug)
            common.$function $@
            ;;
        all)
            common.msg
            common.ask
            common.dump
            common.ts
            common.poll
            common.source
            common.end
            common.ind
            common.installed
            common.presence
            common.debug
            ;;
        *)
            gr.msg -v1 "guru-cli common.sh help" -h
            gr.msg -v1
            gr.msg -v1 "'common.sh' contains group of functions for modules to use. Some functions are "
            gr.msg -v1 "available all time. To get all function in use common.sh needs to be sourced:"
            gr.msg -v1
            gr.msg -v0 "  source common.sh " -c white
            gr.msg -v0 '  gr.msg -c white "hello" ' -c white
            gr.msg -v1
            gr.msg -v1 "all time available functions are: gr.msg, gr.ask, gr.end, gr.ind and gr.debug"
            gr.msg -v1 "other need sousing: gr.ts, gr.poll, gr.source, gr.installed, gr.presence, gr.kv and gr.kvt"
            gr.msg -v1
            gr.msg -v1 "for more information try: "
            gr.msg -v1
            gr.msg -v0 "  $GURU_CALL help common <function> " -c white
            gr.msg -v1
            gr.msg -v1 "available functions are: "
            gr.msg -v1 "    msg, ask, dump, ts, poll, source, end, ind, installed, presence and debug"
            gr.msg -v1
            ;;
    esac
}
