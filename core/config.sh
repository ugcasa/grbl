#!/bin/bash
# guru-client config tools

source $GURU_BIN/tag.sh
source $GURU_BIN/mount.sh
source $GURU_BIN/common.sh
source $GURU_BIN/remote.sh

config.main () {

    local _cmd="$1" ; shift
    case "$_cmd" in
          get|set|user)  config.$_cmd $@                                  ; return $? ;;
              personal)  config.load "$GURU_CFG/$GURU_USER_NAME/user.cfg" ; echo $GURU_REAL_NAME ;;
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
    gmsg -v1 -c white "guru-client config help -----------------------------------------------"
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


config.load () {
    #shopt -s extglob ?
    local _config_file="$GURU_CFG/$GURU_USER/user.cfg"
    [[ "$1" ]] && _config_file="$1"

    local _rc_file="$GURU_USER_RC"
    [[ "$2" ]] && _rc_file="$2"

    [[ $GURU_VERBOSE ]] && msg "$_config_file > $_rc_file\n"
    if ! [[ -f $_config_file ]] ; then NOTEXIST "$_config_file" ; return 100 ; fi
    #if [[ -f $_rc_file ]] ; then rm -f $_rc_file ; fi

    echo "#!/bin/bash" > $_rc_file
    echo "export GURU_CALL=guru" >> $_rc_file
    echo "export GURU_BIN=$HOME/bin" >> $_rc_file
    echo "export GURU_CFG=$HOME/.config/guru" >> $_rc_file
    echo 'export GURU_HOSTNAME=$(hostname)' >> $_rc_file
    echo 'export GURU_MODULES=$(cat $GURU_CFG/installed.modules)' >> $_rc_file

    #tr -d '\r' < $configfile > $_config_file.unix
    while IFS='= ' read -r lhs rhs
    do
      if [[ ! $lhs =~ ^\ *# && -n $lhs ]]; then
          rhs="${rhs%%\#*}"    # remove in line right comments
          rhs="${rhs%%*( )}"   # remove trailing spaces
          case "$lhs" in
                *[*)  _chapter=${lhs//[}
                      _chapter=${_chapter//]}  ;;
                *)      echo "export GURU_${_chapter^^}_${lhs^^}=$rhs"
            esac

      fi
    done < $_config_file >> $_rc_file
}


config.export () {
    local _source_cfg="$GURU_CFG/GURU_USER_NAME/user.cfg"
    local _target_rc="$HOME/.gururc2"
    config.load "$_source_cfg" "$_target_rc"
    chmod +x $_target_rc
    source $_target_rc
}


config.user () {
    exec 3>&1                   # open temporary file handle and redirect it to stdout
    _new_file="$(dialog --editbox "$GURU_USER_RC" "0" "0" 2>&1 1>&3)"
    return_code=$?              # store result value
    exec 3>&-                   # close new file handle

    read -n 1 -r -p "overwrite settings? : " _answ
    case "$_answ" in y) cp "$GURU_USER_RC" "$GURU_USER_RC.backup"
                        echo "$_new_file" >"$GURU_USER_RC"
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

    [ -f "$GURU_USER_RC" ] && target_rc="$GURU_USER_RC" || target_rc="$HOME/.gururc"

    sed -i -e "/$_setting=/s/=.*/=$_value/" "$target_rc"                               # Ähh..
    msg "setting GURU_${_setting^^} to $_value\n"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
        source "$HOME/.gururc2"
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




# config.load () {
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