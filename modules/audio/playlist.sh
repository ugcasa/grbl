

playlist.main () {
# play playlist file

    local user_input=$1
    #local audio_last_played_pointer="/tmp/guru-cli_audio.last"
    #local item_search_string=
    #[[ $2 ]] && item_search_string=$2

    case $user_input in

        continue|last)
            playlist.play /tmp/guru-cli_audio.playlist
            ;;

        list|ls)
            shift
            gr.msg -c pink "in-the-list"
            if [[ $1 ]] ; then
                # if playlist name is given, list all found files
                    playlist.compose $1
                    cat $audio_temp_file
                else
                # print list of playlists set in audio.cfg
                    playlist.list
                fi
            ;;

        "") # printout list of playlists
            gr.msg "please give playlist name from following list"
            playlist.list
            ;;

        *)
            playlist.play $@

        esac

    return 0
}


playlist.play () {
# play playlist or search pattern in the list
    local user_input=$1
    local item_search_string=
    local list_to_play=
    local audio_last_played_pointer="/tmp/guru-cli_audio.last"
    [[ $2 ]] && item_search_string=$2

    gr.debug "$audio_playlist_folder/$user_input.list"

    # check is input a filename and is file ascii
    if [[ -f $user_input ]] && file $user_input | grep -q "text" ; then

        # check that first item exists
        local first_item=$(head -n 1 $user_input)
        if ! [[ -f $first_item ]] ; then
                gr.msg -c yellow "playlist item '$first_item' does not exist"
                return 125
            fi

        list_to_play="--playlist=$user_input"

    # check is there saved playlists on that name
    elif [[ -f "$audio_playlist_folder/$user_input.list" ]] && file "$audio_playlist_folder/$user_input.list" | grep -q "text" ; then

        list_to_play="--playlist=$audio_playlist_folder/$user_input.list"

    # assume that audio.cfg contains list named by user input
    else
        playlist.compose $user_input || return 123

        list_to_play="--playlist=$audio_temp_file"

        # play requested item in the list
        if [[ $item_search_string ]] ; then
                gr.debug "wanted hear item '$item_search_string'"
                local _list=($(cat $audio_temp_file))

                for _list_item in ${_list[@]} ; do
                        if grep -i $item_search_string <<< $_list_item ; then
                                list_to_play="$_list_item"
                                item_name=$_list_item
                                break
                            fi
                    done
            fi

    fi

    # indicate user (now playing data is from mpv stat server)
    corsair.indicate playing $GURU_AUDIO_INDICATOR_KEY

    # stop current audio
    [[ $audio_playing_pid ]] && kill $audio_playing_pid

    # play the playlist
    mpv $list_to_play $mpv_options --save-position-on-quit

    # stop play indication
    gr.end $GURU_AUDIO_INDICATOR_KEY

    return 0
}



### playlist stuff TBD >audio/playlist.sh ------------------------------------------------------------------------


playlist.config () {
# compare user input to configuration and set up

    local user_input=$1
    # check does configuration contain line named by user request
    local found_line=$(grep "GURU_PLAYLIST_${user_input^^}=" $audio_rc)

    found_line="${found_line//'export '/''}"

    if ! [[ $found_line ]] ; then
            gr.msg -c yellow "list '$user_input' not found"
            return 126
        fi

    declare -g playlist_found_name=$(echo $found_line | cut -f3 -d '_' | cut -f1 -d '=')

    local variable="GURU_PLAYLIST_${playlist_found_name}"
    local found_settings=($(eval echo ${!variable}))

    declare -g playlist_location=${found_settings[0]}
    declare -g playlist_phase=${found_settings[1]}
    declare -g playlist_option=${found_settings[2]}

    declare -g list_description="${playlist_location##*/}"
    list_description="${list_description//_/' '}"
    list_description="${list_description//'-'/' - '}"

    gr.debug "playlist_found_name: $playlist_found_name"
    gr.debug "found_line: $found_line"
    gr.debug "found_settings: ${found_settings[@]}"
    gr.debug "playlist_location: $playlist_location"
    gr.debug "playlist_phase: $playlist_phase"
    gr.debug "playlist_option: $playlist_option"
    gr.debug "description: $list_description"

    if ! [[ $playlist_found_name ]] ; then
            gr.msg -c yellow "playlist '$user_input' not found"
            return 127
        fi

    return 0
}


playlist.compose () {
# compose template playlist from given information

    local user_input=$1
    playlist.config $user_input

    local sort_option=
    [[ $playlist_option ]] && sort_option="-$playlist_option"

    if [[ "$playlist_found_name" == "${user_input^^}" ]] ; then

            # fixed issue where audio_temp_file medialist did not include media folder
            find $playlist_location/$playlist_phase -type f \
                | grep -e wav -e mp3 -e m4a -e mkv -e mp4 -e avi \
                | sort $sort_option > $audio_temp_file

            local test=$(cat $audio_temp_file)

            if [[ $test ]] ; then
                    gr.msg -v2 "$(cat $audio_temp_file)"
                    return 0
                else
                    gr.msg -c yellow "got empty playlist"
                    gr.msg "try to 'gr mount audio', 'audiobooks' or 'video'"
                    return 123
                fi
        else
            gr.msg -c yellow "list name '$user_input' not found"
            return 124
        fi
}


playlist.list () {
# list of playlists

    local _list=($(cat $audio_rc | grep "GURU_PLAYLIST_" | grep -v "local" | cut -f3 -d '_' | cut -f1 -d '='))
    _list=(${_list[@],,})

    # if verbose is lover than 1
    gr.msg -V2 -c light_blue "${_list[@]}"

    # higher verbose
    if [[ $GURU_VERBOSE -gt 1 ]] ; then

            for _list_item in ${_list[@]} ; do
                    playlist.config $_list_item
                    gr.msg -n -c light_blue "$_list_item: "
                    gr.msg "$list_description"
                done
         fi

    return 0
}

