#!/bin/bash
# grbl tor browser ujo.guru 2020
source $GRBL_BIN/common.sh

tor.main() {

    source $GRBL_BIN/corsair.sh
    command="$1"; shift
    case "$command" in
         help|check|status|start|kill|install|remove)
                            tor.$command    ; return $? ;;
                      *)    tor.start ;;
        esac
}


tor.help () {
    gr.msg -v1 -c white "grbl tor browser help "
    gr.msg -v2
    gr.msg -v0 "usage:    $GRBL_CALL tor [help|check|status|start|kill|install|remove]"
    gr.msg -v2
}


tor.check () {
    # return 0 if installed (what is same as true) without printout
    if [[ -f $GRBL_APP/tor-browser_en-US/Browser/start-tor-browser ]] ; then
            return 0
        else
            return 100
        fi
}


tor.status () {
    # return 0 if installed (what is same as true) with printout
    gr.msg -n -v1 -t "${FUNCNAME[0]}: "
    gr.msg -n "tor browser is "
    if tor.check ; then
        gr.msg -c green "installed"
        return 0
    else
        gr.msg -c red "not installed"
        return 1
    fi
}


tor.start() {
    tor.check
    sh -c '"$GRBL_APP/tor-browser_en-US/Browser/start-tor-browser" --detach || ([ !  -x "$GRBL_APP/tor-browser_en-US/Browser/start-tor-browser" ] && "$(dirname "$*")"/Browser/start-tor-browser --detach)' dummy %k X-TorBrowser-ExecShell=./Browser/start-tor-browser --detach
    error_code="$?"
    if (( error_code == 127 )); then
        rm -rf "$GRBL_APP/tor-browser_en-US"
        gr.msg -c yellow "failed, try re-install by $GRBL_CALL tor install"
        return "$error_code"
    fi
    return 0
}


tor.kill () {
    msg -v2 -c black "${FUNCNAME[0]} TBD"
}


tor.install () {
    unset _url _dir _file _form _lang
    [[ $GRBL_APP ]] || GRBL_APP="$HOME"                     # if run outside of grbl
    local _url="https://dist.torproject.org/torbrowser"
    local _file="tor-browser-linux64-"
    local _form=".tar.xz"
    local _lang="_${LANGUAGE//_/-}" ; [[ "$1" ]] && _lang="_$1"     # using system language
    local _location="$GRBL_APP/tor-browser""$_lang"
    local _dir="/tmp/$USER/grbl/tor"

    [[ -d $_location ]] && rm -rf $_location

    # enter to temp folder
    [[ -d "$_dir" ]] ||mkdir -p "$_dir"
    cd "$_dir"

    # get version folder list
    [[ -f torbrowser ]] && rm -fr torbrowser
    wget "$_url"

    # get version and generate file and url
    local _ver=$(cat torbrowser | grep "/icons/folder.gif" | cut -d " " -f 5 )
    _ver=${_ver%%'/"'*}
    _ver=${_ver#*'="'}              ; gr.msg -v2 "version: $_ver"
    _file="$_file$_ver$_lang$_form" ; gr.msg -v2 "file: $_file"
    _url="$_url/$_ver/$_file"       ; gr.msg -v2 "url: $_url"
    # get browser
    [[ -f "$_file" ]] && rm -fr "$_file"
    wget "$_url"
    # install browser
    [[ -d "$GRBL_APP" ]] || mkdir -p "$GRBL_APP"
    [[ -d "$GRBL_APP/tor-browser$_lang" ]] && rm -rf "$GRBL_APP/tor-browser$_lang"
    tar xf "$_file" -C "$GRBL_APP"

    gr.msg -c white "grbl is ready to tor, type 'grbl tor' to run browser"
}


tor.remove () {
    local _lang="_${LANGUAGE//_/-}" ; [[ "$1" ]] && _lang="_$1"     # using system language
    local _location="$GRBL_APP/tor-browser""$_lang"
    [[ -d $_location ]] || gr.msg -c white -x 0 "tor browser not installed"
    [[ $GRBL_APP ]] || gr.msg -c red -x 100 "emty variable GRBL_APP"
    [[ -d $GRBL_APP ]] || gr.msg -c yellow -x 100 "$GRBL_APP folder not exist"
    rm -rf $_location || gr.msg -c yellow "unable to remove $_location"
    msg -v2 -c white "${FUNCNAME[0]} tor browser removed"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # source "$GRBL_RC"
    tor.main "$@"
    exit 0
fi


