# don't run this, let the 'test.sh' handle the shit
# guru toolkit unit test template

source $GURU_BIN/module.sh
#source $GURU_BIN/mount.sh

# test module common variables
test_date=20200518
test_yesteday=20200517
test_tomorrow=20200519

module.test() {
    local test_case="$1" ; shift

    case "$test_case" in
                1)  module.test_check   ; return $? ;;  # 1) check few thing to see is it working
                2)  module.test_online  ; return $? ;;  # 2) check readiness of service
                3)  module.test_list    ; return $? ;;  # 3) list some stuff to get some data out
                4)  module.test_add     ; return $? ;;  # 4) action like add
                5)  module.test_open    ; return $? ;;  # 5) action like open
                6)  module.test_rm      ; return $? ;;  # 6) action like remove
            clean)  module.cleanup      ; return $? ;;  # clean the mess you made, run outside
                *)  msg "test case '$test_case' not written\n" ; return 10
    esac
}

module.cleanup () {
    gmsg -v2 -c black "${FUNCTION[0]} TBD.. still TBD?, you filthy bastard!"
}

module.test_check () {
    local _err=("$0")

    printf "date %s (exist) " "$(date -d $test_yesteday +$GURU_DATE_FORMAT)"
    if ! module.main check $test_yesteday ; then
            _err=("${_err[@]}" "100")
        fi

    printf "date %s (non exist) " "$(date -d $test_tomorrow +$GURU_DATE_FORMAT)"
    if module.main check $test_tomorrow ; then
            _err=("${_err[@]}" "101")
            echo $GURU_USER
        fi

    if [[ ${_err[1]} -gt 0 ]] ; then return 101 ; else return 0 ; fi
}


module.test_online() {
    if module.online ; then
            PASSED "${FUNCNAME[0]}" ; return 0
        else
            FAILED "${FUNCNAME[0]}" ; return 100
        fi
    return $?
}


module.test_list () {
    printf "note list test.. "
    if module.ls | grep $test_yesteday >/dev/null ; then
      PASSED ; return 0
    else
      FAILED ; return 104
    fi
}



module.test_add () {
    printf "adding note %s.. " $test_date
    if module.add $test_date ; then
          PASSED ; return 0
      else
          FAILED ; return 105
      fi
}


module.test_open () {
    printf "opening note %s.. " $test_date
    export GURU_EDITOR=cat
    if module.open $test_date | grep "20200518" >/dev/null ; then
          PASSED ; return 0
      else
          FAILED ; return 106
      fi
}


module.test_rm () {
    printf "removing note %s.. " $test_date
    if module.rm $test_date ; then
          PASSED ; return 0
      else
          FAILED ; return 107
      fi
}
