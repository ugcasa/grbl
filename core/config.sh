#!/bin/bash
# guru-client configuration manager 2020 casa@ujo.guru

config.main () {
# main comman parser
    local _cmd="$1" ; shift
    case "$_cmd" in
            user|export|help|edit|get|set|pull|push)
                    config.$_cmd $@
                    return $?
                    ;;
            status|log|debug)
                    gr.msg "no $_cmd data"
                    ;;

                 *) echo "unknown config action '$_cmd'"
                    config.help  $@
                    return $?
                    ;;
        esac
}


config.help () {
# general help
    gr.msg -v1 "guru-client config help " -h
    gr.msg -v2
    gr.msg -v0 "usage:    $GURU_CALL config pull|push|export|user|get|set|help" -c white
    gr.msg -v2
    gr.msg -v1 "actions:"
    gr.msg -v1 " export        export configuration to environment"
    gr.msg -v1 " pull          poll user configuration from server "
    gr.msg -v1 " push          push user configuration to server "
    gr.msg -v1 " user          open user configuration in dialog "
    gr.msg -v1 " edit          edit user config file with preferred editor "
    gr.msg -v1 " get           get single value from user config"
    gr.msg -v1 " set           set value to user config and current environment "
    gr.msg -v1 " help          try '$GURU_CALL help -v2' full help" -V2
    gr.msg -v2
    gr.msg -v1 "examples:" -c white
    gr.msg -v1 "     '$GURU_CALL config user'                            get current host and user settings"
    gr.msg -v1 "     '$GURU_CALL pull -h <host_name> -u <user_name>'     get user and host specific setting from server  "
    gr.msg -v2
}


config.make_rc () {
# make rc file out of configuration file

    local _source_cfg="$1"  # source configuration file
    local _target_rc="$2"   # target rc file
    local _append_rc="$3"   # any input will set to append mode
    local _chapter=
    local _mode=">" ; [[ "$_append_rc" ]] && _mode=">>"

    gr.msg -n -v2 -c gray "$_source_cfg "

    if ! [[ -f $_source_cfg ]] ; then gr.msg -c yellow "$_source_cfg not found" ; return 100 ; fi

    case $(head -n 1 $_source_cfg) in
        *"source"*) gr.msg -v2 -c dark_grey "..no need to compile this type of configs" ; return 0 ;;
    esac
    gr.msg -v2 -c gray "$_mode $_target_rc"

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


config.make_style_rc () {
# export color configuration for shell scripts"

    local _source_cfg="$1"  # source configuration file
    local _target_rc="$2"   # target rc file
    local _append_rc="$3"   # any input will set to append mode

    local _mode=">" ; [[ "$_append_rc" ]] && _mode=">>"

    [[ -f "$_source_cfg" ]] && source $_source_cfg || gr.msg -x 100 -red "$_source_cfg missing"

    gr.msg -n -v1 "setting color codes " ; gr.msg -v2
    gr.msg -v2 -c gray "$_source_cfg $_mode $_target_rc"
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
            gr.msg -n -v1 -V2 -c $color_name "."
            gr.msg -n -v2 -c $color_name "$color_name "
            # make style rc
            printf "\texport C_%s='%s'\n" "${color_name^^}" "$color"  >> $_target_rc
        done
    printf 'fi\n\n' >> $_target_rc
    gr.msg -v1 -c green " done"
}


config.export () {
# export global configuration in use

    source flag.sh

    local _target_rc=$HOME/.gururc
    local _target_user=$GURU_USER ; [[ "$1" ]] && _target_user="$1"

    flag.set pause
    sleep 2

    config.export_type_selector () {

            local _module_cfg="$1"
            gr.debug "looking configs for $_module_cfg"

            # configure file type is set in first line of config file after #!/bin/bash
            if [[ -f $_module_cfg ]] ; then
                case $(head -n 1 $_module_cfg) in
                    *"global"*)
                        echo "# from $_module_cfg" >>$_target_rc
                        config.make_rc "$_module_cfg" "$_target_rc" append \
                            || gr.msg -c red "error processing $_module_cfg" # TBD removed "-v1 -V2", test
                    ;;

                    *"module"*)
                        gr.msg -v2 -c dark_grey "$_module_cfg ..skipping module config files"
                    ;;

                    *"source"*)
                        gr.msg -v2 -c dark_grey "$_module_cfg ..no need to compile this type of configs"
                    ;;

                    *)
                        gr.msg -v2 -c yellow "$_module_cfg ..unknown config file type"
                esac
                fi
        }

    # make backup
    [[ -f "$_target_rc" ]] && mv -f "$_target_rc" "$_target_rc.old"

    # make header
        # write system configs to rc file
    printf "#!/bin/bash \n# guru-client runtime configurations auto generated at $(date)\nexport GURU_USER=$GURU_USER\n" > $_target_rc

    # add module lists made by installer to environment
    GURU_MODULES=( $(cat $GURU_CFG/installed.core) $(cat $GURU_CFG/installed.modules) )
    gr.msg -n -v1 "setting module information "
    gr.msg -N -v2 -c dark_grey "installed modules: '${GURU_MODULES[@]}'"
    echo "export GURU_MODULES=(${GURU_MODULES[@]})" >>$_target_rc
    if grep "export GURU_MODULES" "$_target_rc" >/dev/null ; then
        gr.msg -c green -V2 -v1 "done"
    else
        gr.msg -c red -V2 -v1 "failed"
    fi

    local installed_modules=($(cat $GURU_CFG/installed.core))
    installed_modules=(${installed_modules[@]} $(cat $GURU_CFG/installed.modules))

    local _module_cfg

    for module in ${installed_modules[@]} ; do

        ## add module default config
        _module_cfg="$GURU_CFG/$module.cfg"
        [[ -f $_module_cfg ]] && config.export_type_selector $_module_cfg

        ## add user config
        _module_cfg="$GURU_CFG/$GURU_USER/$module.cfg"
        [[ -f $_module_cfg ]] && config.export_type_selector $_module_cfg
    done

    config.make_style_rc "$GURU_CFG/rgb-color.cfg" "$_target_rc" append
    # set path
    echo "source $GURU_BIN/common.sh" >> $_target_rc
    echo "source $GURU_BIN/prompt.sh" >> $_target_rc
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
        flag.rm pause
    else
        gr.msg -c yellow "something went wrong, recovering old user configuration"
        [[ -f "$_target_rc.old" ]] && mv -f "$_target_rc.old" "$_target_rc" \
            || gr.msg -x 100 -c red "no old backup found, unable to recover"
        return 10
    fi
}


config.pull () {
# pull configuration files from server

    gr.msg -v1 -n -V2 "pulling $GURU_USER@$GURU_HOSTNAME configs.. "
    gr.msg -v2 -n "pulling configs from $GURU_ACCESS_USERNAME@$GURU_ACCESS_DOMAIN:/home/$GURU_ACCESS_USERNAME/usr/$GURU_HOSTNAME/$GURU_USER "
    local _error=0

    rsync -rav --quiet -e "ssh -p $GURU_ACCESS_PORT" \
        "$GURU_ACCESS_USERNAME@$GURU_ACCESS_DOMAIN:/home/$GURU_ACCESS_USERNAME/usr/$GURU_HOSTNAME/$GURU_USER/" \
        "$GURU_CFG/$GURU_USER"
    _error=$?

    if ((_error<9)) ; then
            gr.msg -c green "ok"
            return 0
        else
            gr.msg -c red "failed"
            return $_error
        fi
}


config.push () {
# save configuration to server

    gr.msg -v1 -n -V2 "pushing $GURU_USER@$GURU_HOSTNAME configs.. "
    gr.msg -v2 -n "pushing configs to $GURU_ACCESS_USERNAME@$GURU_ACCESS_DOMAIN:/home/$GURU_ACCESS_USERNAME/usr/$GURU_HOSTNAME/$GURU_USER "
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
            gr.msg -c green "ok"
            return 0
        else
            gr.msg -c red "failed"
            return $_error
        fi
}


config.edit () {
# edit user config file with preferred editor

    local _config_folder="$GURU_CFG/$GURU_USER"

    # if ! [[ -f $_config_file ]] ; then
    #     if gr.ask "user configuration fur user did not found, create local config for $GURU_USER" ; then
    #             mkdir -p $_config_file
    #             cp $GURU_CFG/user-default.cfg $_config_file
    #         fi
    #     fi

    $GURU_PREFERRED_EDITOR -n $_config_folder/*.cfg  || gr.msg -v2 -c yello "error while editing $_config_file.."
}


config.user () {
# open user dialog to make changes to user.cfg

    local _config_file=$GURU_CFG/$GURU_USER/user.cfg

    if ! [[ -f $_config_file ]] ; then
        if gr.ask "user configuration fur user did not found, create local config for $GURU_USER" ; then
                mkdir -p $_config_file
                cp $GURU_CFG/user-default.cfg $_config_file
            else
                return 0
            fi
        fi

    gr.msg -v1 "checking dialog installation.."
    dialog --version >>/dev/null || sudo apt install dialog

    # open temporary file handle and redirect it to stdout
    exec 3>&1
    _new_file="$(dialog --editbox "$GURU_CFG/$GURU_USER/user.cfg" "0" "0" 2>&1 1>&3)"
    return_code=$?
    # close new file handle
    exec 3>&-

    clear

    if (( return_code > 0 )) ; then
            gr.msg "nothing changed.."
            return 0
        fi

    if gr.ask "overwrite settings" ; then
            cp -f "$_config_file" "$GURU_CFG/$GURU_USER/user.cfg.backup"
            gr.msg "backup saved $GURU_CFG/$GURU_USER/user.cfg.backup"
            echo "$_new_file" >"$_config_file"
            gr.msg -c white "configure saved, taking configuration in use.."
            config.export
            #gr.msg -c white "to save new configuration to sever type: '$GURU_CALL config push'"
            config.push
        else
            gr.msg -c dark_golden_rod "ignored"
            gr.msg -c white "to get previous configurations from sever type: '$GURU_CALL config pull'"
        fi
    return 0
}


config.get (){
# get environmental value of variable

    [[ "$1" ]] && _variable="$1" || read -r -p "variable: " _variable
    set | grep "GURU_${_variable^^}" | head -1 | cut -d "=" -f2
    # set |grep "GURU_${_variable^^}"
    return $?
}


config.set () {
# change environment temporary

    [[ "$1" ]] && _variable="$1" || read -r -p "variable: " _variable
    [[ "$2" ]] && _value="$2" || read -r -p "$_variable value: " _value

    #if ! cat $GURU_RC | grep "GURU_${_variable^^}=" >/dev/null; then
    if ! grep "GURU_${_variable^^}=" -q $GURU_RC ; then
            gr.msg -c yellow "no variable 'GURU_${_variable^^}' found"
            return 2
        fi

    #local _found=$(cat $GURU_RC | grep "GURU_${_variable^^}=" | cut -d '=' -f 2)
    local _found=$(grep -q "GURU_${_variable^^}=" $GURU_RC | cut -d '=' -f 2)
    sed -i "s/GURU_${_variable^^}=.*/GURU_${_variable^^}='${_value}'/" $GURU_RC
    gr.msg -v1 "changing GURU_${_variable^^} from $_found to '$_value'"
    source $GURU_RC
    return 0
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
        source $GURU_RC
        config.main "$@"
    fi
