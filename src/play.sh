#!/bin/bash
# timer for giocon client ujo.guru / juha.palm 2019

pv -V >/dev/null || sudo apt install pv 
mpsyt --ver >>/dev/null || mpsyt_install 

main () {
    
    argument="$1"; shift
    show_video=True
    search_music=True                

    case $argument in

            upgrade)            sudo -H pip3 install --upgrade youtube_dl; return $? ;;
            install)            mpsyt_install $@ ;;
            
            song)               to_play="/$@, 1, q"; show_video=False; ;;
            karaoke|lyrics)     to_play="/$@ lyrics, 1, q" ;;
            video|youtube)      to_play="/$@, 1-, q"; search_music=False ;;
            album)              to_play="album $@, 1-, q" ;;
            url|id)             to_play="url $@, 1, q" ;;
            world-news|news)    to_play="url $(cat $GURU_CFG/news-live.pl)"; search_music=False ;; 
            bg|backroung)       to_play="//$@, $((1 + RANDOM % 6)), 1-, q" ; show_video=False ;;
            music-video)        to_play="/$@, 1-, q" ;;
            something|ihansama|\
            random|rändöm)      to_play="/$(shuf -n1  /usr/share/dict/words), 1-, q"; show_video=False ;;
            
            vt|text|ascii)      play_vt $@; mpsyt=False ;;
            demo)               run_demo; mpsyt=False ;;
            beer_brake)         beer_brake ;;

            stop|end)
                exec 3>&2
                exec 2> /dev/null
                    pkill mpsyt
                    pkill pv 
                exec 2>&3
                return 0
                ;;

            help|h)           
                printf 'usage: '$GURU_CALL' play COMMAND what-to-play \ncommands: \n'
                printf 'url|id         play youtube ID or full url \n'
                printf 'video|youtube  search and play video \n'
                printf 'song|music|by  search and play music with video \n'
                printf 'background|bg  search and play play list without video output\n'
                printf 'karaoke        force to find lyrics for songs \n'
                printf 'stop|end       stop and kill player \n'
                printf 'demo           run demo ("'$GURU_CALL' set audio true" to play with audio) \n'
                printf 'vt|text        play vt100 animations ("'$GURU_CALL' play vt help") for more info \n'
                printf 'upgrade        upgrade player \n'          
                printf 'Without command only first match will be played, then exited\n'
                exit 0
                ;;       
            
            "") to_play="/nyan cat, 1, q" ;; 
            
            *) to_play="/$argument $@, 1-, q"; show_video=False ;;
    esac

    if ! [ $mpsyt ]; then 
        pkill mpsyt                                             #; echo to_play: $to_play
        show_video="set show_video $show_video"                 #; echo $show_video
        search_music="set search_music $search_music"           #; echo $search_music
        command="mpsyt $show_video, $search_music, $to_play"    #; echo $command
        gnome-terminal --geometry=80x28 --zoom=0.75 -- /bin/bash -c "$command; exit; $SHELL; "
    fi
}


mpsyt_install () {

        sudo apt-get -y install mplayer python3-pip pulseaudio amixer pkill gnome-terminal
        sudo -H pip3 install --upgrade pip
        sudo -H pip3 install setuptools mps-youtube
        sudo -H pip3 install --upgrade youtube_dl 
        pip3 install mps-youtube --upgrade 
        error=$?
        sudo ln -s /usr/local/bin/mpsyt /usr/bin/mpsyt 
        return $error
}


play_vt() {

        video_name="$1"
        video="$GURU_VIDEO/$1.vt"

        case "$1" in 

            list)
                    more $GURU_CFG/vt.list                            
                    ;;

            locale|local)
                    files=$(basename "$(ls $GURU_VIDEO|grep vt| cut -f1 -d".")")
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
                        cat $GURU_CFG/vt.list |grep $video_name && wget -N -P $GURU_VIDEO http://artscene.textfiles.com/vt100/$1.vt || echo "no video"
                    fi
                    
                    cat "$video" | pv -q -L 2000                         
        esac
}


run_demo() {

        audio=$GURU_AUDIO_ENABLED          
        clear                

        if $audio; then
             $GURU_CALL fadedown
             pkill mplayer
             pkill xplayer
             #guru volume 50
             mplayer >>/dev/null && mplayer -ss 2 -novideo $GURU_AUDIO/fairlight.m4a </dev/null >/dev/null 2>&1 &
             $GURU_CALL fadeup
         fi

        guru play vt twilight
        printf "\n                             akrasia.ujo.guru \n"

        if $audio; then
            $GURU_CALL fadedown
            pkill mplayer
            mplayer >>/dev/null && mplayer -ss 1 $GURU_AUDIO/satelite.m4a </dev/null >/dev/null 2>&1 &                
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

beer_brake () {

        resize -s 24 66

        if $GURU_AUDIO_ENABLED; then
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
        
        if $GURU_AUDIO_ENABLED; then
            guru play stop
        fi

        clear
}


me=${BASH_SOURCE[0]}
if [[ "$me" == "${0}" ]]; then
    main $@
    exit $?
fi



# tests

    # argument=$($GURU_BIN/guru translate -b :en $argument)     # subject command to translator.. interesting but probably not practical

    # while [[ "$#" -gt 0 ]]
    #     do case $1 in
    #           -bg|--backround) show_video=False ;;     
    #           -ko|--karaoke|--lyrics) show_video=False ;;      
    #           *) ;;                                              
    #     esac
    # done


