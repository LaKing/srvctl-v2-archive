function regenerate_opendkim {
    
     _var=/var/opendkim
    
     mkdir -p $_var
     
     chmod 750 $_var
     rm -rf $_var/*
     echo '127.0.0.1' >> $_var/TrustedHosts
     echo '::1' >> $_var/TrustedHosts
     echo '10.10.0.0/16' >> $_var/TrustedHosts
     echo '' >> $_var/SigningTable
     echo '' >> $_var/KeyTable
     
     chmod -R 640 $_var
     chmod 750 $_var
     
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
         fi

         
         if [[ $_c != *.local ]]
         then 
             echo $_c >> $_var/TrustedHosts
             
             for i in $SRV/$_c/opendkim/*.private
             do
                 selector="$(basename $i)"
                 selector="${selector:0:-8}"
                 
                 mkdir -p $_var/$_c
                 chmod 750 $_var/$_c
                 
                 cat $SRV/$_c/opendkim/$selector.private > $_var/$_c/$selector.private
                 chmod -R 640 $_var/$_c/$selector.private
                 
                 echo "$selector._domainkey.$_c $_c:$selector:$_var/$_c/$selector.private" >> $_var/KeyTable
                 echo "*@$_c $selector._domainkey.$_c" >> $_var/SigningTable
             done
         fi
         
         chown -R opendkim:opendkim $_var
         
         
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

