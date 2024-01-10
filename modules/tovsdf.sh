#!/bin/bash 
# tovsdf - Tools to Orchestrate Very Small Docker Farm

# include guru-cli common functions if exists
source common.sh 2>/dev/null || gr.msg () { echo "${@##-*}" | sed 's/^[[:space:]]*//' ; }

tovsdf.main () {
# input: <command> <target> <container_name> example: 'tosdf update dokuwiki ug-wiki'

    local cmd=$1 ; shift
    # default target is docker it self
    local target=docker
    # set
    [[ $1 ]] && target=$1 ; shift

    case $cmd in
        install|start|restart|stop|update|uninstall)
            $target.$cmd $@
            return $?
            ;;
        *)  gr.msg -c yellow "unknown command $cmd"
            tovsdf.help
            ;;
    esac
}


tovsdf.help () {
    gr.msg -v1 -c white "Tools to Orchestrate Very Small Docker Farm - Help "
    gr.msg -v2
    gr.msg -v0 "usage:    $GURU_CALL tovsdf install|start|restart|stop|update|uninstall service"
    gr.msg -v2
    gr.msg -v1 -c white  "commands:"
    gr.msg -v1 " start <service>    Start service or platform"
    gr.msg -v1 " restart            restart service or platform"
    gr.msg -v1 " stop               stop service or platform"
    gr.msg -v1 " update             update service or platform"
    gr.msg -v1 " install            install requirements "
    gr.msg -v1 " uninstall          remove installed requirements "
    gr.msg -v2
    gr.msg -v1 -c white  "services:"
    gr.msg -v3 " docker             containing system"
    gr.msg -v3 " dokuwiki           documentation platform4"
    gr.msg -v3 " wekan              can ban ticket board"
    gr.msg -v2
    gr.msg -v1 -c white  "example:"
    gr.msg -v1 "    $GURU_CALL tovsdf install docker"
    gr.msg -v2
}


docker.restart () {
    gr.msg -c blue "TBD"
    return 0
}


docker.install () {
# install docker to local
# mainly based on https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-20-04

    source /etc/os-release

    gr.msg "checking network connection.."
    if ! ping  -W 3 -c 1 -q docker.com >/dev/null ; then
            gr.msg -c yellow "cannot reach docker.com"
            return 99
        fi

    if ! sudo apt update ; then
            gr.msg -c yellow "source list cannot updated"
            return 100
        fi

    # install needed stuff
    sudo apt install apt-transport-https ca-certificates curl software-properties-common

    # add apr key if not added already
    if ! sudo apt-key list | grep 'docker@docker.com' ; then
            gr.msg -v2 -c white "adding key to apt key list "
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        fi

    # add docker source to sources list
    # check is source listed in sources.list (previous standard location)
    if ! /etc/apt/sources.list | grep download.docker.com ; then
        # if not check is it se in additional-repositories.list and ad source there (current standard location)
        if ! grep -v '#' /etc/apt/sources.d/additional-repositories.list | grep download.docker.com ; then
                gr.msg -v2 -c white "adding repository to /etc/apt/sources.list "
                sudo add-apt-repository "deb https://download.docker.com/linux/ubuntu $UBUNTU_CODENAME stable"
            fi
        fi

    # check did package git installed
    gr.msg -v2 -n "checking installation.. "
    if sudo apt install docker-ce -y ; then
            local _error=$?
            gr.msg -c yellow "error $_error during installation"
            return $_error
        fi

    # check installation by running Docker
    gr.msg -v2 -n "running docker.. "
    if ! sudo docker info ; then
            gr.msg -c yellow "unable to to run docker"
            gr.msg 'you may need to logout and login to enable changes'
            return 100
        fi

    gr.msg -v1 -c green "ok"
    return 0
}


docker.add-to-group () {
# let user to use docker
    sudo usermod -aG docker ${USER}
    gr.msg 'please logout and log in to enable changes'
}


docker.start () {
# sudo systemctl status docker || sudo dockerd
    return 0
}


docker.restart () {
    docker.stop
    docker.start
    return $?
}


docker.uninstall () {

    dpkg -l | grep -i docker
    sudo apt-get purge -y docker-engine docker docker.io docker-ce docker-ce-cli
    sudo apt-get autoremove -y --purge docker-engine docker docker.io docker-ce

    if grep -v '#' /etc/apt/sources.list | grep download.docker.com ; then
        # remove repo
        gr.msg -c dark_grey "TBD $FUNCNAME remove repo"
        fi

    if grep -v '#' /etc/apt/sources.list | grep download.docker.com ; then
        # remove key
        gr.msg -c dark_grey "TBD $FUNCNAME remove key"
        fi
}


wekan.update () {
# update wekan
    gr.msg -c dark_grey "TBD $FUNCNAME"
    return 0
}


dokuwiki.update () {
# pull up to date version from git repository


    dokuwiki.backup $@

# if like to update container
    # local _platform="dokuwiki" # or container
    # [[ $1 ]] && _platform=$1

    # case $_platform in
    #     container)
    #         dokuwiki.container_update
    #         return $?
    #         ;;
    #     dokuwiki)
    #         ;;
    #     all)
    #         ;;
    #       *)
    #         return 1
    #     esac

# for now just update contaier
    dokuwiki.container_update $@
    return $?
}


dokuwiki.update_container () {
# update ghcr.io dokuwiki container

    # default container name
    local container_name="dokuwiki"

    # overwrite if guru-cli variable set
    [[ $GURU_WIKI_CONTAINER_NAME ]] && container_name=$GURU_WIKI_CONTAINER_NAME

    # process user input
    [[ $1 ]] && container_name=$1

    # "we do not recommend or support updating apps inside the container"
    # https://github.com/linuxserver/docker-dokuwiki/pkgs/container/dokuwiki
    procedure=("echo docker inspect -f '{{ index .Config.Labels build_version }} $container_name"
               "echo docker-compose pull $container_name"
               "echo docker-compose up -d $container_name"
               'echo docker image prune'
               #'docker logs -f'
               )

    for (( i = 0; i < ${#procedure[@]}; i++ )); do
        gr.msg -n -v2 "${procedure[$i]}.. "
        if ${procedure[$i]}; then
            gr.msg -v1 -cgreen "ok "
        else
            gr.msg -cyellow "error when '${procedure[$i]}'"
            return $i
        fi
    done
}


dokuwiki.backup () {
# make backup out of dokuwiki data and conf inside of container (opt $1) on server (opt $2)

    # default values
    local container_name="dokuwiki"
    local server="roima"
    local include_folders=(data conf)
    local _date=$(date +%Y%m%d)
    local to_where="${GURU_BACKUP_SERVER_BASE[2]}/${GURU_BACKUP_SERVER_BASE[3]}"

    # overwrite default values if guru-cli variable set
    [[ $GURU_WIKI_CONTAINER_NAME ]] && container_name=$GURU_WIKI_CONTAINER_NAME

    # overwrite if user input
    [[ $1 ]] && container_name=$1
    [[ $2 ]] && server=$2

    local data_folder="$to_where/$container_name-$_date"
    local temp_folder="/tmp/$container_name"

    gr.msg "making backup.. "
    ssh $server -- "[[ -d $temp_folder ]] || mkdir $temp_folder"

    for _inc_folder in ${include_folders[@]}; do
            gr.msg -v2 "$_inc_folder.. "
            ssh $server -- "docker cp $container_name:/config/dokuwiki/$_inc_folder $temp_folder"
        done

    if ssh $server -- "tar -cjf /tmp/$container_name.tar.bz2 $temp_folder" ; then
            gr.msg -v2 -c green "ok"
        fi

    if [[ -d "$data_folder" ]] ; then
            gr.msg -n "removing current backup $data_folder.. "
            rm -fr $data_folder && gr.msg "ok"
        else
            mkdir "$data_folder"
        fi

    gr.msg -n "copying.. "
    if scp "$server:/tmp/$container_name.tar.bz2" "$data_folder/" ; then
            ssh $server -- "rm /tmp/$container_name.tar.bz2 ; rm -rf /tmp/$container_name"
            gr.msg -v2 -c green "ok"
        else
            gr.msg -c yellow "error when copying $container_name.tar.bz2"
            return 100
        fi

    return 0
}

# fuckit
# wekan.update () {
#     # take a database dump and copy it to location set in user.cfg where normal process can copy it to local

#     local _domain=$1
#     local _port=$2
#     local _user=$3
#     local _location=$4

#     # stop container
#     gr.msg -h "stopping docker container.. "
#     gr.debug "Command: ssh ${_user}@${_domain} -p ${_port} ssh ${_user}@${_domain} -p ${_port} -- docker stop wekan"

#     if ssh ${_user}@${_domain} -p ${_port} -- docker stop wekan >/dev/null ; then
#         gr.msg -v2 -c green "ok"
#     else
#         gr.msg -c yellow "error $?"
#         return 128
#     fi

#     # # delete current dump
#     gr.msg -h "delete last dump.. "
#     gr.debug "Command: ${_user}@${_domain} -p ${_port} -- docker exec wekan-db rm -rf /data/dump"

#     if ssh ${_user}@${_domain} -p ${_port} -- docker exec wekan-db rm -rf /data/dump >/dev/null ; then
#         gr.msg -v2 -c green "ok"
#     else
#         gr.msg -c yellow "error $?"
#         return 129
#     fi

#     # take a dump
#     gr.msg -h "take a dump /data/dump.. "
#     gr.debug "Command: ssh ${_user}@${_domain} -p ${_port} -- docker exec wekan-db mongodump -o /data/dump"

#     if ssh ${_user}@${_domain} -p ${_port} -- docker exec wekan-db mongodump -o /data/dump 2>/dev/null ; then
#         gr.msg -c green "ok"
#     else
#         gr.msg -c yellow "error $?"
#         return 130
#     fi

#     # copy to where to rsyck it to final location
#     gr.msg -h "copy to ${_location}.. "
#     gr.debug "Command: ssh ${_user}@${_domain} -p ${_port} -- [[ -d ${_location} ]] || mkdir -p ${_location}"

#     if ssh ${_user}@${_domain} -p ${_port} -- docker cp wekan-db:/data/dump ${_location}  ; then
#         gr.msg -v2 -c green "ok"
#     else
#         gr.msg -c yellow "error $?"
#         return 131
#     fi

#     # start container
#     gr.msg -h "starting docker container.. "
#     gr.debug "Command: ssh ${_user}@${_domain} -p ${_port} -- docker start wekan"

#     if ssh ${_user}@${_domain} -p ${_port} -- docker start wekan >/dev/null ; then
#         gr.msg -v2 -c green "ok"
#     else
#         gr.msg -c yellow "error $?"
#         return 132
#     fi

#     return 0
# }




tovsdf.debug () {
    gr.msg  "${FUNCNAME[0]^^}: tovsdf.sh" -c white
    gr.msg "GURU_WIKI_CONTAINER_NAME:$GURU_WIKI_CONTAINER_NAME"
    gr.msg "GURU_BACKUP_SERVER_BASE:$GURU_BACKUP_SERVER_BASE"
}

[[ $GURU_DEBUG ]] && tovsdf.debug

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # [[ -f $GURU_RC ]] && source $GURU_RC
    tovsdf.main $@
    exit $?
fi

