#!/bin/bash

## Special srvctl for sudo use only.
if [ "$UID" -ne "0" ]
then
    echo "ERROR. nonroot sudoer."
    exit
fi

## limited init
isROOT=true
install_bin=$(realpath "$BASH_SOURCE")
install_dir=${install_bin:0:-15}
source $install_dir/init.sh
isROOT=true
isSUDO=true

## silent log entry
echo "$NOW : [$SUDO_USER@$(hostname) $(pwd)]# $0 $@" >> $LOG/sudo.log

## some extra checks
if ! $LXC_SERVER
then
    echo "ERROR. Not an LXC server."
    exit
fi

if ! $onHS
then
    echo "ERROR. Not on serverfarm host."
    exit
fi

if $onVE
then
    echo "ERROR. This is not supported on containers."
    exit
fi

##

## obsolete
SC_SUDO_USER=$SUDO_USER

#the real thing
SC_USER=$SUDO_USER

## init libs
source $install_dir/libs/commonlib.sh
load_libs

## disabled functions
function hint {
        echo "-" >> /dev/null
} 
function ok {
 echo "-" >> /dev/null   
}
function man {
 echo "-" >> /dev/null   
}

SUCC=" "

## execute the commands
load_commands


## return to the directory we started from.
cd $CWD >> /dev/null 2> /dev/null


