#!/bin/bash


install_bin=$(realpath "$BASH_SOURCE")
install_dir=${install_bin:0:-14}


onHS=true
onVE=true
isUSER=true
isROOT=true

LXC_SERVER=true

## we use the format srvctl or sc command argument [plus-argument]
## command
CMD=''
## argument
ARG=''
## optional single argument
OPA=''
## all arguments
ARGS=''
## Current start directory

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

function msg {
     echo '' > /dev/null   
}
   
source $install_dir/libs/commonlib.sh
load_commands

echo "srvctl by Istvan Kiraly - LaKing@D250.hu - D250 Laboratories - 2015"


exit


