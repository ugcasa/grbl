#!/bin/bash
# automatically generated tester for guru-client corsair.sh Sat Oct 10 02:42:19 EEST 2020 casa@ujo.guru 2020

source $GURU_BIN/common.sh
source $GURU_BIN/corsair.sh

## TODO add test initial conditions here

corsair.test() {
    local test_case=$1
    local _err=($0)
    case "$test_case" in

        check|status|init|raw_write|set|reset|end|kill|install|remove)
              corsair.test_$test_case ; return 0
              ;;  # 1) quick check

           1) corsair.check ; return 0 ;;  # 1) quick check
         all)
         # TODO: check run order.
              corsair.test_main || _err=("${_err[@]}" "101")
              corsair.test_help || _err=("${_err[@]}" "102")
              corsair.test_check || _err=("${_err[@]}" "103")
              corsair.test_status || _err=("${_err[@]}" "104")
              #corsair.test_start || _err=("${_err[@]}" "105")
              corsair.test_init || _err=("${_err[@]}" "106")
              #corsair.test_raw_write || _err=("${_err[@]}" "107")
              corsair.test_set || _err=("${_err[@]}" "108")
              corsair.test_reset || _err=("${_err[@]}" "109")
              #corsair.test_kill || _err=("${_err[@]}" "111")
              #corsair.test_start || _err=("${_err[@]}" "105")
              corsair.test_end || _err=("${_err[@]}" "110")
              if [[ ${_err[1]} -gt 0 ]]; then echo "error: ${_err[@]}"; return ${_err[1]}; else return 0; fi ;;
     compile)
              corsair.test_install || _err=("${_err[@]}" "112")
              corsair.test_remove || _err=("${_err[@]}" "113")
              if [[ ${_err[1]} -gt 0 ]]; then echo "error: ${_err[@]}"; return ${_err[1]}; else return 0; fi ;;

         *) gmsg "test case $test_case not written"
            return 1
    esac
}


corsair.test_main () {
    # function to test corsair module function corsair.main
    local _error=0
    gmsg -v0 -c white 'testing corsair.main'

      ## TODO: add pre-conditions here

      corsair.main set esc green ; _error=$?

      ## TODO: add analysis here and manipulate $_error

    if  ((_error<1)) ; then
       gmsg -v0 -c green 'corsair.main passed'
       return 0
    else
       gmsg -v0 -c red 'corsair.main failed'
       return $_error
  fi
}


corsair.test_help () {
    # function to test corsair module function corsair.help
    local _error=0
    gmsg -v0 -c white 'testing corsair.help'

      ## TODO: add pre-conditions here

      corsair.help ; _error=$?

      ## TODO: add analysis here and manipulate $_error

    if  ((_error<1)) ; then
       gmsg -v0 -c green 'corsair.help passed'
       return 0
    else
       gmsg -v0 -c red 'corsair.help failed'
       return $_error
  fi
}


corsair.test_check () {
    # function to test corsair module function corsair.check
    local _error=0
    gmsg -v0 -c white 'testing corsair.check'

      ## TODO: add pre-conditions here

      corsair.check ; _error=$?

      ## TODO: add analysis here and manipulate $_error

    if  ((_error<1)) ; then
       gmsg -v0 -c green 'corsair.check passed'
       return 0
    else
       gmsg -v0 -c red 'corsair.check failed'
       return $_error
  fi
}


corsair.test_status () {
    # function to test corsair module function corsair.status
    local _error=0
    gmsg -v0 -c white 'testing corsair.status'

      ## TODO: add pre-conditions here

      corsair.status ; _error=$?

      ## TODO: add analysis here and manipulate $_error

    if  ((_error<1)) ; then
       gmsg -v0 -c green 'corsair.status passed'
       return 0
    else
       gmsg -v0 -c red 'corsair.status failed'
       return $_error
  fi
}


# corsair.test_start () {
#     # function to test corsair module function corsair.start
#     local _error=0
#     gmsg -v0 -c white 'testing corsair.start'

#       ## TODO: add pre-conditions here

#       corsair.start ; _error=$?
#       sleep 4

#       ## TODO: add analysis here and manipulate $_error

#     if  ((_error<1)) ; then
#        gmsg -v0 -c green 'corsair.start passed'
#        return 0
#     else
#        gmsg -v0 -c red 'corsair.start failed'
#        return $_error
#   fi
# }


corsair.test_init () {
    # function to test corsair module function corsair.init
    local _error=0
    gmsg -v0 -c white 'testing corsair.init'

      ## TODO: add pre-conditions here

      corsair.init test ; _error=$?
      sleep 2

      ## TODO: add analysis here and manipulate $_error

    if  ((_error<1)) ; then
       gmsg -v0 -c green 'corsair.init passed'
       return 0
    else
       gmsg -v0 -c red 'corsair.init failed'
       return $_error
  fi
}


# corsair.test_raw_write () {
#     # function to test corsair module function corsair.raw_write
#     local _error=0
#     gmsg -v0 -c white 'testing corsair.raw_write'

#       ## TODO: add pre-conditions here

#       corsair.raw_write ; _error=$?

#       ## TODO: add analysis here and manipulate $_error

#     if  ((_error<1)) ; then
#        gmsg -v0 -c green 'corsair.raw_write passed'
#        return 0
#     else
#        gmsg -v0 -c red 'corsair.raw_write failed'
#        return $_error
#   fi
# }


corsair.test_set () {
    # function to test corsair module function corsair.set
    local _error=0
    gmsg -v0 -c white 'testing corsair.set'

      ## TODO: add pre-conditions here

     if ! corsair.set esc red ; then
             _error=$?
         fi

      ## TODO: add analysis here and manipulate $_error

    if ((_error<1)) ; then
       gmsg -v0 -c green 'corsair.set passed'
       return 0
    else
       gmsg -v0 -c red 'corsair.set failed'
       return $_error
  fi
}


corsair.test_reset () {
    # function to test corsair module function corsair.reset
    local _error=0
    gmsg -v0 -c white 'testing corsair.reset'

      ## TODO: add pre-conditions here

      corsair.reset esc ; _error=$?

      ## TODO: add analysis here and manipulate $_error

    if  ((_error<1)) ; then
       gmsg -v0 -c green 'corsair.reset passed'
       return 0
    else
       gmsg -v0 -c red 'corsair.reset failed'
       return $_error
  fi
}


corsair.test_end () {
    # function to test corsair module function corsair.end
    local _error=0
    gmsg -v0 -c white 'testing corsair.end'

      ## TODO: add pre-conditions here

      corsair.end ; _error=$?
      sleep 2

      ## TODO: add analysis here and manipulate $_error

    if  ((_error<1)) ; then
       gmsg -v0 -c green 'corsair.end passed'
       return 0
    else
       gmsg -v0 -c red 'corsair.end failed'
       return $_error
  fi
}


corsair.test_kill () {
    # function to test corsair module function corsair.kill
    local _error=0
    gmsg -v0 -c white 'testing corsair.kill'

      ## TODO: add pre-conditions here

      corsair.kill ; _error=$?

      ## TODO: add analysis here and manipulate $_error

    if  ((_error<1)) ; then
       gmsg -v0 -c green 'corsair.kill passed'
       return 0
    else
       gmsg -v0 -c red 'corsair.kill failed'
       return $_error
  fi
}


corsair.test_install () {
    # function to test corsair module function corsair.install
    local _error=0
    gmsg -v0 -c white 'testing corsair.install'

      ## TODO: add pre-conditions here

      corsair.install ; _error=$?

      ## TODO: add analysis here and manipulate $_error

    if  ((_error<1)) ; then
       gmsg -v0 -c green 'corsair.install passed'
       return 0
    else
       gmsg -v0 -c red 'corsair.install failed'
       return $_error
  fi
}


corsair.test_remove () {
    # function to test corsair module function corsair.remove
    local _error=0
    gmsg -v0 -c white 'testing corsair.remove'

      ## TODO: add pre-conditions here

      corsair.remove ; _error=$?

      ## TODO: add analysis here and manipulate $_error

    if  ((_error<1)) ; then
       gmsg -v0 -c green 'corsair.remove passed'
       return 0
    else
       gmsg -v0 -c red 'corsair.remove failed'
       return $_error
  fi
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$GURU_RC"
    GURU_VERBOSE=2
    corsair.test $@
fi

