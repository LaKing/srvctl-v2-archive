#!/bin/bash
# Last update:2015.04.21-18:44:04
# version 2.2.3
#
# Server Controll script for Fedora with LXC containers
#
# D250 Laboratories / D250.hu
# Author: István király
# LaKing@D250.hu
# 
## Source URL
#URL="https://raw.githubusercontent.com/LaKing/Fedora-scripts/master/srvctl"

## try $(dirname "$BASH_SOURCE")
install_dir=/usr/share/srvctl

source $install_dir/init.sh
source $install_dir/authorize.sh

## init libs
for libfile in $install_dir/libs/*
do
        source $libfile
done

log "[$(whoami)@$(hostname) $(pwd)]# $0 $@"
msg "$(head $0 -n 3 | grep version)"
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

## note if debug is on or off
dbg "Debug mode: on"
dbg "HS: $onHS VE: $onVE SERVER: $LXC_SERVER"

for sourcefile in $install_dir/commands/*
do
        source $sourcefile
done

source $install_dir/finish.sh
