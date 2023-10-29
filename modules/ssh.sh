#!/bin/bash
## bash script to add SSH key to remote service provider
# tested: 2/2020 ubuntu desktop 18.04 and mint cinnamon 19.2
source $GURU_BIN/common.sh

ssh.main () {
    # main selector off ssh functions
    command="$1"
    shift
    case "$command" in
      key|keys)     ssh.key "$@"            ;;
          help)     ssh.help ; return 0     ;;
        status)     ssh.status              ;;
        *)          ssh "$@"
    esac
}


ssh.key () {
    # ssh key tools
    local command="$1"
    shift
    case "$command" in

        remote)
            [[ "$1" == "config" ]] || return 12
            ssh.check_remote_config
            ;;
        check)
            [[ "$1" == "config" ]] || return 12
            ssh.check_remote_config
            ;;
        ps|active)      ssh-add -l  ;;
        renerate|new)   ssh.generate_key $@ ; return $? ;;
        ls|files)       gr.msg -c light_blue $(ls "$HOME/.ssh" | grep "rsa" | grep -v "pub") ;;
        add)            ssh.add_key "$@" ;;
        rm)             ssh.rm_key "$@" ;;
        send)           ssh.copy-id "$@" ;;
        help|*)         ssh.help ;;
    esac

}


ssh.status () {
    gr.msg -v1 "current keys"
    gr.msg -v1 -c light_blue "$(ls $HOME/.ssh/ | grep _id_rsa| grep -v pub)"
}


ssh.help () {
    gr.msg -v1 -c white "guru-client ssh help "
    gr.msg -v2
    gr.msg -v0 "usage:    $GURU_CALL ssh [key|keys] [agent|ps|ls|add|rm|help] <key_file> <host> <port> <user>"
    gr.msg -v2
    gr.msg -v1 -c white "Commands:"
    gr.msg -v1 " key|keys                 key management tools, try '$GURU_CALL ssh key help' for more info."
    gr.msg -v1 "   key ps                 list of activekeys "
    gr.msg -v1 "   key send               send keys to server"
    gr.msg -v1 "    "
    gr.msg -v1 "   key rm                 remove from remote server server [user_name@service_host] "
    gr.msg -v1 "   key add <...>          add keys to server <domain> <port> <user_name> or"
    gr.msg -v1 "   key add <server>       add keys to known server: ujo.guru, git.ujo.guru, github, bitbucket"
    gr.msg -v2
    gr.msg -v1 -c white "Example: "
    gr.msg -v1 "      $GURU_CALL ssh key add $GURU_ACCESS_DOMAIN"
    gr.msg -v1
    gr.msg -v1 "Any on known ssh command is passed trough to open-ssh client"
    gr.msg -v2
}


ssh.rm_key () {
    # remove local keyfiles (not from server known hosts) TODO
    [[ -f "$HOME/.ssh/$input""_id_rsa" ]] && [[ -f "$HOME/.ssh/$input""_id_rsa.pub" ]] || gr.msg -x 127 -c red "key file not found"

    [[ "$1" ]] && local input="$1" || read -r -p "key title (no '_id_rsa') : " input

    read -r -p "Are you sure to delete files '$input""_id_rsa' and '$input""_id_rsa.pub'? " answer

    if [[ "${answer^^}" == "Y" ]]; then
            rm -f "$HOME/.ssh/$input""_id_rsa" || gr.msg -c yellow "error while removing $HOME/.ssh/$input_id_rsa"
            rm -f "$HOME/.ssh/$input""_id_rsa.pub" || gr.msg -c yellow "error while removing $HOME/.ssh/$input_id_rsa.pub"
        fi
    return 0
}


ssh.add_key () {
    # [1] ujo.guru, [2] git.ujo.guru, [3] github, [4] bitbucket
    [ -d "$HOME/.ssh" ] || mkdir "$HOME/.ssh"
    error="1"
    # Select git service provider
    [ "$1" ] && remote="$1" || read -r -p "[1] ujo.guru, [2] git.ujo.guru, [3] github, [4] bitbucket, [5] other or help: " remote
    shift

    case "$remote" in
        1|ujo.guru)     ssh.add_key_accesspoint "$@"    ; error="$?" ;;
        2|git.ujo.guru) ssh.add_key_my_git "$@"         ; error="$?" ;;
        3|github)       ssh.add_key_github "$@"         ; error="$?" ;;
        4|bitbucket)    ssh.add_key_bitbucket "$@"      ; error="$?" ;;
        5|other)        ssh.add_key_other "$@"          ; error="$?" ;;
        help|*)
           gr.msg -v1 "Add key to server and rule to '~/.ssh/config'"
           gr.msg -v2
           gr.msg -v0 "Usage:    $GURU_CALL ssh key add [ujo.guru|git.ujo.guru|github|bitbucket] or [domain] [port] [user_name]"
           gr.msg -v2
           gr.msg -v1 "providers:"
           gr.msg -v1 " 1|ujo.guru        add key to access $GURU_ACCESS_DOMAIN "
           gr.msg -v1 " 2|git.ujo.guru    add key to own git server "
           gr.msg -v1 " 3|github          add key to github.com [user_email] "
           gr.msg -v1 " 4|bitbucket       add key to bitbucket.org [user_email] "
           gr.msg -v1 " 5|other           add key to any server [domain] [port] [user_name] "
           gr.msg -v1
           gr.msg -v1 "Without variables script asks input during process"
           gr.msg -v1
           gr.msg -v1 "Example: "
           gr.msg -v1 "       $GURU_CALL ssh key add github "
        esac
    return "$error"
}



ssh.generate_key () {
    local server=$1 ; shift
    local user=$1 ; shift
    local key_file="$HOME/.ssh/$user-$server"'_id_rsa'
    ssh.keygen "$key_file"
    ssh.add_rule "$key_file" "$server"
    gr.msg -c light_green "new puplic key: $key_file.pub"
}


ssh.keygen () {
    local key_file=$1 ; shift
    local user=$GURU_USER ; [[ $1 ]] && user=$1
    gr.msg -c white "generating keys "
    if ssh-keygen -t rsa -b 4096 -C "$user" -f "$key_file" ; then
            gr.msg -c green "ok"
        else
            gr.msg -x 22 -c red "ssh-keygen error or user interupt"
        fi
    chmod 600 "$key_file"
    return 0
}


ssh.agent_start () {
    ## start agent
    gr.msg -c white "checking/starting agent "
    if eval "$(ssh-agent -s)" ; then
            gr.msg -c green "ok"
        else
            gr.msg -x 23 -c red "ssh-agent start failed"
        fi
    return 0
}


ssh.agent_add () {
    # add private key to agent
    local key_file=$1
    gr.msg -c white "adding key to agent "
    if ssh-add "$key_file" ; then
            gr.msg -c green "ok"
        else
            gr.msg -x 24 -c red "ssh-add error"
        fi
    return 0
}


ssh.copy-id () {
    # send key to server
    local key_file=$1
    local server="$GURU_ACCESS_DOMAIN" ; [[ $2 ]] && server=$2
    local port="$GURU_ACCESS_PORT" ; [[ $3 ]] && port=$3
    local user="$GURU_USER" ; [[ $4 ]] && name=$4
    gr.msg -c white "sending public keys to server "
    if ssh-copy-id -f -p "$port" -i "$key_file" "$user@$server" ; then
            gr.msg -c green "ok"
        else
            gr.msg -x 25 -c red "ssh-copy-id error"
        fi
    return 0
}


ssh.add_rule () {
    local key_file=$1
    local server="$GURU_ACCESS_DOMAIN" ; [[ $2 ]] && server=$2
    #local port="$GURU_ACCESS_PORT" ; [[ $3 ]] && port=$3
    local user="$GURU_USER" ; [[ $3 ]] && user=$3
    if cat $HOME/.ssh/config | grep "$user-$server" >/dev/null ; then
        gr.msg -c green "rule already exist, ok"
    else
        if printf "\nHost *$server \n\tIdentityFile %s\n" $key_file >> "$HOME/.ssh/config" ; then
                gr.msg -c green "ok"
            else
                gr.msg -c red "rule add error"
                return 26
            fi
    fi
}


ssh.add_key_accesspoint () {
    # function to add keys to ujo.guru access point server
    local server=$GURU_ACCESS_DOMAIN
    local key_file="$HOME/.ssh/$GURU_USER-$server"'_id_rsa'

    ssh.keygen "$key_file"
    ssh.agent_start
    ssh.agent_add "$key_file"
    ssh.add_rule "$key_file" "$server"
    ssh.copy-id "$key_file"
    return 0
}


ssh.add_key_github () {
    # function to setup ssh key login with github
    key_output="stdin"
    if xclip -help >/dev/null 2>&1 ; then
            key_output="xclip"
        else
            [[ "$GURU_INSTALL_TYPE" == "desktop" ]] && sudo apt install xclip && key_output="xclip"
    fi

    local server="github.com"
    local key_file="$HOME/.ssh/$GURU_USER-$server"'_id_rsa'
    local ssh_key_add_url="https://github.com/settings/ssh/new"
    [[ "$1" ]] && user_email="$1" || read -r -p "github login email: " user_email

    ssh.keygen "$key_file"
    ssh.agent_start
    ssh.agent_add "$key_file"
    ssh.add_rule "$key_file" "$server"

    gr.msg -c white "adding key to github "
    case $key_output in
            xclip)
                xclip -sel clip < "$key_file.pub"
                gr.msg -c white "paste public key (stored to clipboard) to text box and use $USER@$HOSTNAME as a 'Title'"
                ;;
            stdin)
                gr.msg -c orange ".....copy between lines....."
                cat "$key_file.pub"
                gr.msg -c orange "............................"
                gr.msg -c white "paste public key (stored to clipboard) to text box and use $USER@$HOSTNAME as a 'Title'"
                ;;
            *)  gr.msg "key saved to $key_file.pub and $key_file"
        esac

    if [[ "$GURU_INSTALL_TYPE" == "desktop" ]] ; then
            firefox "$ssh_key_add_url" &
        else
            echo "open browser ans go to url: $ssh_key_add_url"
        fi

    return 0
}


ssh.add_key_bitbucket () {
    # function to setup ssh key login with bitbucket.
    local server="bitbucket.org"
    local key_file="$HOME/.ssh/$GURU_USER-$server"'_id_rsa'
    local ssh_key_add_url="https://bitbucket.org"                               # no able to generalize beep link

    [ "$1" ] && user_email="$1" || read -r -p "bitbucket login email: " user_email

    ssh.keygen "$key_file"
    ssh.agent_start
    ssh.agent_add "$key_file"
    ssh.add_rule "$key_file" "$server"

    gr.msg -c white "adding key to github "
    case $key_output in
            xclip)
                xclip -sel clip < "$key_file.pub"
                ;;
            stdin)
                gr.msg -c orange ".....copy between lines....."
                cat "$key_file.pub"
                gr.msg -c orange "............................"
                ;;
            *)  gr.msg "key saved to $key_file.pub and $key_file"
        esac

    # open remote profile settings
    gr.msg -c orange "step 1) login to bitbucket then go to 'Profile' -> 'Personal settings' -> 'SSH keys' -> 'Add key'"
    gr.msg -c orange "step 2) paste the key into the text box and add 'Title' $USER@$HOSTNAME and click 'Add key'"
    if [[ "$GURU_INSTALL_TYPE" == "desktop" ]] ; then
            gr.msg -c white "paste public key (stored to clipboard) to text box and use $USER@$HOSTNAME as a 'Title'"
            firefox "$ssh_key_add_url" &
        else
            echo "open browser ans go to url: $ssh_key_add_url"
            gr.msg -c white "copy and paste public key to text box and use $USER@$HOSTNAME as a 'Title'"
        fi


    return 0
}


ssh.add_key_my_git () {
    gr.msg -v1 "TBD"
}


# ssh.check_connections () {
# # print a list of connection an simple quest of connection type

#     local _server="$GURU_USER@$GURU_ACCESS_DOMAIN"
#     local _port="$GURU_ACCESS_PORT"

#     [[ $1 ]] && _server=$1
#     [[ $2 ]] && _port=$2

#     local _ifs=$IFS ; IFS=$'\n'
#     local _list=($(\
#         ssh $_server -p $_port -- ps -xf  \
#             | grep -v grep \
#             | grep '?' \
#             | grep sshd \
#             | sed -e's/  */ /g' \
#             | cut -d' ' -f 2,7-
#             ))
#     IFS=$_ifs

#     for item in ${_list[@]} ; do
#             gr.msg -n "$item: "
#             case $item in
#                 *'pts/'*) gr.msg -c aqua_marine "a terminal session" ;;
#                 *'notty'*) gr.msg -c aqua "tunnel end or sshfs" ;;
#                 *) gr.msg -c yellow "unknown connection type" ;;
#                 esac
#         done
# }


ssh.check_config () {
    gr.msg -c yellow "${FUNCKNAME[0]}: TBD "
    return 0
}


ssh.check_remote_config () {
    gr.msg -c yellow "${FUNCKNAME[0]}: TBD "
    return 0
}


ssh.add_key_other () {

    [[ "$1" ]] && server="$1" || read -r -p "domain: " server
    [[ "$2" ]] && port="$2" || read -r -p "port: " port
    [[ "$3" ]] && user="$3" || read -r -p "user name: " user
    local key_file="$HOME/.ssh/$user-$server"'_id_rsa'
    export GURU_USER=$user
    ssh.keygen "$key_file"
    ssh.agent_start
    ssh.agent_add "$key_file"
    ssh.copy-id "$key_file" "$server" "$port"
    ssh.add_rule "$key_file" "$server" "$user"
    return 0
}


# if not runned from terminal, use as library
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # source "$GURU_RC"
    ssh.main "$@"
    exit "$?"
fi

