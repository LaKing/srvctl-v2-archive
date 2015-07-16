#!/bin/bash
# Last update:2015.07.16-15:31:49
# version 2.2.5
#
# Server Controll script for Fedora with LXC containers
#
# D250 Laboratories / D250.hu
# Author: István király
# LaKing@D250.hu
# 
## Source URL
#URL="https://raw.githubusercontent.com/LaKing/Fedora-scripts/master/srvctl"

echo -e "\e[2m$(head $0 -n 3 | grep version)"

install_bin=$(realpath "$BASH_SOURCE")
install_dir=${install_bin:0:-10}

source $install_dir/init.sh
source $install_dir/authorize.sh

if [ "$CMD" == "man" ] || [ "$CMD" == "help" ] || [ "$CMD" == "-help" ] || [ "$CMD" == "--help" ]
then
    source $install_dir/srvctl-man.sh
    exit
fi

## init libs
for libfile in $install_dir/libs/*
do
        source $libfile
done
 
log "[$(whoami)@$(hostname) $(pwd)]# $0 $@"
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
C=$(hostname)
 
#load the commands - and execute them 
for sourcefile in $install_dir/commands/*
do
        source $sourcefile
done
 
source $install_dir/finish.sh
