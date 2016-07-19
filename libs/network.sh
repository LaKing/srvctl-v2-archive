function get_pure_ip {
 ip=$(echo $1 | tr '/' ' ' | awk '{print $1}')
}

function get_primary_ip {
 ip=$(head -n 1 /var/srvctl/ifcfg/ipv4 | tr '/' ' ' | awk '{print $1}')
}


function process_ip_addr {
    
     IP=$2
     echo "  $IP"   
     
     
     if [ "$1" == inet ]
     then
         ## ipv4 address
         if [ "$(ipcalc --addrspace $IP)" != 'ADDRSPACE="Private Use"' ]
         then
             ipcalc -g $IP > /var/srvctl/geoinfo
             echo $IP >> /var/srvctl/ifcfg/ipv4
         fi
     fi
     
     if [ "$1" == inet6 ]
     then
         ## ipv6 address
         echo $IP >> /var/srvctl/ifcfg/ipv6
     fi
     
     
}

function process_network_interface_configuration {
 
        interface=$9
        
        msg "$interface"
        
        ip addr show $interface | grep 'scope global' > /var/srvctl/ifcfg/$interface
        
            while read a
            do
                process_ip_addr $a
            done < /var/srvctl/ifcfg/$interface
        
}


function import_network_configuration {
    msg "Scanning network configuration"
 
    mkdir -p /var/srvctl/ifcfg
    rm -rf /var/srvctl/ifcfg/*
    
    ls -l /sys/class/net | grep 'devices/pci' > /var/srvctl/ifcfg/cards
    
    while read i 
    do
         process_network_interface_configuration $i  
    done < /var/srvctl/ifcfg/cards

    
}

