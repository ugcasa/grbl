# don't run, let teset.sh handle shit
# guru toolkit mount tester
source $GURU_BIN/remote.sh
source $GURU_BIN/mount.sh

remote.test() {
    mount.system
    local test_case="$1"
    local _err=("$0")
    case "$test_case" in
               1) remote.check              ; return $? ;;  # 1) quick check
               4) remote.test_config        ; return $? ;;  # 4) out of system action
           all|8) remote.check              || _err=31      # 1) quick check
                  remote.test_config        || _err=34      # 4) out of system action
                  if [[ ${_err[1]} -gt 0 ]]; then echo "error: ${_err[@]}"; return ${_err[1]}; else return 0; fi
                  ;;
       release|9) remote.check              || _err=31      # 1) quick check
                  remote.test_config        || _err=34      # 4) out of system action
                  if [[ ${_err[1]} -gt 0 ]]; then echo "error: ${_err[@]}"; return ${_err[1]}; else return 0; fi
                  ;;

               *) msg "test case '$test_case' not written\n"
                  return 1
    esac
}

remote.test_config() {
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

    if ((_error<1)) ; then
            TEST_PASSED "${FUNCNAME[0]}"
            return 0
        else
            TEST_FAILED "${FUNCNAME[0]}"
            return 255
        fi
}

