msg "Installing openvpn"

## installl openvpn
pmc openvpn

    if [ "$rootca_host" == "$HOSTNAME" ]
    then
        msg "regenerate hosts config - this is the CA"
    
        root_CA_init
        
        create_client_certificate usernet $HOSTNAME
        create_client_certificate hostnet $HOSTNAME
        
        for _S in $SRVCTL_HOSTS
        do
            ## openvpn client certificate
            create_client_certificate usernet $_S
            create_client_certificate hostnet $_S
        done
        
        cat /etc/srvctl/CA/ca/usernet.crt.pem > /etc/openvpn/usernet-ca.crt.pem 
        cat /etc/srvctl/CA/ca/hostnet.crt.pem > /etc/openvpn/hostnet-ca.crt.pem 
        
        cat /etc/srvctl/CA/usernet/$CDN-$HOSTNAME.key.pem > /etc/openvpn/usernet.key.pem 
        cat /etc/srvctl/CA/usernet/$CDN-$HOSTNAME.crt.pem > /etc/openvpn/usernet.crt.pem 
        
        cat /etc/srvctl/CA/hostnet/$HOSTNAME.key.pem > /etc/openvpn/hostnet.key.pem 
        cat /etc/srvctl/CA/hostnet/$HOSTNAME.crt.pem > /etc/openvpn/hostnet.crt.pem 

        chmod 600 /etc/openvpn/usernet.key.pem
        chmod 600 /etc/openvpn/hostnet.key.pem 
        
    else
    
        if [ "$(ssh -n -o ConnectTimeout=1 $rootca_host hostname 2> /dev/null)" == "$rootca_host" ]
        then
    
            msg "regenerate hosts config - CA is $rootca_host"
    
            if [ ! -f /etc/openvpn/usernet-ca.crt.pem ] || [ ! -f /etc/openvpn/hostnet-ca.crt.pem ] || $all_arg_set
            then
                msg "Grabbing CA certificates from $rootca_host for openvpn"
                ssh -n -o ConnectTimeout=1 root@$rootca_host "cat /etc/srvctl/CA/ca/usernet.crt.pem" > /etc/openvpn/usernet-ca.crt.pem
                ssh -n -o ConnectTimeout=1 root@$rootca_host "cat /etc/srvctl/CA/ca/hostnet.crt.pem" > /etc/openvpn/hostnet-ca.crt.pem
            fi
                
            if [ ! -f /etc/openvpn/usernet.crt.pem ] || [ ! -f /etc/openvpn/usernet.key.pem ] || $all_arg_set
            then
                msg "Grabbing usernet $HOSTNAME certificate from $rootca_host for openvpn"
                ssh -n -o ConnectTimeout=1 root@$rootca_host "cat /etc/srvctl/CA/usernet/$CDN-$HOSTNAME.crt.pem" > /etc/openvpn/usernet.crt.pem
                ssh -n -o ConnectTimeout=1 root@$rootca_host "cat /etc/srvctl/CA/usernet/$CDN-$HOSTNAME.key.pem" > /etc/openvpn/usernet.key.pem
            fi
        
            if [ ! -f /etc/openvpn/hostnet.crt.pem ] || [ ! -f /etc/openvpn/hostnet.key.pem ] || $all_arg_set
            then
                msg "Grabbing hostnet $HOSTNAME certificate from $rootca_host for openvpn"
                ssh -n -o ConnectTimeout=1 root@$rootca_host "cat /etc/srvctl/CA/hostnet/$HOSTNAME.crt.pem" > /etc/openvpn/hostnet.crt.pem
                ssh -n -o ConnectTimeout=1 root@$rootca_host "cat /etc/srvctl/CA/hostnet/$HOSTNAME.key.pem" > /etc/openvpn/hostnet.key.pem
            fi
            
            chmod 600 /etc/openvpn/usernet.key.pem
            chmod 600 /etc/openvpn/hostnet.key.pem 
        
        else
            err "CA $rootca_host connection failed!"
            
        fi
        
    fi

if [ ! -f /etc/openvpn/dh2048.pem ]
then
    openssl dhparam -out /etc/openvpn/dh2048.pem 2048
fi 

## will contain user files
mkdir -p /var/openvpn

## regenerate_users_configs

save_file /etc/openvpn/bridgeup.sh '
#!/bin/sh
BR=$1
DEV=$2
MTU=$3
/sbin/ip link set "$DEV" up promisc on mtu "$MTU"
/sbin/brctl addif "$BR" "$DEV"
exit 0
'

save_file /etc/openvpn/bridgedown.sh '
#!/bin/sh 
BR=$1
DEV=$2
/sbin/brctl delif "$BR" "$DEV"
/sbin/ip link set "$DEV" down
exit 0
'


save_file /etc/openvpn/usernet.conf '## srvctl-created openvpn conf

mode server
port 1100
dev tap-usernet
proto udp
status usernet.log 60
status-version 2
user openvpn
group openvpn
persist-tun
persist-key
keepalive 10 60
inactive 600
verb 4
comp-lzo
script-security 2

up "/bin/bash bridgeup.sh srv-net tap-usernet 1500"
down "/bin/bash bridgedown.sh srv-net tap-usernet"

tls-server 
ca /etc/openvpn/usernet-ca.crt.pem
cert /etc/openvpn/usernet.crt.pem
key /etc/openvpn/usernet.key.pem
dh /etc/openvpn/dh2048.pem

client-config-dir /var/openvpn
ccd-exclusive

server-bridge 10.'$HOSTNET'.0.1 255.255.0.0 10.'$HOSTNET'.250.1 10.'$HOSTNET'.254.250
'

save_file /etc/openvpn/hostnet.conf '## srvctl-created openvpn conf

mode server
port 1101
dev tap-hostnet
proto udp
status hostnet.log 60
status-version 2
user openvpn
group openvpn
persist-tun
persist-key
keepalive 10 60
inactive 600
verb 4
comp-lzo
script-security 2

up "/bin/bash bridgeup.sh srv-net tap-hostnet 1500"
down "/bin/bash bridgedown.sh srv-net tap-hostnet"

tls-server 
ca /etc/openvpn/hostnet-ca.crt.pem
cert /etc/openvpn/hostnet.crt.pem
key /etc/openvpn/hostnet.key.pem
dh /etc/openvpn/dh2048.pem

server-bridge 10.'$HOSTNET'.0.1 255.255.0.0 10.'$HOSTNET'.254.1 10.'$HOSTNET'.254.254

'

## these are the server services

    msg "start openvpn servers"

        systemctl enable openvpn@usernet.service
        systemctl restart openvpn@usernet.service
        sleep 2
        systemctl status openvpn@usernet.service --no-pager

        systemctl enable openvpn@hostnet.service
        systemctl restart openvpn@hostnet.service
        sleep 2
        systemctl status openvpn@hostnet.service --no-pager

## now the clients for the hostnet

for _S in $SRVCTL_HOSTS
do
    msg "hostnet-openvpn clients for $_S"

    _SN=$(echo $_S | tr '.' '-')

save_file /etc/openvpn/$_SN.conf '## srvctl hostnet openvpn client file
client
dev tap-'$_SN'
proto udp
remote '$_S' 1101
nobind
persist-key
persist-tun
ca /etc/openvpn/hostnet-ca.crt.pem
cert /etc/openvpn/hostnet.crt.pem
key /etc/openvpn/hostnet.key.pem
comp-lzo
verb 3
'

    systemctl enable openvpn@$_SN.service
    systemctl restart openvpn@$_SN.service
    sleep 2
    systemctl status openvpn@$_SN.service
done

