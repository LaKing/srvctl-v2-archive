function get_pure_ip {
 ip=$(echo $1 | tr '/' ' ' | awk '{print $1}')
}

function get_primary_ip {
 ip=$(head -n 1 /var/srvctl/ifcfg/ipv4 | tr '/' ' ' | awk '{print $1}')
}


function process_ip_addr {
    
     IP=$2
     msg $IP   
     
     
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

function import_network_configuration {
    msg "Scanning network configuration"
 
    mkdir -p /var/srvctl/ifcfg
    rm -rf /var/srvctl/ifcfg/*
    
    for f in /etc/sysconfig/network-scripts/ifcfg-*
    do

        
        NAME=''
        IPADDR=''
        NETMASK=''
        PREFIX=''
        GATEWAY=''
        DNS1=''
        DNS2=''
        
        source $f
        
        if [ "${f: -4}" == ".bak" ]
        then
            continue
        fi
        
        if [ -z "$NAME" ]
        then
            bak $f
            file=$(basename $f)
            NAME=${file:6}
                msg "NAME=$NAME is missing from $f. Fixing."
            echo "NAME=$NAME" >> $f
        fi
        
        if [ "$NAME" != "loopback" ] && [ ! -z "$(ip link show $NAME | grep 'state UP')" ]
        then
            if [ ! -z "$GATEWAY" ]
            then
                msg $NAME appears to be the default interface
            else
                msg $NAME appears to be a secondary interface
            fi
            echo "IPADDR  $IPADDR"
            echo "NETMASK $NETMASK$PREFIX"
            echo "GATEWAY $GATEWAY"
            echo "DNS1    $DNS1"
            echo "DNS2    $DNS2"
            ip addr show $NAME | grep 'scope global' > $TMP/srvctl-network
            while read a
            do
                process_ip_addr $a
            done < $TMP/srvctl-network
        fi
    done

    
}

