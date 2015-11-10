#!/bin/bash

## start or restart service
hint "SERVICE OP | OP SERVICE" "start|stop|restart|status a service via systemctl.  +|-|!|?"

if [ "$ARG" == "start" ] || [ "$ARG" == "+" ] || [ "$ARG" == "restart" ] || [ "$ARG" == "!" ] || [ "$ARG" == "stop" ]  || [ "$ARG" == "-" ] || [ "$ARG" == "status" ]  || [ "$ARG" == "?" ]
then
    OP=$ARG
    SERVICE=$CMD
fi 

if [ "$CMD" == "start" ] || [ "$CMD" == "+" ] || [ "$CMD" == "restart" ] || [ "$CMD" == "!" ] || [ "$CMD" == "stop" ]  || [ "$CMD" == "-" ] || [ "$CMD" == "status" ]  || [ "$CMD" == "?" ]
then
    OP=$CMD
    SERVICE=$ARG
fi

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

