#!/bin/bash
# simple voice for guru casa@ujo.guru 2023

espeak    -p $GURU_SPEAK_PITCH \
          -s $GURU_SPEAK_SPEED \
          -v $GURU_SPEAK_LANG \
          "$@"


exit $?

### Broken

### casa@electra#client:~/git/guru-client/modules$ gr say file mur.txt
### chmod: cannot access '/tmp/guru-cli_say.rc': No such file or directory
### /home/casa/bin/say.sh: line 107: /tmp/guru-cli_say.rc: No such file or directory
### /home/casa/bin/say.sh: line 89: /tmp/guru-cli_say.rc: No such file or directory
### espeak: option requires an argument -- 'v'

# configuration placeholder
declare -A say_cfg=()
declare -g say_rc="/tmp/guru-cli_say.rc"
declare -g say_cfg_file="$GURU_CFG/say.cfg"
# user level config: "$GURU_CFG/$GURU_USER/say.cfg"


say.help () {

    gr.msg -v1 -c white "guru-cli say help "
    gr.msg -v2
    gr.msg -v0 "usage:    $GURU_CALL say file|help"
    gr.msg -v2
    gr.msg -v1 "  file <filename>       read file "
    gr.msg -v1 "  help                  printout this help "
    gr.msg -v2
    #gr.msg -v1  "options:"
    #gr.msg -v1   " --file               read file"
    gr.msg -v2
    gr.msg -v2 "tunneling commands " -c white
    gr.msg -v2 "  tunnel fast [command] <host>  fast (and brutal) way to open tunnel"
    gr.msg -v2
}


say.main () {
# main command parser
    local _command=$1
    shift

    case "$_command" in

        file|string|stdin|help)
            say.$_command $@
            return $?
            ;;
        *)
            gr.msg -c white "say module: unknown command '$_command'"
            return 1
            ;;
    esac
   # rm $say_rc
}


say.file () {

    espeak -f "$1" \
           -p ${say_cfg[pitch]} \
           -s ${say_cfg[speed]} \
           -v ${say_cfg[lang]}

    return $?
}


say.string () {

    espeak -p ${say_cfg[pitch]} \
           -s ${say_cfg[speed]} \
           -v ${say_cfg[lang]} \
           "$@"
    return $?
}


say.stdin () {

    espeak --stdin \
           -p ${say_cfg[pitch]} \
           -s ${say_cfg[speed]}
    return $?
}


say.rc () {
# source configurations (to be faster)

    if [[ ! -f $say_rc ]] \
        || [[ $(( $(stat -c %Y $say_cfg_file) - $(stat -c %Y $say_rc) )) -gt 0 ]] ; then
            say.make_rc && \
                gr.msg -v1 -c dark_gray "$say_rc updated"
        fi

    [[ ! -d $say_data_folder ]] && [[ -f $GURU_SYSTEM_MOUNT/.online ]] && mkdir -p $say_playlist_folder
    source $say_rc
}


say.make_rc () {
# configure say module

    source config.sh

    # make rc out of foncig file and run it
    gr.msg -c pink "$say_cfg_file:$say_rc"

    if [[ -f $say_rc ]] ; then
            rm -f $say_rc
        fi

    config.make_rc $say_cfg_file $say_rc

    chmod +x $say_rc
    source $say_rc
}


# located here cause rc needs to see some of functions above
say.rc

# variables that needs values that say.rc provides
declare -g say_data_folder="$GURU_SYSTEM_MOUNT/say"

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    say.main $@
    exit $?
fi


# prototype:
# espeak    -p $GURU_SPEAK_PITCH \
#           -s $GURU_SPEAK_SPEED \
#           -v $GURU_SPEAK_LANG \
#           "$@"
