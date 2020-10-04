#!/bin/bash
## bash script to add SSH key to remote service provider
# tested: 2/2020 ubuntu desktop 18.04 and mint cinnamon 19.2
source $GURU_BIN/common.sh

ssh.main() {
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

ssh.key() {
    # ssh key tools
    local command="$1"
    shift
    case "$command" in
        agent)      ssh.add_key_to_agent "$@" ;;
        ps|active)  ssh-add -l  ;;
        ls|files)   ls "$HOME/.ssh" |grep "rsa" |grep -v "pub" ;;
        add)        ssh.add_key "$@" ;;
        rm)         ssh.rm_key "$@" ;;
        help|*)     ssh.help ;;
    esac

}

ssh.status () {
    gmsg -v1 "current keys"
    ls $HOME/.ssh/ |grep _id_rsa|grep -v pub)
}

ssh.help ()  {
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
    gmsg -v1 "      $GURU_CALL ssh key add $GURU_ACCESS_POINT"
    gmsg -v1
    gmsg -v1 "Any on known ssh command is passed trough to open-ssh client"
    gmsg -v2
}


ssh.rm_key() {
    # remove local keyfiles (not from server known hosts) TODO
    echo "key file not found" > "$GURU_ERROR_MSG"
    [ -f "$HOME/.ssh/$input""_id_rsa" ] && [ -f "$HOME/.ssh/$input""_id_rsa.pub" ] || exit 127

    [ "$1" ] && local input="$1" ||read -r -p "key title (no '_id_rsa') : " input

    read -r -p "Are you sure to delete files '$input""_id_rsa' and '$input""_id_rsa.pub'? " answer
    [ "$input" ] || return 127
    if [ "${answer^^}" == "Y" ]; then
        [ -f "$HOME/.ssh/$input""_id_rsa" ] && rm -f "$HOME/.ssh/$input""_id_rsa"
        [ -f "$HOME/.ssh/$input""_id_rsa.pub" ] && rm -f "$HOME/.ssh/$input""_id_rsa.pub"
    fi
}


ssh.add_key(){
    # [1] ujo.guru, [2] git.ujo.guru, [3] github, [4] bitbucket
    xclip -help >/dev/null 2>&1 ||sudo apt install xclip
    [ -d "$HOME/.ssh" ] || mkdir "$HOME/.ssh"
    error="1"
    # Select git service provider
    [ "$1" ] && remote="$1" ||read -r -p "[1] ujo.guru, [2] git.ujo.guru, [3] github, [4] bitbucket, [5] other or help: " remote
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
           gmsg -v1 " 1|ujo.guru        add key to access $GURU_ACCESS_POINT "
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


ssh.add_key_to_agent () {
	local key_file="$HOME/.ssh/$GURU_ACCESS_POINT"'_id_rsa'
    [[ $1 ]] && key_file="$1"
    eval "$(ssh-agent -s)" && echo "Agent OK" || return 23
    ssh-add "$key_file" && echo "Key add OK" || return 24
}


ssh.add_key_accesspoint () {
    # function to add keys to ujo.guru access point server

    local key_file="$HOME/.ssh/$GURU_ACCESS_POINT"'_id_rsa'

    ## Generate keys
    echo "key file exist /user interrupt" >"$GURU_ERROR_MSG"
    ssh-keygen -t rsa -b 4096 -C "$GURU_USER" -f "$key_file" && echo "Key OK" || return 22
    chmod 600 "$key_file"

    ## Start agent and add private key
    echo "ssh-agent do not start" >"$GURU_ERROR_MSG"
    eval "$(ssh-agent -s)" && echo "Agent OK" || return 23

    echo "ssh-add error" >"$GURU_ERROR_MSG"
    ssh-add "$key_file" && echo "Key add OK" || return 24

    echo "ssh-copy-id error" >"$GURU_ERROR_MSG"
    ssh-copy-id -p "$GURU_ACCESS_POINT_PORT" -i "$key_file" "$GURU_ACCESS_POINT"


    # add domain based rule to ssh config
    if [ "$(grep -e ujo.guru < $HOME/.ssh/config)" >/dev/null] ; then
        echo "Rule already exist OK"
    else
        printf "\nHost *ujo.guru \n\tIdentityFile %s\n" "$key_file" >> "$HOME/.ssh/config" && echo "Domain rule add OK" || return 26
    fi

    return 0
}


ssh.add_key_github () {
    # function to setup ssh key login with github

    local key_file="$HOME/.ssh/github_id_rsa"
    local ssh_key_add_url="https://github.com/settings/ssh/new"

    [ "$1" ] && user_email="$1" || read -r -p "github login email: " user_email

    ## Generate keys
    ssh-keygen -t rsa -b 4096 -C "$user_email" -f "$key_file" && echo "Key OK" || return 22
    chmod 600 "$key_file"

    ## Start agent and add private key
    eval "$(ssh-agent -s)" && echo "Agent OK" || return 23
    ssh-add "$key_file" && echo "Key add OK" || return 24

    # Paste public key to github
    xclip -sel clip < "$key_file.pub" && echo "Key copy to clipboard OK" || return 25

    # Open remote profile settings
    printf "\nOpening github settings page to firefox.\n Paste public key (stored to clipboard) to text box and use %s@%s as a 'Title'.\n\n" "$USER" "$HOSTNAME"
    firefox "$ssh_key_add_url" &
    read -r -p "After key is added, continue by pressing enter.. "

    # add domain based rule to ssh config
    if [ "$(grep -e github.com < $HOME/.ssh/config)" ]; then
        echo "Rule already exist OK"
    else
        printf "\nHost *github.com \n\tIdentityFile %s\n" "$key_file" >> "$HOME/.ssh/config" && echo "Domain rule add OK" || return 26
    fi

    return 0
}


ssh.add_key_bitbucket () {
    # function to setup ssh key login with bitbucket.

    local key_file="$HOME/.ssh/bitbucket_id_rsa"
    local ssh_key_add_url="https://bitbucket.org"                               # no able to generalize beep link

    [ "$1" ] && user_email="$1" || read -r -p "bitbucket login email: " user_email

    ## Generate keys
    ssh-keygen -t rsa -b 4096 -C "$user_email" -f "$key_file" && echo "Key OK" || return 22
    chmod 600 "$key_file"

    ## Start agent and add private key
    eval "$(ssh-agent -s)" && echo "Agent OK" || return 23
    ssh-add "$key_file" && echo "Key add OK" || return 24

    # Paste public key to github
    xclip -sel clip < "$key_file.pub" && echo "Key copy to clipboard OK" || return 25

    # Open remote profile settings
    printf "\nOpening bitbucket.prg to firefox\n Login to Bitbucket, go to 'View Profile' and then 'Settings'.\n Select on 'SSH keys' and then 'Add key'\n Then paste the key into the text box, add 'Title' %s@%s and click 'Add key'.\n\n" "$USER" "$HOSTNAME"
    firefox "$ssh_key_add_url" &
    read -r -p "After key is added, continue by pressing enter.. "

    # add domain based rule to ssh config
    if [ "$(grep -e bitbucket.org < $HOME/.ssh/config)" ]; then
        echo "Rule already exist OK"
    else
        printf "\nHost *bitbucket.org \n\tIdentityFile %s\n" "$key_file" >> "$HOME/.ssh/config" && echo "Domain rule add OK" || return 26
    fi

    return 0
}


ssh.add_key_my_git () {
    gmsg -v1 "TBD"
}


ssh.add_key_other() {

    [ "$1" ] && server_domain="$1" ||read -r -p "domain: " server_domain
    [ "$2" ] && server_port="$2" ||read -r -p "port: " server_port
    [ "$3" ] && user_name="$3" ||read -r -p "user name: " user_name

    local key_file="$HOME/.ssh/$user_name@$server_domain"'_id_rsa'

    ## Generate keys
    ssh-keygen -t rsa -b 4096 -C "$user_name" -f "$key_file" && echo "Key OK" || return 22
    chmod 600 "$key_file"

    ## Start agent and add private key
    eval "$(ssh-agent -s)" && echo "Agent OK" || return 23
    ssh-add "$key_file" && echo "Key add OK" || return 24

    ssh-copy-id -i "$key_file" "$user_name@$server_domain" -p "$server_port"

    # add domain based rule to ssh config
    if [ "$(grep -e ujo.guru < $HOME/.ssh/config)" ]; then
        echo "Rule already exist OK"
    else
        printf "\nHost *$server_domain \n\tIdentityFile %s\n" "$key_file" >> "$HOME/.ssh/config" && echo "Domain rule add OK" || return 26
    fi

    return 0
}


# if not runned from terminal, use as library
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$HOME/.gururc2"
    ssh.main "$@"
    exit "$?"
fi

