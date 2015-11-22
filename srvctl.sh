#!/bin/bash
#
# Server Controll script for Fedora with LXC containers
#
# D250 Laboratories / D250.hu
# Author: István király
# LaKing@D250.hu
# 
## Source URL
## URL="https://raw.githubusercontent.com/LaKing/Fedora-scripts/master/srvctl"

install_bin=$(realpath "$BASH_SOURCE")
install_dir=${install_bin:0:-10}

## set FEDORA to the corresponding fedora version on this computer
FEDORA=0
FEDORA_RELEASE="$(cat /etc/fedora-release)"
if [ "${FEDORA_RELEASE:0:6}" == "Fedora" ]
then
    FEDORA=${FEDORA_RELEASE:15:2}
    FEDORA=$(($FEDORA+0))
else
    ## Something is wrong. This is not even fedora. We just run the client then, ...
    ## TODO check how this should be with CentOS and other distros.
    source $install_dir/srvctl-client.sh $1
fi

source $install_dir/init.sh
source $install_dir/authorize.sh

if [ "$CMD" == "man" ] || [ "$CMD" == "help" ] || [ "$CMD" == "-help" ] || [ "$CMD" == "--help" ]
then
    source $install_dir/srvctl-man.sh
    exit
fi

## init libs
source $install_dir/libs/commonlib.sh
load_libs
 
logs "[$USER@$HOSTNAME $(pwd)]# $0 $*"
#msg "$(head $0 -n 3 | grep version)"
SUCC=""
 
## hint provides a sort of help functionality - initialize empty
function hint {
        echo "-" >> /dev/null
} 
 
## this is used at the end of command-blocks, to confirm command success or failure.
function ok {
SUCC=" "
}
 
 
## if onVE C - the container name - should be the hostname
C=$HOSTNAME
 
#load the commands - and execute them 
load_commands
 
source $install_dir/finish.sh

