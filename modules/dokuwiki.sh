#!/bin/bash
# tools to control dokuwiki installation locally or containerd
# casa@ujo.guru (c) 2022

# needed modules
source common.sh
# global variables for module space
declare -g dokuwiki_functions="tick" # just for testing
# enable configuration
declare -g dokuwiki_tovsdf="tick" # just for testing
# implement needed code
source dokuwiki/functions.sh
# plugins
[[ -f tovsdf.sh ]] && source tovsdf.sh

dokuwiki.main () {
# module command parser

    local _cmd
    if [[ $1 ]] ; then _cmd=$1 ; shift ; fi

    case $_cmd in
        install|upgrade|uninstall|help)
            dokuwiki.$_cmd $@
            gr.msg "${FUNCNAME[0]}/dokuwiki_functions='$dokuwiki_functions'"
            return $?
            ;;
        '')
			gr.msg -c white "more details please"
			;;
        *)
			gr.msg -c white "$unknown command '$_cmd'"
            dokuwiki.help $1
            ;;
    esac
}


dokuwiki.help () {
# module help
    gr.msg -v1 "dokuwiki tool help " -c white
    gr.msg -v2
    gr.msg -v0 "usage:    $GURU_CALL dokuwiki install|upgrade|uninstall|help <arguments>"
    gr.msg -v2
    gr.msg -v1 "command 					explanation" -c white
    gr.msg -v1 " upgrade <id:name>  		update service or platform"
    gr.msg -v1 " install            		install requirements "
    gr.msg -v1 " uninstall          		remove installed requirements "
    gr.msg -v2
    gr.msg -v1 "examples " -c white
    gr.msg -v2
    gr.msg -v1 "    $GURU_CALL dokuwiki upgrade 5a617646ecca:wiki-ug "
    gr.msg -v2
}

# module argument TBD parser for --long-arguments

dokuwiki.install () {
	dokuwiki_functions='tock'
	gr.msg "${FUNCNAME[0]}/dokuwiki_functions='$dokuwiki_functions'"
}

dokuwiki.debug () {
# debug stuff, variable printout with different colors
	[[ $1 ]] && local _color="-c $1"
    gr.msg "${FUNCNAME[0]^^}: dokuwiki.sh" -c white
	gr.msg "${FUNCNAME[0]}/dokuwiki_functions='$dokuwiki_functions'" $_color
	gr.msg "dokuwiki_tovsdf='$dokuwiki_tovsdf'" $_color
}

# this enables to source this file
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        [[ $GURU_DEBUG ]] && dokuwiki.debug olive
        dokuwiki.main "$@"
		[[ $GURU_DEBUG ]] && dokuwiki.debug green
        exit "$?"
	fi

