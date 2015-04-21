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

if [ "$UID" -ne "0" ]
then
    if $LXC_SERVER
    then
        ## Authorize this user!
        LOG="$(realpath ~)/.srvctl.log"
        isUSER=true
        #exit
    else    
        ## we only run the client script. 
        if (( "$UID" < 1000 ))
        then
            echo "Permission denied for system user: $(whoami)"
        else
            echo "Running the srvctl-client now!"
            source $install_dir/srvctl-client.sh $1
        fi
        exit
    fi
else
    isROOT=true
fi


## other wise, root can continiue.
