#!/bin/bash 
# automatically generated tester for guru-client yle.sh Wed 10 Jan 2024 01:04:40 AM EET casa@ujo.guru 2020

source $GURU_BIN/common.sh
source ../../modules/yle.sh 

## TODO add test initial conditions here

yle.test() {
    local test_case=$1
    local _err=($0)
    case "$test_case" in
           1) yle.status ; return 0 ;;  # 1) quick check
         all) 
         # TODO: remove non wanted functions and check run order. 
              echo ; yle.test_help || _err=("${_err[@]}" "101") 
              echo ; yle.test_main || _err=("${_err[@]}" "102") 
              echo ; yle.test_podcast || _err=("${_err[@]}" "103") 
              echo ; yle.test_playlist || _err=("${_err[@]}" "104") 
              echo ; yle.test_arguments || _err=("${_err[@]}" "109") 
              echo ; yle.test_sort || _err=("${_err[@]}" "110") 
              echo ; yle.test_make_playlist || _err=("${_err[@]}" "111") 
              echo ; yle.test_get_metadata || _err=("${_err[@]}" "112") 
              echo ; yle.test_get_media || _err=("${_err[@]}" "113") 
              echo ; yle.test_get_subtitles || _err=("${_err[@]}" "114") 
              echo ; yle.test_radio_listen || _err=("${_err[@]}" "115") 
              echo ; yle.test_place_media || _err=("${_err[@]}" "116") 
              echo ; yle.test_play_media || _err=("${_err[@]}" "117") 
              echo ; yle.test_rc || _err=("${_err[@]}" "118") 
              echo ; yle.test_make_rc || _err=("${_err[@]}" "119") 
              if [[ ${_err[1]} -gt 0 ]]; then echo "error: ${_err[@]}"; return ${_err[1]}; else return 0; fi ;; 
         *) gr.msg "test case $test_case not written"
            return 1
    esac
}


yle.test_help () {
    # function to test yle module function yle.help
    local _error=0
    gr.msg -v0 -c white 'testing yle.help'

      ## TODO: add pre-conditions here 

      yle.help ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'yle.help passed' 
       return 0
    else
       gr.msg -v0 -c red 'yle.help failed' 
       return $_error
  fi
}


yle.test_main () {
    # function to test yle module function yle.main
    local _error=0
    gr.msg -v0 -c white 'testing yle.main'

      ## TODO: add pre-conditions here 

      yle.main ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'yle.main passed' 
       return 0
    else
       gr.msg -v0 -c red 'yle.main failed' 
       return $_error
  fi
}


yle.test_podcast () {
    # function to test yle module function yle.podcast
    local _error=0
    gr.msg -v0 -c white 'testing yle.podcast'

      ## TODO: add pre-conditions here 

      yle.podcast ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'yle.podcast passed' 
       return 0
    else
       gr.msg -v0 -c red 'yle.podcast failed' 
       return $_error
  fi
}


yle.test_playlist () {
    # function to test yle module function yle.playlist
    local _error=0
    gr.msg -v0 -c white 'testing yle.playlist'

      ## TODO: add pre-conditions here 

      yle.playlist ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'yle.playlist passed' 
       return 0
    else
       gr.msg -v0 -c red 'yle.playlist failed' 
       return $_error
  fi
}

yle.test_arguments () {
    # function to test yle module function yle.arguments
    local _error=0
    gr.msg -v0 -c white 'testing yle.arguments'

      ## TODO: add pre-conditions here 

      yle.arguments ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'yle.arguments passed' 
       return 0
    else
       gr.msg -v0 -c red 'yle.arguments failed' 
       return $_error
  fi
}


yle.test_sort () {
    # function to test yle module function yle.sort
    local _error=0
    gr.msg -v0 -c white 'testing yle.sort'

      ## TODO: add pre-conditions here 

      yle.sort ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'yle.sort passed' 
       return 0
    else
       gr.msg -v0 -c red 'yle.sort failed' 
       return $_error
  fi
}


yle.test_make_playlist () {
    # function to test yle module function yle.make_playlist
    local _error=0
    gr.msg -v0 -c white 'testing yle.make_playlist'

      ## TODO: add pre-conditions here 

      yle.make_playlist ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'yle.make_playlist passed' 
       return 0
    else
       gr.msg -v0 -c red 'yle.make_playlist failed' 
       return $_error
  fi
}


yle.test_get_metadata () {
    # function to test yle module function yle.get_metadata
    local _error=0
    gr.msg -v0 -c white 'testing yle.get_metadata'

      ## TODO: add pre-conditions here 

      yle.get_metadata ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'yle.get_metadata passed' 
       return 0
    else
       gr.msg -v0 -c red 'yle.get_metadata failed' 
       return $_error
  fi
}


yle.test_get_media () {
    # function to test yle module function yle.get_media
    local _error=0
    gr.msg -v0 -c white 'testing yle.get_media'

      ## TODO: add pre-conditions here 

      yle.get_media ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'yle.get_media passed' 
       return 0
    else
       gr.msg -v0 -c red 'yle.get_media failed' 
       return $_error
  fi
}


yle.test_get_subtitles () {
    # function to test yle module function yle.get_subtitles
    local _error=0
    gr.msg -v0 -c white 'testing yle.get_subtitles'

      ## TODO: add pre-conditions here 

      yle.get_subtitles ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'yle.get_subtitles passed' 
       return 0
    else
       gr.msg -v0 -c red 'yle.get_subtitles failed' 
       return $_error
  fi
}


yle.test_radio_listen () {
    # function to test yle module function yle.radio_listen
    local _error=0
    gr.msg -v0 -c white 'testing yle.radio_listen'

      ## TODO: add pre-conditions here 

      yle.radio_listen ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'yle.radio_listen passed' 
       return 0
    else
       gr.msg -v0 -c red 'yle.radio_listen failed' 
       return $_error
  fi
}


yle.test_place_media () {
    # function to test yle module function yle.place_media
    local _error=0
    gr.msg -v0 -c white 'testing yle.place_media'

      ## TODO: add pre-conditions here 

      yle.place_media ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'yle.place_media passed' 
       return 0
    else
       gr.msg -v0 -c red 'yle.place_media failed' 
       return $_error
  fi
}


yle.test_play_media () {
    # function to test yle module function yle.play_media
    local _error=0
    gr.msg -v0 -c white 'testing yle.play_media'

      ## TODO: add pre-conditions here 

      yle.play_media ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'yle.play_media passed' 
       return 0
    else
       gr.msg -v0 -c red 'yle.play_media failed' 
       return $_error
  fi
}


yle.test_rc () {
    # function to test yle module function yle.rc
    local _error=0
    gr.msg -v0 -c white 'testing yle.rc'

      ## TODO: add pre-conditions here 

      yle.rc ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'yle.rc passed' 
       return 0
    else
       gr.msg -v0 -c red 'yle.rc failed' 
       return $_error
  fi
}


yle.test_make_rc () {
    # function to test yle module function yle.make_rc
    local _error=0
    gr.msg -v0 -c white 'testing yle.make_rc'

      ## TODO: add pre-conditions here 

      yle.make_rc ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green 'yle.make_rc passed' 
       return 0
    else
       gr.msg -v0 -c red 'yle.make_rc failed' 
       return $_error
  fi
}


# () {
    # function to test yle module function #
    local _error=0
    gr.msg -v0 -c white 'testing #'

      ## TODO: add pre-conditions here 

      # ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green '# passed' 
       return 0
    else
       gr.msg -v0 -c red '# failed' 
       return $_error
  fi
}


# () {
    # function to test yle module function #
    local _error=0
    gr.msg -v0 -c white 'testing #'

      ## TODO: add pre-conditions here 

      # ; _error=$?

      ## TODO: add analysis here and manipulate $_error 

    if  ((_error<1)) ; then 
       gr.msg -v0 -c green '# passed' 
       return 0
    else
       gr.msg -v0 -c red '# failed' 
       return $_error
  fi
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then 
    source "$GURU_RC" 
    GURU_VERBOSE=2
    yle.test $@
fi

