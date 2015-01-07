#!/bin/bash

## start or restart service
hint "SERVICE OP" "start|stop|restart|status a service via systemctl.  +|-|!|?"
if [ "$2" == "start" ] || [ "$2" == "+" ] 
then
        if [ -f "/usr/lib/systemd/system/$1.service" ]
        then

        systemctl enable $1.service
        systemctl start  $1.service
        systemctl status $1.service

        ok
        fi

fi ## start


if [ "$2" == "restart" ] || [ "$2" == "!" ] 
then
        if [ -f "/usr/lib/systemd/system/$1.service" ]
        then

        systemctl enable  $1.service
        systemctl restart $1.service
        systemctl status  $1.service

        ok
        fi

fi ## restart


if [ "$2" == "stop" ]  || [ "$2" == "-" ] 
then
        if [ -f "/usr/lib/systemd/system/$1.service" ]
        then

        systemctl disable $1.service
        systemctl stop $1.service
        systemctl status $1.service

        ok
        fi

fi ## disable


if [ "$2" == "status" ]  || [ "$2" == "?" ] 
then
        if [ -f "/usr/lib/systemd/system/$1.service" ]
        then
        systemctl status $1.service
        ok
        fi

fi ## stop

man '
    This is a shorthand syntax for frequent server operations.
    the following are equivalent:
        systemctl status example.service
        sc example ?
        
    to query a service with the supershort operator "?" or with "status"
    to restart and enable a service the operator is "!" or "restart"
    to start and enable a service the operator is "+" or "start"
    to stop and disable a service the operator is "-" or "stop"
        
'

