#!/bin/bash
# grbl android phone tools
# get files from android phone by connecting sshd running on phone
# install this to android phone: https://play.google.com/store/apps/details?id=com.theolivetree.sshserver

source mount.sh
source tag.sh

android_verb="-q"
if ((GRBL_VERBOSE>2)) ; then android_verb="-v" ; fi
    # TBD other way around
android_first_time="$HOME/.data/android-suveren"
    # TBD to ram
android_temp_folder="/tmp/$USER/grbl/android"
android_server_url="https://play.google.com/store/apps/details?id=com.theolivetree.sshserver"

    # TBD user.cfg based shit
android_config_file="$GRBL_CFG/android.locations.cfg"
    # TBD file tools
    # gr.msg -v2  " get /folder         download whole folder "
    # gr.msg -v2  " get /folder/file.md download single folder "
    # gr.msg -v2  " get /folder/file*   download single folder "

android.main () {

      [[ $GRBL_ANDROID_LAN_IP ]] || read -p "phone ip: "     GRBL_ANDROID_LAN_IP
    [[ $GRBL_ANDROID_LAN_PORT ]] || read -p "sshd port: "    GRBL_ANDROID_LAN_PORT
    [[ $GRBL_ANDROID_USERNAME ]] || read -p "ssh user: "     GRBL_ANDROID_USERNAME
    [[ $GRBL_ANDROID_PASSWORD ]] || read -p "password: "     GRBL_ANDROID_PASSWORD

    # android phone command parser
    local _cmd="$1" ; shift
    case "$_cmd" in
            mount|unmount|terminal|get)
                     android.$_cmd "$@"
                     return $?
                     ;;

            status|poll|help|install)
                     android.$_cmd "$@"
                     return $?
                     ;;

               all)  android.get
                     return $?
                     ;;

                 *)  gr.msg -c error "unknown action $_cmd"
        esac

}


android.help () {

    gr.msg -v2
    gr.msg -v1 -c white "grbl android help "
    gr.msg -v0  "usage:    $GRBL_CALL android [s|add|open|rm|check|media|camera|all|install] <application> "
    gr.msg -v2
    gr.msg -v1 -c white "commands:"
    gr.msg -v1  " terminal          open terminal to android "
    gr.msg -v1  " get               download stuff from phone to $android_temp_folder "
    gr.msg -v1  " mount             mount andr"
    gr.msg -v1  " unmount           unmount android "
    gr.msg -v1  " install           install server to android (google play) "
    gr.msg -v1  " help              help printout "
    gr.msg -v2
    gr.msg -v1 -c white "example: "
    gr.msg -v1  "       $GRBL_CALL android terminal "
    gr.msg -v1  "       $GRBL_CALL android mount "
    gr.msg -v1  "       $GRBL_CALL android get "
    gr.msg -v2
    return 0
}


android.confirm_key () {

    if ssh -o HostKeyAlgorithms=+ssh-dss "$GRBL_ANDROID_USERNAME@$GRBL_ANDROID_LAN_IP" \
        -p "$GRBL_ANDROID_LAN_PORT"
        then
            touch $android_first_time
        fi
}


android.terminal () {
    # open ssh terminal connection to phone
    [[ -f $android_first_time ]] || android.confirm_key
    sshpass -p "$GRBL_ANDROID_PASSWORD" \
        ssh -o HostKeyAlgorithms=+ssh-dss "$GRBL_ANDROID_USERNAME@$GRBL_ANDROID_LAN_IP" \
        -p "$GRBL_ANDROID_LAN_PORT"
    echo $?
    return $?
}


android.mount () {
    # mount phone folder set as in phone ssh server settings
    [[ -f $android_first_time ]] || android.confirm_key
    local _mount_point="$HOME/android-$GRBL_ANDROID_USERNAME" ; [[ "$1" ]] && _mount_point="$1"
    gr.msg -v1 -N -c white "mounting $_mount_point"

    if [[ -d "$_mount_point" ]] ; then mkdir -p "$_mount_point" ; fi
    sshfs -o HostKeyAlgorithms=+ssh-dss -p "$GRBL_ANDROID_LAN_PORT" \
        "$GRBL_ANDROID_USERNAME@$GRBL_ANDROID_LAN_IP:/storage/emulated/0" \
        "$_mount_point"
    return $?
}


android.unmount () {
    # unmount folder
    local _mount_point="$HOME/android-$GRBL_ANDROID_USERNAME" ; [[ "$1" ]] && _mount_point="$1"
    gr.msg -v1 -N -c white "unmounting $_mount_point"
    fusermount -u "$_mount_point" || sudo fusermount -u "$_mount_point"
    [[ -d "$_mount_point" ]] &&androidr "$_mount_point"
    return $?
}


android.rmdir () {
    # remove folder in phone
    local _target_folder="$1" ; shift
    gr.msg -v1 -N -c white "removing: $_target_folder"

    if sshpass -p "$GRBL_ANDROID_PASSWORD" \
        ssh "$GRBL_ANDROID_USERNAME@$GRBL_ANDROID_LAN_IP" \
        -p "$GRBL_ANDROID_LAN_PORT" \
        -o "HostKeyAlgorithms=+ssh-dss" "rm -rf $_target_folder"

        then
            gr.msg -c green "removed"
            return 0

        else
            gr.msg -c dark_gold_rod "ignored"
            return 101
        fi
}


android.rm () {
    # remove files from phone
    local _target_files="$1" ; shift
    gr.msg -v1 -N -c white "removing: $_target_files"

    if sshpass -p "$GRBL_ANDROID_PASSWORD" \
        ssh "$GRBL_ANDROID_USERNAME@$GRBL_ANDROID_LAN_IP" \
        -p "$GRBL_ANDROID_LAN_PORT" \
        -o "HostKeyAlgorithms=+ssh-dss" "rm -f $_target_files"
        then
            gr.msg -c green "removed"
            return 0
        else
            gr.msg -c dark_gold_rod "ignored"
            return 101
        fi
}


android.get () {
    # Get all media files from phone

    # mount.online $GRBL_MOUNT_PHOTOS || mount.known_remote photos
    # mount.online $GRBL_MOUNT_VIDEO || mount.known_remote video
    # mount.online $GRBL_MOUNT_PICTURES || mount.known_remote pictures
    # mount.online $GRBL_MOUNT_DOCUMENTS || mount.known_remote documents
    # mount.online $GRBL_MOUNT_VIDEO || mount.known_remote video
    # mount.online $GRBL_MOUNT_AUDIO || mount.known_remote audio

    gr.msg -n -v1 "copying files "
    while IFS= read -r _line ; do

            gr.msg -v3 -c cyan ":$_line:"
            _ifs=$IFS ; IFS='>' ; _list=($_line) ; IFS=$_ifs

            gr.msg -v3 -c green ":${_list[@]}:"

            _action=${_list[0]}
            gr.msg -v3 -c pink ":$_action:"   # cp=copy, mv=move

            _type=${_list[1]}
            gr.msg -v3 -c pink ":$_type:"     # filetype

            _title=${_list[2]}
            _source=${_list[3]}
            _target=$(eval echo "${_list[4]}")
            gr.msg -v3 -c pink ":$_title:"
            gr.msg -v3 -c pink ":$_source:"
            gr.msg -v3 -c pink ":$_target:"

            gr.msg -v1 -V2 -n "."
            gr.msg -n -v2 -c dark_crey "$_title > $_target "
            if ! [[ -d "$_target" ]] ; then mkdir -p "$_target" ; fi

            # check folder exits
            if sshpass -p $GRBL_ANDROID_PASSWORD \
                    ssh -o HostKeyAlgorithms=+ssh-dss -o StrictHostKeyChecking=no -p $GRBL_ANDROID_LAN_PORT \
                    $GRBL_ANDROID_USERNAME@$GRBL_ANDROID_LAN_IP stat "$_source"
                then
                    # copy all files in requested type $android_verb
                    sshpass -p $GRBL_ANDROID_PASSWORD \
                    scp $android_verb -p -o HostKeyAlgorithms=+ssh-dss -P $GRBL_ANDROID_LAN_PORT \
                    $GRBL_ANDROID_USERNAME@$GRBL_ANDROID_LAN_IP:"$_source/*.$_type" $_target
                    _error=$?
                else
                    gr.msg -c pink -v3 "$GRBL_ANDROID_USERNAME@$GRBL_ANDROID_LAN_IP $_source not exist"
                fi

            case $_error in
                    0)  gr.msg -v1 -c green "done"
                        [[ "$_action" == "mv" ]] && echo android.rmdir "$_source"
                        ;;
                    *)  gr.msg -c yellow "$_source $_type failed"
                        ;;
                esac

        done < "$android_config_file"
}


android.install () {

    sudo apt install sshpass sshfs fusermount
    $GRBL_BROWSER $android_server_url
}


android.connected () {

    if ping -c3 -W2 $GRBL_ANDROID_LAN_IP >/dev/null ; then
            return 0
        else
            return 1
        fi
}


android.ssh_active () {

    if  timeout 7 sshpass -p $GRBL_ANDROID_PASSWORD \
        ssh -o "HostKeyAlgorithms=+ssh-dss" -p $GRBL_ANDROID_LAN_PORT \
        $GRBL_ANDROID_USERNAME@$GRBL_ANDROID_LAN_IP ls \
        >/dev/null \
        2>/dev/null

        then
            return 0
        else
            return 1
        fi
}


android.status () {

    local _device_name='phone'

    [[ $GRBL_ANDROID_NAME ]] && _device_name=$GRBL_ANDROID_NAME
    gr.msg -n "checking $_device_name.. "

    if android.connected ; then
            gr.msg -n -c green "connected "
        else
            gr.msg -c dark_gray "not connected"
            return 12
    fi

    if  android.ssh_active ; then
            gr.msg -c green "and online "
        else
            gr.msg -c error "but server is offline"
            return 13
        fi
    return 0
}


android.poll () {
    # poll functions

    local android_indicator_key="f$(gr.poll android)"
    local _cmd="$1" ; shift

    case $_cmd in
            start )
                gr.msg -v1 -t -c black "${FUNCNAME[0]}: backup status polling started" -k $android_indicator_key
                ;;
            end )
                gr.msg -v1 -t -c reset "${FUNCNAME[0]}: backup status polling ended" -k $android_indicator_key
                ;;
            status )
                gr.msg -v1 -t -n "${FUNCNAME[0]}: "
                android.status && gr.ind available -k $android_indicator_key -m "phone available" >/dev/null
                ;;
            *)  gr.msg -c dark_grey "function not written"
                return 0
        esac
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
        #source "$GRBL_RC"
        android.main "$@"
    fi

