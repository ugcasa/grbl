# don't run, let teset.sh handle shit
# guru toolkit mount tester
source $GURU_BIN/remote.sh
source $GURU_BIN/mount.sh

remote.test() {
    mount.system
    local test_case="$1"
    local _err=("$0")
    case "$test_case" in
               1) remote.check              ; return $? ;;
               4) remote.test_config        ; return $? ;;
           all|8) remote.check              || _err=31
                  remote.test_config        || _err=34
                  if [[ ${_err[1]} -gt 0 ]]; then echo "error: ${_err[@]}"; return ${_err[1]}; else return 0; fi
                  ;;
       release|9) remote.check              || _err=31
                  remote.test_config        || _err=34
                  if [[ ${_err[1]} -gt 0 ]]; then echo "error: ${_err[@]}"; return ${_err[1]}; else return 0; fi
                  ;;

               *) gmsg -c dark_grey "test case '$test_case' not written"
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
            gmsg -c green "${FUNCNAME[0]} passed"
            return 0
        else
            gmsg -c red "${FUNCNAME[0]} failed"
            return 255
        fi
}

