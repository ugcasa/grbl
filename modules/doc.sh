#!/bin/bash
# doc tools for GRBL casa@ujo.guru 2025

## issue de la grande: converting to docx and odt format mathematical formula converting does not work. 

declare -g doc_rc=/tmp/$USER/gtbl_doc.rc
declare -g doc_config="$GRBL_CFG/$GRBL_USER/doc.cfg"
declare -g doc_require=(pandoc texlive-latex-recommended)

doc.help () {
# doc help printout

    gr.msg -v1 "GRBL doc help " -h
    gr.msg -v2
    gr.msg -v0 "Usage:    $GRBL_CALL doc convert|help|install|uninstall" -c white
    gr.msg -v2
    gr.msg -v1 "Commands:" -c white
    gr.msg -v1 " convert <pdf|docx|odt>  convert markdown to given format "
    # gr.msg -v1 " check <something>       check stuff "
    # gr.msg -v1 " status                  one line status information of module "
    gr.msg -v1 " install                 install required software: ${doc_require[@]}"
    gr.msg -v1 " uninstall               remove required software: ${doc_require[@]}"
    gr.msg -v1 " help                    get more detailed help by increasing verbose level '$GRBL_CALL doc -v2' "
    gr.msg -v2
    gr.msg -v3 "Options:" -c white
    gr.msg -v3 "  -v 1..4             set module verbose level"
    gr.msg -v3 "  -d                  set module to debug mode"
    gr.msg -v4
    gr.msg -v4 " when module called trough GRBL core.sh module options are given with double hyphen '--'"
    gr.msg -v4 " and bypassed by GRBL core.sh witch removes one hyphen to avoid collision with core.sh options. "
    gr.msg -v3
    gr.msg -v3 "Internal functions: " -c white
    gr.msg -v3
    gr.msg -v3 " Following functions can be used when this file is sourced by command: 'source doc.sh' "
    gr.msg -v3 " Any of external 'commands' are available after sourcing by name 'doc.<function> arguments -options' "
    gr.msg -v3
    gr.msg -v3 " doc.main         main command parser "
    gr.msg -v3 " doc.check        check all is fine, return 0 or error number "
    gr.msg -v3 " doc.status       printout one line module status output "
    gr.msg -v3 " doc.rc           lift environmental variables for module functions "
    gr.msg -v3 "                    check changes in user config and update RC file if needed "
    gr.msg -v3 "                    this enables fast user configuration and keep everything up to date "
    gr.msg -v3 " doc.make_rc      generate RC file to /tmp out of $GRBL_CFG/$GRBL_USER/doc.cfg "
    gr.msg -v3 "                    or if not exist $GRBL_CFG/doc.cfg"
    gr.msg -v3 " doc.install      install all needed software"
    gr.msg -v3 "                    stuff that can be installed by apt-get package manager are listed in  "
    gr.msg -v3 "                    'doc_require' list variable, add them there. Other software that is not "
    gr.msg -v3 "                    available in package manager, or is too old can be installed by this function. "
    gr.msg -v3 "                    Note that install.sh can proceed multi_module call for this function "
    gr.msg -v3 "                    therefore what to install (and uninstall) should be described clearly enough. "
    gr.msg -v3 " doc.uninstall    remove installed software. Do not uninstall software that may be needed "
    gr.msg -v3 "                    by other modules or user. Uninstaller asks user every software that it  "
    gr.msg -v3 "                    going to uninstall  "
    gr.msg -v3 " doc.poll         daemon interface " # TODO remove after checking need from daemon.sh
    gr.msg -v3 " doc.start        daemon interface: things needed to do when daemon request module to start "
    gr.msg -v3 " doc.stop         daemon interface: things needed to do when daemon request module to stop "
    gr.msg -v3 " doc.status       one line status printout "
    gr.msg -v2
    gr.msg -v2 "Examples:" -c white
    gr.msg -v2 "  $GRBL_CALL doc install   # install required software "
    gr.msg -v2 "  $GRBL_CALL doc status    # print status of this module  "
    gr.msg -v3 "  doc.main status    # print status of doc  "
    gr.msg -v2
}

doc.main () {
# doc main command parser

    local _first="$1"
    shift

    case "$_first" in
            check|status|help|poll|start|end|install|uninstall)
                doc.$_first "$@"
                return $?
                ;;

            convert)
                doc.$_first "$@"
                return $?
                ;;

           *)   
                #gr.msg -e1 "unknown command: '$_first'"
                doc.convert $_first "$@"
                return $?
    esac
}


doc.convert() {
# convert original document to given format

    local _format="$1"
    shift

    local _original="$1"
    shift
    
    [[ $_format ]] || read -p "output format pdf|docx|odt? " _format

    if ! [[ -f $_original ]]; then 
        gr.msg -e1 "$_original does not exist, canceling.."
        return 127
    fi

    case ${_original##*.} in 

        md) 
            gr.msg "original file $_original ok"
            ;;
            
        *)
            gr.msg -e1 "unknown input format: '$_original'"
            return 128
    esac

    case "$_format" in

            pdf|docx|odt)
                gr.debug "converting '$_original' to $_format"
                doc.convert.$_format $_original $@
                return $?
                ;;

           *)   
                gr.msg -e1 "unknown output format: '$_format'"
                return 129
    esac
}


doc.convert.pdf() {
# convert markdown to pdf 

    local original_file="$1"
    shift

    local output_file="${original_file%%.*}.pdf"

    if [[ -f $original_file ]]; then 
        output_file="${original_file%%.*}_$(date +$GRBL_FORMAT_FILE_TIME).pdf"
    fi

    pandoc "$original_file" -f markdown -o "$output_file" && \
    firefox "$output_file" &
}

doc.convert.docx() {
# convert markdown to docx 

    local original_file="$1"
    shift

    local output_file="${original_file%%.*}.docx"

    if [[ -f $original_file ]]; then 
        output_file="${original_file%%.*}_$(date +$GRBL_FORMAT_FILE_TIME).docx"
    fi

    pandoc "$original_file" -f markdown -o "$output_file" && \
    libreoffice  "$output_file" &
}

doc.convert.odt() {
# convert markdown to odt 
    
    local original_file="$1"
    shift
    local group_name="$1"
    shift

    local odt_template=
    local template_option=
    local output_file="${original_file%%.*}.odt"

    if [[ -f $original_file ]]; then 
        output_file="${original_file%%.*}_$(date +$GRBL_FORMAT_FILE_TIME).odt"
    fi

    # using template
    if [[ $group_name ]]; then 
        
        source mount.sh
        local odt_template="$GRBL_MOUNT_TEMPLATES/writer-${group_name}.ott"
        
        if [[ -f $odt_template ]]; then
            template_option="--reference-doc=${odt_template} " #--data-dir=$GRBL_MOUNT_TEMPLATES
            gr.debug "template options: '$template_option'"
        else 
            gr.msg "template $group_name not found, converting to planc"
        fi
    fi
    
    source common.sh
    gr.varlist "debug original_file group_name output_file odt_template template_option"
    gr.debug "pandoc $original_file -f markdown -o $output_file $template_option"
    pandoc "$original_file" -f markdown -o "$output_file" $template_option && \
    libreoffice "$output_file" &
    gr.msg -c cyan "$output_file"
}


doc.rc () {
# source configurations (to be faster)

    # check is user config changed
    local _config=

    if [[ -f $GRBL_CFG/$GRBL_USER/doc.cfg ]]; then 
        _config=$GRBL_CFG/$GRBL_USER/doc.cfg
    elif [[ -f $GRBL_CFG/doc.cfg ]]; then 
        _config=$GRBL_CFG/doc.cfg
    else 
        gr.msg -e1 "config file '$_config' missing"
        return 100
    fi

    if [[ ! -f $doc_rc ]] \
        || [[ $(( $(stat -c %Y $_config) - $(stat -c %Y $doc_rc) )) -gt 0 ]] 
    
    then
        doc.make_rc $_config && \
            gr.msg -v2 -c dark_gray "$doc_rc updated"
    fi


    # source current RC file to lift user configurations to environment
    source $doc_rc
}

doc.make_rc () {
# make RC file out of config file

    local _config="$1"
    
    # remove old RC file
    if [[ -f $doc_rc ]] ; then
            rm -f $doc_rc
        fi

    source config.sh   
    config.make_rc "$_config" $doc_rc
    # config.make_rc "$GRBL_CFG/$GRBL_USER/doc.cfg" $doc_rc append

    # make RC executable
    chmod +x $doc_rc
}

doc.status () {
# module status one liner

    # printout timestamp without newline
    gr.msg -t -n "${FUNCNAME[0]}: "

    # check doc is enabled and printout status
    if [[ $GRBL_DOC_ENABLED ]] ; then
        gr.msg -n -v1 -c lime "enabled, " -k $GRBL_DOC_INDICATOR_KEY
    else
        gr.msg -v1 -c black "disabled" -k $GRBL_DOC_INDICATOR_KEY
        return 1
    fi

    gr.msg -c green "ok"
}

doc.install() {
# install required software

    local _errors=()

    # install software that is available distro's package manager repository
    for install in ${doc_require[@]} ; do
        hash $install 2>/dev/null && continue
        gr.ask -h "install $install" || continue
        sudo apt-get -y install $install || _errors+=($?)
    done


    if [[ $_error_count ]]; then
        gr.msg -e1 "${#_error_count} errors of warnings recorded: ${_error_count[@]}"
        return $_error_count
    fi
}

doc.uninstall() {
# uninstall required software

    local _errors=()

    # remove software that is needed ONLY of this module
    for remove in ${doc_require[@]} ; do
        hash $remove 2>/dev/null || continue
        gr.ask -h "remove $remove" || continue
        sudo apt-get -y purge $remove || _errors+=($?)
    done


    if [[ $_error_count ]]; then
        gr.msg -e1 "${#_error_count} errors of warnings recorded: ${_error_count[@]}"
        return $_error_count
    fi
}

doc.option() {
    # process module options

    local options=$(getopt -l "debug;verbose:" -o "dv:" -a -- "$@")

    if [[ $? -ne 0 ]]; then
        echo "option error"
        return 101
    fi

    eval set -- "$options"

    while true; do
        case "$1" in
            -d|debug)
                GRBL_DEBUG=true
                shift
                ;;
            -v|verbose)
                GRBL_VERBOSE=$2
                shift 2
                ;;
            --)
                shift
                break
                ;;
        esac
    done

    doc_command_str=($@)
}

doc.poll () {
# daemon required polling functions

    local _cmd="$1" ; shift

    case $_cmd in
        start )
            gr.msg -v1 -t -c black \
                -k $GRBL_DOC_INDICATOR_KEY \
                "${FUNCNAME[0]}: doc status polling started"
            ;;
        end )
            gr.msg -v1 -t -c reset \
                -k $GRBL_DOC_INDICATOR_KEY \
                "${FUNCNAME[0]}: doc status polling ended"
            ;;
        status )
            doc.status
            ;;
        esac
}

# update rc and get variables to environment
doc.rc

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    doc.option $@
    doc.main ${doc_command_str[@]}
    exit "$?"
else
    [[ $GRBL_DEBUG ]] && gr.msg -c $__doc_color "$__doc [$LINENO] sourced " >&2
fi

