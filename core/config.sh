#!/bin/bash
# guru-client config tools
source common.sh

config.main () {
    # main comman parser
    local _cmd="$1" ; shift
    case "$_cmd" in
            user|export|help|edit|get|set|pull|push)
                    config.$_cmd $@
                    return $?
                    ;;
            status)
                    gmsg "no status data"
                    ;;

                 *) echo "unknown config action '$_cmd'"
                    config.help  $@
                    return $?
                    ;;
        esac
}


config.help () {
    # general help
    gmsg -v1 "guru-client config help " -c white
    gmsg -v2
    gmsg -v0 "usage:    $GURU_CALL config pull|push|export|user|get|set|help"
    gmsg -v2
    gmsg -v1 "actions:"
    gmsg -v1 " export        export configuration to environment"
    gmsg -v1 " pull          poll user configuration from server "
    gmsg -v1 " push          push user configuration to server "
    gmsg -v1 " user          open user configuration in dialog "
    gmsg -v1 " edit          edit user config file with preferred editor "
    gmsg -v1 " get           get single value from user config"
    gmsg -v1 " set           set value to user config and current environment "
    gmsg -v1 " help          try 'help -V' full help" -V2
    gmsg -v1 "examples:" -c white
    gmsg -v1 "     '$GURU_CALL config user'                            get current host and user settings"
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
          rhs="${rhs%%\#*}"         # remove in line right comments
          rhs="${rhs%%*( )}"        # remove trailing spaces
          rhs="${rhs// =/=}"        # remove spaces from =
          rhs="${rhs//= /=}"

          case "$lhs" in
                *[*)  _chapter=${lhs//[}
                      _chapter=${_chapter//]}
                      [[ $_chapter ]] && _chapter="${_chapter}_" ;;
                *)    echo "export GURU_${_chapter^^}${lhs^^}=$rhs"
            esac
      fi
    done < $_source_cfg >> $_target_rc
    return 0
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

    # source $GURU_RC

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
    # set path
    echo "source $GURU_BIN/path.sh" >> $_target_rc
    echo "source $GURU_BIN/alias.sh" >> $_target_rc

    # check and load configuration
    if [[ "$_target_rc" ]] ; then
            # export configure
            chmod +x "$_target_rc"
            source "$_target_rc"

            ## TBD indicator.keyboard init > corsair.main init
            # init corsair profile
            if [[ $GURU_CORSAIR_ENABLED ]] ; then
                    source $GURU_BIN/corsair.sh
                    corsair.main init
                fi
        else
            gmsg -c yellow "somethign went wrong, recovering old user configuration"
            [[ -f "$_target_rc.old" ]] && mv -f "$_target_rc.old" "$_target_rc" \
                || gmsg -x 100 -c red "no old backup found, unable to recover"
            return 10
        fi
}


config.pull () {
    # pull configuration files from server

    gmsg -v1 -n -V2 "pulling $GURU_USER@$GURU_HOSTNAME configs.. "
    gmsg -v2 -n "pulling configs from $GURU_ACCESS_USERNAME@$GURU_ACCESS_DOMAIN:/home/$GURU_ACCESS_USERNAME/usr/$GURU_HOSTNAME/$GURU_USER "
    local _error=0

    rsync -rav --quiet -e "ssh -p $GURU_ACCESS_PORT" \
        "$GURU_ACCESS_USERNAME@$GURU_ACCESS_DOMAIN:/home/$GURU_ACCESS_USERNAME/usr/$GURU_HOSTNAME/$GURU_USER/" \
        "$GURU_CFG/$GURU_USER"
    _error=$?

    if ((_error<9)) ; then
            gmsg -c green "ok"
            return 0
        else
            gmsg -c red "failed"
            return $_error
        fi
}


config.push () {
    # save configuration to server

    gmsg -v1 -n -V2 "pushing $GURU_USER@$GURU_HOSTNAME configs.. "
    gmsg -v2 -n "pushing configs to $GURU_ACCESS_USERNAME@$GURU_ACCESS_DOMAIN:/home/$GURU_ACCESS_USERNAME/usr/$GURU_HOSTNAME/$GURU_USER "
    local _error=0

    # "if not"
    ssh "$GURU_ACCESS_USERNAME@$GURU_ACCESS_DOMAIN" \
        -p "$GURU_ACCESS_PORT" \
        ls "/home/$GURU_ACCESS_USERNAME/usr/$GURU_HOSTNAME/$GURU_USER" >/dev/null 2>&1 || \
        # "then"
        ssh "$GURU_ACCESS_USERNAME@$GURU_ACCESS_DOMAIN" \
            -p "$GURU_ACCESS_PORT" \
            mkdir -p "/home/$GURU_ACCESS_USERNAME/usr/$GURU_HOSTNAME/$GURU_USER"
        # "fi"

    rsync -rav --quiet -e "ssh -p $GURU_ACCESS_PORT" \
        "$GURU_CFG/$GURU_USER/" \
        "$GURU_ACCESS_USERNAME@$GURU_ACCESS_DOMAIN:/home/$GURU_ACCESS_USERNAME/usr/$GURU_HOSTNAME/$GURU_USER/"

    _error=$?
    if ((_error<9)) ; then
            gmsg -c green "ok"
            return 0
        else
            gmsg -c red "failed"
            return $_error
        fi
}


config.edit () {
    # edit user config file with preferred editor

    local _config_file=$GURU_CFG/$GURU_USER/user.cfg

    if ! [[ -f $_config_file ]] ; then
        if gask "user configuration fur user did not found, create local config for $GURU_USER" ; then
                mkdir -p $_config_file
                cp $GURU_CFG/user-default.cfg $_config_file
            fi
        fi

    $GURU_PREFERRED_EDITOR $_config_file  || gmsg -v2 -c yello "error while editing $_config_file.."

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

    gmsg -v1 "checking dialog installation.."
    dialog --version >>/dev/null || sudo apt install dialog

    # open temporary file handle and redirect it to stdout
    exec 3>&1
    _new_file="$(dialog --editbox "$GURU_CFG/$GURU_USER/user.cfg" "0" "0" 2>&1 1>&3)"
    return_code=$?
    # close new file handle
    exec 3>&-

    clear

    if (( return_code > 0 )) ; then
            gmsg "nothing changed.."
            return 0
        fi

    if gask "overwrite settings" ; then
            cp -f "$_config_file" "$GURU_CFG/$GURU_USER/user.cfg.backup"
            gmsg "backup saved $GURU_CFG/$GURU_USER/user.cfg.backup"
            echo "$_new_file" >"$_config_file"
            gmsg -c white "configure saved, taking configuration in use.."
            config.export
            #gmsg -c white "to save new configuration to sever type: '$GURU_CALL config push'"
            config.push
        else
            gmsg -c dark_golden_rod "ignored"
            gmsg -c white "to get previous configurations from sever type: '$GURU_CALL config pull'"
        fi
    return 0
}


config.get (){
    # get environmental value of variable

    [[ "$1" ]] && _variable="$1" || read -r -p "variable: " _variable
    #set |grep "GURU_${_variable^^}"
    set | grep "GURU_${_variable^^}" | head -1 | cut -d "=" -f2
    return $?
}


config.set () {
    # change environment temporary

    [[ "$1" ]] && _variable="$1" || read -r -p "variable: " _variable
    [[ "$2" ]] && _value="$2" || read -r -p "$_variable value: " _value

    if ! cat $GURU_RC | grep "GURU_${_variable^^}=" >/dev/null; then
            gmsg -c yellow "no variable 'GURU_${_variable^^}' found"
            return 2
        fi
    local _found=$(cat $GURU_RC | grep "GURU_${_variable^^}=" | cut -d '=' -f 2)
    sed -i "s/GURU_${_variable^^}=.*/GURU_${_variable^^}='${_value}'/" $GURU_RC
    gmsg -v1 "changing GURU_${_variable^^} from $_found to '$_value'"
    source $GURU_RC
    return 0
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
        source $GURU_RC
        config.main "$@"
    fi
