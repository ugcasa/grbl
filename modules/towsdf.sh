#!/bin/bash 
# towsdf - tools to orchestrate wery small docker farm 

# include guru-cli common functions or
source common.sh 2>/dev/null || gr.msg () { echo "${@##-*}" | sed 's/^[[:space:]]*//' ; }

towsdf.main () {

    local cmd=$1 ; shift
    local platform=docker
    [[ $1 ]] && platform=$1 ; shift

    case $cmd in
        install|start|restart|stop|update|uninstall )
            $platform.$cmd $@
            return $?
            ;;
        *) gr.msg -c yellow "unknown command $cmd"
            towsdf.help
            ;;
    esac
}


towsdf.help () {
    gr.msg -v1 -c white "guru-client towsdf help "
    gr.msg -v2
    gr.msg -v0 "usage:    $GURU_CALL towsdf install|start|restart|stop|update|uninstall service"
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
    gr.msg -v3 " docker             "
    gr.msg -v3 " dokuwiki           "
    gr.msg -v3 " wekan              "
    gr.msg -v2
    gr.msg -v1 -c white  "example:"
    gr.msg -v1 "    $GURU_CALL towsdf install docker"
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

    if ! sudo apt update ; then
            gr.msg -c yellow "system not updatable, check network connections"
            return 100
        fi

    sudo apt install apt-transport-https ca-certificates curl software-properties-common

    if ! sudo apt-key list | grep 'docker@docker.com' ; then
            gr.msg -v2 -c white "adding key to apt key list "
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        fi

    if ! grep -v '#' /etc/apt/sources.list | grep download.docker.com ; then
            gr.msg -v2 -c white "adding repository to /etc/apt/sources.list "
            sudo add-apt-repository "deb https://download.docker.com/linux/ubuntu $UBUNTU_CODENAME stable"
        fi

    if sudo apt install docker-ce -y ; then
            local _error=$?
            gr.msg -c yellow "error $_error during installation"
            return $_error
        fi

    gr.msg -v2 -n "checking installation.. "
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
        fi

    if grep -v '#' /etc/apt/sources.list | grep download.docker.com ; then
        # remove key
        fi
}


dokuwiki.update () {
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

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    [[ -f $GURU_RC ]] && source $GURU_RC
    towsdf.main $@
    exit $?
fi

