#!/bin/bash
# guru-client configuration manager 2020 casa@ujo.guru

config.help () {
# general help

    case $1 in
        format|cfg|files)
            config.help_format
            return 0
    esac

    gr.msg -v1 "guru-client config module help " -h
    gr.msg -v2
    gr.msg -v0 "usage:    $GURU_CALL config pull|push|edit|export|user|get|set|help" -h
    gr.msg -v2
    gr.msg -v1 "commands:" -h
    gr.msg -v2
    gr.msg -v1 "  export         export configuration to environment"
    gr.msg -v1 "  pull           poll user configuration from server"
    gr.msg -v1 "  push           push user configuration to server"
    gr.msg -v1 "  user           open user configuration in dialog"
    gr.msg -v1 "  edit           edit user config file with preferred editor"
    gr.msg -v1 "  change         change variable in user configuration "
    gr.msg -v2 "    <module> <key> <value>"
    gr.msg -v1 "  get            get single value from environment"
    gr.msg -v2 "    <key>"
    gr.msg -v1 "  set            set value to user config and current environment"
    gr.msg -v2 "    <key> <value>"
    gr.msg -v1 "  rm             remove key value pair from environment"
    gr.msg -v2 "    <key>"
    gr.msg -v1 "  help           try '$GURU_CALL help -v2' full help" -V2
    gr.msg -v1 "  help format    config file format information"
    gr.msg -v2
    gr.msg -v1 "examples:" -h
    gr.msg -v2
    gr.msg -v2 "set user settings"
    gr.msg -v1 "  '$GURU_CALL config user'"
    gr.msg -v2
    gr.msg -v2 "get user and host specific settings from server"
    gr.msg -v1 "  '$GURU_CALL config pull -h <host_name> -u <user_name>'"
    gr.msg -v2
    gr.msg -v2 "set user name to permanent configuration"
    gr.msg -v1 "  '$GURU_CALL config change user full_name Martti Servo'"
    gr.msg -v2
}


config.main () {
# main comman parser
    local _cmd="$1" ; shift
    case "$_cmd" in
            user|export|help|edit|get|set|rm|pull|push|list|change)
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
    color_list=()
    for color_srt in ${color_name_list[@]} ; do
            # color name
            color_name=$(echo $color_srt | cut -f1 -d "=") # ; echo "$color_srt"
            color_name=${color_name//"rgb_"/""} # ; echo "$color_name"
            color_list+=("$color_name")
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
    local srt_list=${color_list[@]}
    printf "\texport GURU_COLOR_LIST=(%s)\n" "${srt_list}" >> $_target_rc
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
                        gr.msg -v3 -c dark_grey "$_module_cfg ..skipping module config files"
                    ;;

                    *"source"*)
                        gr.msg -v3 -c dark_grey "$_module_cfg ..no need to compile this type of configs"
                    ;;

                    *)
                        gr.msg -v1 -c yellow "$_module_cfg ..unknown config file type"
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

    gr.debug "$FUNCNAME: rsync -rav --quiet -e ssh -p $GURU_ACCESS_PORT \
              $GURU_ACCESS_USERNAME@$GURU_ACCESS_DOMAIN:/home/$GURU_ACCESS_USERNAME/usr/$GURU_HOSTNAME/$GURU_USER/ \
              $GURU_CFG/$GURU_USER"

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

    gr.debug "$FUNCNAME: rsync -rav --quiet -e ssh -p $GURU_ACCESS_PORT $GURU_CFG/$GURU_USER/ \
              $GURU_ACCESS_USERNAME@$GURU_ACCESS_DOMAIN:/home/$GURU_ACCESS_USERNAME/usr/$GURU_HOSTNAME/$GURU_USER/"

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

    local default_configs=($(find $GURU_CFG/*cfg $GURU_CFG/*list -maxdepth 1 -type f -path '*/\.*'))

    if [[ -d $GURU_CFG/$GURU_USER ]] ; then
        local user_configs=($(find $GURU_CFG/$GURU_USER/*cfg $GURU_CFG/$GURU_USER/*list -maxdepth 1 -type f -path '*/\.*'))
    else
        gr.msg -c yellow "user configuration not found"
    fi

    local list_of_files=(${user_configs[@]} ${default_configs[@]})

    readarray -t sortedfilearr < <(printf '%s\n' "${list_of_files[@]}" | awk -F'/' '
       BEGIN{PROCINFO["sorted_in"]="@val_num_asc"}
       { a[$0]=$NF }
       END{ for(i in a) print i}')

    gr.debug "${sortedfilearr[*]} Thanks RomanPerekhrest https://unix.stackexchange.com/questions/393987"
    $GURU_PREFERRED_EDITOR -n ${sortedfilearr[*]}
}


config.list() {

    IFS=$'\n'
    local search_term=""

    # check if user input module name or search term
    if [[ $1 ]] ; then
        if [[ " ${GURU_MODULES[@]} " =~ " $1 " ]] ; then
            search_term="$1_"
        else
            search_term="$1"
        fi
        shift
    fi

    # search variables
    local global_variables=($(declare -xp | grep "GURU_${search_term^^}" | cut -d" " -f3-))

    # go trough got guru variables
    for variable in ${global_variables[@]} ; do

        key=$(cut -d"=" -f1 <<< $variable)
        value=$(cut -d"=" -f2- <<< $variable)

        # printout key differently depending verbose level
        gr.msg -v1 -V2 -n -c list "$key "
        gr.msg -v2 -V3 -n -c list "$key"
        gr.msg -v3 -n -c list "$key "
        gr.msg -v2 -n -c dark_grey "="
        gr.msg -v3 -n -c list " "

        #printout key
        gr.msg -c white "$value"
    done
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

    IFS=$'\n'
    local key=""

    # check if user input module name or search term
    if [[ $1 ]] ; then
        key="$1"
        shift
    else
        read -r -p "key: " key
    fi

    # get first match
    return=$(declare -xp | grep "GURU_${key^^}" | head -n1 |cut -d" " -f3-)
    gr.debug "$return"
    gr.msg "$(cut -d"=" -f2 <<<$return)"
    return $?
}


config.set () {
# change environment temporary

    [[ "$1" ]] && _variable="$1" || read -r -p "variable: " _variable ; shift
    [[ "$1" ]] && _value="$@"

    #if ! cat $GURU_RC | grep "GURU_${_variable^^}=" >/dev/null; then
    if ! grep "GURU_${_variable^^}=" -q $GURU_RC ; then
            gr.msg -v2 -c yellow "variable 'GURU_${_variable^^}' not found"
            if gr.ask "add new temporary key value pair 'GURU_${_variable^^}=${_value}' ? " ; then
                gr.msg -v2 "setting GURU_${_variable^^} to '$_value'"
                echo "GURU_${_variable^^}=${_value}" >>$GURU_RC
                return 0
            else
                return 1
            fi
        fi

    local _found=$(grep "GURU_${_variable^^}=" $GURU_RC | cut -d '=' -f 2)
    sed -i "s/GURU_${_variable^^}=.*/GURU_${_variable^^}='${_value}'/" $GURU_RC

    gr.msg -v2 "changing GURU_${_variable^^} from $_found to '$_value'"
    source $GURU_RC
    return 0
}


config.rm () {
# change environment temporary

    [[ "$1" ]] && _variable="$1" || read -r -p "variable: " _variable ; shift
    [[ "$1" ]] && _value="$@"

    #if ! cat $GURU_RC | grep "GURU_${_variable^^}=" >/dev/null; then
    if grep "GURU_${_variable^^}=" -q $GURU_RC ; then
        if gr.ask "remove key value pair 'GURU_${_variable^^}=${_value}' ? " ; then
            sed -i "s/GURU_${_variable^^}=.*//" $GURU_RC
            return 0
        else
            return 1
        fi
    else
        gr.msg -v2 -c yellow "variable 'GURU_${_variable^^}' not found"
    fi
}


config.change () {
#  change user configuration value

    local module=$1
    shift
    local key=$1
    shift
    local value="$@"

    if ! [[ $GURU_USER_NAME ]] || ! [[ -d $GURU_CFG ]];  then
        gr.msg "user '$GURU_USER_NAME' is not filled or config folder '$GURU_CFG', assuming that guru is not in installed/in use, exiting.."
        return 101
    fi

    [[ $module ]] || read -p "please insert target module name (if global variable, leave empty): " module
    [[ $module ]] || module="user"

    # check if user input module name or search term
    if ! [[ "$module" == "system" ]] && ! [[ " ${GURU_MODULES[@]} " =~ " $module " ]]; then
        gr.msg -c error "module '$module' does not exist"
        return 102
    fi

    [[ $key ]] || read -p "please insert key name: " key
    if ! [[ $key ]] ; then
        gr.msg -c error "key cannot be empty"
        return 103
    fi

    #[[ $value ]] || read -p "please insert value: " value

    if [[ -f $GURU_CFG/$GURU_USER_NAME/$module.cfg ]]; then
        local target_config="$GURU_CFG/$GURU_USER_NAME/$module.cfg"
    else
        local target_config="$GURU_CFG/$module.cfg"
    fi

    [[ $module == "system" ]] || [[ $module == "user" ]] || header="$module"

    gr.debug "$FUNCNAME: file:'$target_config', module:'$module', header:'$header', key:'$key', value:'$value'"

    if [[ -f $target_config ]]; then

        IFS=$'\n'
        match=($(grep "${key}" $target_config))
        if [[ ${#match[@]} -gt 1 ]] ; then
            for (( i = 0; i < ${#match[@]}; i++ )); do
                gr.msg -n -h "$i: "
                gr.msg -n -c list "$(cut -d"=" -f1 <<<${match[$i]})"
                gr.msg -n -c dark_grey "="
                gr.msg -c aqua "$(cut -d"=" -f2 <<<${match[$i]})"
            done
            read -p "multiple matches, please select: " ans
            case $ans in q*) return 0 ;; esac
            if [[ $ans -ge 0 ]] && [[ $ans -lt ${#match[@]} ]] ; then

                gr.debug "$FUNCNAME command: sed -i s/${match[$ans]}/$(cut -d= -f1 <<<${match[$ans]})='${value}'/ $target_config"
                sed -i "s/${match[$ans]}/$(cut -d"=" -f1 <<<${match[$ans]})='${value}'/" $target_config
                return 0
            else
                gr.msg -c error "non valid answer, canceling.. "
                return 1
            fi
        fi

        gr.debug "$FUNCNAME command: sed -i s/${key}=.*/${key}='${value}'/ $target_config"
        sed -i "s/${key}=.*/${key}='${value}'/" $target_config
    else
        gr.msg -n "$target_config does not exist, creating.. "
        if touch $target_config ; then
            echo "# $target_config $'\n'# guru-cli configuration file for $module module at $(date)" >$target_config
            echo "[$header]$'\n'$key=$value$'\n'" >>$target_config
            gr.msg -c green "ok"
        else
            gr.msg -c error "error $? when creating file: $target_config"
            return 110
        fi
    fi
}


config.help_format() {
    gr.msg -v1 "guru-client configuration file format information " -h
    cat << EOL

    Two different configuration file types are supported.

    "Sourced" configs are declared in module script.
    .cfg file is sourced to fulfill variables.

    # sourced configs: add declaration to module script header
    declare -A access

    # and fill variables in cfg file
    access[domain_name]=
    access[domain_port]=

    # sourced configs usage in script  (sorry for '')
    echo '$'{access[domain_name]}

    "Module" configs are translated to rc file in temp
    that is updated in every run if config file is changed.

    # module configs are xxx type config files
    # config.make_rc will convert configs to rc
    [ai]
    enabled=true
    indicator_key=f6

    # usage in module script
    # following variables are exported to environment during module start
    echo '$'{GURU_AI_ENABLED}  # "true"
    echo '$'{GURU_AI_INDICATOR_KEY}  # "f6"

    Configuration file should contain configuration type
    information in second column of first line.

    Example '#!/bin/bash source' or '#!/bin/bash module'
    (where '#!/bin/bash' is just for syntax higlighting in editors.)
EOL
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
        #source $GURU_RC
        config.main "$@"
    fi


