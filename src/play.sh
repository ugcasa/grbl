# player wrap for giocon.client
# casa@ujo.guru 2019

pv -V >/dev/null || sudo apt install pv
mpsyt --ver >>/dev/null || play.install

play.main () {

    argument="$1"; shift
    show_video="True"                                           # mpsyt believes only "True" with the capital t
    search_music="True"

    case "$argument" in
            beer|demo|help|install|upgrade)
                                    play.$argument $@               ; return 0 ;;
            stop|end)               play.silence $@                 ; return 0 ;;
            vt|text|ascii)          play.text $@                    ; return 0 ;;
            api_key)                play.set_api_key $@             ; return 0 ;;
            url|id)                 to_play="url $@, 1, q"          ;;
            music-video)            to_play="/$@, 1-, q"            ;;
            karaoke|lyrics)         to_play="/$@ lyrics, 1, q"      ;;
            album)                  to_play="album $@, 1-, q"       ;;
            song)                   to_play="/$@, 1, q"                         ; show_video="False"    ;;
            video|youtube)          to_play="/$@, 1-, q"                        ; search_music="False"  ;;
            world-news|news)        to_play="url $(cat $GURU_CFG/news-live.pl)" ; search_music="False"  ;;
            bg|backroung)           to_play="//$@, $((1 + RANDOM % 6)), 1-, q"  ; show_video="False"    ;;
            enter)                  cvlc $GURU_LOCAL_AUDIO/system/enter.mp4 --play-and-exit ; exit 0    ;;

            something|random)       random=$(shuf -n1  /usr/share/dict/words)
                                    to_play="/$random, 1-, q"
                                    show_video="False" ;;

            jotain)                 random=$($GURU_CALL trans -b -p en:fi "$(shuf -n1 /usr/share/dict/words)")
                                    echo "$random"
                                    to_play="/$random, 1-, q"
                                    show_video="False" ;;

            "")                     to_play="/nyan cat, 1, q" ;;
            *)                      to_play="/$argument $@, 1-, q"
                                    show_video="False" ;;
    esac
    pkill mpsyt                                                                     #; echo to_play: $to_play
    show_video="set show_video $(printf '%s' "${show_video[@]^}")"                 #; echo $show_video, (+re capital initial to be sure)
    search_music="set search_music $(printf '%s' "${search_music[@]^}")"           #; echo $search_music (+re capital initial)
    command="mpsyt $show_video, $search_music, $to_play"                            #; echo $command
    gnome-terminal --geometry=80x28 --zoom=0.75 -- /bin/bash -c "$command; exit; $SHELL; "

}

play.upgrade () {
    gmsg -v1 "$( sudo -H pip3 install --upgrade youtube_dl )"
    gmsg -v1 "$( sudo apt-get install )"
    gmsg -v1 "$( mpsyt set player mpv, q )"
    play.set_api_key

    return 0
}


play.help () {
    gmsg -v1 -c white "guru-client play help -----------------------------------------------"
    gmsg -v2
    gmsg -v1 "usage: $GURU_CALL play COMMAND what-to-play "
    gmsg -v2
    gmsg -v1 -c white "commands: "
    gmsg -v1 "  url|id         play youtube ID or full url "
    gmsg -v1 "  video|youtube  search and play video "
    gmsg -v1 "  song|music|by  search and play music with video "
    gmsg -v1 "  background|bg  search and play play list without video output "
    gmsg -v1 "  karaoke        force to find lyrics for songs "
    gmsg -v1 "  stop|end       stop and kill player "
    gmsg -v1 "  demo           run demo "
    gmsg -v1 "  vt|text        play vt100 animations "
    gmsg -v1 "  upgrade        upgrade player "
    gmsg -v1 "  api_key <key>  set youtube api key. empty input uses config file data "
    gmsg -v2
}


play.silence () {
    exec 3>&2
    exec 2> /dev/null
        pkill mpsyt
        pkill pv
    exec 2>&3
    return 0

}


play.set_api_key() {
    # remove cache file
    local api_key=""
    [[ -f /.config/mps-youtube/cache_py_* ]] && rm -f -v "~/.config/mps-youtube/cache_py_*"
    # resolve user input and set key
    [[ "$1" ]] && api_key="$1" || api_key="$GURU_YOUTUBE_API_KEY"
    [[ "$GURU_YOUTUBE_API_KEY" ]] || read -p "input api key: " api_key
    if (( ${#api_key}<20 )); then echo "too short api key" ; return 100 ; fi
    gmsg -v1 "$(mpsyt set api_key $api_key , q | grep -m1 $api_key | xargs)"
    return 0
}


play.install () {
    # install
    sudo apt-get -y install mplayer python3-pip pulseaudio amixer pkill gnome-terminal
    sudo -H pip3 install --upgrade pip
    sudo -H pip3 install setuptools mps-youtube
    sudo -H pip3 install --upgrade youtube_dl
    pip3 install mps-youtube --upgrade
    sudo apt-get install mpv mplayer    # both mplayer to mpv to support easy change
    error=$?
    sudo ln -s /usr/local/bin/mpsyt /usr/bin/mpsyt    # hmm..
    mpsyt set player mpv                # prevent player premature coetus interraptus
    [ $error ] && echo $error
    play.set_api_key
    return $error
}


play.text() {
    # Play text based videos on terminal window.
    # Uses htps://artscene.textfiles.com as source
    # local storage is checked before download
    # Dowloaded files ase saved to $GURU_LOCAL_VIDEO/vt
    video_name="$1"
    video="$GURU_LOCAL_VIDEO/vt/$1.vt"

    case "$1" in

        list)
                more" $GURU_CFG/$GURU_USER/vt.list"
                ;;

        locale|local)
                files=$(basename "$(ls $GURU_LOCAL_VIDEO|grep vt| cut -f1 -d".")")
                echo $files
                ;;

        help|-h|--help)
                echo "Usage: $GURU_CALL play text COMMAD or what-to-play"
                echo "Commands:"
                printf "list            list of videos on artscene.textfiles.com \n"
                printf "local|locale    local videos\n"
                echo 'check list, "'$GURU_CALL' play text list" then "'$GURU_CALL' play text <what-found-in-list>" '
                ;;
            *)
                if ! [ -f $video ]; then
                    cat" $GURU_CFG/$GURU_USER/vt.list" |grep $video_name && wget -N -P $GURU_LOCAL_VIDEO http://artscene.textfiles.com/vt100/$1.vt || echo "no video"
                fi

                cat "$video" | pv -q -L 2000
    esac
    return 0
}


play.demo() {

    audio=$GURU_FLAG_AUDIO
    clear

    if $audio; then
        $GURU_CALL fadedown
        pkill mplayer
        pkill xplayer
        mplayer >>/dev/null && mplayer -ss 2 -novideo $GURU_LOCAL_MUSIC/fairlight.m4a </dev/null >/dev/null 2>&1 &
        $GURU_CALL fadeup
    fi

    guru play vt twilight
    printf "\n                             akrasia.ujo.guru \n"

    if $audio; then
        $GURU_CALL fadedown
        pkill mplayer
        mplayer >>/dev/null && mplayer -ss 1 $GURU_LOCAL_MUSIC/satelite.m4a </dev/null >/dev/null 2>&1 &
        $GURU_CALL fadeup
    fi

    guru play vt jumble
    printf "\n                    http://ujo.guru - ujoguru.slack.com \n"

    if $audio; then
        $GURU_CALL fadedown
        pkill mplayer
    fi
    return 0
}


play.beer () {

    resize -s 24 66

    if $GURU_FLAG_AUDIO; then
        guru play volume 50
        guru play classical music valze
    fi

    while true; do
        guru play vt tauko
        read -n 1 -t 3 input
        if [[ $input ]];
            then
            echo
            break
        fi

    done

    if $GURU_FLAG_AUDIO; then
        guru play stop
    fi

    clear
    return 0
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    play.main "$@"
    exit $?
fi

