#!/bin/bash
# timer for giocon client ujo.guru / juha.palm 2019

variable="$1"
shift

mpsyt --ver >>/dev/null || guru install mpsyt

case $variable in

            vt|text|textfile)
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

            backroung|bg)
                pkill mpsyt
                command="for i in {1..3}; do mpsyt set show_video False, set search_music True, //$@, "'$i'", 1-, q; done"  
                gnome-terminal --geometry=80x28 --zoom=0.75 -- /bin/bash -c "$command; exit; $SHELL; "    
                ;;

            upgrade)
                sudo -H pip3 install --upgrade youtube_dl    			
    			;;

            stop|end)
                pkill mpsyt
                ;;

            help|h)           
                echo $"Usage: guru play COMMAND what-to-play"
                echo "Commands:"
                printf "video|youtube             \tplay video\n"
                printf "song|music|by|band|artist \tPlay music with video\n"
                printf "backroung|bg              \tPlay playlist backround witout video\n"                
                printf "stop|end                  \tStop and kill player\n"
                printf "upgrade                   \tUpgrade player\n"          
                printf "Without command only first match will be played, then exited\n"          
                ;;       
        
            *)                 
                pkill mpsyt
                command="mpsyt set show_video True, set search_music False, /$variable, 1, q"
                gnome-terminal --geometry=80x28 --zoom=0.75 -- /bin/bash -c "$command; exit; $SHELL; "
esac
