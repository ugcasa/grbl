# don't run, let teset.sh handle shit
# guru toolkit mount tester
source $GURU_BIN/project.sh
source $GURU_BIN/mount.sh

project.test() {
    mount.system
    local test_case="$1"
    local _err=("$0")
    case "$test_case" in
                1)  project.check       || return $? ;;
                2)  project.add "test"  || return $? ;;
                3)  project.open "test" || return $? ;;
                4)  project.rm "test"   || return $? ;;
      release|all)  project.check       || _err=("${_err[@]}" "41")  #
                    project.add "test"  || _err=("${_err[@]}" "42")  #
                    project.open "test" || _err=("${_err[@]}" "43")  #
                    project.rm "test"   || _err=("${_err[@]}" "44")  #
                    if [[ ${_err[1]} -gt 0 ]]; then ERROR "${_err[@]}"; return ${_err[1]}; else return 0; fi ;;
                *)  msg "test case '$test_case' not written\n"
                    return 1
    esac
}


project.test_check () {
    if project.check ; then
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


project.test_rm () {
    if project.rm "test" ; then
          PASSED "$0"
          return 0
      else
          FAILED "$0"
          return 44
      fi
}

