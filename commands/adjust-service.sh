#!/bin/bash

## start or restart service
hint "SERVICE OP | OP SERVICE" "start|stop|restart|status a service via systemctl.  +|-|!|?"

if [ "$ARG" == "add" ] || [ "$ARG" == "start" ] || [ "$ARG" == "+" ] || [ "$ARG" == "restart" ] || [ "$ARG" == "!" ] || [ "$ARG" == "stop" ]  || [ "$ARG" == "-" ] || [ "$ARG" == "status" ]  || [ "$ARG" == "?" ] || [ "$CMD" == "remove" ]
then
    OP=$ARG
    SERVICE=$CMD
fi 

if [ "$CMD" == "add" ] || [ "$CMD" == "start" ] || [ "$CMD" == "+" ] || [ "$CMD" == "restart" ] || [ "$CMD" == "!" ] || [ "$CMD" == "stop" ]  || [ "$CMD" == "-" ] || [ "$CMD" == "status" ]  || [ "$CMD" == "?" ] || [ "$CMD" == "remove" ]
then
    OP=$CMD
    SERVICE=$ARG
fi

if [ ! -z "$SERVICE" ] && [ ! -z "$OP" ] && [ -f "/usr/lib/systemd/system/$SERVICE.service" ] 
then
  
  
    if [ "$OP" == "status" ]  || [ "$OP" == "?" ] 
    then
        systemctl status $SERVICE.service
    else
    
        if $isROOT   
        then

            if [ "$OP" == "add" ] || [ "$OP" == "+" ] 
            then
                add_service $SERVICE
            fi


            if [ "$OP" == "start" ] || [ "$OP" == "restart" ] || [ "$OP" == "!" ] 
            then
                systemctl enable  $SERVICE.service
                systemctl restart $SERVICE.service
                systemctl status $SERVICE.service
            fi


            if [ "$OP" == "stop" ] 
            then
                systemctl disable $SERVICE.service
                systemctl stop $SERVICE.service
                systemctl status $SERVICE.service
            fi
    
    
            if [ "$OP" == "remove" ]  || [ "$OP" == "-" ] 
            then
                rm_service $SERVICE
            fi 
    
        else
            err "These service operations need root privileges."  
        fi
  
    fi
  
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


