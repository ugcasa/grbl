#!/bin/bash
# No Fucking Point to Clone Disaster 
# IN case of NFPCP: 
# This is free but useless piece of software. Shit comes without any warranty, to
# the extent permitted by applicable law. If you like to use these uninspiring scripts, 
# you may/or may not redistribute it and/or modify it under the terms of the Do What The 
# Fuck You Want To Public License. In case of wisdom is your guide to life, DO NOT USE 
# this piece of crap for any purpose (except professional chuckle). In case you accidentally 
# cloned this repository it is advisable to remove directory immediately! 
# Published for no reason by Juha Palm ujo.guru 2019
# 
# In case of IOTSIHTOTBACM (installation of this shit in hindsight turned out to be a colossal mistake) do:
# guru uninstall; [ -d $GURU_CFG ] && rm /$GURU_CFG -rf     # to get totally rig of this worm and all your personal configs

version="0.4.5"

source "$HOME/.gururc"                      # user and platform settings (implement here, always up to date)
source "$GURU_CFG/$GURU_USER/deco.cfg"
source "$GURU_BIN/functions.sh"                 # common functions, if no ".sh", check here
source "$(dirname "$0")/lib/common.sh"

counter_main add guru-runned >/dev/null

#$GURU_CALL counter add guru_runned

main () {

    if [ "$1" ]; then                     # guru without parameters starts terminal loop
        parse_argument $@ 
        error_code=$?
    else
        terminal                        # rsplib-legacy-wrappers name collision, not big broblem i think
        
        error_code=$?
    fi

    if (( error_code > 1 )); then
        
        [ -f "$GURU_ERROR_MSG" ] && error_message=$(tail -n 1 $GURU_ERROR_MSG)
        #error_message=$(cat -n 1 $GURU_ERROR_MSG)
        logger "$0 $argument: $error_code: $error_message"              # log errors
        echo "error: $error_code: $error_message"                       # print error
        rm -f $GURU_ERROR_MSG
    fi

    return "$error_code"
}


parse_argument () {
    # parse arguments and delivery variables to corresponding application, function, bash script, python.. whatever

    help () {
             printf "\n-- guru tool-kit linux client - v.$version ---------------- casa@ujo.guru - 2017 - 2020 \n"
                printf "\nUsage:\n\t %s [tool] [command] [variables] \n\nCommand:\n\n" "$GURU_CALL"
                printf 'timer           work track tools ("%s timer help" for more info) \n' "$GURU_CALL"
                printf 'notes           open daily notes \n'
                printf 'translate       google translator in terminal \n'
                printf 'status          status of user \n'
                printf 'ssh             basic ssh functions \n'
                printf 'remote          remote file pulls and pushes \n'
                printf 'mount|umount    mount remote locations \n'
                printf 'document        compile markdown to .odt format \n'
                printf 'keyboard        to setup keyboard shortcuts \n'
                printf 'input           to control varies input devices (keyboard etc.) \n'
                printf 'radio           fm-radio (hackrone rf) \n'
                printf 'news            text-tv like news feed reader for terminal\n'
                printf 'stamp           time stamp to clipboard and terminal\n'
                printf 'counter         to count things \n'
                printf 'play            play videos and music ("%s play help" for more info) \n' "$GURU_CALL"                           
                printf 'phone           get data from android phone \n'
                printf 'set             set options ("%s set help" for more information) \n' "$GURU_CALL" 
                printf 'silence         kill all audio and lights \n'
                printf 'install         install tools ("%s install help" for more info) \n' "$GURU_CALL"
                printf 'upgrade         upgrade guru toolkit \n'
                printf 'uninstall       remove guru toolkit \n'
                printf 'terminal        start guru toolkit in terminal mode to exit terminal mode type "exit"\n'                
                printf 'version         printout version \n'
                printf "\nMost of tools has it own more detailed help page. pls review those before contacting me ;)\n"             
                printf "\nExamples:\n"
                printf "\t %s note yesterday ('%s note help' m morehelp)\n" "$GURU_CALL"
                printf "\t %s install mqtt-server \n" "$GURU_CALL"
                printf "\t %s ssh key add github \n" "$GURU_CALL"
                printf "\t %s timer start at 12:00 \n" "$GURU_CALL"
                printf "\t %s keyboard add-shortcut terminal %s F1\n" "$GURU_CALL" "$GURU_TERMINAL"
                printf "\t %s mount /home/%s/share /home/%s/mount/%s/ \n\n"\
                       "$GURU_CALL" "$GURU_REMOTE_FILE_SERVER_USER" "$USER" "$GURU_REMOTE_FILE_SERVER"
    }

    argument="$1"                       # store original argument
    shift                               # shift arguments left
    export GURU_CMD="$argument"

    case $argument in 

            # os commands
            clear|ls|cd|echo) 
                $argument "$@"
                return $?
                ;;          

            # functions (in functions.sh)
            tor|trans|translate|status|upgrade|document|slack|terminal|set)
                $argument "$@"
                return $? 
                ;;  

            # bash scripts
            unmount|mount|user|project|keyboard|remote|input|counter|note|stamp|timer|phone|play|vol|install|scan|tag|yle)         
                $argument.sh "$@" 
                return $?           
                ;;

            # direct lib calls
            ssh|os|common|tme)         
                lib/$argument.sh "$@" 
                return $?           
                ;;

            # python scripts
            uutiset)
                $argument.py "$@" 
                return $?           
                ;;

            radio)                      # leave background    
                DISPLAY=:0  
                $argument.py "$@" &
                return $?           
                ;;

            # basic stuff
            version|ver|-v|--ver)       # version
                printf "giocon.client v.$version installed to $0\n"
                return 0
                ;;

            uninstall)                  # Get rid of this shit 
                bash $GURU_BIN/uninstall.sh "$@"
                return $? 
                ;;

            help|-h|--help)             # hardly never updated help printout
                help "$@"
                return 0
                ;;

            test)
                case "$1" in
                    1|all )
                        test_all "$@"
                        ;;
                    help|-h )
                        printf "\nUsage:\n\t %s test [<tool>|all] <level> \n" "$GURU_CALL"
                        printf "\nCommands:\n\n"
                        printf " all           test all tools \n" 
                        printf " <level>       numeral level of test detail where: \n"
                        printf "               1 = just a check \n"
                        printf "               2 = tests with temp locations \n"
                        printf "               3 = hot locations \n"
                        printf "\nExample:\n"
                        printf "\t %s test remote 1 \n" "$GURU_CALL" 
                        printf "\t %s test mount 2 \n" "$GURU_CALL" 
                        printf "\t %s test all \n\n" "$GURU_CALL" 
                        echo 
                        ;;
                    *) 
                        test_tool "$@"
                esac
                ;;

            
            "")                 
                ;;

            *)  
                printf "$argument: command not found\n"
    esac    
}


terminal() { 
    # Terminal looper   
    echo $GURU_CALL' in terminal mode (type "help" enter for help)'
    #$GURU_CALL counter add guru_terminal_runned
    while :                                         
        do
            . $HOME/.gururc
            read -e -p "$(printf "\e[1m$GURU_USER@$GURU_CALL\\e[0m:>") " "cmd" 
            [ "$cmd" == "exit" ] && exit 0
            parse_argument $cmd
        done
    return 123
}


test_all() {
    [ "$2" ] && level="$2" || level="all"
    local test_id=$(counter_main add guru-ui_test_id)
    printf "\nTEST $test_id: guru-ui $level $(date) \n" | tee -a "$GURU_LOG"
    unset status
    
    source mount.sh; mount_main test $level; status=$((status+$?))      # TODO not really getting error this far, fix or
    source remote.sh; remote_main test $level; status=$((status+$?))    # find netter method
    source note.sh; note_main test $level; status=$((status+$?))    # find netter method
    
    return $status
}


test_tool() {
    [ "$2" ] && level="$2" || level="all"    
    [ -f "$GURU_BIN/$1.sh" ] && source "$1.sh" || return 123
    local test_id=$(counter_main add guru-ui_test_id)
    printf "\nTEST $test_id: guru-ui $1 $(date) \n" | tee -a "$GURU_LOG"
    $1_main test $level
    return $?
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
    exit $?
fi

