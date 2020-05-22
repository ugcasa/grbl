# don't run, let teset.sh handle shit
# guru toolkit note tester

source $GURU_BIN/note.sh
source $GURU_BIN/mount.sh


note.test() {
    local test_case="$1"
    local _err=("$0")
    mount.system
    case "$test_case" in
                1) note.test_check          ; return $? ;;  # 1) quick check
                2) note.list                ; return $? ;;  # 2) list stuff
                3) note.test_online         ; return $? ;;  # 3) check
                4) note.remount             ; return $? ;;  # 4) action, test locations
                5) note.test_create_clean   ; return $? ;;  # 5) action, create, open and remove
            all|8) note.test_online         || _err=("${_err[@]}" "43")  # 3) check
                   note.remount             || _err=("${_err[@]}" "44")  # 4) action, test locations
                   note.list                || _err=("${_err[@]}" "42")  # 2) list stuff
                   if [[ ${_err[1]} -gt 0 ]]; then echo "error: ${_err[@]}"; return ${_err[1]}; else return 0; fi
                   ;;
        release|9) note.remount       || _err=("${_err[@]}" "44")  # 4) action, test locations
                   note.list                || _err=("${_err[@]}" "42")  # 2) list stuff
                   if [[ ${_err[1]} -gt 0 ]]; then echo "error: ${_err[@]}"; return ${_err[1]}; else return 0; fi
                   ;;
               *)  msg "test case '$test_case' not written\n"
                   return 1
    esac
}


note.test_online() {
    if note.online ; then
            TEST_PASSED "${FUNCNAME[0]}"
            return 0
        else
            TEST_FAILED "${FUNCNAME[0]}"
            return 10
        fi
    return $?
}


note.test_create_clean () {
  echo "TBD"
}


note.test_check () {
    local _err=("$0")

    echo "setting date to 20200517"
    if ! note.main check 20200517 ; then
            _err=("${_err[@]}" "100")  # 2) list stuff
        fi

    echo "setting date to 19970101"
    if note.main check 19970101 ; then
            _err=("${_err[@]}" "101")  # 2) list stuff
            echo $GURU_USER
        fi

    if [[ ${_err[1]} -gt 0 ]] ; then return 41 ; else return 0 ; fi
}


note.test_add () {
    if note.add "test" ; then
          PASSED "$0"
          return 0
      else
          FAILED "$0"
          return 42
      fi
}


note.test_open () {
    if note.open "test" ; then
          PASSED "$0"
          return 0
      else
          FAILED "$0"
          return 43
      fi
}


note.test_rm () {
    if note.rm "test" ; then
          PASSED "$0"
          return 0
      else
          FAILED "$0"
          return 44
      fi
}
