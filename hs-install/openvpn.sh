msg "Installing openvpn"

## delete empty files
for f in /etc/openvpn/*
do
    if [ -z "$(cat $f)" ]
    then
        rm -fr $f
    fi
done

## installl openvpn
pmc openvpn

    if [ "$ROOTCA_HOST" == "$HOSTNAME" ]
    then
        msg "regenerate hosts config - this is the CA"
    
        root_CA_init

        create_ca_certificate client usernet root
        create_ca_certificate client hostnet root
        
        create_ca_certificate server usernet $HOSTNAME
        create_ca_certificate server hostnet $HOSTNAME
        
        create_ca_certificate client usernet $HOSTNAME
        create_ca_certificate client hostnet $HOSTNAME
        
        cat /etc/srvctl/CA/ca/usernet.crt.pem > /etc/openvpn/usernet-ca.crt.pem 
        cat /etc/srvctl/CA/ca/hostnet.crt.pem > /etc/openvpn/hostnet-ca.crt.pem 
        
        cat /etc/srvctl/CA/usernet/server-$HOSTNAME.key.pem > /etc/openvpn/usernet-server.key.pem 
        cat /etc/srvctl/CA/usernet/server-$HOSTNAME.crt.pem > /etc/openvpn/usernet-server.crt.pem 
        
        cat /etc/srvctl/CA/hostnet/server-$HOSTNAME.key.pem > /etc/openvpn/hostnet-server.key.pem 
        cat /etc/srvctl/CA/hostnet/server-$HOSTNAME.crt.pem > /etc/openvpn/hostnet-server.crt.pem 
        
        cat /etc/srvctl/CA/usernet/client-$HOSTNAME.key.pem > /etc/openvpn/usernet-client.key.pem 
        cat /etc/srvctl/CA/usernet/client-$HOSTNAME.crt.pem > /etc/openvpn/usernet-client.crt.pem 
        
        cat /etc/srvctl/CA/hostnet/client-$HOSTNAME.key.pem > /etc/openvpn/hostnet-client.key.pem 
        cat /etc/srvctl/CA/hostnet/client-$HOSTNAME.crt.pem > /etc/openvpn/hostnet-client.crt.pem    
        
        for _S in $SRVCTL_HOSTS
        do
            ## openvpn client certificate
            create_ca_certificate server usernet $_S
            create_ca_certificate server hostnet $_S
            
            create_ca_certificate client usernet $_S
            create_ca_certificate client hostnet $_S
            
            cat /etc/srvctl/CA/usernet/server-$HOSTNAME.key.pem > /etc/openvpn/usernet-server.key.pem 
            cat /etc/srvctl/CA/usernet/server-$HOSTNAME.crt.pem > /etc/openvpn/usernet-server.crt.pem 
        
            cat /etc/srvctl/CA/hostnet/server-$HOSTNAME.key.pem > /etc/openvpn/hostnet-server.key.pem 
            cat /etc/srvctl/CA/hostnet/server-$HOSTNAME.crt.pem > /etc/openvpn/hostnet-server.crt.pem 
            
        done
        

        
    else
    
        if [ "$(ssh -n -o ConnectTimeout=1 $ROOTCA_HOST hostname 2> /dev/null)" == "$ROOTCA_HOST" ]
        then
    
            msg "regenerate hosts config - CA is $ROOTCA_HOST"
    
            if [ ! -f /etc/openvpn/usernet-ca.crt.pem ] || [ ! -f /etc/openvpn/hostnet-ca.crt.pem ] || $all_arg_set
            then
                msg "Grabbing CA certificates from $ROOTCA_HOST for openvpn"
                ssh -n -o ConnectTimeout=1 root@$ROOTCA_HOST "cat /etc/srvctl/CA/ca/usernet.crt.pem" > /etc/openvpn/usernet-ca.crt.pem
                ssh -n -o ConnectTimeout=1 root@$ROOTCA_HOST "cat /etc/srvctl/CA/ca/hostnet.crt.pem" > /etc/openvpn/hostnet-ca.crt.pem
            fi
                
            if [ ! -f /etc/openvpn/usernet-server.crt.pem ] || [ ! -f /etc/openvpn/usernet-server.key.pem ] || $all_arg_set
            then
                msg "Grabbing usernet $HOSTNAME server certificate from $ROOTCA_HOST for openvpn"
                ssh -n -o ConnectTimeout=1 root@$ROOTCA_HOST "cat /etc/srvctl/CA/usernet/server-$HOSTNAME.crt.pem" > /etc/openvpn/usernet-server.crt.pem
                ssh -n -o ConnectTimeout=1 root@$ROOTCA_HOST "cat /etc/srvctl/CA/usernet/server-$HOSTNAME.key.pem" > /etc/openvpn/usernet-server.key.pem
            fi
        
            if [ ! -f /etc/openvpn/hostnet-server.crt.pem ] || [ ! -f /etc/openvpn/hostnet-server.key.pem ] || $all_arg_set
            then
                msg "Grabbing hostnet $HOSTNAME server certificate from $ROOTCA_HOST for openvpn"
                ssh -n -o ConnectTimeout=1 root@$ROOTCA_HOST "cat /etc/srvctl/CA/hostnet/server-$HOSTNAME.crt.pem" > /etc/openvpn/hostnet-server.crt.pem
                ssh -n -o ConnectTimeout=1 root@$ROOTCA_HOST "cat /etc/srvctl/CA/hostnet/server-$HOSTNAME.key.pem" > /etc/openvpn/hostnet-server.key.pem
            fi
            
            if [ ! -f /etc/openvpn/usernet-client.crt.pem ] || [ ! -f /etc/openvpn/usernet-client.key.pem ] || $all_arg_set
            then
                msg "Grabbing usernet $HOSTNAME client certificate from $ROOTCA_HOST for openvpn"
                ssh -n -o ConnectTimeout=1 root@$ROOTCA_HOST "cat /etc/srvctl/CA/usernet/client-$HOSTNAME.crt.pem" > /etc/openvpn/usernet-client.crt.pem
                ssh -n -o ConnectTimeout=1 root@$ROOTCA_HOST "cat /etc/srvctl/CA/usernet/client-$HOSTNAME.key.pem" > /etc/openvpn/usernet-client.key.pem
            fi
        
            if [ ! -f /etc/openvpn/hostnet-client.crt.pem ] || [ ! -f /etc/openvpn/hostnet-client.key.pem ] || $all_arg_set
            then
                msg "Grabbing hostnet $HOSTNAME client certificate from $ROOTCA_HOST for openvpn"
                ssh -n -o ConnectTimeout=1 root@$ROOTCA_HOST "cat /etc/srvctl/CA/hostnet/client-$HOSTNAME.crt.pem" > /etc/openvpn/hostnet-client.crt.pem
                ssh -n -o ConnectTimeout=1 root@$ROOTCA_HOST "cat /etc/srvctl/CA/hostnet/client-$HOSTNAME.key.pem" > /etc/openvpn/hostnet-client.key.pem
            fi
        else
            err "CA $ROOTCA_HOST connection failed!"
            
        fi
        
    fi

chmod 600 /etc/openvpn/*.key.pem

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


save_file /etc/openvpn/usernet-server.conf '## srvctl-created openvpn conf

mode server
local 127.0.0.1
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
cert /etc/openvpn/usernet-server.crt.pem
key /etc/openvpn/usernet-server.key.pem
dh /etc/openvpn/dh2048.pem

client-config-dir /var/openvpn
ccd-exclusive

server-bridge 10.'$HOSTNET'.0.1 255.255.0.0 10.'$HOSTNET'.250.1 10.'$HOSTNET'.254.250
'

save_file /etc/openvpn/hostnet-server.conf '## srvctl-created openvpn conf

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
cert /etc/openvpn/hostnet-server.crt.pem
key /etc/openvpn/hostnet-server.key.pem
dh /etc/openvpn/dh2048.pem

server-bridge 10.'$HOSTNET'.0.1 255.255.0.0 10.'$HOSTNET'.254.1 10.'$HOSTNET'.254.254

'

## these are the server services

    msg "start openvpn servers"

        systemctl enable openvpn@usernet-server.service
        systemctl restart openvpn@usernet-server.service
        #sleep 2
        systemctl status openvpn@usernet-server.service --no-pager

        systemctl enable openvpn@hostnet-server.service
        systemctl restart openvpn@hostnet-server.service
        #sleep 2
        systemctl status openvpn@hostnet-server.service --no-pager

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
remote-cert-tls server
ca /etc/openvpn/hostnet-ca.crt.pem
cert /etc/openvpn/hostnet-client.crt.pem
key /etc/openvpn/hostnet-client.key.pem
comp-lzo
verb 3
'

    systemctl enable openvpn@$_SN.service
    systemctl restart openvpn@$_SN.service
    #sleep 2
    systemctl status openvpn@$_SN.service --no-pager
done






