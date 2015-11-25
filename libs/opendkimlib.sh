function regenerate_opendkim {
    
     mkdir -p /var/srvctl-host/opendkim
     rm -rf /var/srvctl-host/opendkim/*
     echo '127.0.0.1' >> /var/srvctl-host/opendkim/TrustedHosts
     echo '::1' >> /var/srvctl-host/opendkim/TrustedHosts
     echo '10.10.0.0/16' >> /var/srvctl-host/opendkim/TrustedHosts
     echo '' >> /var/srvctl-host/opendkim/SigningTable
     echo '' >> /var/srvctl-host/opendkim/KeyTable
     
     for _c in $(lxc-ls)
     do
         if [ ! -d $SRV/$_c/opendkim ]
         then
             mkdir -p $SRV/$_c/opendkim
             opendkim-genkey -D $SRV/$_c/opendkim -d $_c -s default
             chown -R root:opendkim $SRV/$_c/opendkim
             chmod 640 $SRV/$_c/opendkim/default.private
             chmod 644 $SRV/$_c/opendkim/default.txt
         fi
         
         get_dns_servers $_c       
         if [ "$dns_provider" == $CDN ]
         then 
             msg "OpenDKIM is signing mail for $_c"
             echo $_c >> /var/srvctl-host/opendkim/TrustedHosts
             echo "default._domainkey.$_c $_c:default:$SRV/$_c/opendkim/default.private" >> /var/srvctl-host/opendkim/KeyTable
             echo "*@$_c default._domainkey.$_c" >> /var/srvctl-host/opendkim/SigningTable
         #else
         #    msg "DNS provider for $_c is $dns_provider"
         fi
    done
    
    
    systemctl enable opendkim.service
    systemctl restart opendkim.service
    
    test=$(systemctl is-active opendkim.service)

    if [ "$test" == "active" ]
    then
        msg "OpenDKIM running." > /dev/null
    else
        systemctl status opendkim.service
    fi
}

