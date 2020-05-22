# don't run, let teset.sh handle shit
# guru toolkit mount tester
source $GURU_BIN/project.sh
source $GURU_BIN/mount.sh

project.test() {
    mount.system
    local test_case="$1"
    local _err=("$0")
    case "$test_case" in
                1)  project.test_check       || return $? ;;
                #2)  project.test_add "test"  || return $? ;;
                #3)  project.test_open "test" || return $? ;;
                #4)  project.test_rm "test"   || return $? ;;
      release|all)  project.test_check       || _err=("${_err[@]}" "41")  #
                    #project.test_add "test"  || _err=("${_err[@]}" "42")  #
                    #project.test_open "test" || _err=("${_err[@]}" "43")  #
                    #project.test_rm "test"   || _err=("${_err[@]}" "44")  #
                    if [[ ${_err[1]} -gt 0 ]]; then ERROR "${_err[@]}"; return ${_err[1]}; else return 0; fi ;;
                *)  msg "test case '$test_case' not written\n"
                    return 1
    esac
}


project.test_check () {
    if project.check "test"; then
          PASSED "$0"
          return 0
      else
          FAILED "$0"
          return 41

      fi
}


project.test_add () {
    if project.add "test" ; then
          PASSED "$0"
          return 0
      else
          FAILED "$0"
          return 42
      fi
}


project.test_open () {
    if project.open "test" ; then
          PASSED "$0"
          return 0
      else
          FAILED "$0"
          return 43
      fi
}


project.test_close () {
    if project.close "test" ; then
          PASSED "$0"
          return 0
      else
          FAILED "$0"
          return 43
      fi
}


project.test_rm () {
    if project.rm "test" ; then
          PASSED "$0"
          return 0
      else
          FAILED "$0"
          return 44
      fi
}


project.test_delete () {
    if project.rm "test" ; then
          PASSED "$0"
          return 0
      else
          FAILED "$0"
          return 44
      fi
}

