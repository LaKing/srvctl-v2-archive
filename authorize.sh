#!/bin/bash

## Taken from LabLib ONLY for the manual
green='\e[32m'
red='\e[31m'
blue='\e[34m'
yellow='\e[33m'
xxxx='\e[33m'

NC='\e[0m' # No Color

function hint {
 if [ ! -z "$1" ]
  then
        ## print formatted hint
        printf ${green}"%-40s"${NC} "  $1" 
        printf ${yellow}"%-48s"${NC} "$2"
        ## newline
        echo ''
 fi
} 

function man {
     printf ${xxxx}"%-40s"${NC} "  $1"
     echo ''
     echo ''
}

if [ "$1" == "man" ] || [ "$1" == "help" ] || [ "$1" == "-help" ] || [ "$1" == "--help" ]
then    
        for sourcefile in $install_dir/commands/*
        do
                source $sourcefile
        done
        exit
fi

function man {
    echo 1 > /dev/null
}

## If user is root or runs on root privileges, continiue. 
## (TODO: userspace implementation)
if [ "$UID" -ne "0" ]
then
    echo "The srvctl script needs root privileges. Running srvctl-client now! $(whoami)"
    ## we only run the client script. 
    if (( "$UID" < 1000 ))
    then
        echo "system user: $(whoami)"
    else
        source $install_dir/srvctl-client.sh
    fi
    exit
fi


## other wise, root can continiue.
