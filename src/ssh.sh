#!/bin/bash
## bash script to add SSH key to remote service provider
# tested: 2/2020 ubuntu desktop 18.04 and mint cinnamon 19.2 

# Issues
# SC2015: Note that A && B || C is not if-then-else. C may run when A is true.
# Yes: in this case  this if fine

# SC2143: Use grep -q instead of comparing output with [ -n .. ].
# SC2086: Double quote to prevent globbing and word splitting.
# Yes: in this case this if fine: no input that may split

# Inclides
. lib/common.sh

ssh_main(){
    error="1"  # Warning "1" is default exit code

    # Install requirements
    xclip -help >/dev/null 2>&1 ||sudo apt install xclip

    [ -d "$HOME/.ssh" ] || mkdir "$HOME/.ssh"

    # Select git service provider
    [ "$1" ] && remote="$1" ||read -r -p "[1] github, [2] bitbucket or [3] other: " remote
    shift 

    case $remote in
        
        1|ujo.guru)
            add_key_accesspoint "$@"
            ;;
        2|github)
            add_key_github "$@"
            error="$?"
            ;;
        3|bitbucket)
            add_key_bitbucket "$@"
            error="$?"
            ;;        
        4|other)
            my-git_ssh_set "$@"
            error="$?"
            ;;
        help|*)
           printf "Usage: \n\t%s [remote_provider] [login_email]\n" "$0"
           printf "Remote_provider:\n1|github        github.com account\n"
           printf "2|bitbucket     bitbucket.org account \n"
           printf "3|other         other account\n"
           printf "without variables script asks input during process\n"
    esac

    if [[ "$error" -gt "1" ]]; then 
        echo "Error: $error, Something went wrong." 
        return $error
    fi

    return 0
}

add_key_accesspoint () {
    # function to setup ssh key login with github 
    
    local key_file="$HOME/.ssh/ujo.guru_id_rsa"
    local ssh_key_add_url="ujo.guru"

    [ "$1" ] && user_name="$1" || read -r -p "github login email: " user_name

    ## Generate keys
    ssh-keygen -t rsa -b 4096 -C "$user_name" -f "$key_file" && echo "Key OK" || return 22
    chmod 600 "$key_file"

    ## Start agent and add private key
    eval "$(ssh-agent -s)" && echo "Agent OK" || return 23
    ssh-add "$key_file" && echo "Key add OK" || return 24    

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


my-git_ssh_set() {
    echo "TBD"
    return 1
}


# if not runned from terminal, use as library
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    ssh_main "$@"
    exit "$?"
fi

