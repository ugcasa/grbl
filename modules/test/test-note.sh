# don't run, let teset.sh handle shit
# grbl toolkit note tester

source $GRBL_BIN/note.sh
source $GRBL_BIN/mount.sh

test_note=20200518
exist_note=20200517
nonexist_note=20200519

note.test() {
    local test_case="$1"
    local _err=("$0")
    mount.system
    case "$test_case" in
                1)  note.test_online  ; return $? ;;  # 3) check
                2)  note.remount      ; return $? ;;  # 5) action, remove
                3)  note.test_check   ; return $? ;;  # 1) quick check
                4)  note.test_list    ; return $? ;;  # 2) list stuff
                5)  note.test_add     ; return $? ;;  # 5) action, add
                6)  note.test_open    ; return $? ;;  # 5) action, open
                7)  note.test_rm      ; return $? ;;  # 5) action, remove
      release|all)  note.test_check   || _err=("${_err[@]}" "41")  # 3) check
                    note.test_online  || _err=("${_err[@]}" "42")  # 3) check
                    note.remount      || _err=("${_err[@]}" "43")  # 4) action, test locations
                    note.test_list    || _err=("${_err[@]}" "44")  # 3) check
                    note.test_add     || _err=("${_err[@]}" "45")  # 3) check
                    note.test_open    || _err=("${_err[@]}" "46")  # 3) check
                    note.test_rm      || _err=("${_err[@]}" "47")  # 3) check-
                    if [[ ${_err[1]} -gt 0 ]]; then echo "error: ${_err[@]}"; return ${_err[1]}; else return 0; fi
                    ;;
               *)  msg "test case '$test_case' not written\n"
                   return 1
    esac
}


note.test_online() {
    if note.online ; then
            gr.msg -c green "${FUNCNAME[0]} passed" ; return 0
        else
            gr.msg -c red "${FUNCNAME[0]} failed" ; return 10
        fi
    return $?
}


note.test_list () {
    printf "note list test.. "
    local _should_contain=$(date -d $exist_note +$GRBL_FORMAT_FILE_DATE)
    echo $_should_contain
    if note.check $_should_contain ; then
      gr.msg -c green "passed" ; return 0
    else
      gr.msg -c red "failed" ; return 44
    fi
}


note.test_check () {
    local _err=("$0")

    printf "date %s (exist) " "$(date -d $exist_note +$GRBL_FORMAT_FILE_DATE)"
    if ! note.main check $exist_note ; then
            _err=("${_err[@]}" "100")
        fi

    printf "date %s (non exist) " "$(date -d $nonexist_note +$GRBL_FORMAT_FILE_DATE)"
    if note.main check $nonexist_note ; then
            _err=("${_err[@]}" "101")
        fi

    if [[ ${_err[1]} -gt 0 ]] ; then return 41 ; else return 0 ; fi
}


note.test_add () {
    printf "adding note %s.. " $test_note
    if note.add $test_note ; then
          gr.msg -c green "passed"
          return 0
      else
          gr.msg -c red "failed"
          return 45
      fi
}


note.test_open () {
    printf "opening note %s.. " $test_note
    export GRBL_PREFERRED_EDITOR="cat"
    if note.open $test_note | grep "18.5.2020" >/dev/null ; then
          gr.msg -c green "passed"
          return 0
      else
          gr.msg -c red "failed"
          return 46
      fi
}


note.test_rm () {
    printf "removing note %s.. " $test_note
    if note.rm $test_note ; then
          gr.msg -c green "passed"
          return 0
      else
          gr.msg -c red "failed"
          return 47
      fi
}
