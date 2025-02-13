# don't run, let teset.sh handle shit
# grbl toolkit system.sh tester

source $GRBL_BIN/mount.sh
source $GRBL_BIN/system.sh      # TODO: meaby double not sure, check late


system.test() {
    local test_case="$1"
    local _err=("$0")
    mount.system
    case "$test_case" in
                1) system.get_version             ; return $? ;;  # 1) quick check
                3) system.set_test                ; return $? ;;  # 3) information or check
#                6) system.rollback_test           ; return $? ;;  # 6) action, touch hot files
#          clean|7) system.upgrade_test            ; return $? ;;  # 7) return
            all|8) system.get_version             || _err=("${_err[@]}" "51")  # 1) quick check
                   #system.rollback_test           || _err=("${_err[@]}" "56")  # 6) action, touch hot files
                   #system.upgrade_test            || _err=("${_err[@]}" "57")  # 7) return
                   if [[ ${_err[1]} -gt 0 ]]; then echo "error: ${_err[@]}"; return ${_err[1]}; else return 0; fi
                   ;;
        release|9) system.get_version             || _err=("${_err[@]}" "52")  # 1) quick check
                   #system.rollback_test           || _err=("${_err[@]}" "56")  # 6) action, touch hot files
                   #system.upgrade_test            || _err=("${_err[@]}" "57")  # 7) return
                   if [[ ${_err[1]} -gt 0 ]]; then echo "error: ${_err[@]}"; return ${_err[1]}; else return 0; fi
                   ;;
               *)  msg "test case '$test_case' not written\n"
                   return 1
    esac
}

system.get_version () {
  $GRBL_CALL version && gr.msg -c green "${FUNCNAME[0]} passed" || gr.msg -c red "${FUNCNAME[0]} failed"
  return $?
}

system.upgrade_test () {
    # input roll number
    local _error=0

    system.upgrade ; _error=$?

    if ((_error<1)) ; then
        gr.msg -c green "${FUNCNAME[0]} passed"
        return 0
    else
        gr.msg -c red "${FUNCNAME[0]} failed"
        return $_error
    fi
}


system.rollback_test () {
    # later: input roll number
    local _target_version="0.4.8"
    local _error=0

    system.rollback || return $?
    grep "$_target_version" <<< "$(bash $GRBL_BIN/$GRBL_CALL version)"; _error=$?

    if ((_error<1)) ; then
        gr.msg -c green "passed"
        else
        gr.msg -c red "failed"
        _error=$((_error+10))
      fi

    system.upgrade >/dev/null || return $?

    if ((_error<1)) ; then
        gr.msg -c green "${FUNCNAME[0]} passed"
        return 0
    else
        gr.msg -c red "${FUNCNAME[0]} failed"
        return $_error
    fi
}



