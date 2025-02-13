#!/bin/bash
# TODO: re-written non tested

source common.sh

url_source="http://www.microchip.com/forums/download.axd?file=0;749972"
local_source="$GURU_BIN/modules/programmer/PK2DeviceFile.zip"


pk2.main () {
    # command parser
    program_indicator_key="f$(gr.poll programmer)"

    local _cmd="$1" ; shift
    case "$_cmd" in
               status|help|install|remove)
                    pk2.$_cmd "$@" ; return $? ;;
               *)
					gr.msg -c yellow "${FUNCNAME[0]}: unknown command: $_cmd"
					return 127
        esac

    return 0
}


pk2.help () {
    gr.msg -v1 -c white "guru-client pk2 help "
    gr.msg -v2
    gr.msg -v0 "usage:    $GURU_CALL pk2 start|end|status|help|install|remove"
    gr.msg -v2
    gr.msg -v1 -c white "commands: "
    gr.msg -v1 " install                  install pk2 programmer for PIC "
    gr.msg -v1 " remove                   remove installationa and requirements "
    gr.msg -v2 " help                     printout this help "
    gr.msg -v2
    gr.msg -v1 -c white "example: "
    gr.msg -v1 "         $GURU_CALL programmer pk2 status "
    gr.msg -v2
}


pk2.status () {
    if pk2cmd --version >>/dev/null ; then # TBD check argument
        gr.msg -v1 -c green "pk2 installed" -k $program_indicator_key
        return 0
    else
        gr.msg -v1 -c red "pk2 not installed" -k $program_indicator_key
        return 1
    fi
}


pk2.install () {

	# check installation
	if pk2cmd -?v ; then
		gr.msg -c green "already installed"
		gr.msg -v2 "to reinstall perform 'remove' first"
		return 0
	fi

	cd /tmp ; mkdir pk2 ; cd pk2

	# install requirements
	sudo apt update
	sudo apt install -y g++ libusb-dev

	# get source and unzip to temp
	if ! [[ -f PICkit2_PK2CMD_WIN32_SourceV1-21_RC1.zip ]] ; then
		wget http://ww1.microchip.com/downloads/en/DeviceDoc/PICkit2_PK2CMD_WIN32_SourceV1-21_RC1.zip
	fi
	unzip PICkit2_PK2CMD_WIN32_SourceV1-21_RC1.zip

	# copile
	cd pk2cmd/pk2cmd
	make linux || gr.msg -c yellow "installation failed" && gr.msg -c green "ok"
	sudo cp pk2cmd /usr/local/bin/
	sudo chmod u+s /usr/local/bin/pk2cmd

	[[ -d /usr/share/pk2 ]] || sudo mkdir /usr/share/pk2

	# check/get device file
	if ! [ -f $local_source ]; then
    	firefox "$url_source"
    	read -p "waiting until downlaod ready, continue by pressing anykey "
    	mv /Downloads/PK2DeviceFile.zip $local_source
	fi

	# unzip and place
	unzip $local_source
	sudo mv PK2DeviceFile.dat /usr/share/pk2

	# cleaning up
	rm -rf cd /tmp/$USER/pk2

	# Testing
	# export PATH=$PATH:/usr/share/pk2
	pk2cmd -?v && gr.msg -c green "installation OK" || gr.msg -c red "installation failed"

}


pk2.poll () {

    local _cmd="$1" ; shift

    case $_cmd in
        start )
            gr.msg -v1 -t -c black "${FUNCNAME[0]}: pk2 programmer polling started" -k $program_indicator_key
            ;;
        end )
            gr.msg -v1 -t -c reset "${FUNCNAME[0]}: pk2 programmer polling ended" -k $program_indicator_key
            ;;
        status )
			pk2.status
            ;;
        esac
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    #source "$GURU_RC"
    ok2.main "$@"
    exit $?
fi

