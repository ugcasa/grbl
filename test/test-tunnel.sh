#!/bin/bash 
# automatically generated tester for grbl tunnel.sh Sun 08 Aug 2021 11:57:59 PM EEST casa@ujo.guru 2020

source $GRBL_BIN/common.sh
source $GRBL_BIN/tunnel.sh

## TODO add test initial conditions here

tunnel.test() {
    local test_case=$1
    local _err=($0)
    case "$test_case" in
           1) tunnel.test_status ; return $? ;;  # 1) quick check
           2) tunnel.test_open ; return $? ;;  # 1) quick check
           3) tunnel.test_close ; return $? ;;  # 1) quick check
           4) tunnel.test_help ; return $? ;;  # 1) quick check

           help|main|status|add|rm|ls|parameters|open|close|tmux|poll|requirements)
              project.test_$test_case ; return $? ;;
         all) 
         # TODO: remove non wanted functions and check run order. 
              echo ; tunnel.test_help || _err=("${_err[@]}" "101") 
              echo ; tunnel.test_status || _err=("${_err[@]}" "103")
              echo ; tunnel.test_add || _err=("${_err[@]}" "104")
              echo ; tunnel.test_rm  || _err=("${_err[@]}" "105")
              echo ; tunnel.test_ls || _err=("${_err[@]}" "106") 
              #echo ; tunnel.test_parameters || _err=("${_err[@]}" "107")
              echo ; tunnel.test_open  || _err=("${_err[@]}" "108")
              echo ; tunnel.test_main || _err=("${_err[@]}" "102")
              echo ; tunnel.test_close || _err=("${_err[@]}" "109")
              #echo ; tunnel.test_tmux || _err=("${_err[@]}" "110")
              echo ; tunnel.test_poll start|| _err=("${_err[@]}" "111")
              #echo ; tunnel.test_requirements || _err=("${_err[@]}" "112")
              gr.msg "cleaning.."
              tunnel.main close all

              if [[ ${_err[1]} -gt 0 ]]; then echo "error: ${_err[@]}"; return ${_err[1]}; else return 0; fi ;;
         *) gr.msg "test case $test_case not written"
            return 1
    esac
}



tunnel.test_help () {
    # function to test tunnel module function tunnel.help
    local _error=0
    gr.msg -v0 -c white 'testing tunnel.help'

      ## TODO: add pre-conditions here 

      tunnel.help ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'tunnel.help passed'
       return 0
    else
       gr.msg -v0 -c red 'tunnel.help failed'
       return $_error
  fi
}


tunnel.test_main () {
    # function to test tunnel module function tunnel.main
    local _error=0
    gr.msg -v0 -c white 'testing tunnel.main'

      ## TODO: add pre-conditions here 

      tunnel.main ls ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'tunnel.main passed'
       return 0
    else
       gr.msg -v0 -c red 'tunnel.main failed'
       return $_error
  fi
}


tunnel.test_status () {
    # function to test tunnel module function tunnel.status
    local _error=0
    gr.msg -v0 -c white 'testing tunnel.status'

      ## TODO: add pre-conditions here 

      tunnel.status ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'tunnel.status passed'
       return 0
    else
       gr.msg -v0 -c red 'tunnel.status failed'
       return $_error
  fi
}


tunnel.test_add () {
    # function to test tunnel module function tunnel.add
    local _error=0
    gr.msg -v0 -c white 'testing tunnel.add'

      ## TODO: add pre-conditions here 

      tunnel.add test; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'tunnel.add passed'
       return 0
    else
       gr.msg -v0 -c red 'tunnel.add failed'
       return $_error
  fi
}


tunnel.test_rm () {
    # function to test tunnel module function tunnel.rm
    local _error=0
    gr.msg -v0 -c white 'testing tunnel.rm'

      ## TODO: add pre-conditions here 

      tunnel.rm test ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'tunnel.rm passed'
       return 0
    else
       gr.msg -v0 -c red 'tunnel.rm failed'
       return $_error
  fi
}


tunnel.test_ls () {
    # function to test tunnel module function tunnel.ls
    local _error=0
    gr.msg -v0 -c white 'testing tunnel.ls'

      ## TODO: add pre-conditios here

      tunnel.open wiki
      tunnel.ls wiki ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'tunnel.ls passed'
       return 0
    else
       gr.msg -v0 -c red 'tunnel.ls failed'
       return $_error
  fi
}


# tunnel.test_parameters () {
#     # function to test tunnel module function tunnel.parameters
#     local _error=0
#     gr.msg -v0 -c white 'testing tunnel.parameters'

#       ## TODO: add pre-conditions here

#       tunnel.parameters ; _error=$?

#       ## TODO: add analysis here and manipulate $_error

#     if  ((_error<1)) ; then
#        gr.msg -v0 -c green 'tunnel.parameters passed'
#        return 0
#     else
#        gr.msg -v0 -c red 'tunnel.parameters failed'
#        return $_error
#   fi
# }


tunnel.test_open () {
    # function to test tunnel module function tunnel.open
    local _error=0
    gr.msg -v0 -c white 'testing tunnel.open'

      ## TODO: add pre-conditions here 

      tunnel.open wiki ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'tunnel.open passed'
       return 0
    else
       gr.msg -v0 -c red 'tunnel.open failed'
       return $_error
  fi
}


tunnel.test_close () {
    # function to test tunnel module function tunnel.close
    local _error=0
    gr.msg -v0 -c white 'testing tunnel.close'

      ## TODO: add pre-conditions here 

      tunnel.close wiki ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'tunnel.close passed'
       return 0
    else
       gr.msg -v0 -c red 'tunnel.close failed'
       return $_error
  fi
}


# tunnel.test_tmux () {
#     # function to test tunnel module function tunnel.tmux
#     local _error=0
#     gr.msg -v0 -c white 'testing tunnel.tmux'

#       ## TODO: add pre-conditions here

#       tunnel.tmux ; _error=$?

#       ## TODO: add analysis here and manipulate $_error

#     if  ((_error<1)) ; then
#        gr.msg -v0 -c green 'tunnel.tmux passed'
#        return 0
#     else
#        gr.msg -v0 -c red 'tunnel.tmux failed'
#        return $_error
#   fi
# }


tunnel.test_poll () {
    # function to test tunnel module function tunnel.poll
    local _error=0
    gr.msg -v0 -c white 'testing tunnel.poll'

      ## TODO: add pre-conditions here 

      tunnel.poll start || (( _error++ ))
      tunnel.poll status || (( _error++ ))
      tunnel.poll end || (( _error++ ))

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'tunnel.poll passed'
       return 0
    else
       gr.msg -v0 -c red 'tunnel.poll failed'
       return $_error
  fi
}


# tunnel.test_requirements () {
#     # function to test tunnel module function tunnel.requirements
#     local _error=0
#     gr.msg -v0 -c white 'testing tunnel.requirements'

#       ## TODO: add pre-conditions here

#       tunnel.requirements ; _error=$?

#       ## TODO: add analysis here and manipulate $_error

#     if  ((_error<1)) ; then
#        gr.msg -v0 -c green 'tunnel.requirements passed'
#        return 0
#     else
#        gr.msg -v0 -c red 'tunnel.requirements failed'
#        return $_error
#   fi
# }


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then 
    source "$GRBL_RC"
    source ../../modules/tunnel.sh
    GRBL_VERBOSE=2
    tunnel.test $@
fi

