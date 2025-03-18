#!/bin/bash 
# convert file to another formats. Wrap around for good known stand stone: pandoc, imagemagic, dwebp, ffmpeg ..
# grbl preferred archive formats TBD config what to want from user.cfg
# for now hard written as following:
#  all images -> png
#  all video  -> mp4
#  all photos -> jpg

#source common.sh
convert_indicator_key=f7
[[ $GRBL_CONVERT_INDICATOR ]] && convert_indicator_key=$GRBL_CONVERT_INDICATOR

convert.help () {
# general help

    gr.msg -v1 -c white "grbl convert help "
    gr.msg -v2
    gr.msg -v0 "usage:    $GRBL_CALL convert <dest_format> file list"
    gr.msg -v2
    gr.msg -v1 " install       install imagemagic and other needed tools from api ropository "
    gr.msg -v1 " remove        remove os distributor version of imagemagic (may be very old) "
    gr.msg -v1 " compile       remove current imagemagic installation, then download and compile from github "
    gr.msg -v1 " <format>      specify from format and all pictures are converted to $GRBL_FORMAT_PICTURE"
    gr.msg -v1 "               specify from format and all videos are converted to $GRBL_FORMAT_VIDEO"
    gr.msg -v1 "               supported formats: webp webm mkv avif"
    gr.msg -v1 " <file(s)> <format> "
    gr.msg -v1 "               convert list of tiles to given format TODO: only videos supported for now"
    gr.msg -v1 " <target>      specify target format to convert to it (experimental)"
    gr.msg -v1 "               supported formats: dokuwiki, png, ods"
    gr.msg -v2
    gr.msg -v1 -c white "example:"
    gr.msg -v1 "      $GRBL_CALL convert webp                # converts all webp in folder to $GRBL_FORMAT_PICTURE "
    gr.msg -v1 "      $GRBL_CALL convert dokuwiki            # converts specified markdown files to dokuwiki format "
    gr.msg -v1 "      $GRBL_CALL convert ods <filename.md>   # converts markdown file to Libre Office Writer format "
    gr.msg -v2
    gr.msg -v1 "avif support is still issue 2018 to 2023 >:/ https://github.com/ImageMagick/ImageMagick/issues/1432"
    return 0
}

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

    case $input in


        install|remove|compile|check)
            convert.$input
            return $?
            ;;

        webp|webm|mkv|a|avif)
            convert.check_format $input || return 100
            convert.from_$input $@
            return $?
            ;;

        dokuwiki|png)
            convert.to_$input $@
            return $?
            ;;

        doc|document|ods)
            convert.to_ods $@
            return $?
            ;;

        help|poll|status)
            convert.$input $@
            return $?
            ;;
        *)
            ## TODO wanted command example 'gr convert hello.jpg to png', see following function below help
            # this badly written module is, rewrite desirable
            local list=($input $@)
            local file_list=()
            local orig_format=

            # check all items in list
            for item in ${list[@]}; do
                gr.debug "checking $item.."

                # Non positional destination format check
                case $item in
                    # video format
                    mkv|avi|mp4|webm)
                        to_format=$item
                        gr.debug "format is $to_format"
                        method=video
                        continue
                        ;;

                    # picture format
                    webp|tiff|png|jpg|jpeg|avif)
                        to_format=$item
                        gr.debug "format is $to_format"
                        method=picture
                        continue
                        ;;
                esac

                if [[ -f $item ]]; then
                    gr.debug "file $item found"
                    file_list+=("$item")
                else
                    gr.msg "file $item not found"
                    continue
                fi
            done

            if ! [[ $method ]] || ! [[ $to_format ]] || ! [[ $file_list ]]; then
                gr.msg -e1 "some of variables are empty"
                gr.debug "method:$method format:$to_format file_list:${file_list[@]}"
                return 128
            fi

            for file in ${file_list[@]}; do
                gr.msg "processing $file.."
                orig_format=${file##*.}

                gr.debug "call: convert.${method} $file $to_format"
                convert.${method} $file $to_format
            done
        ;;

    esac
    return 0
}


convert.to () {
## TODO wanted command example 'gr convert hello.jpg to png'
## accept file lists until 'to' is found, after that is target format
## skip if files do not match mimetype of file ending
## global GRBL_FORCE flag "-f" overwrites existing and deletes original files
## will accept list of different file (*.*/*/.) types but check if convert possible first, this disables force flag to avoid catastrophes
## lists of files that share same, known file ending, and mime type (*.webp) can be forced
## following prototype functions below might be useful
    gr.msg -e0 TBD
    return 0
}


convert.source_options () {
# returns pandoc/imagemagick convert/inkscape/magick file type option name, file ending and file type specific option flag for given file
## TODO continue if seems good method, too tired, no time and not needed now

    local _file="$1"
    if ! [[ -f $_file ]]; then
        gr.msg -e1 "file $_file not found"
        return 127
    fi

    case ${_file##*.} in
        png)
            _method="inkscape $_file"
            ;;
        jpg|jpeg)
            _method="convert $_file"
            ;;
        md|mmd)
            _method="pandoc -t markdown $_file"
            ;;
        txt)
            _method="pandoc -t text $_file"
            ;;
        html|htm)
            _method="pandoc -t html $_file -s "
    esac

}


convert.target_options () {
    return 0
}

convert.perform () {

    source_app=$(convert.source_options | cut -f1 -d' ')
    source_options=$(convert.source_options | cut -f2- -d' ')
    target_app=$(convert.target_options | cut -f1 -d' ')
    target_options=$(convert.source_options | cut -f2- -d' ')

    # if source and target can be done with one application just perform
    if [[ $source_app == $target_app ]]; then
        convert.$source_app $source_options $target_options
        return 0
    fi

    # otherwise figure out best method to perform convert process
    gr.msg "unable to perform, TBD: find out what conversion are not available with single app and are those even possible nor needed"
}


## Functions to convert from.format -> to.format

convert.mkv_to_mp4 () {
# Convert video from mkv to mp4

    local dest_format=mp4

    local file=$1

    if ![[ -f $file ]]; then
        gr.msg -e1 "$FUNCNAME: file $file not found"
        return 127
    fi

    file_base_name=${file%%.*}

    gr.msg -c aqua -k $convert_indicator_key

    # convert
    gr.msg -v1 -n -c light_blue "$file_base_name$rand.${dest_format}.. "

    local dest_file=$file_base_name.${dest_format}

    # there is a file with same name
    if [[ -f "$dest_file" ]] ; then
        gr.msg -h -n "$dest_file exists "
        dest_file=$file_base_name$RANDOM.${dest_format}
    fi

    if ffmpeg -y -hide_banner -loglevel error -i "$file" "$dest_file" ; then
        gr.msg -v1 -c green "ok" -k $convert_indicator_key
    else
        gr.msg -v1 -c red "failed $?" -k $convert_indicator_key
        return 128
    fi

    # force remove original if convert success
    [[ $GRBL_FORCE ]] && [[ -f $dest_file ]] && rm $file
    return 0
}

convert.video () {
# Cross convert video files

    local file=$1
    shift
    local dest_format=$1
    shift

    if [[ $1 ]]; then
        gr.msg -v3 -e3 "$FUNCNAME WARNING: extra operand(s): $@"
    fi

    if ! [[ -f $file ]]; then
        gr.msg -v1 -e1 "$FUNCNAME: file $file not found"
        return 127
    fi

    case $dest_format in
        mkv|avi|mp4|webm) true ;;
        *)
            gr.msg -v1 "$FUNCNAME: unknow target format $dest_format"
            return 129
    esac

    case ${file##*.} in
        mkv|avi|mp4|webm) true ;;
        *)
            gr.msg -v1 "$FUNCNAME: unknow source format $dest_format"
            return 130
    esac

    file_base_name=${file%%.*}

    gr.msg -c aqua -k $convert_indicator_key

    # convert
    gr.msg -v1 -n -c light_blue "$file_base_name$rand.${dest_format}.. "

    local dest_file=$file_base_name.${dest_format}

    # there is a file with same name
    if [[ -f "$dest_file" ]] ; then
        gr.msg -v1 -h -n "$dest_file exists "
        dest_file=$file_base_name$RANDOM.${dest_format}
    fi

    if ffmpeg -y -hide_banner -loglevel error -i "$file" "$dest_file" ; then
        gr.msg -v1 -c green "ok" -k $convert_indicator_key
    else
        gr.msg -v1 -c red "failed $?" -k $convert_indicator_key
        return 128
    fi

    # force remove original if convert success
    [[ $GRBL_FORCE ]] && [[ -f $dest_file ]] && rm $file
    return 0
}


## Function to convert all files from -> $GRBL_FORMAT_*


# convert from methods. Always convert to png
## TODO issue #59 make one convert.format <format> all there three are almost identical

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
    local dest_format=$GRBL_FORMAT_PICTURE
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
            dwebp -quiet "$file_base_name.webp" -o "/tmp/$USER/$file_base_name.${dest_format}"

            # check file size
            local orig_size=$(wc -c "$file_base_name.${dest_format}" | awk '{print $1}')
            local new_size=$(wc -c "/tmp/$USER/$file_base_name.${dest_format}" | awk '{print $1}')

            if [[ $orig_size -eq $new_size ]] ; then

                # check does pictures have same content
                local orig=$(identify -quiet -format "%#" "$file_base_name.${dest_format}" )
                local new=$(identify -quiet -format "%#" "/tmp/$USER/$file_base_name.${dest_format}")

                # check file contains same data, rename if not
                if [[ "$orig" == "$new" ]] ; then
                    gr.msg -v2 -n "identical content "
                # skip
                    if ! [[ $GRBL_FORCE ]] ; then
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

        if [[ -f "/tmp/$USER/$file_base_name.${dest_format}" ]] ; then
            mv "/tmp/$USER/$file_base_name.${dest_format}" "$file_base_name$rand.${dest_format}" \
                && gr.msg -v1 -c green "ok" \
                || gr.msg -c yellow "move failed $?"
        else
            dwebp -quiet "$file_base_name.webp" -o "$file_base_name$rand.${dest_format}"\
                && gr.msg -v1 -c green "ok" \
                || gr.msg -c yellow "convert failed $?"
        fi

        # force remove original if convert success
        [[ $GRBL_FORCE ]] && [[ -f "$file_base_name$rand.${dest_format}" ]] && rm "$file_base_name.webp"

        # clean up
        [[ -f "/tmp/$USER/$file_base_name.${dest_format}" ]] && rm "/tmp/$USER/$file_base_name.${dest_format}"

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
    local dest_format=$GRBL_FORMAT_VIDEO
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
        [[ $GRBL_FORCE ]] && [[ -f $file_base_name$rand.${dest_format} ]] && rm $file_base_name.webm

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
    local dest_format=$GRBL_FORMAT_VIDEO
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
        [[ $GRBL_FORCE ]] && [[ -f $file_base_name$rand.${dest_format} ]] && rm $file_base_name.mkv

    done
    return 0
}


## convert to methods

convert.to_dokuwiki () {

    local convert_indicator_key="f$(gr.poll convert)"
    # input list of files to export, expects that input is "note ans pushes it to wiki/notes tbd fix next

    if ! md2doku -h >/dev/null; then
        sudo apt update
        [[ $GRBL_GIT_TRIALS ]] || GRBL_GIT_TRIALS="$HOME/git"
        cd $GRBL_GIT_TRIALS
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
    # [[ $GRBL_FORCE ]] && [[ $file_base_name$rand.${dest_format} ]] && rm $file_base_name.mkv
    if ! [[ -d $GRBL_MOUNT_WIKIPAGES ]] ; then
        source mount.sh
        cd $GRBL_BIN
        if ! timeout -k 10 10 ./mount.sh wikipages ; then
            gr.msg -c red "mount failed: $?" -k $convert_indicator_key
            return 122
        fi
    fi

    local option="-a --ignore-existing "
    local message="up tp date "

    if [[ $GRBL_FORCE ]] ; then
        option="--recursive --delete "
        message="updated (force)"
    fi

    (( $GRBL_VERBOSE >= 1)) && option="--progress $option "

    gr.msg -n -v1 "${#files_done[@]} file(s) "
    gr.msg -n -v2 -c light_blue "${files_done[@]} "
    gr.msg -n -v2 "to $GRBL_MOUNT_WIKIPAGES/notes.. "

    rsync $option ${files_done[@]} $GRBL_MOUNT_WIKIPAGES/notes

    gr.msg -v2 -c green "$message" -k $convert_indicator_key
    rm ${files_done[@]}
}


convert.to_ods () {
# create odt from from input file, markdown original expexted (what else?)


    local _template_name="default"

    case $1 in
        thin|new)
        _template_name="thin"
        shift
        ;;
    esac

    if [[ "$1" ]] ; then
        input_file="$1"
    else
        read -p "please input file name to convert .odt format: " input_file
    fi

    # get date for note
    _date=$(date +$GRBL_FORMAT_FILE_DATE-$GRBL_FORMAT_FILE_TIME)

    local odt_file="${input_file%%.*}_${_date}.odt"
    local odt_template="$GRBL_MOUNT_TEMPLATES/$_template_name-template.odt"

    # sub second filename ramdomizer
    if [ -f "$odt_file" ]; then
        odt_file="${odt_file%%.*}.$RANDOM.odt"
    fi

    # printout variables for debug purpoces
    gr.debug "date:'$_date', \
          input_file: '$input_file', \
          odt_template: '$odt_template', \
          odt_file: '$odt_file'"

    if ! [ -f "$input_file" ]; then
        gr.msg -e1 "no input file '$input_file' found"
        return 123
    fi

    # compile markdown to open office file format
    pandoc "$input_file" --reference-doc="$odt_template" \
            -f markdown -o "$odt_file"
    local _error=$?

    if [[ $_error -gt 0 ]] ; then
        gr.msg -e1 "error '$_error' during pandoc convert progress.. "
        return $_error
    fi

    if ! [[ -f $odt_file ]]; then
        gr.msg -e2 "No file generated, unknown error"
    fi

    #printout output file location
    gr.msg -v1 "$odt_file"

    # open office program
    $GRBL_PREFERRED_OFFICE_DOC "$odt_file" 2>/dev/null &
}


convert.html_to_md () {
# download and convert web page to markdown file

    # output filename
    if [[ "$1" ]] ; then
        input_file="$1"
        shift
    else
        read -p "please give markdown file name: " file_name
    fi

    # url to source
    if [[ "$1" ]] ; then
        url="$1"
    else
        read -p "please input url to convert markdown: " url
    fi

    pandoc -s -r html $url -o $file_name
    sed -n '/:::/!p' temp file

}


convert.md_to_pdf () {
# create pdf from from markdown original
# TODO make general function for many as possible formats

    if [[ "$1" ]] ; then
        input_file="$1"
    else
        read -p "please input file name to convert .pdf format: " input_file
    fi

    # get date for note
    _date=$(date +$GRBL_FORMAT_FILE_DATE-$GRBL_FORMAT_FILE_TIME)

    local target_file="${input_file%%.*}_${_date}.pdf"


    # sub second filename random
    if [ -f "$target_file" ]; then
        target_file="${target_file%%.*}.$RANDOM.pdf"
    fi

    # printout variables for debug purposes
    gr.debug "date:'$_date', \
          input_file: '$input_file', \
          target_file: '$target_file'"

    if ! [ -f "$input_file" ]; then
        gr.msg -e1 "no input file '$input_file' found"
        return 123
    fi

    # compile markdown to open office file format
    pandoc "$input_file" -f markdown -o "$target_file"
    local _error=$?

    if [[ $_error -gt 0 ]] ; then
        gr.msg -e1 "error '$_error' during pandoc convert progress.. "
        return $_error
    fi

    if ! [[ -f $target_file ]]; then
        gr.msg -e2 "No file generated, unknown error"
    fi

    #printout output file location
    gr.msg -v1 "$target_file"

    # open office program
    $GRBL_PREFERRED_OFFICE_DOC "$target_file" 2>/dev/null &
}

# covert_bash_2_json () {
# # bash variable content to json bopy

#     jq --arg keyvar "$bash_var" '.[$keyvar]' json

# }


# convert.json_2_bash () {


#     path="test_data"

#     convert.make_test_json () {

#         cat > "/tmp/$USER/test.json" <<EOL
# {
#   "$path": {
#     "url": "example.com",
#     "name": "John Doe",
#     "date": "10/22/2017"
#   }
# }
# EOL


#     #cat /tmp/$USER/test.json

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

#         # for keyval in $(grep -E '": [^\{]' /tmp/$USER/test.json | sed -e 's/: /=/' -e "s/\(\,\)$//"); do
#         #     echo "export $keyval"
#         #     eval export $keyval
#         # done

#         echo ${test_data[url]}

#     }

#     convert.make_test_json
#     convert.json_bashvar /tmp/$USER/test.json

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

        if dwebp -version >/tmp/$USER/dweb_version ; then
            gr.msg -v2 -c green "using dwebp v.$(< /tmp/$USER/dweb_version) for webp support"
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

    if [[ $GRBL_CONVERT_ENABLED ]] ; then
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
    #source "$GRBL_RC"
    convert.main $@
    exit $?
fi




