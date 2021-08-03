# don't run, let teset.sh handle shit
# guru toolkit mount tester

source $GURU_BIN/mount.sh

mount.test () {
    mount.system
    local test_case="$1"
    local _err=("$0")
    case "$test_case" in
               1) mount.check               ; return $? ;;  # 1) quick check
               2) mount.test_list           ; return $? ;;  # 2) list of stuff
               3) mount.test_info           ; return $? ;;  # 3) information
               4) mount.test_mount          ; return $? ;;  # 4) out of system action
               5) mount.test_unmount        ; return $? ;;  # 5) return
               6) mount.test_default_mount  ; return $? ;;  # 6) touch hot files
               7) mount.test_known_remote   ; return $? ;;  # 7) return
           clean) mount.clean_test          ; return $? ;;  # make clean
     release|all) mount.check               || _err=("${_err[@]}" "21")  # 1) quick check
                  mount.test_list           || _err=("${_err[@]}" "22")  # 2) list of stuff
                  mount.test_info           || _err=("${_err[@]}" "23")  # 3) information
                  mount.test_mount          || _err=("${_err[@]}" "24")  # 4) out of system action
                  mount.test_unmount        || _err=("${_err[@]}" "25")  # 5) return
                  mount.test_default_mount  || _err=("${_err[@]}" "26")  # 5) return
                  mount.test_known_remote   || _err=("${_err[@]}" "27")  # 7) return
                  mount.clean_test          || _err=("${_err[@]}" "29")  # make clean
                  if [[ ${_err[1]} -gt 0 ]]; then echo "error: ${_err[@]}"; return ${_err[1]}; else return 0; fi ;;
               *) msg "test case '$test_case' not written\n"
                  return 1
    esac
}


mount.clean_test () {
    local error=0

    if unmount.defaults ; then
            gmsg -c green "${FUNCNAME[0]} unmount passed"
            error=0
        else
            gmsg -c red "${FUNCNAME[0]} unmount failed"
            error=10
        fi

    if mount.defaults ; then
            gmsg -c green "${FUNCNAME[0]} mount passed"
            error=$((error))
        else
            gmsg -c red "${FUNCNAME[0]} mount failed"
            error=21
        fi

    if ((_error>9)) ; then return 28 ; fi
    return 0
}


mount.test_mount () {
    # TBD new mountpoints for Hesus Testman
    if mount.remote "/home/$GURU_USER_NAME/usr/test" "$HOME/tmp/test_mount" ; then
            gmsg -c green "${FUNCNAME[0]} passed"
            return 0
        else
            gmsg -c red "${FUNCNAME[0]} failed"
            return 22
        fi
}


mount.test_unmount () {
    local _mount_point="$HOME/tmp/test_mount"
     # TBD new mountpoints for Hesus Testman
    if unmount.remote "$_mount_point" ; then
            gmsg -c green "${FUNCNAME[0]} passed"
            rm -rf "$H_mount_point" || WARNING "error when removing $_mount_point "
            return 0
        else
            gmsg -c red "${FUNCNAME[0]} failed"
            return 23
        fi
}


mount.test_default_mount (){
    local _err=0
    # to test online ignore
    gmsg -n "${FUNCNAME[0]} mount defaults "
    if mount.defaults ; then
            gmsg -c green "passed"
            _err=0
        else
            gmsg -c red "failed"
            _err=$((_err+10))
        fi
    sleep 1
    # to test unmount
    gmsg -n "${FUNCNAME[0]} un-mount defaults "
    if unmount.defaults ; then
            gmsg -c green " passed"
            _err=$_err
        else
            gmsg -c red "failed"
            _err=$((_err+10))
        fi
    sleep 1
    # to test re-mount
    gmsg -n "${FUNCNAME[0]} re-mount defaults "
    if mount.defaults ; then
            gmsg -c green "passed"
            _err=$_err
        else
            gmsg -c red "failed"
            _err=$((_err+10))
        fi

    if ((_err>9)) ; then return 29 ; fi
    return 0
}


mount.test_known_remote () {
# Test that

    local _err=("$0")
    unmount.known_remote audio ; _err=("${_err[@]}" "$?")
    # Second error in list is to validate result
    mount.known_remote audio ;   _err=("${_err[@]}" "$?")

    if [[ ${_err[2]} -gt 0 ]]; then
            gmsg -c red "${FUNCNAME[0]} failed"
            gmsg -c yellow "error: ${_err[@]}"
            # Return error
            return ${_err[2]};
        else
            gmsg -c green "${FUNCNAME[0]} passed"
            return 0
        fi
}


mount.test_list () {

    # be sure that system is mounted
    mount.system || return 24
    gmsg -n "sshfs list check.. "
    # if "Track" is in output pass
    if mount.list | grep "/.data" >/dev/null ; then
        gmsg -c green "${FUNCNAME[0]} passed"
        return 0
    else
        gmsg -c red "${FUNCNAME[0]} failed"
        return 24
    fi
}


mount.test_info () {
    # be sure that system is mounted
    mount.system || return 25

    gmsg -n "sshfs list check: "
    # if "Track" is in output pass
    if mount.info | grep "$GURU_SYSTEM_MOUNT" >/dev/null ; then
        gmsg -c green "${FUNCNAME[0]} passed"
        return 0
    else
        gmsg -c red "${FUNCNAME[0]} failed"
        return 25
    fi
}

