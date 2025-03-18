#!/bin/bash
# grbl configuration manager 2020 casa@ujo.guru

__config_color="green"
__config=$(readlink --canonicalize --no-newline $BASH_SOURCE)

config.help () {
# general help
    gr.msg -v4 -n -c $__config_color "$__config [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo $@ >&2
    case $1 in
        format|cfg|files)
            config.help_format
            return 0
    esac
    gr.msg -v1 "grbl config module help " -h
    gr.msg -v2
    gr.msg -v0 "usage:    $GRBL_CALL config pull|push|edit|export|user|get|set|help" -h
    gr.msg -v2
    gr.msg -v1 "commands:" -h
    gr.msg -v2
    gr.msg -v1 "  export                    set all core environment variables"
    gr.msg -v1 "  pull                      get user configuration from $GRBL_ACCESS_DOMAIN "
    gr.msg -v1 "  push                      push user configuration to $GRBL_ACCESS_DOMAIN "
    gr.msg -v1 "  enable <module>           enable module "
    gr.msg -v1 "  disable <module>          disable module "
    gr.msg -v1 "  dialog <module>           modify configurations in terminal dialog "
    gr.msg -v1 "  edit                      edit user config file with preferred editor "
    gr.msg -v2 "  edit <module1 module2>    edit configurations of following moudules "
    gr.msg -v1 "  change <m> <k> <v>        change variable in user configuration "
    gr.msg -v1 "  get <key>                 get single value from environment "
    gr.msg -v1 "  set <key> <value>         set value to current environment "
    gr.msg -v1 "  rm <key>                  remove key value pair from environment "
    gr.msg -v1 "  help                      try '$GRBL_CALL help -v2' full help" -V2
    gr.msg -v1 "  help format               config file format information"
    gr.msg -v2
    gr.msg -v1 "examples:" -h
    gr.msg -v2
    gr.msg -v2 "set user settings"
    gr.msg -v1 "  '$GRBL_CALL config user'"
    gr.msg -v2
    gr.msg -v2 "get user and host specific settings from server"
    gr.msg -v1 "  '$GRBL_CALL config pull -h <host_name> -u <user_name>'"
    gr.msg -v2
    gr.msg -v2 "set user name to permanent configuration"
    gr.msg -v1 "  '$GRBL_CALL config change user full_name Martti Servo'"
    gr.msg -v2
}

config.main () {
# main command parser
    gr.msg -v4 -n -c $__config_color "$__config [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo $@ >&2

    local _first="$1" ; shift
    case "$_first" in
            dialog|export|help|edit|get|set|save|rm|pull|push|list|change)
                    config.$_first $@
                    return $?
                    ;;
            status|log|debug)
                    gr.msg -c dark_grey "no $_first data"
                    ;;
            enable|active)
                    config.change $1 enabled true
                    ;;
            disable|disactive)
                    config.change $1 enabled false
                    ;;
                 "")
                    config.export
                    return $?
                    ;;
                 *)
                    config.edit $_first $@
                    return $?
                    ;;
        esac
}

config.make_rc () {
# make rc file out of configuration file
    gr.msg -v4 -n -c $__config_color "$__config [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo $@ >&2

    local _source_cfg="$1"  # source configuration file
    local _target_rc="$2"   # target rc file
    local _append_rc="$3"   # any input will set to append mode
    local _chapter=
    local _mode=">" ; [[ "$_append_rc" ]] && _mode=">>"

    gr.msg -n -v3 -c gray "$_source_cfg "

    if ! [[ -f $_source_cfg ]] ; then
        gr.msg -c yellow "$_source_cfg not found"
        return 100
    fi

    case $(head -n 1 $_source_cfg) in
        *"source"*) gr.msg -v3 -c dark_grey "..no need to compile this type of configs"
        return 0 ;;
    esac

    gr.msg -v3 -c gray "$_mode $_target_rc"

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
                *)    echo "export GRBL_${_chapter^^}${lhs^^}=$rhs"
            esac
      fi
    done < $_source_cfg >> $_target_rc
    chmod +x $_target_rc
    return $?
}


config.make_style_rc () {
# export color configuration for shell scripts
    gr.msg -v4 -n -c $__config_color "$__config [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo $@ >&2

    local _source_cfg="$1"  # source configuration file
    local _target_rc="$2"   # target rc file
    local _append_rc="$3"   # any input will set to append mode

    local _mode=">" ; [[ "$_append_rc" ]] && _mode=">>"

    [[ -f "$_source_cfg" ]] && source $_source_cfg || gr.msg -x 100 -red "$_source_cfg missing"

    gr.msg -n -v1 "setting color codes " ; gr.msg -v2
    gr.msg -v2 -c gray "$_source_cfg $_mode $_target_rc"
    [[ $_append_rc ]] || echo "#!/bin/bash" > $_target_rc
    printf 'if [[ "$GRBL_FLAG_COLOR" ]] ; then \n' >> $_target_rc
    printf "\texport C_NORMAL=%s\n" "'\033[0m'"  >> $_target_rc
    printf "\texport C_HEADER=%s\n" "'\033[1;37m'" >> $_target_rc
    # parse trough color strings
    color_name_list=$(set | grep rgb_ | grep -v grep | grep -v "   " ) # ; echo "$color_name_list"
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
        # compose color code
        color=$(printf '\033[38;2;%s;%s;%sm' "$_r" "$_g" "$_b")
        color=${color//''/'\033'}  # bubble cum
        # printout
        #echo -e "$color $color_name $color_value"
        gr.msg -n -v1 -V2 -c $color_name "."
        gr.msg -n -v2 -c $color_name "$color_name "
        # make style rc
        printf "\texport C_%s='%s'\n" "${color_name^^}" "$color"  >> $_target_rc
    done
    local srt_list=${color_list[@]}
    printf "\texport GRBL_COLOR_LIST=(%s)\n" "${srt_list}" >> $_target_rc
    printf 'fi\n\n' >> $_target_rc
    gr.msg -v1 -c green " done"
}


config.export () {
# make .grblrc

    gr.msg -v4 -n -c $__config_color "$__config [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo $@ >&2

    source flag.sh

    local _target_rc=$HOME/.grblrc
    local _target_user=$GRBL_USER ; [[ "$1" ]] && _target_user="$1"

    flag.set pause
    sleep 2

    config.export_type_selector () {
        gr.msg -v4 -n -c $__config_color "$__config [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo $@ >&2

        local _module_cfg="$1"
        gr.debug "looking configs for $_module_cfg"

        # configure file type is set in first line of config file after #!/bin/bash
        if [[ -f $_module_cfg ]] ; then
            case $(head -n 1 $_module_cfg) in
                *"global"*)
                    echo "# from $_module_cfg" >>$_target_rc
                    config.make_rc "$_module_cfg" "$_target_rc" append \
                        || gr.msg -c red "error processing $_module_cfg"
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
    printf "#!/bin/bash \n# grbl runtime configurations auto generated at $(date)\nexport GRBL_USER=$GRBL_USER\n" > $_target_rc

    # add module lists made by installer to environment
    GRBL_MODULES=( $(cat $GRBL_CFG/installed.core) $(cat $GRBL_CFG/installed.modules) )
    gr.msg -n -v1 "setting module information "
    gr.msg -N -v2 -c dark_grey "installed modules: '${GRBL_MODULES[@]}'"
    echo "export GRBL_MODULES=(${GRBL_MODULES[@]})" >>$_target_rc
    if grep "export GRBL_MODULES" "$_target_rc" >/dev/null ; then
        gr.msg -c green -V2 -v1 "done"
    else
        gr.msg -c red -V2 -v1 "failed"
    fi

    local installed_modules=($(cat $GRBL_CFG/installed.core))
    installed_modules=(${installed_modules[@]} $(cat $GRBL_CFG/installed.modules))

    local _module_cfg

    for module in ${installed_modules[@]} ; do

        ## add module default config
        _module_cfg="$GRBL_CFG/$module.cfg"
        [[ -f $_module_cfg ]] && config.export_type_selector $_module_cfg

        ## add user config
        _module_cfg="$GRBL_CFG/$GRBL_USER/$module.cfg"
        [[ -f $_module_cfg ]] && config.export_type_selector $_module_cfg
    done

    config.make_style_rc "$GRBL_CFG/rgb-color.cfg" "$_target_rc" append

    # autocomplete of core module
    echo 'list="${GRBL_MODULES[@]}"' >>$_target_rc
    echo 'complete -W "$list" $GRBL_CALL' >>$_target_rc
    echo 'complete -W "$list" $GRBL_SYSTEM_ALIAS' >>$_target_rc

    # make basic functions always available
    echo "source $GRBL_BIN/common.sh" >> $_target_rc
    echo "source $GRBL_BIN/prompt.sh" >> $_target_rc
    echo "source $GRBL_BIN/alias.sh" >> $_target_rc

    # check and load configuration
    if [[ "$_target_rc" ]] ; then
        # export configure
        chmod +x "$_target_rc"
        source "$_target_rc"

        # initialize corsair profile
        if [[ $GRBL_CORSAIR_ENABLED ]] ; then
            source $GRBL_BIN/corsair.sh
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
    gr.msg -v4 -n -c $__config_color "$__config [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo $@ >&2

    gr.debug "$FUNCNAME: rsync -rav --quiet -e ssh -p $GRBL_ACCESS_PORT \
              $GRBL_ACCESS_USERNAME@$GRBL_ACCESS_DOMAIN:/home/$GRBL_ACCESS_USERNAME/grbl/config/$GRBL_HOSTNAME/$GRBL_USER/ \
              $GRBL_CFG/$GRBL_USER"

    gr.msg -v1 -n -V2 "pulling $GRBL_USER@$GRBL_HOSTNAME configs.. "
    gr.msg -v2 -n "pulling configs from $GRBL_ACCESS_USERNAME@$GRBL_ACCESS_DOMAIN:/home/$GRBL_ACCESS_USERNAME/grbl/config/$GRBL_HOSTNAME/$GRBL_USER "
    local _error=0


    rsync -rav --quiet -e "ssh -p $GRBL_ACCESS_PORT" \
        "$GRBL_ACCESS_USERNAME@$GRBL_ACCESS_DOMAIN:/home/$GRBL_ACCESS_USERNAME/grbl/config/$GRBL_HOSTNAME/$GRBL_USER/" \
        "$GRBL_CFG/$GRBL_USER"
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
    gr.msg -v4 -n -c $__config_color "$__config [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo $@ >&2

    gr.debug "$FUNCNAME: rsync -rav --quiet -e ssh -p $GRBL_ACCESS_PORT $GRBL_CFG/$GRBL_USER/ \
              $GRBL_ACCESS_USERNAME@$GRBL_ACCESS_DOMAIN:/home/$GRBL_ACCESS_USERNAME/grbl/config/$GRBL_HOSTNAME/$GRBL_USER/"

    gr.msg -v1 -n -V2 "pushing $GRBL_USER@$GRBL_HOSTNAME configs.. "
    gr.msg -v2 -n "pushing configs to $GRBL_ACCESS_USERNAME@$GRBL_ACCESS_DOMAIN:/home/$GRBL_ACCESS_USERNAME/grbl/config/$GRBL_HOSTNAME/$GRBL_USER "
    local _error=0

    # "if not"
    ssh "$GRBL_ACCESS_USERNAME@$GRBL_ACCESS_DOMAIN" \
        -p "$GRBL_ACCESS_PORT" \
        ls "/home/$GRBL_ACCESS_USERNAME/grbl/config/$GRBL_HOSTNAME/$GRBL_USER" >/dev/null 2>&1 || \
        # "then"
        ssh "$GRBL_ACCESS_USERNAME@$GRBL_ACCESS_DOMAIN" \
            -p "$GRBL_ACCESS_PORT" \
            mkdir -p "/home/$GRBL_ACCESS_USERNAME/grbl/config/$GRBL_HOSTNAME/$GRBL_USER"
        # "fi"

    rsync -rav --quiet -e "ssh -p $GRBL_ACCESS_PORT" \
        "$GRBL_CFG/$GRBL_USER/" \
        "$GRBL_ACCESS_USERNAME@$GRBL_ACCESS_DOMAIN:/home/$GRBL_ACCESS_USERNAME/grbl/config/$GRBL_HOSTNAME/$GRBL_USER/"

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
    gr.msg -v4 -n -c $__config_color "$__config [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo $@ >&2

    local module_list=($@)
    local file_list=()
    local default_configs=($(find $GRBL_CFG/*cfg $GRBL_CFG/*list -maxdepth 1 -type f -path '*/\.*'))

    if [[ -d $GRBL_CFG/$GRBL_USER ]] ; then
        local user_configs=($(find $GRBL_CFG/$GRBL_USER/*cfg $GRBL_CFG/$GRBL_USER/*list -maxdepth 1 -type f -path '*/\.*'))
    else
        gr.msg -c yellow "user configuration not found"
        gr.msg -v2 "to create it copy $GRBL_CFG/${module}.cfg to $GRBL_CFG/$GRBL_USER/${module}.cfg"
    fi

    # files given as arguments or find all config files
    if [[ ${module_list[0]} ]] ; then

        gr.debug "got a list of module names: ${module_list[@]}"

        # check module config exist
        for module in ${module_list[@]} ; do
            if [[ -f "$GRBL_CFG/$GRBL_USER/${module}.cfg" ]]; then
                file_list+=("$GRBL_CFG/$GRBL_USER/${module}.cfg")
            else
                # TBD if module exits and config does not ask to create config
                gr.msg -e1 "no config found $GRBL_PREFERRED_EDITOR $GRBL_CFG/$GRBL_USER/${module}.cfg"
            fi
        done
        # open configs to new editor window
        $GRBL_PREFERRED_EDITOR -n ${file_list[@]}
        return $?
    else
        gr.debug "no module list: ${module_list[@]}"
        # collect found files
        local list_of_files=(${user_configs[@]} ${default_configs[@]})
        # sort files to
        readarray -t sortedfilearr < <(printf '%s\n' "${list_of_files[@]}" | awk -F'/' '
           BEGIN{PROCINFO["sorted_in"]="@val_num_asc"}
           { a[$0]=$NF }
           END{ for(i in a) print i}')

        gr.debug "opening for edit: ${sortedfilearr[*]}"
        # Thanks RomanPerekhrest https://unix.stackexchange.com/questions/393987
        $GRBL_PREFERRED_EDITOR -n ${sortedfilearr[*]}
        return $?
    fi
}


config.list() {

    gr.msg -v4 -n -c $__config_color "$__config [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo $@ >&2
    IFS=$'\n'
    local search_term=""

    # check if user input module name or search term
    if [[ $1 ]] ; then
        if [[ " ${GRBL_MODULES[@]} " =~ " $1 " ]] ; then
            search_term="$1_"
        else
            search_term="$1"
        fi
        shift
    fi

    # search variables
    local global_variables=($(declare -xp | grep "GRBL_${search_term^^}" | cut -d" " -f3-))

    # go trough got grbl variables
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


config.dialog () {
# open user dialog to make changes to configurations
    gr.msg -v4 -n -c $__config_color "$__config [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo $@ >&2

    local module=user
    [[ $1 ]] && module=$1
    local target_config=$GRBL_CFG/$GRBL_USER/$module.cfg

    if ! [[ $target_config ]] ; then
        gr.ask "configuration file does not exist, create?" || return 0
        printf '%s\n\n' "# grbl configuration file for $module module at $(date)" >$target_config
        printf '%s\n%s\n' "[$module]" >>$target_config
    fi
    gr.msg -v2 "checking dialog installation.."
    dialog --version >>/dev/null || sudo apt install dialog

    # open temporary file handle and redirect it to std out
    exec 3>&1
    _new_file="$(dialog --editbox "$GRBL_CFG/$GRBL_USER/$module.cfg" "0" "0" 2>&1 1>&3)"
    return_code=$?

    # close new file handle
    exec 3>&-
    clear

    if (( return_code > 0 )) ; then
            gr.msg "nothing changed.."
            return 0
        fi

    cp -f "$target_config" "$GRBL_CFG/$GRBL_USER/$module.cfg.backup" && \
        gr.msg -v2 "backup saved $GRBL_CFG/$GRBL_USER/$module.cfg.backup"

    echo "$_new_file" >"$target_config" && \
        gr.msg "$GRBL_CFG/$GRBL_USER/$module.cfg saved"

    if gr.ask "take settings in use?" ; then
        gr.msg -c white "configure saved, taking configuration in use.."
        config.export
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
    return=$(declare -xp | grep "GRBL_${key^^}" | head -n1 |cut -d" " -f3-)
    gr.debug "$return"
    gr.msg "$(cut -d"=" -f2 <<<$return)"
    return $?
}


config.set () {
# change environment temporary
    gr.msg -v4 -n -c $__config_color "$__config [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo $@ >&2

    [[ "$1" ]] && _config_file="$1" || read -r -p "cfg file: " _config_file ; shift
    [[ "$1" ]] && _variable="$1" || read -r -p "variable: " _variable ; shift
    [[ "$1" ]] && _value="$@"

    #if ! cat $GRBL_RC | grep "GRBL_${_variable^^}=" >/dev/null; then
    if ! grep "GRBL_${_variable^^}=" -q  $_config_file ; then
        gr.msg -v4 -c yellow "variable 'GRBL_${_variable^^}' not found"
        gr.msg -v4 "setting GRBL_${_variable^^} to '$_value'"
        echo "GRBL_${_variable^^}=${_value}" >> $_config_file
    fi

    local _found=$(grep "GRBL_${_variable^^}="  $_config_file | cut -d '=' -f 2)
    sed -i "s/GRBL_${_variable^^}=.*/GRBL_${_variable^^}='${_value}'/"  $_config_file

    gr.msg -v2 "changing GRBL_${_variable^^} from $_found to '$_value'"
    source  $_config_file
    return 0
}

config.save () {
# change or add permanent configuration
    gr.msg -v4 -n -c $__config_color "$__config [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo $@ >&2

    [[ "$1" ]] && _config_file="$1" || read -r -p "cfg file: " _config_file ; shift
    [[ "$1" ]] && _variable="$1" || read -r -p "variable: " _variable ; shift
    [[ "$1" ]] && _value="$@" # value can be set empty in bash '' is "false"

    # check is key in configuration
    if grep "${_variable}=" -q $_config_file ; then
    # exist, change value
        local _found=$(grep "${_variable}=" $_config_file | cut -d '=' -f 2)
        gr.msg -v2 "changing ${_variable} from ${_found} to '${_value}'"
        sed -i "s/${_variable}=.*/${_variable}='${_value}'/" $_config_file || return 100
    else
    # non exist, add key/value pair
        gr.msg -v2 -c yellow "variable '$_variable' not found, adding new key/value pair"
        echo "${_variable}=${_value}" >>$_config_file || return 100
    fi
    return 0
}

config.rm () {
# change environment temporary
    gr.msg -v4 -n -c $__config_color "$__config [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo $@ >&2

    [[ "$1" ]] && _variable="$1" || read -r -p "variable: " _variable ; shift
    [[ "$1" ]] && _value="$@"

    #if ! cat $GRBL_RC | grep "GRBL_${_variable^^}=" >/dev/null; then
    if grep "GRBL_${_variable^^}=" -q $GRBL_RC ; then
        if gr.ask "remove key value pair 'GRBL_${_variable^^}=${_value}' ? " ; then
            sed -i "s/GRBL_${_variable^^}=.*//" $GRBL_RC
            return 0
        else
            return 1
        fi
    else
        gr.msg -v2 -c yellow "variable 'GRBL_${_variable^^}' not found"
    fi
}


config.change () {
# change configuration value in configuration file.
# GRBL_MODULE_KEY='value' Global variables do not include module name.
# Value are optional, key is needed and module needs placeholder.
# Target is user configuration in ~/.config/grbl/<USER_NAME>
# Default configuration is kept in ~/.config/grbl and is overwritten during installation

    gr.msg -v4 -n -c $__config_color "$__config [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo $@ >&2

    local module=$1 ; shift
    local key=$1 ; shift
    local value="$@"
    local target_config=

    # Check is user name and config folder variables filled
    if ! [[ $GRBL_USER_NAME ]] || ! [[ -d $GRBL_CFG ]];  then
        gr.msg "user '$GRBL_USER_NAME' is not filled or config folder '$GRBL_CFG', \
                assuming that grbl is not in installed/in use, exiting.."
        # 101: grbl not in use
        return 101
    fi

    # re-ask module name if not given. Set module to system if still left empty
    [[ $module ]] || read -p "please insert target module name (if global variable, leave empty): " module
    [[ $module ]] || module="system"

    # check is user module name, can be empty when setting global variables GRBL_KEY
    if ! [[ "$module" == "system" ]] && ! [[ " ${GRBL_MODULES[@]} " =~ " $module " ]]; then
        gr.msg -c error "module '$module' does not exist"
        return 102
    fi

    # ask user to fulfill key name. GRBL_MODULE_KEY or GRBL_KEY
    [[ $key ]] || read -p "please insert key name: " key
    if ! [[ $key ]] ; then
        gr.msg -c error "key cannot be empty"
        return 103
    fi

    # in bash 'false' is empty, therefore value can be empty
    # [[ $value ]] || read -p "please insert value: " value

    # header is not in use, did not found easy method to parse file under wanted header
    target_config="$GRBL_CFG/$GRBL_USER_NAME/$module.cfg"
    # [[ $module == "system" ]] || [[ $module == "user" ]] || header="$module"

    # all needed variables filled, print is these out for debug use
    gr.debug "$FUNCNAME: file:'$target_config', module:'$module', key:'$key', value:'$value'"

    # check configuration file is created
    if [[ -f $target_config ]]; then

        # create list of matches
        IFS=$'\n'
        match=($(grep "${key}" $target_config))
        if [[ ${#match[@]} -gt 1 ]] ; then

            # go trough matched lines and printout list with numbers
            for (( i = 0; i < ${#match[@]}; i++ )); do
                gr.msg -n -h "$i: "
                gr.msg -n -c list "$(cut -d"=" -f1 <<<${match[$i]})"
                gr.msg -n -c dark_grey "="
                gr.msg -c aqua "$(cut -d"=" -f2 <<<${match[$i]})"
            done
            read -p "multiple matches, please select: " ans

            # ask user to select line or quit
            case $ans in q*) return 0 ;; esac
            if [[ $ans -ge 0 ]] && [[ $ans -lt ${#match[@]} ]] ; then

                # printout for debug and change matching line
                gr.debug "$FUNCNAME command: sed -i s/${match[$ans]}/$(cut -d= -f1 <<<${match[$ans]})='${value}'/ $target_config"
                sed -i "s/${match[$ans]}/$(cut -d"=" -f1 <<<${match[$ans]})='${value}'/" $target_config
                return 0
            else
                gr.msg -c error "non valid answer, canceling.. "
                return 1
            fi
        fi

        # change value to nothing if set false
        case $value in
            false|disabled|disable|off|falce|null)
                value=
        esac

        # in case where there is only on matching line, just change it
        gr.debug "$FUNCNAME command: sed -i s/${key}=.*/${key}='${value}'/ $target_config"
        sed -i "s/${key}=.*/${key}='${value}'/" $target_config
    else
    # create configuration file from // better to use template from parent directory?
        gr.msg -n "$target_config does not exist, creating.. "

        if touch $target_config ; then
            printf '%s\n\n' "# grbl configuration file for $module module at $(date)" >$target_config
            printf '%s\n%s\n' "[$module]" "$key='$value'" >>$target_config
            gr.msg -c green "ok"
        else
            gr.msg -c error "error $? when creating file: $target_config"
            return 110
        fi
    fi
}


config.help_format() {
    gr.msg -v1 "grbl configuration file format information " -h
    gr.msg -v4 -n -c $__config_color "$__config [$LINENO] $FUNCNAME: " >&2 ; [[ $GRBL_DEBUG ]] && echo $@ >&2
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
    echo '$'{GRBL_AI_ENABLED}  # "true"
    echo '$'{GRBL_AI_INDICATOR_KEY}  # "f6"

    Configuration file should contain configuration type
    information in second column of first line.

    Example '#!/bin/bash source' or '#!/bin/bash module'
    (where '#!/bin/bash' is just for syntax higlighting in editors.)
EOL
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
    config.main "$@"
else
    gr.msg -v4 -c $__config_color "$__config [$LINENO] sourced " >&2
fi


