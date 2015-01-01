#!/bin/bash

## Some init stuff

## some formatted date 
NOW=$(date +%Y.%m.%d-%H:%M:%S)
MSG="## srvctl modification. $NOW"
DDN=$(dnsdomainname)

## if enabled, containers should be accessible on container.yourdomain.net
ENABLE_CDDN=true

####################################################
## Configuration defaults - Overwritten in config!
##
##(TODO: or rpm / yum if latest version will be available in a repo, so not yet .)

## srvctl config 
## Use with "" if value contains spaces.

## use the latst version, options are 'yum' 'git' 'zip' 'src' 
LXC_INSTALL='yum'
## eventually specify the version - mandatory for zip, optional for yum
LXC_VERSION=''

## logfile
LOG=/var/log/srvctl.log

## temporal backup and work directory
TMP=/temp

## The main /srv folder mount point - SSD recommended
SRV=/srv

## Used for certificate generation - do not leave it empty in config file.
ssl_password=no_pass

## Company codename - use your own
CMP=Unknown

## Company domain name - use your own
CDN=Unknown

## CC as Certificate creation
CCC=HU
CCST=Hungary
CCL=Budapest

## IPv4 Address of the host
HOSTIPv4=127.0.0.1

## IPv6 address of the host
HOSTIPv6=::1

## IPv6 address range base
RANGEv6=::1
PREFIXv6=64

## File to share this system's VE domains to ns servers - http share recommended
dns_share=/root/dns.tar.gz


#### the following options are exported to containers, when they get created..

## for php.ini in containers
php_timezone=Europe/Budapest

## turn off debug messages
debug=false

##########################################################
## These where the sourceable variables - used in update-install too!
## Import custom configuration directives now, t oapply customized variables.
source /etc/srvctl/config 2> /dev/null
##
##########################################################

## Some way to figure out, .. is this script running in the srvctl container, or on the host system?
if mount | grep -q 'on /var/srvctl' 
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

## we use the format srvctl or sc command argument [plus-arguments]
CMD=$1
ARG=$2
## Current start directory
CWD=$(pwd)

##cd /root
