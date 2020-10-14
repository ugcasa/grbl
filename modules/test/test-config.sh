# don't run, let teset.sh handle shit
# guru toolkit config.sh tester

source $GURU_BIN/config.sh

config.test() {
    local test_case="$1"
    local _err=("$0")
    mount.system
    case "$test_case" in
                1) config.test_get                ; return $? ;;
                2) config.test_set                ; return $? ;;
              all) config.test_get                || _err=("${_err[@]}" "61")
                   config.test_set                || _err=("${_err[@]}" "62")
                   if [[ ${_err[1]} -gt 0 ]]; then echo "error: ${_err[@]}"; return ${_err[1]}; else return 0; fi
                   ;;
               *)  msg "test case '$test_case' not written\n"
                   return 1
    esac
}


config.test_get () {
    # get system values test
    if config.get "audio_enabled" | grep "true" >/dev/null; then
        TEST_PASSED "${FUNCNAME[0]}"
        return 0
    else
        TEST_FAILED "${FUNCNAME[0]}"
        return 101
    fi
}


config.test_set () {
    # WILL FAIL sed broken fix later
    config.set "audio_enabled" "test"
    msg "returns: %s \n" "$(config.get audio_enabled)"

    if config.get "audio_enabled" | grep "test" >/dev/null; then
            TEST_PASSED "${FUNCNAME[0]}"
            config.set "audio_enabled" "true"             # cleanup
            return 0
    else
            TEST_FAILED "${FUNCNAME[0]}"
            config.set "audio_enabled" "true"             # cleanup
            return 101
    fi
}