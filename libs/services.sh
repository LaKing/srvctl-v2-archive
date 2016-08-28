function restart_service {
    local service=$1
               
    systemctl restart $service
    
    local _xit=$?
    
    if [ "$_xit" == 0 ]
    then
         msg "$service $(systemctl is-active $service) $(systemctl is-enabled $service)"
    else
        err "restart of $service failed (exit-code $_xit)"
        systemctl status $service --no-pager
    fi   
        
   
}

function restart_services {
     
     msg "restarting all services"
     
     if [ ! -d /etc/srvctl/system ]
     then
        err "No srvctl-managed services."
        return
     fi
     
     
     for r in /etc/srvctl/system/*
     do
         restart_service ${r:19}
     done
     
    if [ -f "/usr/lib/systemd/system/openvpn@.service" ]
    then
    
        for c in /etc/openvpn/*.conf
        do
            restart_service "openvpn@${c:13: -5}"     
        done  
    fi
        
}

