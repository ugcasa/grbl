#!/bin/bash
# guru-client config tools

source $GURU_BIN/common.sh
source $GURU_BIN/remote.sh

config.main () {

    local _cmd="$1" ; shift
    case "$_cmd" in
          get|set|user)  config.$_cmd $@                                  ; return $? ;;
              personal)  config.make_rc "$GURU_CFG/$GURU_USER_NAME/user.cfg" ; echo $GURU_REAL_NAME ;;
                export)  config.export $@                                 ; return $? ;;
             pull|push)  remote."$_cmd"_config $@                         ; return $? ;;
                  help)  config.help $@                                   ; return $? ;;
                status)  echo "no status data" ;;
                     *)  echo "unknown config action '$_cmd'"
                         GURU_VERBOSE=1
                         config.help $@                                   ; return $? ;;
        esac
}


config.help () {
    gmsg -v1 -c white "guru-client config help "
    gmsg -v2
    gmsg -v0 "usage:    $GURU_CALL config [action] <target> "
    gmsg -v2
    gmsg -v1 "actions:"
    gmsg -v1 " export        export userconfiguration to encironment"
    gmsg -v2 "               (run this every time configuration is changed) "
    gmsg -v1 " pull          poll user configuration from server "
    gmsg -v1 " push          push user configuration to server "
    gmsg -v2 " user          open user config in dialog "
    gmsg -v2 " help          help printout "
    gmsg -v2
    gmsg -v1 -c white "examples:"
    gmsg -v1 "     '$GURU_CALL config'                                 get current host and user settings"
    gmsg -v1 "     '$GURU_CALL pull -h <host_name> -u <user_name>'     get user and host spesific setting from server  "
    gmsg -v2 "                                                   useful when porting setting from computer to another or adding users"
    # guru-client user configuration file
    # to send configurations to server type 'guru remote push' and
    # to get configurations from server type 'guru remote pull'
    # backup is kept at .config/guru/<user>/userrc.backup
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
    [[ $_append_rc ]] || printf "#!/bin/bash \nexport GURU_USER=$GURU_USER\n" > $_target_rc

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

    #tr -d '\r' < $configfile > $user_source_cfg.unix
}

config.make_color_rc () {
    #export color config for shell scripts"
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
    local _target_rc="$HOME/.gururc2"
    local _target_user=$GURU_USER ; [[ "$1" ]] && _target_user="$1"

    # make backup
    [[ -f "$_target_rc" ]] && mv -f "$_target_rc" "$_target_rc.old"
    # make config<
    config.make_rc "$GURU_CFG/system.cfg" "$_target_rc"
    config.make_rc "$GURU_CFG/$_target_user/user.cfg" "$_target_rc" append
    config.make_color_rc "$GURU_CFG/rgb-color.cfg" "$_target_rc" append
    # check config
    if [[ "$_target_rc" ]] ; then
            # export configure
            chmod +x "$_target_rc"
            source "$_target_rc"
        else
            gmsg -c yellow "somethign went wrong, recovering old user configuration"
            [[ -f "$_target_rc.old" ]] && mv -f "$_target_rc.old" "$_target_rc" || gmsg -x 100 -c red "no old backup found, unable to recover"
            return 10
        fi
}


config.user () {
    exec 3>&1                   # open temporary file handle and redirect it to stdout
    _new_file="$(dialog --editbox "$GURU_SYSTEM_RC" "0" "0" 2>&1 1>&3)"
    return_code=$?              # store result value
    exec 3>&-                   # close new file handle

    read -n 1 -r -p "overwrite settings? : " _answ
    case "$_answ" in y) cp "$GURU_SYSTEM_RC" "$GURU_SYSTEM_RC.backup"
                        echo "$_new_file" >"$GURU_SYSTEM_RC"
                        printf "\nsaved\n"
                        echo "to save new configuration also to sever type: 'guru remote push'" ;;
                     *) printf "\nignored\n"
                        echo "to get previous configurations from sever type: 'guru remote pull'" ;;
                    esac
}


config.get (){              # get tool-kit environmental variable

    [ "$1" ] && _setting="$1" || read -r -p "setting to read: " _setting
    set |grep "GURU_${_setting^^}"
    #set |grep "GURU_${_setting^^}" |cut -c13-
    return $?
}


config.set () {             # set tool-kit environmental variable
    # set guru environmental funtions
    [ "$1" ] && _setting="$1" || read -r -p "setting to read: " _setting
    [ "$2" ] && _value="$2" || read -r -p "$_setting value: " _value

    [ -f "$GURU_SYSTEM_RC" ] && target_rc="$GURU_SYSTEM_RC" || target_rc="$HOME/.gururc"

    sed -i -e "/$_setting=/s/=.*/=$_value/" "$target_rc"                               # Ähh..
    msg "setting GURU_${_setting^^} to $_value\n"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
        #source "$HOME/.gururc2"
        config.main "$@"
    fi


  # --calendar     <text> <height> <width> <day> <month> <year>
  # --checklist    <text> <height> <width> <list height> <tag1> <item1> <status1>...
  # --dselect      <directory> <height> <width>
  # --editbox      <file> <height> <width>
  # --fselect      <filepath> <height> <width>
  # --gauge        <text> <height> <width> [<percent>]
  # --infobox      <text> <height> <width>
  # --inputbox     <text> <height> <width> [<init>]
  # --inputmenu    <text> <height> <width> <menu height> <tag1> <item1>...
  # --menu         <text> <height> <width> <menu height> <tag1> <item1>...
  # --msgbox       <text> <height> <width>
  # --passwordbox  <text> <height> <width> [<init>]
  # --pause        <text> <height> <width> <seconds>
  # --progressbox  <height> <width>
  # --radiolist    <text> <height> <width> <list height> <tag1> <item1> <status1>...
  # --tailbox      <file> <height> <width>
  # --tailboxbg    <file> <height> <width>
  # --textbox      <file> <height> <width>
  # --timebox      <text> <height> <width> <hour> <minute> <second>
  # --yesno        <text> <height> <width>




# config.make_rc () {
#     #shopt -s extglob
#     local _config_file="$1"       ; echo "input: $_config_file"
#     local _rc_file="$2"           ; echo "input: $_rc_file"

#     if ! [[ -f $_config_file ]] ; then NOTEXIST "$_config_file" ; return 100 ; fi
#     if [[ -f $_rc_file ]] ; then rm -f $_rc_file ; fi
#     #tr -d '\r' < $configfile > $_config_file.unix
#     while IFS='= ' read -r lhs rhs
#     do
#       if [[ ! $lhs =~ ^\ *# && -n $lhs ]]; then
#           rhs="${rhs%%\#*}"    # remove in line right comments
#           rhs="${rhs%%*( )}"   # remove trailing spaces
#           #rhs="${rhs%\"*}"     # remove opening string quotes
#           #rhs="${rhs#\"*}"     # remove closing string quotes
#           #echo "$lhs=$rhs"
#           #declare -x $lhs="$rhs"

#           echo "export $lhs=$rhs"

#       fi
#     done < $_config_file > $_rc_file
# }