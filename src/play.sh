#!/bin/bash
# timer for giocon client ujo.guru / juha.palm 2019

variable="$1"
shift

mpsyt --ver >>/dev/null || guru install mpsyt

volume () {
    amixer set 'Master' $1 >>/dev/null
}

fade_low () {
    for i in {1..5}
        do
        amixer -M get Master >>/dev/null
        amixer set 'Master' 5%- >>/dev/null
        sleep 0.5
    done
}

fade_up () {
    for i in {1..5}
        do
        amixer -M get Master >>/dev/null
        amixer set 'Master' 5%+ >>/dev/null
        sleep 0.5
    done
}


pulseaudio_pause()
{
    #kill all audio permately, till logout
    
    echo autospawn = no > $HOME/.config/pulse/client.conf
    pulseaudio --kill
    rm $HOME/.config/pulse/client.conf

}

pulseaudio_pause()
{
    pulseaudio --start
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
                    echo $"Usage: guru play text COMMAD or what-to-play"
                    echo "Commands:"
                    printf "list            list of videos on artscene.textfiles.com \n"
                    printf "local|locale    local videos\n"
                    echo 'check list, "guru play text list" then "guru play text <what-found-in-list>" ' 
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
            fade_low
             pkill mplayer
             pkill xplayer
             volume 50%                
             mplayer >>/dev/null && mplayer -ss 2 -novideo $GURU_AUDIO/fairlight.m4a </dev/null >/dev/null 2>&1 &
             fade_up
         fi

        guru play vt twilight
        printf "\n                             akrasia.ujo.guru \n"

        if $audio; then
            fade_low
            pkill mplayer
            mplayer >>/dev/null && mplayer -ss 1 $GURU_AUDIO/satelite.m4a </dev/null >/dev/null 2>&1 &                
            fade_up
        fi

        guru play vt jumble
        printf "\n                    http://ujo.guru - ujoguru.slack.com \n"

        if $audio; then
            fade_low
            pkill mplayer
        fi
}


case $variable in

            vt|text|textfile)
                play_vt $@
                ;;

            karaoke|kara|oke|sing)
                pkill mpsyt
                command="mpsyt set show_video True, set search_music True, /$@ lyrics, 1, q"
                gnome-terminal --geometry=80x28 --zoom=0.75 -- /bin/bash -c "$command; exit; $SHELL; "
                ;;

            video|youtube)
                pkill mpsyt
                command="mpsyt set show_video True, set search_music False, /$@, 1-, q"
                gnome-terminal --geometry=80x28 --zoom=0.75 -- /bin/bash -c "$command; exit; $SHELL; "
                ;;

            song|music|by|band|artist)
                pkill mpsyt
                command="mpsyt set show_video True, set search_music True, /$@, 1-, q"
                gnome-terminal --geometry=80x28 --zoom=0.75 -- /bin/bash -c "$command; exit; $SHELL; "
                ;;

            album)
                pkill mpsyt
                command="mpsyt set show_video True, set search_music True, album $@"
                gnome-terminal --geometry=80x28 --zoom=1 -- /bin/bash -c "$command; exit; $SHELL; "
                ;;

            url|id)
                pkill mpsyt
                command="mpsyt set show_video, url $@, 1, q"
                gnome-terminal --geometry=80x28 --zoom=0.75 -- /bin/bash -c "$command; exit; $SHELL; "
                ;;

            backroung|bg)
                pkill mpsyt
                #command="for i in {1..3}; do mpsyt set show_video False, set search_music True, //$@, "'$i'", 1-, q; done"  
                command="mpsyt set show_video False, set search_music True, //$@, $((1 + RANDOM % 6)), 1-, q"  
                gnome-terminal --geometry=80x28 --zoom=0.75 -- /bin/bash -c "$command; exit; $SHELL; "    
                ;;

            demo) 
                run_demo
                ;;

            upgrade)
                sudo -H pip3 install --upgrade youtube_dl    			
    			;;

            stop|end)
                pkill mpsyt
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
        
            *)                 
                pkill mpsyt
                command="mpsyt set show_video True, set search_music False, /$variable, 1, q"
                gnome-terminal --geometry=80x28 --zoom=0.75 -- /bin/bash -c "$command; exit; $SHELL; "
esac
