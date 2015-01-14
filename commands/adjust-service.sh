#!/bin/bash

## start or restart service
hint "SERVICE OP | OP SERVICE" "start|stop|restart|status a service via systemctl.  +|-|!|?"

OP=$2
SERVICE=$1

if [ "$1" == "start" ] || [ "$1" == "+" ] || [ "$1" == "restart" ] || [ "$1" == "!" ] || [ "$1" == "stop" ]  || [ "$1" == "-" ] || [ "$1" == "status" ]  || [ "$1" == "?" ]
then
    OP=$1
    SERVICE=$2
fi

if [ ! -f "/usr/lib/systemd/system/$SERVICE.service" ]
then
    exit
fi

if [ "$OP" == "start" ] || [ "$OP" == "+" ] 
then
        systemctl enable $SERVICE.service
        systemctl start  $SERVICE.service
        systemctl status $SERVICE.service

        ok
fi ## start


if [ "$OP" == "restart" ] || [ "$OP" == "!" ] 
then
        systemctl enable  $SERVICE.service
        systemctl restart $SERVICE.service
        systemctl status  $SERVICE.service

        ok
fi ## restart


if [ "$OP" == "stop" ]  || [ "$OP" == "-" ] 
then
        systemctl disable $SERVICE.service
        systemctl stop $SERVICE.service
        systemctl status $SERVICE.service

        ok
fi ## disable


if [ "$OP" == "status" ]  || [ "$OP" == "?" ] 
then
        systemctl status $SERVICE.service
        ok
fi ## stop

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

