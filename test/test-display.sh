#!/bin/bash 
# automatically generated tester for grbl display.sh Sun 25 Sep 2022 03:13:33 PM EEST casa@ujo.guru 2020

source $GRBL_BIN/common.sh
source ../../modules/display.sh 

## TODO add test initial conditions here

display.test() {
    local test_case=$1
    local _err=($0)
    case "$test_case" in
           1) display.status ; return 0 ;;  # 1) quick check
         all) 
         # TODO: remove non wanted functions and check run order. 
              echo ; display.test_main || _err=("${_err[@]}" "101") 
              echo ; display.test_help || _err=("${_err[@]}" "102") 
              echo ; display.test_check || _err=("${_err[@]}" "103") 
              echo ; display.test_ls || _err=("${_err[@]}" "104") 
              echo ; display.test_set || _err=("${_err[@]}" "105") 
              echo ; display.test_reset || _err=("${_err[@]}" "106") 
              if [[ ${_err[1]} -gt 0 ]]; then echo "error: ${_err[@]}"; return ${_err[1]}; else return 0; fi ;; 
         *) gr.msg "test case $test_case not written"
            return 1
    esac
}


display.test_main () {
    # function to test display module function display.main
    local _error=0
    gr.msg -v0 -c white 'testing display.main'

      ## TODO: add pre-conditions here 

      display.main ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'display.main passed' 
       return 0
    else
       gr.msg -v0 -c red 'display.main failed' 
       return $_error
  fi
}


display.test_help () {
    # function to test display module function display.help
    local _error=0
    gr.msg -v0 -c white 'testing display.help'

      ## TODO: add pre-conditions here 

      display.help ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'display.help passed' 
       return 0
    else
       gr.msg -v0 -c red 'display.help failed' 
       return $_error
  fi
}


display.test_check () {
    # function to test display module function display.check
    local _error=0
    gr.msg -v0 -c white 'testing display.check'

      ## TODO: add pre-conditions here 

      display.check ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'display.check passed' 
       return 0
    else
       gr.msg -v0 -c red 'display.check failed' 
       return $_error
  fi
}


display.test_ls () {
    # function to test display module function display.ls
    local _error=0
    gr.msg -v0 -c white 'testing display.ls'

      ## TODO: add pre-conditions here 

      display.ls ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'display.ls passed' 
       return 0
    else
       gr.msg -v0 -c red 'display.ls failed' 
       return $_error
  fi
}


display.test_set () {
    # function to test display module function display.set
    local _error=0
    gr.msg -v0 -c white 'testing display.set'

      ## TODO: add pre-conditions here 

      display.set ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'display.set passed' 
       return 0
    else
       gr.msg -v0 -c red 'display.set failed' 
       return $_error
  fi
}


display.test_reset () {
    # function to test display module function display.reset
    local _error=0
    gr.msg -v0 -c white 'testing display.reset'

      ## TODO: add pre-conditions here 

      display.reset ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'display.reset passed' 
       return 0
    else
       gr.msg -v0 -c red 'display.reset failed' 
       return $_error
  fi
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then 
    source "$GRBL_RC"
    GRBL_VERBOSE=2
    display.test $@
fi

