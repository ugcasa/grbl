#!/bin/bash 
# convert file to another formats. Wrap around for good known stand stone: pandoc, imagemagic, dwebp, ffmpeg ..
# guru preferred archive formats TBD config what to want from user.cfg
# for now hard written as following:
#  all images -> png
#  all video  -> mp4
#  all photos -> jpg

#source common.sh
convert_indicator_key=f7
[[ $GURU_CONVERT_INDICATOR ]] && convert_indicator_key=$GURU_CONVERT_INDICATOR

convert.main () {
    # convert format parser
    # TBD: analysis: from - to periaate oletuksilla?
    #   input filun formaatti kun on tiedossa niin output kiinnostelee
    #   gr convert dokuwiki, oletus = to_dokuwiki = ok
    #   gr convert markdown, oletus = to_markdown oli input ketä vaan jos from ja to löytyy = ok
    #   kerii listan jos ei inputtia määritelty
    # new shit: nielee myös option '--i as input_file' ja '--f as format' jos filun nimestä ei selkene (TBD core.sh second level options: upvote!)

    local format=$1
    shift

    case $format in

        install|remove|compile|check)
            convert.$format
            return $?
            ;;

        webp|webm|mkv|a|avif)
            convert.check_format $format || return 100
            convert.from_$format $@
            return $?
            ;;

        dokuwiki|png)
            convert.to_$format $@
            return $?
            ;;

        help|poll|status)
            convert.$format $@
            return $?
            ;;
        *)  gr.msg -c yellow "unknown format $format"

    esac
    return 0
}


convert.help () {
# general help

    gr.msg -v1 -c white "guru convert help "
    gr.msg -v2
    gr.msg -v0 "usage:    $GURU_CALL convert <dest_format> file list"
    gr.msg -v2
    gr.msg -v1 " install       install imagemagic and other needed tools from api ropository "
    gr.msg -v1 " remove        remove os distributor version of imagemagic (may be very old) "
    gr.msg -v1 " compile       remove current imagemagic installation, then download and compile from github "
    gr.msg -v1 " <format>      specify from format and all pictures are converted to $GURU_FORMAT_PICTURE"
    gr.msg -v1 "               specify from format and all videos are converted to $GURU_FORMAT_VIDEO"
    gr.msg -v1 "               supported formats: webp webm mkv avif"
    gr.msg -v1 " <target>      specify target format to convert to it (experimental)"
    gr.msg -v1 "               supported formats: dokuwiki png"
    gr.msg -v2
    gr.msg -v1 -c white "example:"
    gr.msg -v1 "      $GURU_CALL convert webp         # converts all webp in folder to $GURU_FORMAT_PICTURE "
    gr.msg -v1 "      $GURU_CALL convert dokuwiki     # converts specified markdown files to dokuwiki format "
    gr.msg -v2
    gr.msg -v1 "avif support is still issue 2018 to 2023 >:/ https://github.com/ImageMagick/ImageMagick/issues/1432"
    return 0
}


## convert from methods. Always convert to png

# TBD issue #59 make one convert.format <format> all there three are almost identical

convert.from_webp () {
# convert all webp in folder to png format

    if [[ $1 ]] ; then
        find_files=($@)
    else
        detox *webp 2>/dev/null
        find_files=$(echo *webp | grep -v '*')
    fi

    if ! [[ $find_files ]] ; then
        gr.msg -v1 -c white "no files found"
        return 1
    fi

    local rand=""
    local dest_format=$GURU_FORMAT_PICTURE
    #[[ $2 ]] && dest_format=$2

    for file in ${find_files[@]} ; do

        local rand=

        # remove file ending
        local file_base_name=$(sed 's/\.[^.]*$//' <<< "$file")
        gr.msg -v3 -c pink "file_base_name: $file_base_name"

        # check do original exist
        if ! [[ -f "$file_base_name.webp" ]] ; then
            gr.msg -v1 -c yellow "file $file_base_name.webp not found"
            continue
        fi

        # there is a file with same name
        if [[ -f "$file_base_name.${dest_format}" ]] ; then
            gr.msg -v1 -n "$file_base_name.${dest_format} exists, "

            # convert webp to temp
            dwebp -quiet "$file_base_name.webp" -o "/tmp/$file_base_name.${dest_format}"

            # check file size
            local orig_size=$(wc -c "$file_base_name.${dest_format}" | awk '{print $1}')
            local new_size=$(wc -c "/tmp/$file_base_name.${dest_format}" | awk '{print $1}')

            if [[ $orig_size -eq $new_size ]] ; then

                # check does pictures have same content
                local orig=$(identify -quiet -format "%#" "$file_base_name.${dest_format}" )
                local new=$(identify -quiet -format "%#" "/tmp/$file_base_name.${dest_format}")

                # check file contains same data, rename if not
                if [[ "$orig" == "$new" ]] ; then
                    gr.msg -v2 -n "identical content "
                # skip
                    if ! [[ $GURU_FORCE ]] ; then
                        gr.msg -v1 -c dark_grey "skipping "
                        continue
                    fi
                # overwrite
                    gr.msg -n -v2 -c yellow "overwriting "
                    rm -f "$file_base_name.${dest_format}"
                else
                # append
                    gr.msg -n -v1 -c light_blue "appending "
                    rand="-$(shuf -i 1000-9999 -n 1)"
                fi
            fi
        fi


        # convert
        gr.msg -v1 -n "$file_base_name$rand.${dest_format}.. "

        if [[ -f "/tmp/$file_base_name.${dest_format}" ]] ; then
            mv "/tmp/$file_base_name.${dest_format}" "$file_base_name$rand.${dest_format}" \
                && gr.msg -v1 -c green "ok" \
                || gr.msg -c yellow "move failed $?"
        else
            dwebp -quiet "$file_base_name.webp" -o "$file_base_name$rand.${dest_format}"\
                && gr.msg -v1 -c green "ok" \
                || gr.msg -c yellow "convert failed $?"
        fi

        # force remove original if convert success
        [[ $GURU_FORCE ]] && [[ -f "$file_base_name$rand.${dest_format}" ]] && rm "$file_base_name.webp"

        # clean up
        [[ -f "/tmp/$file_base_name.${dest_format}" ]] && rm "/tmp/$file_base_name.${dest_format}"

    done
    return 0
}


convert.from_webm () {

    local convert_indicator_key="f$(gr.poll convert)"

    if [[ $1 ]] ; then
        find_files=($@)
    else
        detox *webm 2>/dev/null
        find_files=$(echo *webm | grep -v '*')
    fi

    if ! [[ $find_files ]] ; then
        gr.msg -c white "no files found"
    fi

    local rand=""
    local dest_format=$GURU_FORMAT_VIDEO
    #[[ $2 ]] && dest_format=$2

    for file in ${find_files[@]} ; do

        rand=""
        file_base_name=${file%%.*}

        gr.msg -v3 -c aqua "$file_base_name" -k $convert_indicator_key

        # check do original exist
        if ! [[ -f "$file" ]] ; then
            gr.msg -c yellow "file $file not found"
            continue
        fi

        # convert
        gr.msg -n -c light_blue "$file_base_name$rand.${dest_format}.. "

        # there is a file with same name
        if [[ -f "$file_base_name.${dest_format}" ]] ; then
            gr.msg -n "overwriting.. "
        fi

        if ffmpeg -y -hide_banner -loglevel error -i "$file" "$file_base_name$rand.${dest_format}" ; then
            gr.msg -c green "ok" -k $convert_indicator_key
        else
            gr.msg -c red "failed: $?" -k $convert_indicator_key
        fi

        # force remove original if convert success
        [[ $GURU_FORCE ]] && [[ -f $file_base_name$rand.${dest_format} ]] && rm $file_base_name.webm

    done
    return 0
}


convert.from_mkv () {

    local convert_indicator_key="f$(gr.poll convert)"

    if [[ $1 ]] ; then
        find_files=($@)
    else
        eval 'detox *mkv'
        find_files=$(eval 'ls *mkv')
    fi

    if ! [[ $find_files ]] ; then
        gr.msg -c white "no files found"
    fi

    local rand=""
    local dest_format=$GURU_FORMAT_VIDEO
    #[[ $2 ]] && dest_format=$2

    for file in ${find_files[@]} ; do

        rand=""
        file_base_name=${file%%.*}

        gr.msg -v3 -c aqua "$file_base_name" -k $convert_indicator_key

        # check do original exist
        if ! [[ -f "$file" ]] ; then
            gr.msg -c yellow "file $file not found"
            continue
        fi

        # convert
        gr.msg -n -c light_blue "$file_base_name$rand.${dest_format}.. "

        # there is a file with same name
        if [[ -f "$file_base_name.${dest_format}" ]] ; then
            gr.msg -n "file exists "
        fi

        if ffmpeg -y -hide_banner -loglevel error -i "$file" "$file_base_name$rand.${dest_format}" ; then
            gr.msg -c green "ok" -k $convert_indicator_key
        else
            gr.msg -c red "failed: $?" -k $convert_indicator_key
        fi

        # force remove original if convert success
        [[ $GURU_FORCE ]] && [[ -f $file_base_name$rand.${dest_format} ]] && rm $file_base_name.mkv

    done
    return 0
}


## convert to methods

convert.to_dokuwiki () {

    local convert_indicator_key="f$(gr.poll convert)"
    # input list of files to export, expects that input is "note ans pushes it to wiki/notes tbd fix next

    if ! md2doku -h >/dev/null; then
        sudo apt update
        [[ $GURU_GIT_TRIALS ]] || GURU_GIT_TRIALS="$HOME/git"
        cd $GURU_GIT_TRIALS
        git clone https://github.com/mostekcm/markdown-to-dokuwiki.git
        cd markdown-to-dokuwiki
        npm --version || sudo apt install npm -y
        npm install -g
    fi

    if [[ $1 ]] ; then
        find_files=($@)
    else
        # eval 'detox *md'
        # lähdetään siitä että note moduli tuottaa filunimet oikein.
        find_files=($(eval 'ls *md'))
        # vähän jykevä metodi, miksei filelistan nyt saisi helpommallakin?
    fi

    if ! [[ $find_files ]] ; then
        gr.msg -c white "no files found"
    fi

    # local rand=""
    local dest_format="txt"
    local files_done=()

    for file in ${find_files[@]} ; do

        # rand=""
        file_base_name=${file%%.*}

        gr.msg -v3 -c aqua "$file_base_name" -k $convert_indicator_key

        # check do original exist
        if ! [[ -f "$file" ]] ; then
            gr.msg -c yellow "file $file not found"
            continue
        fi

        gr.msg -n -v2 -c light_blue "$file "

        ## Fun block to write, magic room
        # TBD flag or ghost to check is content modified in web interface
        # TBD version file if upper situation, yes, shit way it is but easy and better then data loses

        # check there is a file with same name and rand four digits blog to new file name
        # if [[ -f "$file_base_name.${dest_format}" ]] ; then
        #         rand="$(date +%s%N | cut -b10-13)"
        #         gr.msg -v2 -n "to $file_base_name.${dest_format} "
        #     fi

        # TBD create a temp file to ram that han cen modified (see new features)
        # TBD remove all headers content with dot as first letter
        # TBD remove all lines that start with dot

        if pandoc -s -r markdown -t dokuwiki $file > $file_base_name.${dest_format} ; then
            gr.msg -v2 -c green "converted" -k $convert_indicator_key

            if grep "tag: " $file -q ; then
                tag="{{tag>$(grep 'tag: ' $file | cut -d ' ' -f2-)}}"
                echo -e "\n$tag\n" >>$file_base_name.${dest_format}
            fi

            files_done=(${files_done[@]} "$file_base_name.${dest_format}")

        else
            gr.msg -c red "failed: $?" -k $convert_indicator_key
        fi

    done

        ## publish prototype hardcoded for notes tbd create publish.sh module

    if ! [[ ${files_done[0]} ]] ; then
        gr.msg -c reset "nothing to do" -k $convert_indicator_key
        return 0
    fi

    # force remove original if convert success
    # [[ $GURU_FORCE ]] && [[ $file_base_name$rand.${dest_format} ]] && rm $file_base_name.mkv
    if ! [[ -d $GURU_MOUNT_WIKIPAGES ]] ; then
        source mount.sh
        cd $GURU_BIN
        if ! timeout -k 10 10 ./mount.sh wikipages ; then
            gr.msg -c red "mount failed: $?" -k $convert_indicator_key
            return 122
        fi
    fi

    local option="-a --ignore-existing "
    local message="up tp date "

    if [[ $GURU_FORCE ]] ; then
        option="--recursive --delete "
        message="updated (force)"
    fi

    (( $GURU_VERBOSE >= 1)) && option="--progress $option "

    gr.msg -n -v1 "${#files_done[@]} file(s) "
    gr.msg -n -v2 -c light_blue "${files_done[@]} "
    gr.msg -n -v2 "to $GURU_MOUNT_WIKIPAGES/notes.. "

    rsync $option ${files_done[@]} $GURU_MOUNT_WIKIPAGES/notes

    gr.msg -v2 -c green "$message" -k $convert_indicator_key
    rm ${files_done[@]}
}

# covert_bash_2_json () {
# # bash variable content to json bopy

#     jq --arg keyvar "$bash_var" '.[$keyvar]' json

# }


# convert.json_2_bash () {


#     path="test_data"

#     convert.make_test_json () {

#         cat > "/tmp/test.json" <<EOL
# {
#   "$path": {
#     "url": "example.com",
#     "name": "John Doe",
#     "date": "10/22/2017"
#   }
# }
# EOL


#     #cat /tmp/test.json

#     }

#     convert.json_bashvar () {
#     # input json file path
#     #  there is security implication to this approach, that is if the user could manipulate the json to wreak havoc.

#       declare -A test_data="$(jq -r '
#       def replace_dot:
#         . | gsub("\\."; "_");
#       def trim_spaces:
#         . | gsub("^[ \t]+|[ \t]+$"; "");
#       to_entries|map(
#         "export \(.key|trim_spaces|replace_dot)="
#         + "\(.value|tostring|trim_spaces|@sh)"
#         )|.[]' $@)"

#         # values=$(cat $1)
#         # while read -rd $'' line
#         # do
#         #     export "$line"
#         # done < <(jq -r <<<"$values" \
#         #          'to_entries|map("\(.key)=\(.value)\u0000")[]')

#         # constants="$(cat ${1} | jq ".$path" | jq -r "to_entries|map(\(.key)=\(.value|tostring))|.[]")"
#         # echo -e $constants

#         # for keyval in $(grep -E '": [^\{]' /tmp/test.json | sed -e 's/: /=/' -e "s/\(\,\)$//"); do
#         #     echo "export $keyval"
#         #     eval export $keyval
#         # done

#         echo ${test_data[url]}

#     }

#     convert.make_test_json
#     convert.json_bashvar /tmp/test.json

# }

convert.from_avif () {

    if ! convert.check avif ; then
        return 100
    fi

    gr.msg -v2 -c green "avif supported"
    # this might help https://github.com/SoftCreatR/imei/blob/main/imei.sh
}


convert.check_format() {

    if convert.check $1 ; then
        gr.msg -v2 "format $1 is supported"
        return 0
    else

        if dwebp -version >/tmp/dweb_version ; then
            gr.msg -v2 -c green "using dwebp v.$(< /tmp/dweb_version) for webp support"
            return 0
        else
            gr.msg -v2 -c yellow "format $1 is not supported"
            return 1
        fi

    fi
}


convert.check () {
# check if critical file format are supported and version is above 7.1

    local _return=0

    gr.msg -v2 -n "checking format support: "
    local formats=(jpg png gif tiff webp avif)
    [[ $1 ]] && formats=(jpg png gif tiff $1)

    for format in ${formats[@]} ; do
        if convert -list format | grep ${format^^} >/dev/null; then
            gr.msg -v2 -n -c green "$format "
        else
            gr.msg -v2 -n -c red "$format "
            _return=1
        fi
    done

    local im_version=$(convert -version | head -n1 | cut -d" " -f3)

    case $im_version in
        "6."*|"5."*|"4."*|"7.0"*)
            gr.msg -v1 -c yellow "imagemagic v.$im_version is way too old "
            _return=1
        ;;

        "7."*)
            gr.msg -v2 "imagemagic v.$im_version "
        ;;
    esac
    return $_return
}


convert.compile () {
# get and compile imagemagick with webp and avif support

    local im_version="7.1.1"

    [[ $1 ]] && im_version=$1

    # uninstall if installed by apt
    if apt list --installed | grep imagemagick; then
        gr.msg "installed system version of imagemagick"

        if convert.check ; then
            gr.msg "seems that distributor added valid version to repository"
            return 0

        else
            if sudo apt remove --purge imagemagick; then
                gr.msg -c green "current installation removed"
            else
                gr.msg -c red "purging failed, do manually"
                return 2
            fi
        fi
    fi

    sudo apt-get update

    #Install Build-Essential in order to configure and make the final Install
    sudo apt-get install build-essential
    #libjpg62-dev required in order to work with basic JPG files
    sudo apt-get install -y libjpeg62-dev
    #libtiff-dev is required in order to work with TIFF file format
    sudo apt-get install -y libtiff-dev
    #libpng-dev required in order to work with basic PNG files
    sudo apt-get install -y libpng-dev

    # uninstalling compiled version
    sudo make uninstall && gr.msg -c green "uninstalled" || gr.msg -c red "uninstallation failed"

    gr.msg -h "cloning ImageMagick source from github.com.."
    cd /tmp
    git clone https://github.com/ImageMagick/ImageMagick.git ImageMagick-$im_version
    cd ImageMagick-$im_version

    gr.msg -h "configuring.."

    if ./configure \
            --with-bzlib=yes \
            --with-djvu=yes \
            --with-dps=yes \
            --with-fftw=yes \
            --with-flif=yes \
            --with-fontconfig=yes \
            --with-fpx=yes \
            --with-freetype=yes \
            --with-gslib=yes \
            --with-gvc=yes \
            --with-heic=yes \
            --with-jbig=yes \
            --with-jemalloc=yes \
            --with-jpeg=yes \
            --with-jxl=yes \
            --with-lcms=yes \
            --with-lqr=yes \
            --with-lzma=yes \
            --with-magick-plus-plus=yes \
            --with-openexr=yes \
            --with-openjp2=yes \
            --with-pango=yes \
            --with-perl=yes \
            --with-png=yes \
            --with-raqm=yes \
            --with-raw=yes \
            --with-rsvg=yes \
            --with-tcmalloc=yes \
            --with-tiff=yes \
            --with-webp=yes \
            --with-wmf=yes \
            --with-x=yes \
            --with-xml=yes \
            --with-zip=yes \
            --with-zlib=yes \
            --with-zstd=yes \
            --with-gcc-arch=native
            then
        gr.msg -c green "configure ok"
    else
        gr.msg -c red "configure failed"
        return 3
    fi


    gr.msg -h "compiling.."
    if make; then
        gr.msg -c green "successfully compiled"
    else
        gr.msg -c red "compile failed, error: $?"
        return 4
    fi

    gr.msg -h "installing.."
    if sudo make install; then  # sudo identify -version
        gr.msg -c green "successfully installed"
    else
       gr.msg -c red "installation failed, error: $?"
       # run in-depth check_imagemagick
       make check
       return 5
    fi

    sudo ldconfig /usr/local/lib

    gr.msg -h "checking format support.."
    if convert.check; then
        gr.msg -c green "installation seems to work"
    else
       gr.msg -c yellow "compiling new version did not bring support for wanted formats"
       return 6
    fi
}


# convert.install_imagemagick () {
#     # compile avif support to imagemagic

#     sudo apt-get update
#     sudo apt-get install libheif-dev libaom-dev libjpeg-dev libpng-dev
#     sudo apt build-dep imagemagick

#     wget https://imagemagick.org/download/ImageMagick.tar.gz
#     tar xvzf ImageMagick.tar.gz
#     cd into the dir
#     ./configure --with-heic=yes --with-webp=yes
#     # PS: If you also want webp, also use this flag: --with-webp=yes
#     # PPS: If you also want vips, also turn on the --with-modules flag
#     #      (see https://github.com/libvips/libvips/issues/343 and https://github.com/libvips/libvips/issues/418)
#     sudo make
#     sudo make install
#     sudo ldconfig /usr/local/lib
#     sudo identify -version   # to check if installed ok
#     make check  # optional run in-depth check
#     identify -list format | grep AVIF  # It should print a line

# }


convert.install () {
    # install needed

    # webp and atif format support
    convert.check || convert.install_imagemagick

    ffmpeg -version >/dev/null && \
    dwebp -version -quiet >/dev/null && \
    detox --help >/dev/null && \
        return 0
        ## tbd detox install check

    sudo apt update && \
    sudo apt install webp ffmpeg detox imagemagick

    }


convert.remove () {
    # remove tools

    dwebp -version -quiet >/dev/null || return 0
    sudo apt remove webp ffmpeg
}


convert.status () {
    # check latest convert is reachable and returnable.

    gr.msg -n -v1 -t "${FUNCNAME[0]}: "

    if [[ $GURU_CONVERT_ENABLED ]] ; then
        gr.msg -v1 -c green -k $convert_indicator_key \
            "enabled"
    else
        gr.msg -v1 -c reset -k $convert_indicator_key \
            "disabled"
        return 1
    fi



    return 0
}


convert.poll () {
    # poll functions

    local convert_indicator_key="f$(gr.poll convert)"
    local _cmd="$1" ; shift

    case $_cmd in
        start )
            gr.msg -v1 -t -c black "${FUNCNAME[0]}: convert status polling started" -k $convert_indicator_key
            ;;
        end )
            gr.msg -v1 -t -c reset "${FUNCNAME[0]}: convert status polling ended" -k $convert_indicator_key
            ;;
        status )
            convert.status
            ;;
        *)  gr.msg -c dark_grey "function not written"
            return 0
    esac
}



if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
    #source "$GURU_RC"
    convert.main $@
    exit $?
fi




