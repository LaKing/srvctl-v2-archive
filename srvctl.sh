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

if [ ! -d /usr/share/srvctl ]
then
    install_bin=$(realpath "$BASH_SOURCE")
    install_dir=${install_bin:0:-10}
else
    install_bin=/usr/share/srvctl/srvctl.sh
    install_dir=/usr/share/srvctl
fi

    install_ver=$(cat $install_dir/version)

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
#echo "Libs loaded"
 
logs "[$(whoami)@$(hostname) $(pwd)]# $0 $*"
#msg "$(head $0 -n 3 | grep version)"
SUCC=""
 
## hint provides a sort of help functionality - initialize empty
function hint {
        echo 0 >> /dev/null
} 
 
## this is used at the end of command-blocks, to confirm command success or failure.
function ok {
SUCC=" "
}
 
 
## if onVE C - the container name - should be the hostname
C=$HOSTNAME
       
#load the commands - and execute them 
load_commands
#echo "Commands loaded"
 
source $install_dir/finish.sh


