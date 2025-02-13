#!/bin/bash
# automatically generated tester for grbl mqtt.sh Sun 01 Aug 2021 02:46:03 PM EEST casa@ujo.guru 2020

source $GRBL_BIN/common.sh
source ../../modules/mqtt.sh 

## TODO add test initial conditions here

mqtt.test() {
    local test_case=$1
    local _err=($0)
    case "$test_case" in
           1) mqtt.status ; return 0 ;;  # 1) quick check
         all) 
         # TODO: remove non wanted functions and check run order. 
              mqtt.test_help || _err=("${_err[@]}" "101") 
              mqtt.test_main || _err=("${_err[@]}" "102") 
              mqtt.test_enabled || _err=("${_err[@]}" "103") 
              mqtt.test_online || _err=("${_err[@]}" "104") 
              mqtt.test_status || _err=("${_err[@]}" "105") 
              mqtt.test_sub || _err=("${_err[@]}" "106") 
              mqtt.test_pub || _err=("${_err[@]}" "107") 
              mqtt.test_single || _err=("${_err[@]}" "108") 
              mqtt.test_log || _err=("${_err[@]}" "109") 
              mqtt.test_poll || _err=("${_err[@]}" "110") 
              # mqtt.test_install || _err=("${_err[@]}" "111")
              # mqtt.test_remove || _err=("${_err[@]}" "112")
              if [[ ${_err[1]} -gt 0 ]]; then echo "error: ${_err[@]}"; return ${_err[1]}; else return 0; fi ;; 
         *) gr.msg "test case $test_case not written"
            return 1
    esac
}


mqtt.test_help () {
    # function to test mqtt module function mqtt.help
    local _error=0
    gr.msg -v0 -c white 'testing mqtt.help'

      ## TODO: add pre-conditions here 

      mqtt.help ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'mqtt.help passed'
       return 0
    else
       gr.msg -v0 -c red 'mqtt.help failed'
       return $_error
  fi
}


mqtt.test_main () {
    # function to test mqtt module function mqtt.main
    local _error=0
    gr.msg -v0 -c white 'testing mqtt.main'

      ## TODO: add pre-conditions here 

      mqtt.main ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'mqtt.main passed'
       return 0
    else
       gr.msg -v0 -c red 'mqtt.main failed'
       return $_error
  fi
}


mqtt.test_enabled () {
    # function to test mqtt module function mqtt.enabled
    local _error=0
    gr.msg -v0 -c white 'testing mqtt.enabled'

      ## TODO: add pre-conditions here 

      mqtt.enabled ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'mqtt.enabled passed'
       return 0
    else
       gr.msg -v0 -c red 'mqtt.enabled failed'
       return $_error
  fi
}


mqtt.test_online () {
    # function to test mqtt module function mqtt.online
    local _error=0
    gr.msg -v0 -c white 'testing mqtt.online'

      ## TODO: add pre-conditions here 

      mqtt.online ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'mqtt.online passed'
       return 0
    else
       gr.msg -v0 -c red 'mqtt.online failed'
       return $_error
  fi
}


mqtt.test_status () {
    # function to test mqtt module function mqtt.status
    local _error=0
    gr.msg -v0 -c white 'testing mqtt.status'

      ## TODO: add pre-conditions here 

      mqtt.status ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'mqtt.status passed'
       return 0
    else
       gr.msg -v0 -c red 'mqtt.status failed'
       return $_error
  fi
}


mqtt.test_sub () {
    # function to test mqtt module function mqtt.sub
    local _error=0
    gr.msg -v0 -c white 'testing mqtt.sub'

      ## TODO: add pre-conditions here 
    export -f mqtt.sub
    timeout 2s bash -c mqtt.sub '#' ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'mqtt.sub passed'
       return 0
    else
       gr.msg -v0 -c red 'mqtt.sub failed'
       return $_error
  fi
}


mqtt.test_pub () {
    # function to test mqtt module function mqtt.pub
    local _error=0
    gr.msg -v0 -c white 'testing mqtt.pub'

      ## TODO: add pre-conditions here 

      mqtt.pub "/test" "test" ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'mqtt.pub passed'
       return 0
    else
       gr.msg -v0 -c red 'mqtt.pub failed'
       return $_error
  fi
}


mqtt.test_single () {
    # function to test mqtt module function mqtt.single
    local _error=0
    gr.msg -v0 -c white 'testing mqtt.single'

      ## TODO: add pre-conditions here 
       export -f mqtt.single
       timeout 2s bash -c mqtt.single "test" ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'mqtt.single passed'
       return 0
    else
       gr.msg -v0 -c red 'mqtt.single failed'
       return $_error
  fi
}


mqtt.test_log () {
    # function to test mqtt module function mqtt.log
    local _error=0
    gr.msg -v0 -c white 'testing mqtt.log'

      ## TODO: add pre-conditions here 
    export -f mqtt.log
    timeout 2s bash -c mqtt.log "/test" "test"; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'mqtt.log passed'
       return 0
    else
       gr.msg -v0 -c red 'mqtt.log failed'
       return $_error
  fi
}


mqtt.test_poll () {
    # function to test mqtt module function mqtt.poll
    local _error=0
    gr.msg -v0 -c white 'testing mqtt.poll'

      ## TODO: add pre-conditions here 

      mqtt.poll start; _error=$?
      mqtt.poll end; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'mqtt.poll passed'
       return 0
    else
       gr.msg -v0 -c red 'mqtt.poll failed'
       return $_error
  fi
}


mqtt.test_install () {
    # function to test mqtt module function mqtt.install
    local _error=0
    gr.msg -v0 -c white 'testing mqtt.install'

      ## TODO: add pre-conditions here 

      mqtt.install ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'mqtt.install passed'
       return 0
    else
       gr.msg -v0 -c red 'mqtt.install failed'
       return $_error
  fi
}


mqtt.test_remove () {
    # function to test mqtt module function mqtt.remove
    local _error=0
    gr.msg -v0 -c white 'testing mqtt.remove'

      ## TODO: add pre-conditions here 

      mqtt.remove ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'mqtt.remove passed'
       return 0
    else
       gr.msg -v0 -c red 'mqtt.remove failed'
       return $_error
  fi
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then 
    source "$GRBL_RC"
    GRBL_VERBOSE=2
    mqtt.test $@
fi

