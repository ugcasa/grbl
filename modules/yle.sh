#!/bin/bash

#source common.sh

declare -g yle_rc="/tmp/guru-cli_yle.rc"
declare -g yle_run_folder="$(pwd)"
declare -g yle_playlist_folder="$GURU_DATA/yle/playlists"
declare -g yle_temp_folder="$HOME/tmp/yle"
declare -g yle_episodes=()
declare -g yle_media_address=
declare -g yle_media_filename=

yle.help () {

    gr.msg -v1 "guru-cli yle help " -c white
    gr.msg -v2
    gr.msg -v0  "usage:    $GURU_CALL yle get|play|radio|playlist|news|episodes|sub|metadata|install|uninstall|help"
    gr.msg -v2
    gr.msg -v1 "commands: " -c white
    gr.msg -v2
    gr.msg -v1 "  get|dl <id|url>     download media to media folder "
    gr.msg -v1 "  play <id|url>       play episode from stream"
    gr.msg -v1 "  radio ls            list of known yle radio stations"
    gr.msg -v1 "  radio <station>     listen radio <station>"
    gr.msg -v1 "  news                play latest yle tv news "
    gr.msg -v1 "  episodes <url>      get episodes of collection page"
    gr.msg -v1 "  sort                sort files in folder based on yle timestamp"
    gr.msg -v1 "  sub <id|url>        get subtitles for video"
    gr.msg -v1 "  playlist <name>     play playlist"
    gr.msg -v2 "    list              list of playlists"
    gr.msg -v2 "    add               add new playlist"
    gr.msg -v2 "    edit              open playlist in $GURU_PREFERRED_EDITOR"
    gr.msg -v2 "    mv                rename playlist"
    gr.msg -v2 "    rm                remove playlist"
    gr.msg -v2 "    <name> nro        play list item nro"
    gr.msg -v1 "  metadata            get media metadata"
    gr.msg -v1 "  install             install requirements"
    gr.msg -v1 "  uninstall           remove requirements "
    gr.msg -v1 "  help                this help window"
    gr.msg -v2
    gr.msg -v1 "examples: " -c white
    gr.msg -v2
    gr.msg -v1 "  $GURU_CALL yle get 1-4454526        # download media id (or url)"
    gr.msg -v1 "  $GURU_CALL yle play 1-2707315       # play media id (or url)"
    gr.msg -v1 "  $GURU_CALL yle playlist default 4   # play default playlist item 4"
    gr.msg -v1 "  $GURU_CALL yle radio puhe           # to play yle puhe stream"
    gr.msg -v1 "  $GURU_CALL yle episodes https://areena.yle.fi/audio/1-1792200   "
    gr.msg -v2
}


yle.main () {

    yle.arguments $@
    gr.debug "$FUNCNAME command: ${module_command[@]:0:1} transfer:${module_command[@]:1}"

    case ${module_command[@]:0:1} in

        listen|radio)
            yle.radio_listen ${module_command[@]:1}
            ;;

        list|playlist)
            yle.playlist ${module_command[@]:1}
            ;;

        podcast|install|uninstall|upgrade|sort)
            yle.${module_command[@]:0:1} ${module_command[@]:1}
            ;;

        play)
            # echo "$1" | grep "https://" && $GURU_YLE_BASE_URL="" || $GURU_YLE_BASE_URL="https://areena.yle.fi/" >/dev/null
            # gr.msg "getting from url ${GURU_YLE_BASE_URL%/}$1"
            yle-dl --pipe "${GURU_YLE_BASE_URL%/}$1" 2>/dev/null | mpv -
            return $?
            ;;

        get|dl|download)
            for item in "${module_command[@]}"
                do
                   yle.get_metadata "$item" || return 127
                   yle.get_media
                   yle.place_media
                done
            ;;

        news|uutiset)

            news_core="https://areena.yle.fi/1-3235352"
            # yle-dl --pipe --latestepisode "$news_core" 2>/dev/null | mpv -
            # issue 20221206.2 --latestepisode broken, fix below
            yle-dl --pipe $(yle-dl --showepisodepage $news_core | tail -n2 | head -n1)  2>/dev/null | mpv -
            ;;

        episode|episodes)

            yle.get_metadata ${module_command[@]} || return 127

            if ! [[ $yle_episodes ]] ; then
                gr.msg -c white "single episode"
                return 0
            fi

            gr.msg -c light_blue "${yle_episodes[@]}"

            # if [[ $2 == "dl" ]] || gr.ask "download all ${#yle_episodes[@]} episodes?" ; then
            if gr.ask "download all ${#yle_episodes[@]} episodes?" ; then

                    for episode in ${yle_episodes[@]} ; do
                        yle.get_metadata $episode && \
                        yle.get_media && \
                        yle.place_media
                        done
                fi
            ;;

        play)
            yle.get_metadata "$command" || return 127
            echo "osoite: $yle_media_address"
            yle-dl --pipe "$yle_media_address" 2>/dev/null | mpv -
            ;;

        subtitle|subtitles|sub|subs)
            yle.get_metadata ${module_command[@]} || return 127
            yle.get_subtitles
            yle.place_media "$yle_run_folder"
            ;;

        status)  echo "no status data" ;;

        meta|data|metadata|information|info)

            for item in "${module_command[@]}"
                do
                   yle.get_metadata $item && yle.get_media
                done
            ;;

        help)
            yle.help ${module_command[@]}
            ;;

        *)
            for item in "${module_command[@]}"
                do
                   yle.get_metadata $item
                done
            ;;

        esac

    return 0
}


yle.podcast () {
# play yle.areena podcasts

    source audio.sh
    source flag.sh
    declare -g areena_url=
    declare -g temp_playlist="$GURU_DATA/yle/playlists/temp.playlist"
    declare -g json_folder="$GURU_DATA/yle/podcasts"
    declare -ag episode_list=()
    declare -g serie_id="single"
    declare -g selected_podcast_file=
    declare -g selection=0
    declare -g podcast_name=
    # podcast episode variables for menu
    declare -ag title description duration published webpage episode_url
    # podcast list variables for selector
    declare -ag podcast_episde_amount podcast_files podcast_list_title

    # initialize
    [[ -d $json_folder ]] || mkdir -p $json_folder

    #colors


    podcast.get () {
    # get episode or or list of episodes by url given
    # returns episode list in global episode_list variable

        local got=$1

        if ! [[ $got ]]; then
            read -p "Annan sarjan koontisivu tai sivun id: " got
        fi

        if [[ $got =~ "${GURU_YLE_PODCAST_URL%/}" ]] ; then
           areena_url=$got
        else
            areena_url=${GURU_YLE_PODCAST_URL%/}/$got
        fi

        gr.debug "$FUNCNAME GURU_YLE_PODCAST_URL:${GURU_YLE_PODCAST_URL%/}, areena_url: $areena_url"

        # all program_id's start with '1-'
        if ! [[ "$areena_url" =~ "/1-" ]] ; then
            gr.msg -e1 "not a stream page"
            return 101
        fi

        episode_list=($(yle-dl --showepisodepage $areena_url 2>&1))

        # check is program_id valid (yle-dl crashes if not)
        _error=$?
        if [[ $_error -gt 0 ]] ; then
            gr.msg -e1 "non valid url got $_error from yle-dl"
            return 102
        fi

        # check did episode_list list is single or list of episodes
        if [[ ${#episode_list[@]} -gt 1 ]] ; then
            serie_id=${areena_url##*/}
            selected_podcast_file=$json_folder/$serie_id.json
            gr.debug "found ${#episode_list[@]} episodes"

        elif [[ ${#episode_list[@]} == 1 ]] ; then
            gr.debug "$FUNCNAME surprisingly short list: $episode_list"
            if [[ "$episode_list" == "$areena_url" ]] ; then
                gr.msg -e0 "given id/url is single episode page"
            fi
            return 103
        else
            gr.msg -e1 "got nothing"
            return 104
        fi

        echo ${episode_list[@]} >/home/casa/guru/.data/yle/playlists/playlist
        return 0
    }

    podcast.build () {
    # play list of episodes given in episode_list variable
        if [[ -f $selected_podcast_file ]] ; then
            gr.ask "database found, overwrite $selected_podcast_file?" || return 0
        fi

        gr.debug "$FUNCNAME got: ${episode_list[@]} json:$selected_podcast_file"

        gr.msg -v2 -h "building database for ${#episode_list[@]} episodes:"
        gr.msg -V2 -n "building database for ${#episode_list[@]} episodes "
        for (( i = 0; i < ${#episode_list[@]}; i++ )); do
            gr.msg -v2 -c dark_grey "$i ${episode_list[$i]}"
            yle-dl --showmetadata ${episode_list[$i]} | jq -s 'flatten' >>$selected_podcast_file
            gr.msg -V2 -n -c dark_grey "."
        done
        gr.msg -c green "ok"
    }

    podcast.update () {
    # read database
        local _title=
        podcast_list_title=()
        podcast_files=($(find $json_folder -maxdepth 1 -type f))
        for file in ${podcast_files[@]} ; do
            _title="$(jq '.[] | .episode_title' "$file" | head -n1 | cut -d':' -f1 )"
            _title=${_title//'–'/'-'}
            podcast_list_title+=("${_title//'"'}")
            podcast_episde_amount+=($(jq length $file | wc -l))
        done
    }

    podcast.select () {
    # select from known series

        local selection=0
        local pre_selection=

        select.list ()  {
        # printout list of known series
            local _title=
            [[ $GURU_DEBUG ]] || clear
            gr.msg -h "yle.areena podcasts"
            for (( i = 0; i < ${#podcast_list_title[@]}; i++ )); do

                _title=${podcast_list_title[$i]}
                gr.msg -n -h -w4 "${i})"
                gr.msg -n -c list "$_title"
                gr.msg -n -v2 -c dark_grey " (${podcast_episde_amount[$i]})"
                gr.msg

                if [[ $1 ]] && [[ ${_title,,} == $1* ]] ; then
                        selected_podcast_file=${podcast_files[$i]}
                        pre_selection=true
                        break
                fi
            done
            gr.msg -v1 -c dark_grey "(a)dd, (r)emove, (u)pdate, (v)erbosity (q)uit or (0..$((${#podcast_list_title[@]}-1)))"
        }


        # need to update only once during session
        [[ $podcast_name ]] || podcast.update

        # select series file
        while true ; do

            select.list
            [[ $pre_selection ]] && [[ $selected_podcast_file ]] && break
            read -p "select: " selection

            case $selection in
                [0-9]|1[0-9]|2[0-9]|3[0-9])
                    if [[ $selection -ge 0 ]] && [[ $selection -lt ${#podcast_list_title[@]} ]] ; then
                        selected_podcast_file=${podcast_files[$selection]}
                        break
                    fi
                    ;;
                a)
                    podcast.get $@
                    podcast.build
                    ;;
                u)
                    podcast.update
                    ;;
                v)  read -p "select verbosity: " selection
                    if [[ $selection -ge 0 ]] && [[ $selection -lt 3 ]] ; then
                        export GURU_VERBOSE=$selection
                    fi
                    ;;
                r)  read -p "podcast to remove: " selection
                    if [[ $selection -ge 0 ]] && [[ $selection -lt ${#podcast_list_title[@]} ]] ; then
                        if gr.ask "remove ${podcast_list_title[$selection]}?" ; then
                            gr.debug "$FUNCNAME rm :${podcast_files[$selection]}"
                            rm ${podcast_files[$selection]}
                        fi
                    fi
                    podcast.update
                    ;;
                q)
                    exit 0
                    ;;
                *)
                    continue
            esac
        done

        gr.debug "$FUNCNAME selected_podcast_file:'$selected_podcast_file'"
        return 0
    }

    podcast.episodes () {

        IFS=$'\n'
        published=($(jq '.[] | .publish_timestamp' $selected_podcast_file))
        title=($(jq '.[] | .episode_title' $selected_podcast_file))
        description=($(jq '.[] | .description' $selected_podcast_file))
        duration=($(jq '.[] | .duration_seconds' $selected_podcast_file))
        webpage=($(jq '.[] | .webpage' $selected_podcast_file))
        episode_url=($(jq '.[] | .flavors[] | .url' $selected_podcast_file))

        # podcast name
        [[ $GURU_DEBUG ]] || clear
        podcast_name=$(cut -d":" -f1 <<<${title[0]//'"'})
        gr.msg -h "${podcast_name//'–'/'-'}"

        # date stamp width
        [[ ${#title[@]} -lt 10 ]] && width=3
        [[ ${#title[@]} -gt 9 ]] && width=4
        [[ ${#title[@]} -gt 99 ]] && width=5

        for (( i = 0; i < ${#title[@]}; i++ )); do

            # clean up and formatting
            published[$i]=$(date -d ${published[$i]//'"'} +%d.%m.%Y)
            title[$i]=${title[$i]//$podcast_name: }
                title[$i]=${title[$i]//'"'}
                title[$i]=${title[$i]//' _'}
                title[$i]=${title[$i]//'–'/'-'}
                title[$i]=${title[$i]//'\'/'”'}
                title[$i]=${title[$i]//'  '/' '}
                title[$i]=${title[$i]//'*'}
                title[$i]=${title[$i]//'’'/"'"}
            description[$i]=${description[$i]//'\n\n'/' '}
                description[$i]=${description[$i]//'\n'/' '}
                description[$i]=${description[$i]//'\r\r'/ }
                description[$i]=${description[$i]//'\r'}
                description[$i]=${description[$i]//'  '/' '}
                description[$i]=${description[$i]//'//'/'/'}
            duration[$i]=$((${duration[$i]} / 60 ))
            webpage[$i]=${webpage[$i]//'"'}
            episode_url[$i]=${episode_url[$i]//'"'}

            # printout
            gr.msg -h -n -w$width "$(($i+1)))"
            gr.msg -v2 -n -w11 -c dark_grey "${published[$i]} "
            gr.msg -n -c list "${title[$i]} "
            gr.msg -n -v2 -c dark_grey "${duration[$i]} min"
            gr.msg
            gr.msg -v3 -n -c grey "${description[$i]}"
            gr.msg -v3 -n -c dark_grey " ${webpage[$i]}"
            gr.msg -v3 -N
        done
    }

    podcast.play () {
    # play url

        local item=$(($1-1))

        # now playing for other modules
        audio.stop
        flag.set audio_stop
        local np="${title[$item]} [$1/${#title[@]}]"
        echo ${np} >$GURU_AUDIO_NOW_PLAYING

        # printout user view
        gr.msg -N -h ${np}

        gr.msg -n -c grey "${description[$item]}"
        gr.msg -c dark_grey " ${webpage[$item]}"

        # play item
        mpv ${episode_url[$item]}
        [[ -f $GURU_AUDIO_NOW_PLAYING ]] && rm $GURU_AUDIO_NOW_PLAYING
    }

    podcast.menu () {

        local item=1
        local timeout=

        if [[ $1 ]] ; then
            item=$1
            timeout=5
        fi

        podcast.episodes
        local loops=3
        local max=$((${#title[@]}))
        while true ; do

            gr.msg -v1 -c dark_grey "(n)ext, (p)revious, (c)ontinuous, (l)ist, (d)escriptions, (s)eries, (a)dd, (u)pdate, (q)uit or (1..$max)"
            if [[ $timeout ]] ; then
                read -p "[$item/$max] continue ${timeout}s: " -t $timeout selection
            else
                read -p "[$item/$max] select: " selection
            fi
            selection=${selection:-continue}

            case $selection in
                [0-9]|[1-9][0-9]|[1-9][0-9][0-9])
                    [[ $selection -ge 1 ]] && [[ $selection -le $max ]] && item=$selection || continue ;;
                n)  [[ $item -lt $max ]] && item=$(( item + 1 )) || continue ;;
                p)  [[ $item -gt 1 ]] && item=$(( item - 2 )) || continue ;;
                l)  export GURU_VERBOSE=2 ; podcast.episodes ; continue ;;
                u)  podcast.update ; podcast.episodes ; continue ;;
                s)  podcast.select ; podcast.menu ;;
                a)  podcast.get ; podcast.build ; podcast.select ; podcast.menu ;;
                d)  [[ $GURU_VERBOSE -gt 2 ]] && export GURU_VERBOSE=2 || export GURU_VERBOSE=3 ; podcast.episodes ; continue ;;
                c)  ! [[ $timeout ]] && timeout=5 || timeout= ; continue ;;
                q*)  exit 0 ;;
                continue) true ;;
                *)  continue ;;
            esac

            podcast.play $item

            if [[ $item -lt $max ]] ; then
                [[ $timeout ]] && item=$(( item + 1 ))
            else
                item=1
            fi

            # print list when it goes hide
            loops=$((loops-1))
            if [[ $GURU_VERBOSE -lt 3 ]] && [[ $loops -le 0 ]]; then
                podcast.episodes
                loops=3
            fi
         done
    }

    local command=$1
    shift
    gr.debug "$FUNCNAME command: $command, rest: $@"

    case $command in

        add)
            podcast.get $@
            podcast.build
            ;;
        play)
            podcast.select $1
            podcast.menu $2
            ;;
        *)
            podcast.select $command
            podcast.menu $1
            ;;
        help)
            yle.help
            ;;
    esac

}


yle.playlist () {
# play playlists

    local url=
    local name="default"
    local line=0
    local lines=
    local ans1= ; local ans2= ; local ans3=
    if [[ $1 ]] ; then name=$1 ; shift ; fi

    local playlist="$yle_playlist_folder/$name"

    case $name in
        list) ls ${playlist%/*} ; return 0 ;;
        rm) rm "${playlist%/*}/$1" ; return 0  ;;
        add|edit) $GURU_PREFERRED_EDITOR "${playlist%/*}/$1" ; return 0 ;;
        mv|rename) mv ${playlist%/*}/$1 ${playlist%/*}/$2 ; return 0;;
        show|view) cat ${playlist%/*}/$1 ; return 0;;
    esac

    [[ $1 ]] && line=$(($1 - 1 ))

    # create folder and files
    [[ -d ${playlist%/*} ]] || mkdir -p ${playlist%/*}
    [[ $playlist ]] || touch $playlist

    while true ; do

        # check condition of playlist file
        if ! [[ $(head -n1 $playlist) ]] ; then
            $GURU_PREFERRED_EDITOR $playlist
            gr.msg -c yellow "playlist file empty, please add link to https://areena.yle.fi content"
            gr.ask "ready to continue" || break
            line=0
        fi

        # check is file emty
        [[ $(head -n1 $playlist) ]] || break

        # add enpty line to playlist file
        [[ -s "$playlist" && -z "$(tail -c 1 "$playlist")" ]] || echo >>$playlist

        # clean up
        sed -i '/^[ \t]*$/d' $playlist

        # set variables
        lines=$(wc -l $playlist | cut -d' ' -f1)
        line=$(( line + 1 ))

        # limits
        [[ $line -gt $lines ]] && line=1
        [[ $line -lt 1 ]] && line=$lines

        # playing
        gr.msg -h -v1 "playing playlist item $line/$lines"
        gr.msg -c white -v2 "press 'qq' to quit, 'q' for next, 'qp' for previous, 'q + <number>' to play item or 'qe' to edit playlist"
        item=$(sed "${line}q;d" $playlist)

        if grep "https://areena.yle.fi" <<<$item ; then
            yle.main play $item
        else
            gr.msg -v2 -c yellow "'$item' is not an yle.fi link, skipping"
            continue
        fi

        # user control
        read -n1 -t1 ans1
        read -n1 -t1 ans2
        read -n1 -t1 ans3
        echo

        case $ans1 in
            q|Q) break ;;
            e|E) $GURU_PREFERRED_EDITOR $playlist & ;;
            p|P) line=$(( line - 2 )) ; [[ $ans2 == "p" ]] && line=$(( line - 1 )) ; continue ;;
            [0-9]*) line="$ans1$ans2$ans3" ; line=$(( line - 1 )) ;;
        esac

    done

    gr.msg -v2 "guru say bye bye"
}


# block_rev () {
#     # trick to reverse array without reversing strings
#     array=($@)

#     f() { array=("${BASH_ARGV[@]}"); }

#     shopt -s extdebug
#     f "${array[@]}"
#     shopt -u extdebug

#     echo "${array[@]}"
# }


# yle.place () {

#     find_files () {
#         for entry in $@ ; do
#               [[ -f $entry ]] && echo $entry
#             done
#     }

#     split_filename () {
#         local filename=$1
#         local pos=0
#         local episode=
#         local name=

#         sepa='-'

#         for type in ${left[@]} ; do

#             (( pos++ ))

#             case $type in
#                 name)
#                         name="$name$(echo $filename | cut -f $pos -d $sepa) "
#                         ;;
#                 episode)
#                         word="$(echo $filename | cut -f $pos -d $sepa) "

#                         if grep -ve 's0' -ve 'e0' <<<$word ; then
#                             episode="$episode$word"
#                         else
#                             code=$word
#                             break
#                         fi

#                         ;;
#                     esac
#             done

#         pos=0
#         for type in ${right[@]} ; do

#                 (( pos++ ))

#                 case $type in
#                     ending)
#                             sepa='.'
#                             ending="$(echo $filename | cut -f 1 -d $sepa)"
#                             ;;
#                     time)
#                             sepa='t'
#                             time="$(echo $filename | cut -f $pos -d $sepa)"
#                             ;;
#                     day)
#                             day="$(echo $filename | cut -f $pos -d $sepa)"
#                             ;;
#                     month)  month="$(echo $filename | cut -f $pos -d $sepa)"
#                             ;;
#                     year)   year="$(echo $filename | cut -f $pos -d $sepa)"
#                             ;;
#                         esac
#                 done

#         gr.msg "name: $name"
#         gr.msg "episode: $episode"
#         gr.msg "ending: $ending"
#         gr.msg "day: $day"
#         gr.msg "month: $month"
#         gr.msg "time: $time"

#         }

#     files=($(find_files '*mp4 *mkv'))
#     gr.msg -v3 -c light_blue "files: ${files[@]}"

#     sepa='-'
#     left=(name name name name name episode episode episode episode episode episode episode)


#     #right_rev=(ending time day month year code)
#     right=(code year month day time ending)

#     # gr.msg "order: ${left[@]} $(block_rev ${right_rev[@]})"
#     gr.msg "order: ${left[@]} ${right[@]}"

#     for file in ${files[@]} ; do
#         split_filename $file

#         done

# }


yle.arguments () {
# module argument parser

    local got_args=($@)

    for (( i = 0; i < ${#got_args[@]}; i++ )); do
        # gr.debug "${FUNCNAME[0]}: argument: $i:${got_args[$i]}"

        case ${got_args[$i]} in

            --play)
                export yle_do_play=true
                ;;
            *)
                export module_command+=("${got_args[$i]}")
                ;;
        esac
    done
}



yle.sort () {

    if [[ $yle_do_play ]] ; then
        yle.make_playlist $@ | mpv --playlist=-
    else
        yle.make_playlist $@
    fi
}


yle.make_playlist () {
# process list of files given in file ardered by given way
# do this to folder before: shopt -s globstar ; rename 's/_/-/g' * ; rename 's/ /-/g' *

    local items_to_sort=$1

    # if input contains
    if [[ -d $items_to_sort ]] ; then
        folder="$(realpath -s ${items_to_sort})/"
        shift
        items_to_sort=$1
    fi

    items=$(ls $folder*$items_to_sort*)
    [[ $items ]] || return 1

    while read line; do
        date_stamp=$(echo $line | rev | cut -d'.' -f 2- | cut -d '-' -f-4 | rev)
        echo "$(date -d ${date_stamp//-/} +%-s) $line"
    done <<<$items | sort | cut -d' ' -f2-
}


yle.get_metadata () {

    local error=
    local meta_data="$yle_temp_folder/meta.json"
    local yle_media_title="no media"

    # make temp if not exist already
    [[ -d "$yle_temp_folder" ]] || mkdir -p "$yle_temp_folder"
    cd "$yle_temp_folder"

    #local $GURU_YLE_BASE_URL="https://areena.yle.fi/"
    # do not add base url if it already given
    if echo $1 | grep "http" ; then
            media_url=$1
        fi

    media_url="${GURU_YLE_BASE_URL%/}$1"

    gr.msg -v3 -c deep_pink "media_url: $media_url"

    # Check if id contain yle_episodes, then select first one (newest)
    yle_episodes=($(yle-dl --showepisodepage $media_url | grep -v $media_url))
    # episode_ids=($(yle-dl $media_url --showmetadata | jq '.[].program_id'))
    gr.msg -v3 -c light_blue "yle_episodes: ${yle_episodes[@]}"

    # change media address poin to first episode
    [[ ${yle_episodes[0]} ]] && media_url=${yle_episodes[0]}

    # Get metadata
    yle-dl $media_url --showmetadata > $meta_data

    grep "error" $meta_data && error=$(cat $meta_data | jq '.[].flavors[].error')

    if [[ $error ]] ; then
            echo "$error"
            return 100
        fi

    # set variables (like they be local anyway)
    yle_media_title="$(cat "$meta_data" | jq '.[].title')"
    gr.msg -v2 "${yle_media_title//'"'/""}"

    yle_media_address="$media_url "
    #$(cat "$meta_data" | jq '.[].webpage')
    #yle_media_address=${yle_media_address//'"'/""}
    yle_media_filename=$(cat "$meta_data" | jq '.[].filename')
}


yle.get_media () {
    # get media from server and place it to /$USER/tmp


    # detox filename
    output_filename=${yle_media_filename//. /-}
    output_filename=${output_filename//.: /-}
    output_filename=${output_filename//: /-}
    output_filename=${output_filename// /-}
    output_filename=${output_filename//-_-/-}
    output_filename=${output_filename//--/-}
    output_filename=${output_filename//'"'/}
    output_filename=${output_filename,,}

    gr.msg -v3 -c deep_pink "output filename: $output_filename"

    # check is tmp file alredy there
    if [[ -f $output_filename ]] ; then
            gr.msg -c yellow "file exist, overwriting "
            rm $output_filename
        fi

    # download stuff
    yle-dl "$media_url" -o "$output_filename" --sublang all

    # to check did yle-dl change format
    local got_filename=$(echo ${output_filename%.*}*)

    if [[ -f $got_filename ]] ; then
            # got valid filename, update global variables
            yle_media_filename=$got_filename
            return 0
        else
            # update global variables
            yle_media_filename=$output_filename
            return 0
        fi

    return 127
}


yle.get_subtitles () {


    [ -d "$yle_temp_folder" ] && rm -rf "$yle_temp_folder"
    mkdir -p "$yle_temp_folder"
    cd "$yle_temp_folder"
    yle-dl "$media_url" --subtitlesonly #2>/dev/null
    #yle_media_filename=$(detox -v * | grep -v "Scanning")
    #yle_media_filename=${yle_media_filename#*"-> "}
}


yle.radio_listen () {

    case $1 in
        ls|list)
            local possible=('puhe' 'radio1' 'kajaani' 'klassinen' 'x' 'x3 m' 'vega' 'kemi' 'turku' \
                            'pohjanmaa' 'kokkola' 'pori' 'kuopio' 'mikkeli' 'oulu' 'lahti' 'kotka' 'rovaniemi' \
                            'hameenlinna' 'tampere' 'vega aboland' 'vega osterbotten' 'vega ostnyland' 'vega vastnyland' 'sami')
            gr.msg -c light_blue ${possible[@]}
            return 0
            ;;
        esac

    local channel="yle $@"
    local options=
    [[ $GURU_VERBOSE -lt 1 ]] && options="--really-quiet"
    channel=$(echo $channel | sed -r 's/(^| )([a-z])/\U\2/g' )
    local url="https://icecast.live.yle.fi/radio/$channel/icecast.audio"
    mpv $options $url
}


yle.place_media () {

    #location="$@"

    media_file_format="${yle_media_filename: -5}"
    media_file_format="${media_file_format#*.}"
    #media_file_format="${media_file_format^^}"
    gr.msg -c deep_pink "media_file_format: $media_file_format, yle_media_filename $yle_media_filename"

    if ! [[ -f $yle_media_filename ]] ; then
            gr.msg -c yellow "file $yle_media_filename not found"
            return 124
        fi

    #$GURU_CALL tag "$yle_media_filename" "yle $(date +$GURU_FILE_DATE_FORMAT) $yle_media_title $media_url"

    source mount.sh
    case "$media_file_format" in

        mp3|wav)
            mount.main audio
            location="$GURU_MOUNT_AUDIO" ;;


        mkv|mp4|src|sub|avi)
            mount.main video
            location="$GURU_MOUNT_TV" ;;
        *)
            mount.main downloads
            location="$GURU_MOUNT_DOWNLOADS" ;;
    esac

    # input overwrites basic shit
    if [[ "$1" ]] ; then
            location="$1"
            shift
        fi

    [[ -d $location ]] || mkdir -p $location

    # moving to default location
    gr.msg -c white "saving to: $location/$yle_media_filename"
    mv -f $yle_media_filename $location

}


yle.play_media () {
    mpv --play-and-exit "$1" &
}


yle.upgrade() {
    # pip3 install --user --upgrade yle-dl
    python3 -m pip install --user --upgrade pipx
}


yle.install() {

    # # Ubuntu 23.04 or above
    # sudo apt update
    # sudo apt install pipx
    # pipx ensurepath

    # Ubuntu 22.04 or below
    python3 -m pip install --user pipx
    python3 -m pipx ensurepath
    pipx install yle-dl --force

    # pip3 install --upgrade pip
    # [[ -f /home/casa/.local/bin/yle-dl ]] || pip3 install --user --upgrade yle-dl
    ffmpeg -h >/dev/null 2>/dev/null || sudo apt install ffmpeg -y
    jq --version >/dev/null || sudo apt install jq -y
    sudo apt install detox mpv
    echo "Successfully installed"
}


yle.uninstall(){

    sudo -H pip3 uninstall --user yle-dl
    sudo apt remove ffmpeg jq  -y
    echo "uninstalled"
}


yle.rc () {
# source configurations (to be faster)

    if [[ ! -f $yle_rc ]] \
        || [[ $(( $(stat -c %Y $GURU_CFG/$GURU_USER/yle.cfg) - $(stat -c %Y $yle_rc) )) -gt 0 ]] \
        || [[ $(( $(stat -c %Y $GURU_CFG/$GURU_USER/audio.cfg) - $(stat -c %Y $yle_rc) )) -gt 0 ]]
        then
            yle.make_rc && \
                gr.msg -v1 -c dark_gray "$yle_rc updated"
        fi

    source $yle_rc
}


yle.make_rc () {
# configure yle module

    source config.sh

    # make rc out of config file and run it
    if [[ -f $yle_rc ]] ; then
            rm -f $yle_rc
        fi

    config.make_rc "$GURU_CFG/$GURU_USER/audio.cfg" $yle_rc
    config.make_rc "$GURU_CFG/$GURU_USER/yle.cfg" $yle_rc append
    chmod +x $yle_rc
    source $yle_rc
}

yle.rc

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # source "$GURU_RC"
    yle.main "$@"
fi
# local $GURU_YLE_BASE_URL

# same but for youtube

# video.build () {

#     data_location="/home/casa/karsulle"
#     data_file="karsulle_katsottavaa.cfg"
#     url_base="https://www.youtube.com/watch?v"

#     [[ -d $data_location ]] || mkdir -p $data_location
#     [[ -f $data_file ]] || gr.msg -x 100 -c yellow "data tiedosto $data_file puuttuu"

#     ids=$(cut -d " " -f 1 $data_file)
#     headers=$(cut -d " " -f 2- $data_file)

#     lines=$(cat $data_file)
#     youtube-dl --version || video.install

#     for id in ${ids[@]} ; do
#         gr.msg -c white "downloading $url_base=$id to $data_location.. "
#         youtube-dl --ignore-errors --continue --no-overwrites \
#                --output "$data_location/%(title)s.%(ext)s" \
#                "$url_base=$id"
#     done


# }


# video.install () {
#     sudo apt update || gr.msg -x 101 -c yellow "apt update failed"
#     sudo apt install youtube-dl ffmpeg
# }



# video.build