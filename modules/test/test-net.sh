#!/bin/bash 
# automatically generated tester for grbl net.sh Wed 05 Oct 2022 06:20:31 PM EEST casa@ujo.guru 2020

source $GRBL_BIN/common.sh
source ../../core/net.sh 

## TODO add test initial conditions here

net.test() {
    local test_case=$1
    local _err=($0)
    case "$test_case" in
           1) net.status ; return 0 ;;  # 1) quick check
         all) 
         # TODO: remove non wanted functions and check run order. 
              echo ; net.test_help || _err=("${_err[@]}" "101") 
              echo ; net.test_main || _err=("${_err[@]}" "102") 
              echo ; net.test_check || _err=("${_err[@]}" "103") 
              echo ; net.test_status || _err=("${_err[@]}" "104") 
              echo ; net.test_poll || _err=("${_err[@]}" "105") 
              echo ; net.test_install || _err=("${_err[@]}" "106") 
              echo ; net.test_remove || _err=("${_err[@]}" "107") 
              if [[ ${_err[1]} -gt 0 ]]; then echo "error: ${_err[@]}"; return ${_err[1]}; else return 0; fi ;; 
         *) gr.msg "test case $test_case not written"
            return 1
    esac
}


net.test_help () {
    # function to test net module function net.help
    local _error=0
    gr.msg -v0 -c white 'testing net.help'

      ## TODO: add pre-conditions here 

      net.help ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'net.help passed' 
       return 0
    else
       gr.msg -v0 -c red 'net.help failed' 
       return $_error
  fi
}


net.test_main () {
    # function to test net module function net.main
    local _error=0
    gr.msg -v0 -c white 'testing net.main'

      ## TODO: add pre-conditions here 

      net.main ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'net.main passed' 
       return 0
    else
       gr.msg -v0 -c red 'net.main failed' 
       return $_error
  fi
}


net.test_check () {
    # function to test net module function net.check
    local _error=0
    gr.msg -v0 -c white 'testing net.check'

      ## TODO: add pre-conditions here 

      net.check ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'net.check passed' 
       return 0
    else
       gr.msg -v0 -c red 'net.check failed' 
       return $_error
  fi
}


net.test_status () {
    # function to test net module function net.status
    local _error=0
    gr.msg -v0 -c white 'testing net.status'

      ## TODO: add pre-conditions here 

      net.status ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'net.status passed' 
       return 0
    else
       gr.msg -v0 -c red 'net.status failed' 
       return $_error
  fi
}


net.test_poll () {
    # function to test net module function net.poll
    local _error=0
    gr.msg -v0 -c white 'testing net.poll'

      ## TODO: add pre-conditions here 

      net.poll ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'net.poll passed' 
       return 0
    else
       gr.msg -v0 -c red 'net.poll failed' 
       return $_error
  fi
}


net.test_install () {
    # function to test net module function net.install
    local _error=0
    gr.msg -v0 -c white 'testing net.install'

      ## TODO: add pre-conditions here 

      net.install ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'net.install passed' 
       return 0
    else
       gr.msg -v0 -c red 'net.install failed' 
       return $_error
  fi
}


net.test_remove () {
    # function to test net module function net.remove
    local _error=0
    gr.msg -v0 -c white 'testing net.remove'

      ## TODO: add pre-conditions here 

      net.remove ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'net.remove passed' 
       return 0
    else
       gr.msg -v0 -c red 'net.remove failed' 
       return $_error
  fi
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then 
    source "$GRBL_RC"
    GRBL_VERBOSE=2
    net.test $@
fi

