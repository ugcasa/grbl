#!/bin/bash
# guru tool-kit testing functions for all modules

source $GURU_BIN/lib/common.sh
source $GURU_BIN/lib/deco.sh
source $GURU_BIN/functions.sh
source $GURU_BIN/counter.sh
source $GURU_BIN/mount.sh
source $GURU_BIN/remote.sh
source $GURU_BIN/note.sh
source $GURU_BIN/timer.sh


# Tool test case functions

test.note_mountpoint() {
    if note.remount; then
            TEST_PASSED ${FUNCNAME[0]}
            return 0
        else
            TEST_FAILED ${FUNCNAME[0]}
            return 10
        fi
    return $?
}


remote.test_config(){
    # test remote configuration pull and push
    local _error=30
    if remote.push_config; then
            _error=0
        else
            _error=$((_error+1))
        fi

    if remote.pull_config; then
            _error=$_error
        else
            _error=$((_error+1))
        fi

    if ((_error<9)); then
            TEST_PASSED ${FUNCNAME[0]}
        else
            TEST_FAILED ${FUNCNAME[0]}
        fi

    return $_error
}


mount.clean_test () {
    local error=0
    if unmount.defaults_raw; then
            TEST_PASSED "${FUNCNAME[0]} unmount"
            error=0
        else
            TEST_FAILED "${FUNCNAME[0]} unmount"
            error=10
        fi

    if mount.defaults_raw; then
            TEST_PASSED "${FUNCNAME[0]} mount"
            error=$((error))
        else
            TEST_FAILED "${FUNCNAME[0]} mount"
            error=$((error+10))
        fi
    return $error
}


mount.test_mount () {
    if mount.remote "/home/$GURU_USER/usr/test" "$HOME/tmp/test_mount"; then
            TEST_PASSED ${FUNCNAME[0]}
            return 0
        else
            TEST_FAILED ${FUNCNAME[0]}
            return 10
        fi
}


mount.test_unmount () {
    local _mount_point="$HOME/tmp/test_mount"
    if mount.unmount "$_mount_point"; then
            TEST_PASSED ${FUNCNAME[0]}
            rm -rf "$H_mount_point" || WARNING "error when removing $_mount_point "
            return 0
        else
            TEST_FAILED ${FUNCNAME[0]}
            return 10
        fi
}


mount.test_default_mount (){
    local _error=0
    msg "file server default folder mount \n"
    if mount.defaults_raw; then
            TEST_PASSED "${FUNCNAME[0]} mount"
            _error=0
        else
            TEST_FAILED "${FUNCNAME[0]} mount"
            _error=$((_error+10))
        fi

    sleep 0.5
    msg "un-mount defaults  "
    if unmount.defaults_raw; then
            TEST_PASSED "${FUNCNAME[0]} unmount"
            _error=$_error
        else
            TEST_FAILED "${FUNCNAME[0]} unmount"
            _error=$((_error+1))
        fi

    if ((_error>9)); then
        return 29
    else
        return 0
    fi
}


mount.test_known_remote () {
    local _error=""
    mount.unmount Audio
    mount.known_remote Audio; _error=$?
    if ((_error<10)); then
            TEST_PASSED ${FUNCNAME[0]}
            return 0
        else
            TEST_FAILED ${FUNCNAME[0]}
            return 0
        fi
}


main.test_tool() {
    # Tool to test tools. Simply call sourced tool main function and parse normal commands
    [ "$1" ] && tool=$1 || read -r -p "imput tool name to teset: " tool
    [ "$2" ] && level="$2" || level="all"
    [ -f "$GURU_BIN/$1.sh" ] && source "$1.sh" || return 123
    local test_id=$(counter.main add guru-ui_test_id)
    msg "\nTEST $test_id: guru-ui $1 $level $(date)\n"
    if $1.test "$level"; then
            TEST_PASSED "TEST $test_id $tool"
            return 0
        else
            TEST_FAILED "TEST $test_id $tool"
            return 25
        fi
}


## tool test parsers

note.test() {
    mount.system
    local test_case="$1"
    local _error=0
    case "$test_case" in
                1) note.check               ; return $? ;;
                2) test.note_mountpoint     ; return $? ;;
                3) note.list                ; return $? ;;
              all) test.note_mountpoint     || _error=42
                   note.list                || _error=43
                   return $_error           ;;
               *)  msg "unknown test case '$test_case'\n"
                   return 1
    esac
}

remote.test () {
    mount.system
    local test_case="$1"
    local _error=0
    case "$test_case" in
               1) remote.check              ; return $? ;;
               2) remote.test_config        ; return $? ;;
             all) remote.check              || _error=31
                  remote.test_config        || _error=32
                  return $_error            ;;
               *) msg "unknown test case '$test_case'\n"
                  return 1
    esac
}

mount.test () {
    mount.system
    local test_case="$1"
    local _error=0
    case "$test_case" in
               1) mount.check_system        ; return $? ;;
               2) mount.test_mount          ; return $? ;;
               3) mount.test_unmount        ; return $? ;;
               4) mount.test_list           ; return $? ;;
               5) mount.test_info           ; return $? ;;
               6) mount.test_default_mount  ; return $? ;;
               7) mount.test_known_remote   ; return $? ;;
         clean|8) mount.clean_test          ; return $? ;;
             all) mount.check_system        || _error=21
                  mount.test_mount          || _error=22
                  mount.test_unmount        || _error=23
                  mount.test_list           || _error=24
                  mount.test_info           || _error=25
                  mount.test_known_remote   || _error=27
                  mount.clean_test          || _error=28
                  return $_error                ;;
               *) msg "unknown test case '$test_case'\n"
                  return 1
    esac
}


## main test parser

mount.test_info () {
    msg "sshfs info test\n"
    mount.system                                    # be sure that system is mounted to validate result
    if mount.sshfs_info | grep "/Track"; then       # "Track" is on list if system is mounted
        TEST_PASSED ${FUNCNAME[0]}
        return 0
    else
        TEST_FAILED ${FUNCNAME[0]}
        return 11
    fi
}


mount.test_list () {
    msg "sshfs list test\n"
    mount.system                                    # be sure that system is mounted to validate result
    if mount.list | grep "/Track"; then             # "Track" is on list if system is mounted
        TEST_PASSED ${FUNCNAME[0]}
        return 0
    else
        TEST_FAILED ${FUNCNAME[0]}
        return 11
    fi
}


test.help () {
    echo "-- guru tool-kit main test help -------------------------------------"
    printf "usage:\t %s test <tool>|all|validate <tc_nr>|all   \n" "$GURU_CALL"
    printf "\ntools:\n"
    printf " <tool> <tc_nr>|all     all test cases \n"
    printf " <tool> validate        validation tests prits out only results \n"
    #printf " validate               run full validation test \n"
    printf "\nexample:"
    printf "\t %s test mount 1 \n" "$GURU_CALL"
    printf "\t\t %s test remote all \n" "$GURU_CALL"
    #printf "\t\t %s test validate \n" "$GURU_CALL"
    return 0
}


test.main() {
    # main test case parser
    export VERBOSE="true"                                                           # dev test verbose is always on
    export LOGGING="true"
    case "$1" in
        1-100|all)  main.test_tool mount "$1"
                    main.test_tool remote "$1"
                    main.test_tool note "$1"
                    return 0 ;;
        help|-h|"") test.help
                    return 0 ;;
        *)          main.test_tool $@
                    return $?
    esac
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then        # if sourced only import functions
    source $HOME/.gururc                                    # source all
    test.main "$@"
    exit "$?"
fi


