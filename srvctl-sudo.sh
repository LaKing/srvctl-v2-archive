#!/bin/bash

## Special srvctl for sudo use only.
if [ "$UID" -ne "0" ]
then
    echo "ERROR. nonroot sudoer."
    exit
fi

## limited init
install_dir=/usr/share/srvctl
source $install_dir/init.sh

## silent log entry
echo "$NOW : [$SUDO_USER@$(hostname) $(pwd)]# $0 $@" >> $LOG

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
SC_SUDO_USER=$SUDO_USER

## init libs
for libfile in $install_dir/libs/*
do
        source $libfile
done

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

## execute the sudo command
for sourcefile in $install_dir/commands/*
do
        source $sourcefile
done


## return to the directory we started from.
cd $CWD >> /dev/null 2> /dev/null
