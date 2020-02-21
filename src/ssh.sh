#!/bin/bash
## bash script to add SSH key to remote service provider
# tested: 2/2020 ubuntu desktop 18.04 and mint cinnamon 19.2 

ssh_main() {
    # main selector off ssh functions
    command="$1"
    shift
    case $command in 
        
        ls-key|list-keys)
            ssh-add -l
            ;;
        add-key)
            ssh_add_key "$@"
            ;;
        rm-key)
            echo "TBD"
            ;;
        pull-cfg|pull-config|get-config)
            pull_guru_config_file
            ;;
        push-cfg|push-config|put-config)
            push_guru_config_file
            ;;
        help|*)
            printf "ssh main menu\nUsage:\n\t$0 [command] [variables]\n"
            printf "\nCommands:\n"
            printf " pull-cfg      get personal config from server and replace guru './config/guru/%s/userrc' file \n" "$GURU_USER"
            printf " push-cfg      sends current user config to %s \n\n" "$GURU_ACCESS_POINT_SERVER"
            printf " ls-key        list of keys \n"
            printf " add-keys      adds keys to server [server_selection] [variables] \n"
            printf " rm-key        remove from remote server server [key_file] \n"
            printf " rm-key-local  remove local key files server [key_file] \n"
            ;;
    esac
}


pull_guru_config_file(){
    rsync -rvz --quiet -e "ssh -p $GURU_ACCESS_POINT_SERVER_PORT" "$GURU_USER@$GURU_ACCESS_POINT_SERVER:/home/$GURU_USER/usr/cfg/$GURU_USER.userrc.sh" "$GURU_CFG/$GURU_USER/userrc" 
}


push_guru_config_file(){
    rsync -rvz --quiet -e "ssh -p $GURU_ACCESS_POINT_SERVER_PORT" "$GURU_CFG/$GURU_USER/userrc" "$GURU_USER@$GURU_ACCESS_POINT_SERVER:/home/$GURU_USER/usr/cfg/$GURU_USER.userrc.sh"
}


ssh_add_key(){
    error="1"  # Warning "1" is default exit code
    # [1] ujo.guru, [2] git.ujo.guru, [3] github, [4] bitbucket
    # Install requirements
    xclip -help >/dev/null 2>&1 ||sudo apt install xclip

    [ -d "$HOME/.ssh" ] || mkdir "$HOME/.ssh"

    # Select git service provider
    [ "$1" ] && remote="$1" ||read -r -p "[1] ujo.guru, [2] git.ujo.guru, [3] github, [4] bitbucket : " remote
    shift 

    case $remote in
        
        1|ujo.guru)
            add_key_accesspoint "$@"
            ;;
        2|git.ujo.guru)
            add_key_my-git "$@"
            error="$?"
            ;;
        3|github)
            add_key_github "$@"
            error="$?"
            ;;
        4|bitbucket)
            add_key_bitbucket "$@"
            error="$?"
            ;;        
        5|other)
            add_key_other "$@"
            error="$?"
            ;;   
        help|*)
           printf "Add key to server and rule to ~/.ssh/config \nUsage: \n\t%s add-key [selection] [variables]\n" "$0"
           printf "\nselections:\n\n"
           printf "1|ujo.guru      add key to ujo.guru accesspoint\n"     
           printf "2|git.ujo.guru  add key to own git server \n"
           printf "3|github        add key to github.com [user_email] \n"
           printf "4|bitbucket     add key to bitbucket.org [user_email] \n"
           printf "5|other         add key to any server [domain] [port] [username] \n\n"
           printf "without variables script asks input during process\n\n"
    esac

    if [[ "$error" -gt "1" ]]; then 
        echo "Error: $error, Something went wrong." 
        return $error
    fi

    return 0
}


add_key_accesspoint () {        # mint pass, ubuntu not tested
    # function to add keys to ujo.guru access point server 

    local key_file="$HOME/.ssh/$GURU_ACCESS_POINT_SERVER"'_id_rsa'
    local server_domain="$GURU_ACCESS_POINT_SERVER"
    local server_port="$GURU_ACCESS_POINT_SERVER_PORT"

    ## Generate keys
    ssh-keygen -t rsa -b 4096 -C "$GURU_USER" -f "$key_file" && echo "Key OK" || return 22
    chmod 600 "$key_file"

    ## Start agent and add private key
    eval "$(ssh-agent -s)" && echo "Agent OK" || return 23
    ssh-add "$key_file" && echo "Key add OK" || return 24    

    ssh-copy-id -i "$key_file" "$GURU_USER@$server_domain" -p "$server_port"

    # add domain based rule to ssh config
    if [ "$(grep -e ujo.guru < $HOME/.ssh/config)" ]; then 
        echo "Rule already exist OK"
    else
        printf "\nHost *ujo.guru \n\tIdentityFile %s\n" "$key_file" >> "$HOME/.ssh/config" && echo "Domain rule add OK" || return 26
    fi
    return 0
}


add_key_github () {
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


add_key_bitbucket () {
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


add_key_other() {
    
    [ "$1" ] && server_domain="$1" ||read -r -p "domain: " server_domain   
    [ "$2" ] && server_port="$2" ||read -r -p "port: " server_port  
    [ "$3" ] && user_name="$3" ||read -r -p "user name: " user_name

    local key_file="$HOME/.ssh/$server_domain"'_id_rsa'

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
    return 1
}


# if not runned from terminal, use as library
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    ssh_main "$@"
    exit "$?"
fi

