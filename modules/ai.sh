#!/bin/bash
# guru-cli chatGPT implementation casa@ujo.guru 2023

source common.sh

## declare, ai.sh global variables. remove/comment out not needed ones
declare -g ai_temp_file="$GURU_TEMP/ai.tmp"

declare -g ai_rc="/tmp/$USER/guru-cli_ai.rc"
declare -g ai_data_folder=$GURU_SYSTEM_MOUNT/ai

gr.debug "ai_temp_file: $ai_temp_file"
gr.debug "ai_rc: $ai_rc"
gr.debug "ai_data_folder: $ai_data_folder"


ai.help () {
# user help
    gr.msg -v1 "guru-cli ai help " -c white
    gr.msg -v2 "chatgpt interface for guru.cli"
    gr.msg -v2
    gr.msg -v0  "usage:  $GURU_CALL ai ask|image|status|list|install|remove|help" -c white
    gr.msg -v0  "        $GURU_CALL ai 'question sting'" -c white
    gr.msg -v2
    gr.msg -v1 "commands: " -c white
    gr.msg -v1 " ask <question>     ask something from chatGPT"
    gr.msg -v1 " image              generate images "
    gr.msg -v1 " status             check installation and availability "
    gr.msg -v2 " list               list available openAI models "
    gr.msg -v1 " install            install requirements "
    gr.msg -v1 " remove             remove requirements "
    gr.msg -v2 " help               printout this help "
    gr.msg -v2
    gr.msg -v1 "examples:  " -c white
    gr.msg -v1 "         $GURU_CALL ai tell me something about digital assistants"
    gr.msg -v2
}


ai.check () {

    if [[ -f $GURU_BIN/chatgpt.sh ]]; then
        return 0
    else
        return 1
    fi
}


ai.main () {
# main command parser

    local function="$1" ; shift
    ## declare one shot variables here only if really needed
    ## declare -g bubble_gum=̈́true

    case "$function" in
        list|ask|image|help|poll|status|install|remove)
            ai.$function $@
            return $?
            ;;
        *)
            ai.ask "$@"
            return 0
            ;;
    esac
}


ai.image () {

    local prompt="${@}"
    local out_file="$GURU_AI_IMAGE_FOLDER/ai-${prompt//' '/'_'}.png"
    local SIZE="512x512"

    if [[ -z $GURU_AI_IMAGE_FOLDER ]] && ! [[ -d $GURU_AI_IMAGE_FOLDER ]] ; then
        gr.msg "non valid folder '$GURU_AI_IMAGE_FOLDER'"
        return 101
    fi

    source $GURU_BIN/ailib.sh
    # generate image
    ailib.request_to_image "$prompt"
    ailib.handle_error "$image_response"

    # get image location
    image_url=$(echo "$image_response" | jq -r '.data[0].url')
    gr.msg -v2 "${image_url}"
    # get the result
    curl ${image_url} -S -s --get --output $out_file
    gr.msg "$out_file"

    # show result if graphical session
    [[ "$DISPLAY" ]] || [[ "$WAYLAND_DISPLAY" ]] || [[ "$MIR_SOCKET" ]] && xviewer $out_file &
}


ai.list () {

    $GURU_BIN/chatgpt.sh --list
}


ai.ask () {

    local question="$@"
    ai.check || ai.status

    if [[ $GURU_CHATGPT_RUN_AS == 'lib' ]] ; then
        ## use modified version of chatGPT-shell-cli
        source $GURU_BIN/ailib.sh
        ailib.parse_arguments -c -p "$question"
        ailib.main

        # TBD got error fold: invalid number of columns: ‘’ i dunno why?
        # answer=$(ailib.main)
        # answer=$(echo $answer | tr -d '\n')
        # gr.msg -c white "$answer"
    else
        ## use original script
        answer=$(echo $question | $GURU_BIN/chatgpt.sh -c | tr -d '\n')
        gr.msg -c white "$answer"
    fi

    return $?
}


ai.status () {
# output ai status

    gr.msg -n -t -v1 "${FUNCNAME[0]}: "

    # check ai is enabled
    if [[ -f $GURU_BIN/chatgpt.sh ]]; then
        gr.msg -n -v1 -c green "installed, "
    else
        gr.msg -v1 -k $ai_indicator_key -c reset "not installed "
        return 1
    fi

    if [[ $GURU_AI_ENABLED ]] ; then
        gr.msg -n -v1 \
        -c green "enabled, "
    else
        gr.msg -v1 \
        -c black "disabled" \
        -k $ai_indicator_key
        return 1
    fi

    if ai.check ; then
        gr.msg -v1 \
        -k $ai_indicator_key \
        -c green "available "
    else
        gr.msg -v1 \
        -c red "non functional" \
        -k $ai_indicator_key
        return 1
    fi

    return 0
}



ai.poll () {
# daemon interface

    local _cmd="$1" ; shift
    case $_cmd in
        start)
            gr.msg -v1 -t -c black "${FUNCNAME[0]}: ai status polling started" -k $ai_indicator_key
            ;;
        end)
            gr.msg -v1 -t -c reset "${FUNCNAME[0]}: ai status polling ended" -k $ai_indicator_key
            ;;
        status)
            ai.status $@
            ;;
        *)  ai.help
            ;;
        esac
}


ai.install () {
#install chatgpt client and requirements

    # sudo apt update || gr.msg -c red "not able to update"
    # sudo apt install -y ...
    # pip3 install --user ...



    if [[ -f $GURU_BIN/chatgpt.sh ]]; then
        gr.msg "already installed, removing current installation"
        ai.remove
    fi

    gr.msg "getting latest version from github.."
    [[ -d $GURU_APP ]] && cd $GURU_APP || cd /tmp

    if [[ -d chatGPT-shell-cli ]]; then
        rm -rf chatGPT-shell-cli
    fi

    git clone https://github.com/0xacx/chatGPT-shell-cli.git
    cd chatGPT-shell-cli
    if cp chatgpt.sh $GURU_BIN ; then
        gr.msg -c green "installation succeeded"
        return 0
    else
        gr.msg -c red "failed"
        return 100
    fi
}


ai.remove () {
# remove installation and requirements

    if [[ -f $GURU_BIN/chatgpt.sh ]]; then
        rm $GURU_BIN/chatgpt.sh && gr.msg -c green "removed " || gr.msg -c red "failed to remove installation "
    else
        gr.msg -c yellow "installation not found"
    fi
    return 0
}


ai.rc () {
# source configurations

    ## check is module configuration changed lately, update rc if so
    if [[ ! -f $ai_rc ]] \
        || [[ $(( $(stat -c %Y $GURU_CFG/$GURU_USER/ai.cfg) - $(stat -c %Y $ai_rc) )) -gt 0 ]] ## \
        # || [[ $(( $(stat -c %Y $GURU_CFG/$GURU_USER/ai.cfg) - $(stat -c %Y $ai_rc) )) -gt 0 ]]
        then
            ai.make_rc && \
                gr.msg -v1 -c dark_gray "$ai_rc updated"
        fi

    [[ ! -d $ai_data_folder ]] && [[ -f $GURU_SYSTEM_MOUNT/.online ]] && mkdir -p $ai_data_folder
    source $ai_rc

}


ai.make_rc () {
# construct ai configuration rc

    source config.sh

    if [[ -f $ai_rc ]] ; then
            rm -f $ai_rc
        fi

    config.make_rc "$GURU_CFG/$GURU_USER/ai.cfg" $ai_rc
    # config.make_rc "$GURU_CFG/$GURU_USER/mount.cfg" $ai_rc append
    chmod +x $ai_rc
    # source $ai_rc
}

# located here cause rc needs to see some of functions above
ai.rc

declare -g ai_indicator_key=$GURU_AI_INDICATOR_KEY
gr.debug "ai_indicator_key: $ai_indicator_key"
gr.debug "enabled: $GURU_AI_ENABLED"
gr.debug "image location: $GURU_AI_IMAGE_FOLDER"
export OPENAI_KEY=$GURU_CHATGPT_TOKEN

## if called ai.sh file general guru configuration is sourced, then main ai.main called

if [[ ${BASH_SOURCE[0]} == ${0} ]]; then
    #source $GURU_RC
    ai.main $@
    exit $?
fi

