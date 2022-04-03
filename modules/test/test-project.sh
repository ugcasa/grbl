#!/bin/bash
# automatically generated tester for guru-client project.sh Tue 03 Aug 2021 09:53:07 AM EEST casa@ujo.guru 2020

source $GURU_BIN/common.sh
source $GURU_BIN/project.sh
GURU_VERBOSE=2
## TODO add test initial conditions here

project.test() {
    local test_case=$1
    local _err=($0)
    case "$test_case" in

         help|main|status|add|ls|info|sublime|open|close|toggle|sublime|open|close|rm|exist|change|poll)
              project.test_$test_case ; return 0 ;;
           1) project.status ; return 0 ;;  # 1) quick check
         all)
         # TODO: remove non wanted functions and check run order.
              echo ; project.test_help || _err=("${_err[@]}" "101")
              echo ; project.test_main || _err=("${_err[@]}" "102")
              echo ; project.test_status || _err=("${_err[@]}" "103")
              echo ; project.test_add || _err=("${_err[@]}" "104")
              echo ; project.test_ls || _err=("${_err[@]}" "105")
              echo ; project.test_info || _err=("${_err[@]}" "106")
              echo ; project.test_sublime || _err=("${_err[@]}" "107")
              echo ; project.test_open || _err=("${_err[@]}" "108")
              echo ; project.test_close || _err=("${_err[@]}" "109")
              echo ; project.test_toggle || _err=("${_err[@]}" "110")
              echo ; project.test_sublime || _err=("${_err[@]}" "111")
              echo ; project.test_open || _err=("${_err[@]}" "112")
              echo ; project.test_close || _err=("${_err[@]}" "113")
              echo ; project.test_rm || _err=("${_err[@]}" "114")
              echo ; project.test_exist || _err=("${_err[@]}" "115")
              echo ; project.test_change || _err=("${_err[@]}" "116")
              echo ; project.test_poll || _err=("${_err[@]}" "117")
              if [[ ${_err[1]} -gt 0 ]]; then echo "error: ${_err[@]}"; return ${_err[1]}; else return 0; fi ;;
         *) gr.msg "test case $test_case not written"
            return 1
    esac
}


project.test_help () {
    # function to test project module function project.help
    local _error=0
    gr.msg -v0 -c white 'testing project.help'

      ## TODO: add pre-conditions here

      project.help ; _error=$?

      ## TODO: add analysis here and manipulate $_error

    if  ((_error<1)) ; then
       gr.msg -v0 -c green 'project.help passed'
       return 0
    else
       gr.msg -v0 -c red 'project.help failed'
       return $_error
  fi
}


project.test_main () {
    # function to test project module function project.main
    local _error=0
    gr.msg -v0 -c white 'testing project.main'

    ## create test project
    if project.main exist test ; then
        project.main close test && gr.msg -v0 -c green 'project.main close ok' || ((_error++))
        project.main rm test && gr.msg -v0 -c green 'project.main rm ok' || ((_error++))
    else
        project.main add test && gr.msg -v0 -c green 'project.main add ok' || ((_error++))
    fi


    if  ((_error<1)) ; then
       gr.msg -v0 -c green 'project.main passed'
       return 0
    else
       gr.msg -v0 -c red 'project.main failed'
       return $_error
  fi
}


project.test_status () {
    # function to test project module function project.status
    local _error=0
    gr.msg -v0 -c white 'testing project.status'

      ## TODO: add pre-conditions here

      project.status ; _error=$?

      ## TODO: add analysis here and manipulate $_error

    if  ((_error<1)) ; then
       gr.msg -v0 -c green 'project.status passed'
       return 0
    else
       gr.msg -v0 -c red 'project.status failed'
       return $_error
  fi
}


project.test_add () {
    # function to test project module function project.add
    local _error=0
    gr.msg -v0 -c white 'testing project.add'

      ## TODO: add pre-conditions here

      project.add test ; _error=$?

      ## TODO: add analysis here and manipulate $_error

    if  ((_error<1)) ; then
       gr.msg -v0 -c green 'project.add passed'
       return 0
    else
       gr.msg -v0 -c red 'project.add failed'
       return $_error
  fi
}


project.test_ls () {
    # function to test project module function project.ls
    local _error=0
    gr.msg -v0 -c white 'testing project.ls'

      ## TODO: add pre-conditions here

      project.ls ; _error=$?

      ## TODO: add analysis here and manipulate $_error

    if  ((_error<1)) ; then
       gr.msg -v0 -c green 'project.ls passed'
       return 0
    else
       gr.msg -v0 -c red 'project.ls failed'
       return $_error
  fi
}


project.test_info () {
    # function to test project module function project.info
    local _error=0
    gr.msg -v0 -c white 'testing project.info'

      ## TODO: add pre-conditions here

      project.info ; _error=$?

      ## TODO: add analysis here and manipulate $_error

    if  ((_error<1)) ; then
       gr.msg -v0 -c green 'project.info passed'
       return 0
    else
       gr.msg -v0 -c red 'project.info failed'
       return $_error
  fi
}


project.test_sublime () {
    # function to test project module function project.sublime
    local _error=0
    gr.msg -v0 -c white 'testing project.sublime'

      ## TODO: add pre-conditions here

      project.sublime test ; _error=$?

      ## TODO: add analysis here and manipulate $_error

    if  ((_error<1)) ; then
       gr.msg -v0 -c green 'project.sublime passed'
       return 0
    else
       gr.msg -v0 -c red 'project.sublime failed'
       return $_error
  fi
}


project.test_open () {
    # function to test project module function project.open
    local _error=0
    gr.msg -v0 -c white 'testing project.open'

      ## TODO: add pre-conditions here

      project.open test ; _error=$?

      ## TODO: add analysis here and manipulate $_error

    if  ((_error<1)) ; then
       gr.msg -v0 -c green 'project.open passed'
       return 0
    else
       gr.msg -v0 -c red 'project.open failed'
       return $_error
  fi
}


project.test_close () {
    # function to test project module function project.close
    local _error=0
    gr.msg -v0 -c white 'testing project.close'

      ## TODO: add pre-conditions here

      project.close test ; _error=$?

      ## TODO: add analysis here and manipulate $_error

    if  ((_error<1)) ; then
       gr.msg -v0 -c green 'project.close passed'
       return 0
    else
       gr.msg -v0 -c red 'project.close failed'
       return $_error
  fi
}


project.test_toggle () {
    # function to test project module function project.toggle
    local _error=0
    gr.msg -v0 -c white 'testing project.toggle'

      ## TODO: add pre-conditions here

      project.toggle ; _error=$?

      ## TODO: add analysis here and manipulate $_error

    if  ((_error<1)) ; then
       gr.msg -v0 -c green 'project.toggle passed'
       return 0
    else
       gr.msg -v0 -c red 'project.toggle failed'
       return $_error
  fi
}



project.test_rm () {
    # function to test project module function project.rm
    local _error=0
    gr.msg -v0 -c white 'testing project.rm'

      ## TODO: add pre-conditions here

      project.rm test ; _error=$?

      ## TODO: add analysis here and manipulate $_error

    if  ((_error<1)) ; then
       gr.msg -v0 -c green 'project.rm passed'
       return 0
    else
       gr.msg -v0 -c red 'project.rm failed'
       return $_error
  fi
}


project.test_exist () {
    # function to test project module function project.exist
    local _error=100
    gr.msg -v0 -c white 'testing project.exist'

      ## TODO: add pre-conditions here

      if project.exist test ; then
         _error=0
      fi

      ## TODO: add analysis here and manipulate $_error

    if  ((_error<1)) ; then
       gr.msg -v0 -c green 'project.exist passed'
       return 0
    else
       gr.msg -v0 -c red 'project.exist failed'
       return $_error
  fi
}


project.test_change () {
    # function to test project module function project.change
    local _error=0
    gr.msg -v0 -c white 'testing project.change'

      ## TODO: add pre-conditions here

      project.change client ; _error=$?

      ## TODO: add analysis here and manipulate $_error

    if  ((_error<1)) ; then
       gr.msg -v0 -c green 'project.change passed'
       return 0
    else
       gr.msg -v0 -c red 'project.change failed'
       return $_error
  fi
}


project.test_poll () {
    # function to test project module function project.poll
    local _error=0
    gr.msg -v0 -c white 'testing project.poll'

      ## TODO: add pre-conditions here

      project.poll start || (( _error++ ))
      project.poll status || (( _error++ ))
      project.poll end || (( _error++ ))

      ## TODO: add analysis here and manipulate $_error

    if  ((_error<1)) ; then
       gr.msg -v0 -c green 'project.poll passed'
       return 0
    else
       gr.msg -v0 -c red 'project.poll failed'
       return $_error
  fi
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$GURU_RC"
    source ../../modules/project.sh
    GURU_VERBOSE=2
    project.test $@
fi

