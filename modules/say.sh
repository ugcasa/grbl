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
    gr.debug "$FUNCNAME TBD"
}


say.main () {
# main command parser
    local _input=$@
    local _command="$1"
    shift
    local _message=$@

    case "$_command" in

        file|string|stdin|help|test)
            say.$_command "$_message"
            return $?
            ;;
        *)
            say.string "$_input"
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

say.test () {
# quck test cases

    local sting="one two tree four"
    echo "$sting" >/tmp/test.say

    say.main string "string test: $sting"
    gr.ask -s "did you hear numbers from one to four?" || let error++

    say.main "file test:"
    say.main file /tmp/test.say
    gr.ask -s "did you hear numbers from one to four?" || let error++

    say.main "stdin test:"
    cat /tmp/test.say |say.main stdin
    gr.ask -s "did you hear numbers from one to four?" || let error++

    gr.msg -n -h "test result is " -s
    if [[ $error -lt 1 ]]; then
        gr.msg -c pass "passed" -s
        return 0
    else
        gr.msg -c fail "failed" -s
        return 1
    fi
}

# located here cause rc needs to see some of functions above
say.rc

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    say.main "$@"
    exit $?
fi
