#!/bin/bash

## Some init stuff
## first, variables that can be, but dont have to be custom

## some formatted date 
NOW=$(date +%Y.%m.%d-%H:%M:%S)
MSG="## srvctl $NOW"

## Servers can have a direct domain name - what we can override
## useful in multi-server setups
DDN=$(dnsdomainname)
SDN=$(dnsdomainname)

## MYSQL / MARIADB conf file that stores the mysql root password - in containers
MDF=/etc/mysqldump.conf

## global variables with default values
all_arg_set=false

## get $VERSION_ID
source /etc/os-release
ARCH=$(uname -m)


SRVCTL_HOSTS=''

if [ -f /etc/srvctl/hosts ]
then

    while read _h
    do

        if [ "$_h" == "$HOSTNAME" ] || [ "$_h" == localhost ] || [ "$HOSTNAME" == localhost ]
        then
            continue
        fi
              
        SRVCTL_HOSTS="$_h $SRVCTL_HOSTS"

    done < /etc/srvctl/hosts
fi

## defaults that can stay as tey are
## .. or can be customized, ...

DISABLE_NFS=false
DISABLE_BINDMOUNT=false
LOGO_SVG=$install_dir/d250.svg
LOGO_ICO=$install_dir/favicon.ico

## set FEDORA to the corresponding fedora version on this computer

if ! [ "$NAME" == "Fedora" ]
then
    ## Something is wrong. This is not even fedora. We just run the client then, ...
    ## TODO check how this should be with CentOS and other distros.
    source $install_dir/srvctl-client.sh $1
fi

####################################################

## The main /srv folder mount point - SSD recommended
SRV=/srv

## These where the variables to be custimized - used in update-install too!
source $install_dir/hs-install/config

##########################################################

## Import custom configuration directives now, to apply customized variables.
if [ -f "/etc/srvctl/config" ]
then
    source /etc/srvctl/config 

    #if [ -z "$HOSTIPv4" ]
    #then
    #    HOSTIPv4=$(dig @ns1.google.com -t txt o-o.myaddr.l.google.com +short)
    #    ntc "HOSTIPv4 is $HOSTIPv4"
    #    echo "## srvctl-detected $NOW" >> /etc/srvctl/config 
    #    echo "HOSTIPv4=$HOSTIPv4" >> /etc/srvctl/config
    #    echo '' >> /etc/srvctl/config
    #fi

fi



mkdir -p $LOG

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
## command, lowercase
CMD=$1
CMD=${CMD,,}
## argument
ARG=$2
## optional single argument
OPA=$3
## all optional arguments
OPAS="${@:2}"
OPAS3="${@:3}"
OPAS4="${@:4}"
## all arguments, including command and argument
ARGS="$*"

## Current start directory
CWD=$(pwd)
cd ~






