#!/bin/bash

## Some init stuff
## first, variables that can be, but dont have to be custom

## some formatted date 
NOW=$(date +%Y.%m.%d-%H:%M:%S)
MSG="## srvctl modification. $NOW"
DDN=$(dnsdomainname)

## if enabled, containers should be accessible on container.yourdomain.net
ENABLE_CDDN=true

####################################################

## These where the variables to be custimized - used in update-install too!
source $install_dir/hs-install/config

##########################################################

## Import custom configuration directives now, to apply customized variables.
if [ -f "/etc/srvctl/config" ]
then
    source /etc/srvctl/config 
    #2> /dev/null
fi

## variable detection

onHS=false
onVE=false
isUSER=false
isROOT=false
isSUDO=false

LXC_SERVER=false

SC_USER="$(whoami)"

if [ -f "/var/srvctl/locale-archive" ] 
then
    LXC_SERVER=true
    ## Some way to figure out, .. is this script running in the srvctl container, or on the host system?
    if mount | grep -q 'on /var/srvctl type' 
    then
      ## We are in a container of srvctl for sure
      #echo CONTAINER $(hostname)
      onHS=false
      onVE=true
    else
      ## We are propably on the host
      #echo HOST $(hostname)
      onHS=true
      onVE=false
    fi
fi

## we use the format srvctl or sc command argument [plus-argument]
## command
CMD=$1
## argument
ARG=$2
## optional single argument
OPA=$3
## all arguments, including command and argument
ARGS="$*"
## Current start directory
CWD=$(pwd)

cd ~



