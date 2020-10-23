#!/bin/bash
# guru-client config tools

source $GURU_BIN/common.sh
source $GURU_BIN/remote.sh

config.main () {

    local _cmd="$1" ; shift
    case "$_cmd" in
              get|user)  config.$_cmd $@                        ; return $? ;;
                   set)  gmsg -v black "config.$_cmd disabled"  ; return $? ;;
             pull|push)  remote."$_cmd"_config $@               ; return $? ;;
                export)  config.export $@                       ; return $? ;;
                  help)  config.help $@                         ; return $? ;;
                status)  echo "no status data" ;;
                     *)  echo "unknown config action '$_cmd'"
                         GURU_VERBOSE=2
                         config.help  $@                        ; return $? ;;
        esac
}


config.help () {
    gmsg -v1 "guru-client config help " -c white
    gmsg -v2
    gmsg -v0 "usage:    $GURU_CALL config [pull|push|export|user|help -v] "
    gmsg -v2
    gmsg -v1 "actions:"
    gmsg -v1 " export        export configuration to environment"
    gmsg -v2 "               (run this every time configuration is changed) "
    gmsg -v1 " pull          poll user configuration from server "
    gmsg -v1 " push          push user configuration to server "
    gmsg -v1 " user          open user configuration in dialog "
    gmsg -v1 " help          try 'help -V' full help" -V2
    core.help flags
    gmsg -v1 "examples:" -c white
    gmsg -v1 "     '$GURU_CALL config'                                 get current host and user settings"
    gmsg -v1 "     '$GURU_CALL pull -h <host_name> -u <user_name>'     get user and host specific setting from server  "
}


config.make_rc () {
    # make rc file out of configuration file

    local _source_cfg="$1"
    local _target_rc="$2"
    local _append_rc="$3"
    local _mode=">" ; [[ "$_append_rc" ]] && _mode=">>"

    gmsg -v2 -c gray "$_source_cfg $_mode $_target_rc"

    #_source_cfg=$HOME/.config/guru/$GURU_USER_NAME/user.cfg

    if ! [[ -f $_source_cfg ]] ; then gmsg -c yellow "$_source_cfg not found" ; return 100 ; fi
    #if [[ -f $_target_rc ]] ; then rm -f $_target_rc ; fi

    # write system configs to rc file
    [[ $_append_rc ]] || printf "#!/bin/bash \n# guru-client runtime configurations auto generated at $(date)\nexport GURU_USER=$GURU_USER\n" > $_target_rc

    # read config file, use chapter name as second part of variable name
    while IFS='= ' read -r lhs rhs ;  do
      if [[ ! $lhs =~ ^\ *# && -n $lhs ]]; then
          rhs="${rhs%%\#*}"    # remove in line right comments
          rhs="${rhs%%*( )}"   # remove trailing spaces
          case "$lhs" in
                *[*)  _chapter=${lhs//[}
                      _chapter=${_chapter//]}
                      [[ $_chapter ]] && _chapter="$_chapter""_" ;;
                *)    echo "export GURU_${_chapter^^}${lhs^^}=$rhs"
            esac
      fi
    done < $_source_cfg >> $_target_rc
    return 0

    #tr -d '\r' < $configfile > $user_source_cfg.unix
}


config.make_color_rc () {
    # export color configuration for shell scripts"
    local _source_cfg="$1"
    local _target_rc="$2"
    local _append_rc="$3"
    local _mode=">" ; [[ "$_append_rc" ]] && _mode=">>"
    # use same style file than corsair
    [[ -f "$_source_cfg" ]] && source $_source_cfg || gmsg -x 100 -red "$_source_cfg missing"

    gmsg -n -v1 "setting color codes " ; gmsg -v2
    gmsg -v2 -c gray "$_source_cfg $_mode $_target_rc"
    [[ $_append_rc ]] || echo "#!/bin/bash" > $_target_rc
    printf 'if [[ "$GURU_FLAG_COLOR" ]] ; then \n' >> $_target_rc
    printf "\texport C_NORMAL=%s\n" "'\033[0m'"  >> $_target_rc
    printf "\texport C_HEADER=%s\n" "'\033[1;37m'" >> $_target_rc
    # parse trough color strings
    color_name_list=$(set | grep rgb_ | grep -v grep | grep -v "   " )            # ; echo "$color_name_list"

    for color_srt in ${color_name_list[@]} ; do
            # color name
            color_name=$(echo $color_srt | cut -f1 -d "=") # ; echo "$color_srt"
            color_name=${color_name//"rgb_"/""} # ; echo "$color_name"
            # color value
            color_value=$(echo $color_srt | cut -f2 -d "=") # ; echo "$color_value"
            # slice hex code to 8 bit pieces
            _r="${color_value:0:2}"
            _g="${color_value:2:2}"
            _b="${color_value:4:2}" # ; echo "$_r:$_g:$_b"
            # turn hex to dec
            _r="$((16#$_r))"
            _g="$((16#$_g))"
            _b="$((16#$_b))"
            # compose colorcode
            color=$(printf '\033[38;2;%s;%s;%sm' "$_r" "$_g" "$_b")
            color=${color//''/'\033'}  # bubblecum
            # printout
            #echo -e "$color $color_name $color_value"
            gmsg -n -v1 -V2 -c $color_name "."
            gmsg -n -v2 -c $color_name "$color_name "
            # make stylerc
            printf "\texport C_%s='%s'\n" "${color_name^^}" "$color"  >> $_target_rc
        done
    printf 'fi\n\n' >> $_target_rc
    gmsg -v1 -c green " done"
}


config.export () {
    # export configuration to use
    local _target_rc=$HOME/.gururc
    local _target_user=$GURU_USER ; [[ "$1" ]] && _target_user="$1"

    # make backup
    [[ -f "$_target_rc" ]] && mv -f "$_target_rc" "$_target_rc.old"

    # include system configuration
    gmsg -n -v1 "setting system configuration " ; gmsg -v2
    if config.make_rc "$GURU_CFG/system.cfg" "$_target_rc" ; then
            gmsg -c green -V2 -v1 "done"
        else
            gmsg -c red -V2 -v1 "failed"
        fi

    # add module lists made by installer to environment
    GURU_MODULES=( $(cat $GURU_CFG/installed.core) $(cat $GURU_CFG/installed.modules) )
    gmsg -n -v1 "setting module information "
    gmsg -N -v2 -c dark_grey "installed modules: '${GURU_MODULES[@]}'"
    echo "export GURU_MODULES=(${GURU_MODULES[@]})" >>$_target_rc
    if grep "export GURU_MODULES" "$_target_rc" >/dev/null ; then
            gmsg -c green -V2 -v1 "done"
        else
            gmsg -c red -V2 -v1 "failed"
        fi

    # include system configuration
    gmsg -n -v1 "setting user configuration " ; gmsg -v2
    config.make_rc "$GURU_CFG/$_target_user/user.cfg" "$_target_rc" append && gmsg -v1 -V2 -c green "done"
    config.make_color_rc "$GURU_CFG/rgb-color.cfg" "$_target_rc" append

    # check and load configuration
    if [[ "$_target_rc" ]] ; then
            # export configure
            chmod +x "$_target_rc"
            source "$_target_rc"
            if [[ $GURU_CORSAIR_ENABLED ]] ; then
                    source $GURU_BIN/corsair.sh
                    corsair.main init
                fi
        else
            gmsg -c yellow "somethign went wrong, recovering old user configuration"
            [[ -f "$_target_rc.old" ]] && mv -f "$_target_rc.old" "$_target_rc" || gmsg -x 100 -c red "no old backup found, unable to recover"
            return 10
        fi
}


config.user () {
    # open user dialog to make changes to user.cfg
    local _config_file=$GURU_CFG/$GURU_USER/user.cfg

    if ! [[ -f $_config_file ]] ; then
        if gask "user configuration fur user did not found, create local config for $GURU_USER" ; then
                mkdir -p $_config_file
                cp $GURU_CFG/user-default.cfg $_config_file
            else
                return 0
            fi
        fi

    # open temporary file handle and redirect it to stdout
    exec 3>&1
    _new_file="$(dialog --editbox "$GURU_CFG/$GURU_USER/user.cfg" "0" "0" 2>&1 1>&3)"
    return_code=$?
    # close new file handle
    exec 3>&-

    if (( return_code > 0 )) ; then
            gmsg "nothing changed.."
            return 0
        fi

    if gask "overwrite settings" ; then
            cp -f "$_config_file" "$GURU_CFG/$GURU_USER/user.cfg.backup"
            gmsg "backup saved $GURU_CFG/$GURU_USER/user.cfg.backup"
            echo "$_new_file" >"$_config_file"
            gmsg -c green "configure saved"
            gmsg "to save new configuration to sever type: '$GURU_CALL config push'"
        else
            gmsg -c dark_golden_rod "ignored"
            gmsg "to get previous configurations from sever type: '$GURU_CALL config pull'"
        fi
    return 0
}


config.get (){              # get tool-kit environmental variable

    [ "$1" ] && _setting="$1" || read -r -p "setting to read: " _setting
    #set |grep "GURU_${_setting^^}"
    set | grep "GURU_${_setting^^}" | head -1 | cut -d "=" -f2
    return $?
}


# config.set () {             # set tool-kit environmental variable
#     # set guru environmental funtions
#     [ "$1" ] && _setting="$1" || read -r -p "setting to read: " _setting
#     [ "$2" ] && _value="$2" || read -r -p "$_setting value: " _value

#     [ -f "$GURU_RC" ] && target_rc="$GURU_RC" || target_rc="$HOME/.gururc"

#     sed -i -e "/$_setting=/s/=.*/=$_value/" "$target_rc"                               # Ähh..
#     msg "setting GURU_${_setting^^} to $_value\n"
# }


if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
        config.main "$@"
    fi
