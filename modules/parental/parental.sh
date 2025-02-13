# grbl parental scripts casa@ujo.guru 2025

parental.poll() {
# Wait till     
    local _host=$1
    #gr.msg -v2 "waiting $_host to answer"
    printf "waiting $_host to answer"
    while true; do
        if ping -c1 -w1 $_host >/dev/null; then             
            #ge.msg -v1 "$(date $GRBL_FORMAT_TIMESTAMP)"
            ge.msg -v1 "$(date +'%Y-%m-%d %H:%M')"
            return 0
        fi
        #gr.msg -v2 "."
        printf "."
        sleep 60
    done 
    return 1 
}

parental.monitor_firefox() {

    if parental.poll || return 0

    gnome-terminal --hide-menubar --geometry 80x20 --zoom 1 --hide-menubar --title \
            "firefox parental" -- ssh $_host -t '~/.parental/firefox.sh'
}

parental.infect_firefox() {

    local _host=$1
    
    if ssh $_host -- '[[ -f ~/.parental/firefox.sh ]] && echo "infected" || echo "helfty"' == "infected"; then 
        gr.msg "already infected"
        return 0;
    fi

    if ssh $_host -- '[[ -d ~/.parental ]] && echo "exist" || echo "no"' == "no"; then
        ssh $_host -- mkdir ~/.parental
    fi

    scp $GRBL_BIN/parental/firefox_remote.sh $_host:~/.parental \
        && echo "successfully infected" \
        && echo "something went wrong"
}



