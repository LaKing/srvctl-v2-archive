#!/bin/bash

dbg $isROOT

#if $isROOT
#then 
## no identation

## start or restart service
hint "SERVICE OP | OP SERVICE" "start|stop|restart|status a service via systemctl.  +|-|!|?"

if [ "$2" == "start" ] || [ "$2" == "+" ] || [ "$2" == "restart" ] || [ "$2" == "!" ] || [ "$2" == "stop" ]  || [ "$2" == "-" ] || [ "$2" == "status" ]  || [ "$2" == "?" ]
then
    OP=$2
    SERVICE=$1
fi 

if [ "$1" == "start" ] || [ "$1" == "+" ] || [ "$1" == "restart" ] || [ "$1" == "!" ] || [ "$1" == "stop" ]  || [ "$1" == "-" ] || [ "$1" == "status" ]  || [ "$1" == "?" ]
then
    OP=$1
    SERVICE=$2
fi

dbg $OP $SERVICE

if [ ! -z "$SERVICE" ] && [ ! -z "$OP" ] && [ -f "/usr/lib/systemd/system/$SERVICE.service" ] 
then
  
  if $isROOT   
  then
  
    if [ "$OP" == "start" ] || [ "$OP" == "+" ] 
    then
        systemctl enable $SERVICE.service
        systemctl start  $SERVICE.service

    fi ## start


    if [ "$OP" == "restart" ] || [ "$OP" == "!" ] 
    then
        systemctl enable  $SERVICE.service
        systemctl restart $SERVICE.service

    fi ## restart


    if [ "$OP" == "stop" ]  || [ "$OP" == "-" ] 
    then
        systemctl disable $SERVICE.service
        systemctl stop $SERVICE.service

    fi ## disable
 
  fi
  
  systemctl status $SERVICE.service
  ok

fi

man '
    This is a shorthand syntax for frequent operations on services.
    the following are equivalent:
        
        systemctl status example.service
        sc example ?
        
    to query a service with the supershort operator "?" or with "status"
    to restart and enable a service the operator is "!" or "restart"
    to start and enable a service the operator is "+" or "start"
    to stop and disable a service the operator is "-" or "stop"
        
'

#fi ## isROOT

