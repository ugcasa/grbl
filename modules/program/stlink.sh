#!/bin/bash
# TODO: re-written non tested

source common.sh

stlink.main () {
    # command parser
    program_indicator_key="f$(gr.poll program)"

    local _cmd="$1" ; shift
    case "$_cmd" in
               status|help|install|remove)
                    stlink.$_cmd "$@" ; return $? ;;
               *)
                    gr.msg -c yellow "${FUNCNAME[0]}: unknown command: $_cmd"
                    return 127
        esac

    return 0
}


stlink.help () {
    gr.msg -v1 -c white "guru-client st-link help "
    gr.msg -v2
    gr.msg -v0 "usage:    $GURU_CALL st-link start|end|status|help|install|remove"
    gr.msg -v2
    gr.msg -v1 -c white "commands: "
    gr.msg -v1 " install                  install st-link programmer for st mcu "
    gr.msg -v1 " remove                   remove installationa and requirements "
    gr.msg -v2 " help                     printout this help "
    gr.msg -v2
    gr.msg -v1 -c white "example: "
    gr.msg -v1 "         $GURU_CALL programmer st-link status "
    gr.msg -v2
}


stlink.status () {

    if locate st-flash >/dev/null ; then
        gr.msg -v2 -c green "installed" -k $program_indicator_key
        return 0
    else
        gr.msg -v2 -c red "not installed" -k $program_indicator_key
        return 1
    fi
}


stlink.install () {

    # check installation
    if st-flash -v ; then
        gr.msg -c green "already installed"
        gr.msg -v2 "to reinstall perform 'remove' first"
        return 0
    fi


    cd /tmp ; mkdir st-link ; cd st-link

    # did not work properly - not mutch testing done
    st-flash --version && exit 0

    cmake >>/dev/null || sudo apt install cmake
    sudo apt install --reinstall build-essential -y

    dpkg -l libusb-1.0-0-dev >>/dev/null || sudo apt-get install libusb-1.0-0-dev

    cd /tmp
    [ -d stlink ] && rm -rf stlink
    git clone https://github.com/texane/stlink
    cd stlink
    make release
    #install binaries:
    sudo cp build/Release/st-* /usr/local/bin -f
    #install udev rules
    sudo cp etc/udev/rules.d/49-stlinkv* /etc/udev/rules.d/ -f
    #and restart udev
    sudo udevadm control --reload
    gr.msg -c green "guru is now ready to program st mcu's"
    gr.msg -v1 "usage: st-flash --reset read test.bin 0x8000000 4096"

}


stlink.poll () {

    local _cmd="$1" ; shift

    case $_cmd in
        start )
            gr.msg -v1 -t -c black "${FUNCNAME[0]}: st-link programmer polling started" -k $program_indicator_key
            ;;
        end )
            gr.msg -v1 -t -c reset "${FUNCNAME[0]}: st-link programmer polling ended" -k $program_indicator_key
            ;;
        status )
            stlink.status
            ;;
        esac
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    #source "$GURU_RC"
    stlink.main "$@"
    exit $?
fi

