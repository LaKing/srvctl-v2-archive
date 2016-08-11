#!/bin/bash

## start or restart service
hint "SERVICE OP | OP SERVICE" "start|stop|restart|status (enable|remove) a service via systemctl. Shortcuts for OP: +|-|!|?"

OP=''
SERVICE=''

if [ "$ARG" == "enable" ] || [ "$ARG" == "start" ] || [ "$ARG" == "+" ] || [ "$ARG" == "restart" ] || [ "$ARG" == "!" ] || [ "$ARG" == "stop" ]  || [ "$ARG" == "-" ] || [ "$ARG" == "status" ]  || [ "$ARG" == "?" ] || [ "$ARG" == "remove" ]
then
    OP=$ARG
    SERVICE=$CMD
fi 

if [ "$CMD" == "enable" ] || [ "$CMD" == "start" ] || [ "$CMD" == "+" ] || [ "$CMD" == "restart" ] || [ "$CMD" == "!" ] || [ "$CMD" == "stop" ]  || [ "$CMD" == "-" ] || [ "$CMD" == "status" ]  || [ "$CMD" == "?" ] || [ "$CMD" == "remove" ]
then
    OP=$CMD
    SERVICE=$ARG
fi

if [ "$OP" == "?" ] 
then 
    OP=status
fi
if [ "$OP" == "!" ] 
then 
    OP=restart
fi
if [ "$OP" == "+" ] 
then 
    OP=enable
fi
if [ "$OP" == "-" ] 
then 
    OP=remove
fi

if [ ! -z "$SERVICE" ] && [ ! -z "$OP" ] && [ -f "/usr/lib/systemd/system/$SERVICE.service" ]
then
  
  
    if [ "$OP" == "status" ] 
    then
        systemctl status $SERVICE.service  --no-pager
    else
    
        if $isROOT   
        then

            if [ "$OP" == "enable" ]
            then
                add_service $SERVICE
            fi


            if [ "$OP" == "start" ]
            then
                systemctl enable  $SERVICE.service
                systemctl restart $SERVICE.service
                systemctl status $SERVICE.service  --no-pager
            fi


            if [ "$OP" == "stop" ] 
            then
                systemctl disable $SERVICE.service
                systemctl stop $SERVICE.service
                systemctl status $SERVICE.service  --no-pager
            fi
    
    
            if [ "$OP" == "remove" ]
            then
                rm_service $SERVICE
            fi 
    
        else
            err "These service operations need root privileges."  
        fi
  
    fi
  
ok
fi

if [ "$SERVICE" == openvpn ] && [ ! -z "$OP" ] && [ -f "/usr/lib/systemd/system/openvpn@.service" ] && $isROOT
then
        
        for c in /etc/openvpn/*.conf
        do
            s="${c:13: -5}"
            msg "$s"
            echo "systemctl $OP openvpn@$s --no-pager"
            systemctl $OP openvpn@$s --no-pager
            
            if [ "$OP" == "restart" ]
            then
                systemctl status openvpn@$s --no-pager
            fi
            
        done  
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


