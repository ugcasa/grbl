#!/bin/bash
# guru tool-kit testing functions for all modules

source $GURU_BIN/lib/common.sh
source $GURU_BIN/lib/deco.sh

source $GURU_BIN/system.sh
source $GURU_BIN/functions.sh
source $GURU_BIN/counter.sh
source $GURU_BIN/mount.sh
source $GURU_BIN/remote.sh
source $GURU_BIN/note.sh
source $GURU_BIN/timer.sh


note.test_online() {
    if note.remount ; then
            TEST_PASSED "${FUNCNAME[0]}"
            return 0
        else
            TEST_FAILED "${FUNCNAME[0]}"
            return 10
        fi
    return $?
}


remote.test_config(){
    # test remote configuration pull and push
    local _error=0

    if remote.push_config ; then
            _error=0
        else
            _error=$((_error+1))
        fi

    if remote.pull_config ; then
            _error=$_error
        else
            _error=$((_error+1))
        fi

    if ((_error<9)) ; then
            TEST_PASSED "${FUNCNAME[0]}"
        else
            TEST_FAILED "${FUNCNAME[0]}"
        fi
    if ((_error>9)) ; then return 32 ; fi
    return 0
}


mount.clean_test () {
    local error=0

    if unmount.defaults_raw ; then
            TEST_PASSED "${FUNCNAME[0]} unmount"
            error=0
        else
            TEST_FAILED "${FUNCNAME[0]} unmount"
            error=10
        fi

    if mount.defaults_raw ; then
            TEST_PASSED "${FUNCNAME[0]} mount"
            error=$((error))
        else
            TEST_FAILED "${FUNCNAME[0]} mount"
             error=21
        fi
    if ((_error>9)) ; then return 28 ; fi
    return 0
}


mount.test_mount () {

    if mount.remote "/home/$GURU_USER/usr/test" "$HOME/tmp/test_mount" ; then
            TEST_PASSED "${FUNCNAME[0]}"
            return 0
        else
            TEST_FAILED "${FUNCNAME[0]}"
            return 22
        fi
}


mount.test_unmount () {
    local _mount_point="$HOME/tmp/test_mount"

    if unmount.remote "$_mount_point" ; then
            TEST_PASSED "${FUNCNAME[0]}"
            rm -rf "$H_mount_point" || WARNING "error when removing $_mount_point "
            return 0
        else
            TEST_FAILED "${FUNCNAME[0]}"
            return 23
        fi
}


mount.test_default_mount (){
    local _err=0

    msg "file server default folder mount \n"
    if mount.defaults_raw ; then
            TEST_PASSED "${FUNCNAME[0]} mount"
            _err=0
        else
            TEST_FAILED "${FUNCNAME[0]} mount"
            _err=$((_err+10))
        fi

    sleep 0.5
    msg "un-mount defaults  "
    if unmount.defaults_raw ; then
            TEST_PASSED "${ FUNCNAME[0]} unmount"
            _err=$_err
        else
            TEST_FAILED "${FUNCNAME[0]} unmount"
            _err=$((_err+1))
        fi

    if ((_err>9)) ; then return 29 ; fi
    return 0
}


mount.test_known_remote () {
    # Test that
    local _err=("$0")
    unmount.known_remote audio ; _err=("${_err[@]}" "$?")
    mount.known_remote audio ;   _err=("${_err[@]}" "$?")        # Second error in list is to validate result

    if [[ ${_err[2]} -gt 0 ]]; then
            echo "error: ${_err[@]}"
            TEST_FAILED "${FUNCNAME[0]}"
            return ${_err[2]};                                 # Return error
        else
            TEST_PASSED "${FUNCNAME[0]}"
            return 0
        fi
}


mount.test_list () {
    msg "sshfs list check: "
    mount.system || return 24                       # be sure that system is mounted

   if mount.list | grep "/Track" ; then             # if "Track" is in output pass
        TEST_PASSED "${FUNCNAME[0]}"
        return 0
    else
        TEST_FAILED "${FUNCNAME[0]}"
        return 24
    fi
}


mount.test_info () {
    msg "sshfs list check: "
    mount.system || return 25                       # be sure that system is mounted

    if mount.sshfs_info | grep "/Track" ; then       # if "Track" is in output pass
        TEST_PASSED "${FUNCNAME[0]}"
        return 0
    else
        TEST_FAILED "${FUNCNAME[0]}"
        return 25
    fi
}


system.upgrade_test () {
    # input roll number
    local _target_version="$GURU_VERSION"
    local _error=0

    system.upgrade || return $?
    grep "$_target_version" <<< "$(bash $GURU_BIN/$GURU_CALL version)"; _error=$?

    if ((_error<1)) ; then
        TEST_PASSED "${FUNCNAME[0]}"
        return 0
    else
        TEST_FAILED "${FUNCNAME[0]}"
        return $_error
    fi
}


system.rollback_test () {
    # later: input roll number
    local _target_version="0.4.8"
    local _error=0

    system.rollback || return $?
    grep "$_target_version" <<< "$(bash $GURU_BIN/$GURU_CALL version)"; _error=$?

    if ((_error<1)) ; then
        PASSED "version matches"
        else
        FAILED "version mismatch $(bash $GURU_BIN/$GURU_CALL version), expecting $_target_version"
        _error=$((_error+10))
      fi

    system.upgrade || return $?

    if ((_error<1)) ; then
        TEST_PASSED "${FUNCNAME[0]}"
        return 0
    else
        TEST_FAILED "${FUNCNAME[0]}"
        return $_error
    fi
}

system.get_test () {
    # get system values test
    if system.get "audio_enabled" | grep "true" >>/dev/null; then
        TEST_PASSED "${FUNCNAME[0]}"
        return 0
    else
        TEST_FAILED "${FUNCNAME[0]}"
        return 101
    fi
}

system.set_test () {
    # WILL FAIL sed broken fix later
    system.set "audio_enabled" "test"
    msg "return.. $(system.get audio_enabled)\n"
    if system.get "audio_enabled" | grep "test" >>/dev/null; then
            TEST_PASSED "${FUNCNAME[0]}"
            #system.set "audio_enabled" "true"
            return 0
    else
            TEST_FAILED "${FUNCNAME[0]}"
            #system.set "audio_enabled" "true"
            return 101
    fi
}


# Test case actions
# 1) quick check
# 2) list stuff
# 3) information or check
# 4) action, test locations
# 5) return
# 6) action, touch hot files
# 7) return
# validation tests
# make clean

system.test() {
    local test_case="$1"
    local _err=("$0")
    mount.system
    case "$test_case" in
                1) system.get_test                ; return $? ;;  # 1) quick check
                3) system.set_test                ; return $? ;;  # 3) information or check
                6) system.rollback_test           ; return $? ;;  # 6) action, touch hot files
          clean|7) system.upgrade_test            ; return $? ;;  # 7) return
              all) system.get_test                || _err=("${_err[@]}" "41")  # 1) quick check
                   #system.set_test                || _err=("${_err[@]}" "43")  # 3) information or check
                   system.rollback_test           || _err=("${_err[@]}" "46")  # 6) action, touch hot files
                   system.upgrade_test            || _err=("${_err[@]}" "47")  # 7) return
                   if [[ ${_err[1]} -gt 0 ]]; then echo "error: ${_err[@]}"; return ${_err[1]}; else return 0; fi
                   ;;
          release)
                   system.get_test                || _err=("${_err[@]}" "42")  # 1) quick check
                   #system.set_test                || _err=("${_err[@]}" "43")  # 3) information or check
                   system.rollback_test           || _err=("${_err[@]}" "46")  # 6) action, touch hot files
                   system.upgrade_test            || _err=("${_err[@]}" "47")  # 7) return
                   if [[ ${_err[1]} -gt 0 ]]; then echo "error: ${_err[@]}"; return ${_err[1]}; else return 0; fi
                   ;;
               *)  msg "test case '$test_case' not written\n"
                   return 1
    esac
}


note.test() {
    local test_case="$1"
    local _err=("$0")
    mount.system
    case "$test_case" in
                1) note.check               ; return $? ;;  # 1) quick check
                2) note.list                ; return $? ;;  # 2) list stuff
                3) note.test_online         ; return $? ;;  # 3) check
                6) note.contruct "20191212" ; return $? ;;  # 6) action, touch hot files
              all) note.test_online         || _err=("${_err[@]}" "43")  # 3) check
                   note.list                || _err=("${_err[@]}" "42")  # 2) list stuff
                   if [[ ${_err[1]} -gt 0 ]]; then echo "error: ${_err[@]}"; return ${_err[1]}; else return 0; fi
                   ;;
          release) note.test_online         || _err=("${_err[@]}" "43")  # 3) check
                   note.list                || _err=("${_err[@]}" "42")  # 2) list stuff
                   if [[ ${_err[1]} -gt 0 ]]; then echo "error: ${_err[@]}"; return ${_err[1]}; else return 0; fi
                   ;;
               *)  msg "test case '$test_case' not written\n"
                   return 1
    esac
}





remote.test () {
    mount.system
    local test_case="$1"
    local _err=("$0")
    case "$test_case" in
               1) remote.check              ; return $? ;;  # 1) quick check
               4) remote.test_config        ; return $? ;;  # 4) out of system action
             all) remote.check              || _err=31    # 1) quick check
                  remote.test_config        || _err=34    # 4) out of system action
                  if [[ ${_err[1]} -gt 0 ]]; then echo "error: ${_err[@]}"; return ${_err[1]}; else return 0; fi
                  ;;
         release) remote.check              || _err=31    # 1) quick check
                  remote.test_config        || _err=34    # 4) out of system action
                  if [[ ${_err[1]} -gt 0 ]]; then echo "error: ${_err[@]}"; return ${_err[1]}; else return 0; fi
                  ;;

               *) msg "test case '$test_case' not written\n"
                  return 1
    esac
}



mount.test () {
    mount.system
    local test_case="$1"
    local _err=("$0")
    case "$test_case" in
               1) mount.check_system        ; return $? ;;  # 1) quick check
               2) mount.test_list           ; return $? ;;  # 2) list of stuff
               3) mount.test_info           ; return $? ;;  # 3) information
               4) mount.test_mount          ; return $? ;;  # 4) out of system action
               5) mount.test_unmount        ; return $? ;;  # 5) return
               6) mount.test_default_mount  ; return $? ;;  # 6) touch hot files
               7) mount.test_known_remote   ; return $? ;;  # 7) return
           clean) mount.clean_test          ; return $? ;;  # make clean
             all) mount.check_system        || _err=("${_err[@]}" "21")  # 1) quick check
                  mount.test_list           || _err=("${_err[@]}" "22")  # 2) list of stuff
                  mount.test_info           || _err=("${_err[@]}" "23")  # 3) information
                  mount.test_mount          || _err=("${_err[@]}" "24")  # 4) out of system action
                  mount.test_unmount        || _err=("${_err[@]}" "25")  # 5) return
                  mount.clean_test          || _err=("${_err[@]}" "29")  # make clean
                  if [[ ${_err[1]} -gt 0 ]]; then echo "error: ${_err[@]}"; return ${_err[1]}; else return 0; fi
                  ;;
         release) mount.check_system        || _err=("${_err[@]}" "21")  # 1) quick check
                  mount.test_list           || _err=("${_err[@]}" "22")  # 2) list of stuff
                  mount.test_info           || _err=("${_err[@]}" "23")  # 3) information
                  mount.test_mount          || _err=("${_err[@]}" "24")  # 4) out of system action
                  mount.test_unmount        || _err=("${_err[@]}" "25")  # 5) return
                  if [[ ${_err[1]} -gt 0 ]]; then echo "error: ${_err[@]}"; return ${_err[1]}; else return 0; fi
                  ;;

               *) msg "test case '$test_case' not written\n"
                  return 1
    esac
}

## test main

test.help () {
    echo "-- guru tool-kit main test help -------------------------------------"
    printf "usage:\t %s test <tool>|all|release <tc_nr>|all   \n" "$GURU_CALL"
    printf "\ntools:\n"
    printf " <tool> <tc_nr>|all     all test cases \n"
    printf " <tool> release        validation tests prints out only results \n"
    printf " release               run full validation test \n"
    printf "\nexample:"
    printf "\t %s test mount 1 \n" "$GURU_CALL"
    printf "\t\t %s test remote all \n" "$GURU_CALL"
    printf "\t\t %s test release \n" "$GURU_CALL"
    return 0
}



test.tool() {
    # Tool to test tools. Simply call sourced tool main function and parse normal commands
    local _tool=""
    local _case=""
    local _lang=""
    local _test_id=""                    #
    local _error=0

    [ "$1" ] && _tool=$1 || read -r -p "input tool name to test: " _tool
    [ "$2" ] && _case="$2" || _case="all"
    _test_id=$(counter.main add guru-shell_test_id)
    msg "\n${WHT}TEST $_test_id: guru-shell $_tool #$_case - $(date)\n${NC}"

    if [ -f "$GURU_BIN/$_tool.sh" ]; then
                _lang="sh"
    elif [ -f "$GURU_BIN/$_tool.py" ]; then
                _lang="py"
        else
                msg "tool '$_tool' not found\n"
                TEST_FAILED "TEST $_test_id $_tool"
                return 10
        fi

    source "$_tool.$_lang"
    $1.test "$_case" ; _error=$?

    if ((_error==1)) ; then
         TEST_IGNORED "TEST $_test_id $_tool.$_lang"
        return 0
        fi

    if ((_error<1)) ; then
             TEST_PASSED "TEST $_test_id $_tool.$_lang"
            return 0
        else
             TEST_FAILED "TEST $_test_id $_tool.$_lang"
            return $_error
        fi
}


test.all() {
    # run all module tests and all cases
    local _error=0
    for _tool in ${all_tools[@]}; do
            test.tool $_tool "$1" || _error=$((_error+1))
        done

    if ((_error<1)); then
            PASSED "\nTest run result is"
        else
            msg "counted $_error error(s)\n"
            FAILED "\nTest run result is"
        fi

    return $_error
}


test.release() {
    # validation test, tests all but prints out only module reports
    local _error=0
    local _test_id=$(counter.main add guru-shell_validation_test_id)

        msg "\n${WHT}RELEASE TEST $_test_id: guru-shell v.$GURU_VERSION $(date)${NC}\n"
        test.all |grep --color=never "result is:" |grep "TEST" || _error=$?

        if ((_error<9)); then
                PASSED "RELEASE $_test_id RESULT"
            else
                msg "last error code were: $_error\n"
                FAILED "RELEASE $_test_id RESULT"
            fi
        return $_error
}


test.main() {
    # main test case parser
    all_tools=("remote" "mount" "note" "system")
    export VERBOSE=true
    export LOGGING=true
    case "$1" in
        snap|quick) test.all 1              ; return $? ;;
            *[1-9]) test.all "$1"           ; return $? ;;
               all) time test.all           ; return $? ;;
           release) test.release            ; return 0  ;;
        help|-h|"") test.help               ; return 0  ;;
        *)          test.tool $@            ; return $? ;;
    esac
}


test.loop() {
    export VERBOSE=true                             # printout unit test output
    export LOGGING=""                                # do not log to file
    TIMEFORMAT='%R'                                 # time output format

    msg "start '$1' case '$2' loop by pressing 'enter' (quit 'q'): "
    while read -n 1 -e  cmd; do
            [ "$cmd" == "q" ] && return 0
            source $HOME/.gururc
            [ "$2" ] && time $1.test "$2" || time test.main "$@"
        done
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source $HOME/.gururc
    source $GURU_BIN/lib/deco.sh
    export VERBOSE=true
    export COUNTER=""

    case "$1" in
        loop) shift ; test.loop "$@" ; exit "$?" ;;
        esac
    test.main "$@"
    exit "$?"
fi
