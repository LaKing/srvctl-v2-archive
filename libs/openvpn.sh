function make_openvpn_client_conf { ## for user

    local _u=$1
    local _ovpn=/home/$_u/$CDN-$HOSTNAME-openvpn-conf.ovpn

    if [ -f $_ovpn ]
    then
        return
    fi

    if ssh $ROOTCA_HOST srvctl create_ca_certificate client usernet $_u
    then
                
    save_file $_ovpn "## Openvpn client configuration file for $HOSTNAME
## Windows users can install http://www.openvpn.net/release/openvpn-2.1.3-install.exe
## Configs
client
dev tap$HOSTNET
proto udp
remote $HOSTNAME 1100
nobind
persist-key
persist-tun
comp-lzo
verb 3        
## Certificates
<ca>
$(ssh $ROOTCA_HOST cat /etc/srvctl/CA/ca/usernet.crt.pem)
</ca>
<cert>
$(ssh $ROOTCA_HOST cat /etc/srvctl/CA/usernet/client-$_u.crt.pem)
</cert>
<key>
$(ssh $ROOTCA_HOST cat /etc/srvctl/CA/usernet/client-$_u.key.pem)
</key>
"

    msg "Created openvpn config file for $_u@$HOSTNAME"
    
    else
        err "Connection to $ROOTCA_HOST failed ..."
    fi

}



