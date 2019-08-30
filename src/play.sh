#!/bin/bash
# timer for giocon client ujo.guru / juha.palm 2019

pv -V >/dev/null || sudo apt install pv 
mpsyt --ver >>/dev/null || mpsyt_install 

main () {

    case $argument in

            vt|text|textfile)
                play_vt $@
                ;;

            song)
                pkill mpsyt
                command="mpsyt set show_video False, set search_music True, /$@, 1, q"
                gnome-terminal --geometry=80x28 --zoom=0.75 -- /bin/bash -c "$command; exit; $SHELL; "                
                ;;

            karaoke)
                pkill mpsyt
                command="mpsyt set show_video True, set search_music True, /$@ lyrics, 1, q"
                gnome-terminal --geometry=80x28 --zoom=0.75 -- /bin/bash -c "$command; exit; $SHELL; "                
                ;;

            video|youtube)
                pkill mpsyt
                command="mpsyt set show_video True, set search_music False, /$@, 1-, q"
                gnome-terminal --geometry=80x28 --zoom=0.75 -- /bin/bash -c "$command; exit; $SHELL; "
                ;;

            album)
                pkill mpsyt
                command="mpsyt set show_video True, set search_music True, album $@"
                gnome-terminal --geometry=80x28 --zoom=1 -- /bin/bash -c "$command; exit; $SHELL; "
                ;;

            url|id)
                pkill mpsyt
                command="mpsyt set show_video True, url $@, 1, q"
                gnome-terminal --geometry=80x28 --zoom=0.75 -- /bin/bash -c "$command; exit; $SHELL; "
                ;;

            demo) 
                run_demo
                ;;

            upgrade)
                sudo -H pip3 install --upgrade youtube_dl  
                return $?             
                ;;

            install) 
                mpsyt_install $@
                ;;

            stop|end)
                
                exec 3>&2
                exec 2> /dev/null
                    pkill mpsyt 
                    pkill pv 
                exec 2>&3
                return 0
                ;;

            world-news)     # wrong
                pkill mpsyt
                command="mpsyt set show_video True, url $(cat $GURU_CFG/news-live.pl)"
                gnome-terminal --geometry=80x28 --zoom=0.75 -- /bin/bash -c "$command; exit; $SHELL; "
                ;;

            help|h)           
                printf 'usage: '$GURU_CALL' play COMMAND what-to-play \ncommands: \n'
                printf 'url|id         play youtube ID or full url \n'
                printf 'video|youtube  search and play video \n'
                printf 'song|music|by  search and play music with video \n'
                printf 'backroung|bg   search and play play list without video output\n'
                printf 'karaoke        force to find lyrics for songs \n'
                printf 'stop|end       stop and kill player \n'
                printf 'demo           run demo ("'$GURU_CALL' set audio true" to play with audio) \n'
                printf 'vt|text        play vt100 animations ("'$GURU_CALL' play vt help") for more info \n'
                printf 'upgrade        upgrade player \n'          
                printf 'Without command only first match will be played, then exited\n'
                ;;       
        
            backroung|bg)
                pkill mpsyt                
                command="mpsyt set show_video False, set search_music True, //$@, $((1 + RANDOM % 6)), 1-, q"  
                gnome-terminal --geometry=80x28 --zoom=0.75 -- /bin/bash -c "$command; exit; $SHELL; "    
                ;;

            music-video)
                pkill mpsyt
                command="mpsyt set show_video True, set search_music True, /$@, 1-, q"
                gnome-terminal --geometry=80x28 --zoom=0.75 -- /bin/bash -c "$command; exit; $SHELL; "
                ;; 

            *)
                pkill mpsyt
                command="mpsyt set show_video False, set search_music True, /$argument $@, 1-, q"
                gnome-terminal --geometry=80x28 --zoom=0.25 -- /bin/bash -c "$command; exit; $SHELL; "
                ;;
    esac
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


# pulseaudio_pause()
# {
#     #kill all audio permately, till logout
#     echo autospawn = no > $HOME/.config/pulse/client.conf
#     pulseaudio --kill
#     rm $HOME/.config/pulse/client.conf
# }


# pulseaudio_pause()
# {
#     pulseaudio --start
#     return $?
# }


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

me=${BASH_SOURCE[0]}
if [[ "$me" == "${0}" ]]; then
    argument="$1"
    shift
    main $@
    exit $?
fi

