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
             dkim_selector="default"
             if [ ${_c:0:5} == "mail." ]
             then
                 dkim_selector="mail"
             fi
             mkdir -p $SRV/$_c/opendkim
             opendkim-genkey -D $SRV/$_c/opendkim -d $_c -s $dkim_selector
             chown -R root:opendkim $SRV/$_c/opendkim
             chmod 640 $SRV/$_c/opendkim/default.private
             chmod 644 $SRV/$_c/opendkim/default.txt
         fi
         
         if [[ $_c != *.local ]] && [ -d $SRV/$_c/opendkim ]
         then 
             echo $_c >> /var/srvctl-host/opendkim/TrustedHosts
             
             for i in $SRV/$_c/opendkim/*.private
             do
                 selector="$(basename $i)"
                 selector="${selector:0:-8}"
                 echo "$selector._domainkey.$_c $_c:$selector:$SRV/$_c/opendkim/$selector.private" >> /var/srvctl-host/opendkim/KeyTable
                 echo "*@$_c $selector._domainkey.$_c" >> /var/srvctl-host/opendkim/SigningTable
             done
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

