#!/bin/bash
# guru tool-kit config tools

source $GURU_BIN/tag.sh
source $GURU_BIN/mount.sh
source $GURU_BIN/lib/common.sh


config.main () {

    local _cmd="$1" ; shift
    case "$_cmd" in
                user)  config.user  ;;  # social media
                help)  config.help  ;;
                   *)  echo "unknown action $_cmd"
        esac
}


config.help () {
    echo "-- guru tool-kit config help -----------------------------------------------"
    printf "usage:\t %s config [action] <target> \n" "$GURU_CALL"
    printf "\nactions:\n"
    printf " user          open user config in dialog \n"
    printf " help          help printout \n"
    printf "\nexample:     %s config user \n" "$GURU_CALL"
}


guru tool-kit user configuration file
to send configurations to server type 'guru remote push' and
to get configurations from server type 'guru remote pull'
backup is kept at .config/guru/<user>/userrc.backup

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


if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
        source "$HOME/.gururc"
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