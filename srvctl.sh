#!/bin/bash
# Last update:2015.01.07-04:26:26
# version 2.0.2
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

source $install_dir/authorize.sh
source $install_dir/init.sh

for libfile in $install_dir/libs/*
do
        source $libfile
done

log "[$(whoami)@$(hostname) $(pwd)]# $0 $1 $2 $3 $4 $5 $6 $7 $8 $9"
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

### TODO 2.x check if this is needed. propably only on source install
if $onHS
then
        ## yum and source builds work with different directories.
        lxc_usr_path="/usr"
        if [ "$LXC_INSTALL" == "git" ] || [ "$LXC_INSTALL" == "src" ] || [ "$LXC_INSTALL" == "zip" ]
        then
                lxc_usr_path="/usr/local"

                if [ -z $(echo $LD_LIBRARY_PATH | grep '/usr/local/lib') ]
                then
                        export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib
                fi
        fi

fi

## if onVE C - the container name - should be the hostname
C=$(hostname)

## note if debug is on or off
dbg "Debug mode: on"

for sourcefile in $install_dir/commands/*
do
        source $sourcefile
done

source $install_dir/finish.sh
