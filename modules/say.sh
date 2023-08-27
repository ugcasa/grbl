#!/bin/bash
# simple voice for guru casa@ujo.guru 2023

# configuration placeholder
declare -A say_cfg=()
declare -g say_cfg_file="$GURU_CFG/say.cfg"
declare -g say_cfg_usr_file="$GURU_CFG/$GURU_USER/say.cfg"

say.help () {

    gr.msg -v1 -c white "guru-cli say help "
    gr.msg -v2
    gr.msg -v0 "usage:    $GURU_CALL say file|help"
    gr.msg -v2
    gr.msg -v1 "  file <filename>       read file "
    gr.msg -v1 '  string "string"       read sting '
    gr.msg -v1 "  stdin <something      read from stdin "
    gr.msg -v1 "  help                  printout this help "
    gr.msg -v2
}


say.check_lang () {
    gr.msg "TBD"
}


say.main () {
# main command parser
    local _command="$1"
    shift

    case "$_command" in

        file|string|stdin|help)
            say.$_command "$@"
            return $?
            ;;
        *)
            say.string "$_command $@"
            return $?
            ;;
    esac
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

    [[ -f $say_cfg_file ]] && source $say_cfg_file || gr.msg -c yellow "no configuration found '$say_cfg_file', using defaults"
    [[ -f $say_usr_cfg_file ]] && source $say_usr_cfg_file

}

# located here cause rc needs to see some of functions above
say.rc

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    say.main "$@"
    exit $?
fi
