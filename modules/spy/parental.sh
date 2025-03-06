# grbl parental scripts casa@ujo.guru 2025
parental_host=

parental.poll() {
# Wait till     
    #gr.msg -v2 "waiting $parental_host to answer"
    printf "waiting $parental_host to answer"
    while true; do
        if ping -c1 -w1 $parental_host >/dev/null; then
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

    parental.poll $1 || return 0

    gnome-terminal --hide-menubar --geometry 80x20 --zoom 1 --hide-menubar --title \
            "firefox parental" -- ssh $parental_host -t '~/.parental/firefox.sh'
}

parental.infect_firefox() {

    local _host=$1
    
    if ssh $parental_host -- '[[ -f ~/.parental/firefox.sh ]] && echo "infected" || echo "helfty"' == "infected"; then
        gr.msg "already infected"
        return 0;
    fi

    if ssh $parental_host -- '[[ -d ~/.parental ]] && echo "exist" || echo "no"' == "no"; then
        ssh $parental_host -- mkdir ~/.parental
    fi

    scp $GRBL_BIN/parental/firefox_remote.sh $parental_host:~/.parental \
        && echo "successfully infected" \
        && echo "something went wrong"
}



