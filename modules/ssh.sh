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
        ps|active)  ssh-add -l  ;;
        ls|files)   ls "$HOME/.ssh" | grep "rsa" | grep -v "pub" ;;
        add)        ssh.add_key "$@" ;;
        rm)         ssh.rm_key "$@" ;;
        help|*)     ssh.help ;;
    esac

}


ssh.status () {
    gmsg -v1 "current keys"
    gmsg -v1 -c $GURU_COLOR_LIST "$(ls $HOME/.ssh/ | grep _id_rsa| grep -v pub)"
}


ssh.help () {
    gmsg -v1 -c white "guru-client ssh help "
    gmsg -v2
    gmsg -v0 "usage:    $GURU_CALL ssh [key|keys] [agent|ps|ls|add|rm|help]"
    gmsg -v2
    gmsg -v1 -c white "Commands:"
    gmsg -v1 " key|keys             key management tools, try '$GURU_CALL ssh key help' for more info."
    gmsg -v1 "   key ps             list of activekeys "
    gmsg -v1 "   key ls             list of keys files"
    gmsg -v1 "   key rm             remove from remote server server [user_name@service_host] "
    gmsg -v1 "   key add <...>      add keys to server <domain> <port> <user_name> or"
    gmsg -v1 "   key add <server>   add keys to known server: ujo.guru, git.ujo.guru, github, bitbucket"
    gmsg -v2
    gmsg -v1 -c white "Example: "
    gmsg -v1 "      $GURU_CALL ssh key add $GURU_ACCESS_DOMAIN"
    gmsg -v1
    gmsg -v1 "Any on known ssh command is passed trough to open-ssh client"
    gmsg -v2
}


ssh.rm_key () {
    # remove local keyfiles (not from server known hosts) TODO
    [[ -f "$HOME/.ssh/$input""_id_rsa" ]] && [[ -f "$HOME/.ssh/$input""_id_rsa.pub" ]] || gmsg -x 127 -c red "key file not found"

    [[ "$1" ]] && local input="$1" || read -r -p "key title (no '_id_rsa') : " input

    read -r -p "Are you sure to delete files '$input""_id_rsa' and '$input""_id_rsa.pub'? " answer

    if [[ "${answer^^}" == "Y" ]]; then
            rm -f "$HOME/.ssh/$input""_id_rsa" || gmsg -c yellow "error while removing $HOME/.ssh/$input_id_rsa"
            rm -f "$HOME/.ssh/$input""_id_rsa.pub" || gmsg -c yellow "error while removing $HOME/.ssh/$input_id_rsa.pub"
        fi
    return 0
}


ssh.add_key () {
    # [1] ujo.guru, [2] git.ujo.guru, [3] github, [4] bitbucket
    xclip -help >/dev/null 2>&1 || sudo apt install xclip
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
           gmsg -v1 "Add key to server and rule to '~/.ssh/config'"
           gmsg -v2
           gmsg -v0 "Usage:    $GURU_CALL ssh key add [ujo.guru|git.ujo.guru|github|bitbucket] or [domain] [port] [user_name]"
           gmsg -v2
           gmsg -v1 "providers:"
           gmsg -v1 " 1|ujo.guru        add key to access $GURU_ACCESS_DOMAIN "
           gmsg -v1 " 2|git.ujo.guru    add key to own git server "
           gmsg -v1 " 3|github          add key to github.com [user_email] "
           gmsg -v1 " 4|bitbucket       add key to bitbucket.org [user_email] "
           gmsg -v1 " 5|other           add key to any server [domain] [port] [user_name] "
           gmsg -v1
           gmsg -v1 "Without variables script asks input during process"
           gmsg -v1
           gmsg -v1 "Example: "
           gmsg -v1 "       $GURU_CALL ssh key add github "
        esac
    return "$error"
}


ssh.keygen () {
    local key_file=$1 ; shift
    local user=$GURU_USER ; [[ $1 ]] && user=$1
    gmsg -c white "generating keys "
    if ssh-keygen -t rsa -b 4096 -C "$user" -f "$key_file" ; then
            gmsg -c green "ok"
        else
            gmsg -x 22 -c red "ssh-keygen error or user interupt"
        fi
    chmod 600 "$key_file"
    return 0
}


ssh.agent_start () {
    ## start agent
    gmsg -c white "checking/starting agent "
    if eval "$(ssh-agent -s)" ; then
            gmsg -c green "ok"
        else
            gmsg -x 23 -c red "ssh-agent start failed"
        fi
    return 0
}


ssh.agent_add () {
    # add private key to agent
    local key_file=$1
    gmsg -c white "adding key to agent "
    if ssh-add "$key_file" ; then
            gmsg -c green "ok"
        else
            gmsg -x 24 -c red "ssh-add error"
        fi
    return 0
}


ssh.copy-id () {
    # send key to server
    local key_file=$1
    local server="$GURU_ACCESS_DOMAIN" ; [[ $2 ]] && server=$2
    local port="$GURU_ACCESS_PORT" ; [[ $3 ]] && port=$3

    gmsg -c white "sending public keys to server "
    if ssh-copy-id -f -p "$port" -i "$key_file" "$server" ; then
            gmsg -c green "ok"
        else
            gmsg -x 25 -c red "ssh-copy-id error"
        fi
    return 0
}


ssh.add_rule () {
    local key_file=$1
    local server="$GURU_ACCESS_DOMAIN" ; [[ $2 ]] && server=$2
    local user="$GURU_USER" ; [[ $3 ]] && user=$3

    if cat $HOME/.ssh/config | grep "$user-$server" >/dev/null ; then
        gmsg -c green "rule already exist, ok"
    else
        if printf "\nHost *$server \n\tIdentityFile %s\n" "$key_file" >> "$HOME/.ssh/config" ; then
                gmsg -c green "ok"
            else
                gmsg -x 26 -c red "rule add error"
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
    ssh.copy-id "$key_file"
    ssh.add_rule "$key_file" "$server"
    return 0
}


ssh.add_key_github () {
    # function to setup ssh key login with github
    local server="github.com"
    local key_file="$HOME/.ssh/$GURU_USER-$server"'_id_rsa'
    local ssh_key_add_url="https://github.com/settings/ssh/new"
    [[ "$1" ]] && user_email="$1" || read -r -p "github login email: " user_email

    ssh.keygen "$key_file"
    ssh.agent_start
    ssh.agent_add "$key_file"

    # copy key to cliboard
    gmsg -c white "adding key to github "
    xclip -sel clip < "$key_file.pub"
    gmsg -c deep_pink "paste public key (stored to clipboard) to text box and use $USER@$HOSTNAME as a 'Title'"

    # open remote profile settings
    firefox "$ssh_key_add_url" &
    gmsg -c white "after key is added, continue by pressing enter.. " ; read -r

    # add rule
    ssh.add_rule "$key_file" "$server"
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

    # copy key to cliboard
    xclip -sel clip < "$key_file.pub"

    # open remote profile settings
    gmsg -c deep_pink "step 1) login to bitbucket then go to 'Profile' -> 'Personal settings' -> 'SSH keys' -> 'Add key'"
    gmsg -c deep_pink "step 2) paste the key into the text box and add 'Title' $USER@$HOSTNAME and click 'Add key'"

    firefox "$ssh_key_add_url" &

    gmsg -c white "after key is added, continue by pressing enter.. " ; read -r

    # add domain based rule to ssh config
    ssh.add_rule "$key_file" "$server"
    return 0
}


ssh.add_key_my_git () {
    gmsg -v1 "TBD"
}


ssh.add_key_other () {

    [ "$1" ] && server="$1" || read -r -p "domain: " server
    [ "$2" ] && port="$2" || read -r -p "port: " port
    [ "$3" ] && user="$3" || read -r -p "user name: " user
    local key_file="$HOME/.ssh/$user-$server"'_id_rsa'

    ssh.keygen "$key_file"
    ssh.agent_start
    ssh.agent_add "$key_file"
    ssh.copy-id "$key_file" "$server" "$port"
    ssh.add_rule "$key_file" "$server" "$user"

    return 0
}


# if not runned from terminal, use as library
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$GURU_RC"
    ssh.main "$@"
    exit "$?"
fi

