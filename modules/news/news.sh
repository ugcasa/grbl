#!/bin/bash
# grbl single file module template casa@ujo.guru 2022
# include other newss/libraries that are needed
# source nnnn.sh

# declare global variables for news
declare -g news_temp_file="$GRBL_TEMP/news.tmp"
declare -g news_rc="/tmp/$USER/grbl_news.rc"
declare -g news_data_folder=$GRBL_SYSTEM_MOUNT/news


news.help () {
# user help
    gr.msg -v1 "grbl news help " -c white
    gr.msg -v2
    gr.msg -v2 "news reader and timed new features for debian terminal "
    gr.msg -v2
    gr.msg -v0 "usage: " -c white
    gr.msg -v0 "          $GRBL_CALL news command variables"
    gr.msg -v0 "          $GRBL_CALL --option --optin_with_value <value>"
    gr.msg -v2
    gr.msg -v1 "commands: " -c white
    gr.msg -v1 " ls         list something "
    gr.msg -v1 " install    install requirements "
    gr.msg -v1 " remove     remove installed requirements "
    gr.msg -v1 " help       printout this help "
    gr.msg -v2
    gr.msg -v1 "options: " -c white
    gr.msg -v1 " --option   option "
    gr.msg -v1 " --value    option with value "
    gr.msg -v1 "example: " -c white
    gr.msg -v1 "          $GRBL_CALL news <command>"
    gr.msg -v2
}


news.main () {
# main command parser

    local function="$1" ; shift

    case "$function" in
            ## add functions called from outside on this list
            ls|status|poll|install|remove|help)
                news.$function $@
                return $?
                ;;

            read|rss)
                python3 $GRBL_BIN/news/rss-news.py "$@"
                ;;
            *)
                news.help
                return 0
                ;;
        esac
}


news.ls () {
# list something
    gr.msg "nothing to list"
    # test and return result
    return 0
}


news.status () {
# output news status

    gr.msg -n -t -v1 "${FUNCNAME[0]}: "

    # check news is installed
    if [[ -f $GRBL_BIN/news.sh ]]; then
        gr.msg -n -v1 -c green "installed, "
    else
        gr.msg -v1 -k $news_indicator_key -c reset "not installed "
        return 1
    fi

    # check news is enabled
    if [[ $GRBL_NEWS_ENABLED ]] ; then
        gr.msg -n -v1 \
        -c green "enabled, "
    else
        gr.msg -v1 \
        -c black "disabled" \
        -k $news_indicator_key
        return 1
    fi

    # check that news works
    if news.check ; then
        gr.msg -v1 \
        -k $news_indicator_key \
        -c green "available "
    else
        gr.msg -v1 \
        -c red "non functional" \
        -k $news_indicator_key
        return 1
    fi

    return 0
}


news.poll () {
# daemon interface

    local _cmd="$1" ; shift
    case $_cmd in
        start)
            gr.msg -v1 -t -c black "${FUNCNAME[0]}: news status polling started" -k $news_indicator_key
            ;;
        end)
            gr.msg -v1 -t -c reset "${FUNCNAME[0]}: news status polling ended" -k $news_indicator_key
            ;;
        status)
            news.status $@
            ;;
        *)  news.help
            ;;
        esac
}


news.install () {
# install requirements
    # sudo apt update || gr.msg -c red "not able to update"
    # sudo apt install -y ...
    # pip3 install --user ...
    gr.msg "nothing to install"
    return 0
}


news.remove () {
# remove requirements
    # sudo apt remove -y ...
    # pip3 remove --user ...
    gr.msg "nothing to remove"
    return 0
}


news.rc () {
# source configurations

    local module_config="$GRBL_CFG/$GRBL_USER/news.cfg"

    # use defaults if not exist
    [[ -f $module_config ]] || module_config="$GRBL_CFG/news.cfg"

    # check is module configuration changed lately, update rc if so
    if [[ ! -f $news_rc ]] || [[ $(( $(stat -c %Y $module_config) - $(stat -c %Y $news_rc) )) -gt 0 ]] ; then
            news.make_rc && gr.msg -v1 -c dark_gray "$news_rc updated"
        fi

    [[ ! -d $news_data_folder ]] && [[ -f $GRBL_SYSTEM_MOUNT/.online ]] && mkdir -p $news_data_folder
    if [[ -f $news_rc ]] ; then
        source $news_rc
    else
        gr.msg -v2 -c dark_gray "no configuration"
    fi
}


news.make_rc () {
# construct news configuration rc

    source config.sh
    local module_config="$GRBL_CFG/$GRBL_USER/news.cfg"

    # try to find user configuration
    if ! [[ -f $module_config ]] ; then
        gr.debug "$module_config does not exist"
        module_config="$GRBL_CFG/news.cfg"

        # try to find default configuration
        if ! [[ -f $module_config ]] ; then
            gr.debug "$module_config not exist, skipping"
            return 1
        fi
    fi

    # remove existing rc file
    if [[ -f $news_rc ]] ; then
            rm -f $news_rc
        fi

    config.make_rc $module_config $news_rc
    # config.make_rc "$GRBL_CFG/$GRBL_USER/another_news.cfg" $news_rc append
    chmod +x $news_rc
}

# run these functions every time news is called
news.rc

# global variables that need values from news configuration
# declare global that need configuration values from rc
declare -g news_indicator_key="esc"
[[ $GRBL_NEWS_INDICATOR_KEY ]] && news_indicator_key=$GRBL_NEWS_INDICATOR_KEY

# check is news.sh run alone, if sourced by core.sh this
if [[ ${BASH_SOURCE[0]} == ${0} ]]; then

    # run without grbl installation
    if [[ -z $GRBL_RC ]] ; then
        export GRBL_CALL="grbl"
        export GRBL_RC="$HOME/.grblrc"
        export GRBL_BIN="$HOME/bin"
        export GRBL_CFG="$HOME/.config/grbl"
        export GRBL_TEMP="/tmp/$USER/grbl"
    fi
    source $GRBL_RC
    news.main $@
    exit $?
fi
