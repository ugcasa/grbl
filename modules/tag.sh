#!/bin/bash
# Mick Tagger - ujo.guru 2019

# TBD code review for this module.. shit load of elementary stupidity

tag.main () {
    # get arguments

    tag_action="$1" ; shift
    tag_file_name="$1" ; shift

    # parse file format
    tag_file_format="${tag_file_name: -5}"      #read last characters of filename
    tag_file_format="${tag_file_format#*.}"     #read after separator
    tag_file_format="${tag_file_format^^}"      #upcase

    gr.debug "tag_action: '$tag_action', \
              tag_file_name: '$tag_file_name' \
              tag_file_format: $tag_file_format, \
              string: '$@'"

    case $tag_action in
        install|status)
              tag.$tag_action $@
              return $?
              ;;
          esac

    case "$tag_file_format" in                                           ### # #
    3G2|3GP2|3GP|3GPP|AAX|AI|AIT|ARQ|ARW|CR2|CR3|CRM|CRW|CIFF|PBM|GIF|GPR|\
    CS1|DCP|DNG|DR4|DVB|EPS|EPSF|PS|ERF|EXIF|EXV|F4A|F4B|F4P|F4V|FFF|FLIF|\
           HDP|WDP|JXR|HEIC|HEIF|ICC|ICM|IIQ|IND|RWL|SR2|SRW|THM|JNG|MNG|PPM|\
                    INDD|INDT|JP2|JPF|JPM|JPX|JPEG|JPG|JPE|LRV|M4A|M4B|M4P|M4V|\
                     MEF|MIE|MOS|MOV|QT|MPO|MQV|MRW|NEF|NRW|ORF|PDF|PEF|PNG|\
                                    PGM|PSD|PSB|PSDT|QTIF|QTI|QIF|RAF|RAW|RW2|\
                                    TIFF|TIF|VRD|X3F|XMP) tag.picture $tag_action $@   ;;
                                                     MP3) tag.audio $tag_action $@     ;;
                                                     MP4) tag.mp4 $tag_action $@       ;;
                                              MD|TXT|MDD) tag.text $@      ;;
                                                       *) echo "unknown format"
                                                            return 123          #####
    esac                                                           ###################
    }                                                               ####################
                                                                     ####################
                                                                      #################
                                                                       ##############  #
                                                                        ##########  ##

tag.help () {
    echo "usage:    $GURU_CALL tag [add|rm|get] <file>"
}


tag.text () {
    # If file has more than two lines it's taggable
    local temp_file=/tmp/$USER/tag_temp

    _get_tags () {
        current_tags=$(sed -n '2p' $tag_file_name)
        current_tags=${current_tags##*": "}
    }

    _add_tags () {
        _new_tags=$@
        _get_tags

        gr.debug "current_tags. '$current_tags', \
                  temp_file, '$temp_file', \
                  tag_file_name: '$tag_file_name', \
                  temp_file: '$temp_file'"

        if [[ "$current_tags" ]] ; then
            sed '2d' $tag_file_name > $temp_file \
                && mv -f $temp_file $tag_file_name
        else
            current_tags="text ${tag_file_format,,} $GURU_USER $GURU_TEAM"
        fi

        sed "2i\\tag: $current_tags ${_new_tags[@]}" "$tag_file_name" > "$temp_file" \
            && mv -f "$temp_file" "$tag_file_name"

    }

    _rm_tags () {

        _get_tags

        if [[ "$current_tags" ]]; then
            sed '2d' $tag_file_name >$temp_file && mv -f temp_file.txt $tag_file_name
        fi
    }

    gr.debug "$FUNCNAME: got: '$@'"

    case "$tag_action" in

        ls|"")
            _get_tags
            [[ "$current_tags" ]] && echo $current_tags
            ;;
        add)
            _add_tags $@
            ;;
        rm)
            _rm_tags $1
            ;;
        *)
            _add_tags $@
            ;;
        esac
}


tag.audio () {
    # Audio tagging tools
    tag_container="TIT3"            # Comment better? is shown by default in various programs

    _get_tags () {
        current_tags=$(mid3v2 -l $tag_file_name |grep $tag_container)
        current_tags=${current_tags##*=}
        return 0
    }

    _add_tags () {                                                                                      #; echo "current_tags:$current_tags|"; echo "new tags:$@|"
        _get_tags
        [[ $current_tags == "" ]] && current_tags="audio ${tag_file_format,,} $GURU_USER $GURU_TEAM"
        mid3v2 --$tag_container "${current_tags// /,},${@// /,}" "$tag_file_name"                   # use "," as separator to use multible tags
    }

    _rm_tags () {
        mid3v2 --delete-frames="$tag_container" "$tag_file_name"
    }

    case "$tag_action" in

        ls|"")
            _get_tags
            [ "$current_tags" ] && echo "${current_tags//,/ }"
            ;;
        add)
            [[ "$@" ]] && _add_tags "$@"
            ;;
        rm)
            _rm_tags
            ;;
        *)
            [[ "$@" ]] && string="$tag_action $@" || string="$tag_action"
            [[ "$tag_action" ]] && _add_tags "$string"
            ;;
        esac

        return 0            # Otherwice returns 1
}


tag.mp4 () {
    # Video tagging tools
    local tag_action=$1
    shift
    local tag_container="--comment"
    local current_tags=

    get () {
        current_tags=$(AtomicParsley $tag_file_name -t | grep cmt)
        [[ $current_tags ]] && echo "${current_tags##*": "}"
        return 0
    }

    add () {
        new_tags=$@
        current_tags=$(get)
        [[ $current_tags ]] || current_tags="video ${tag_file_format,,} $GURU_USER"
        AtomicParsley "$tag_file_name" "$tag_container" "$current_tags $new_tags" --overWrite  >/dev/null
    }

    rm () {
        AtomicParsley "$tag_file_name" "$tag_container" "" --overWrite  >/dev/null
    }

    case "$tag_action" in
            get|add|rm) $tag_action $@  ;;
            *) get $@
        esac
        return 0
}


tag.picture () {
    # Picture tagging tools
        tag_container="Comment"                 # the title under which the information is stored in the image

    _get_tags () {
        current_tags=$(exiftool -quiet -$tag_container "$tag_file_name")
        current_tags=${current_tags##*": "}
    }

    _add_tags () {
        _get_tags
        [[ "$current_tags" == "" ]] && current_tags="picture ${tag_file_format,,} $GURU_USER $GURU_TEAM"
        exiftool -quiet -$tag_container="$current_tags $@" "$tag_file_name" -overwrite_original_in_place -q
    }

    _rm_tags () {
        exiftool -quiet -$tag_container= "$tag_file_name" -overwrite_original_in_place -q
    }


    case "$tag_action" in

        ls|"")
            _get_tags
            [ "$current_tags" ] && echo "$current_tags"
            ;;
        add)
            [[ "$@" ]] && _add_tags "$@"
            ;;
        rm)
            _rm_tags
            ;;
        *)
            [[ "$@" ]] && string="$tag_action $@" || string="$tag_action"
            [[ "$tag_action" ]] && _add_tags "$string"
            ;;
        esac
}

tag.status () {
    gr.msg -n -v1 -t "${FUNCNAME[0]}: "
    gr.msg -c gray "no status information"
    return 0
}

tag.install () {
# install neede software
    sudo apt install libimage-exiftool-perl atomicparsley python3-mutagen
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then                # run if called or act like lib is included
    tag.main "$@"
    return $?
fi

