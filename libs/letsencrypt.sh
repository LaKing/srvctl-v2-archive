

function add_to_domlist {
    
    _domain=$1
    
    ## verify if we dont already have a srvctl cert for this domain (verified wildcard cert)
    #for _d in $(ls /etc/srvctl/cert)
    #do   
    #    sc_pem=/etc/srvctl/cert/$_d/pound.pem
    #    if [ -f $sc_pem ]
    #    then
    #        if openssl verify -CAfile $sc_pem -verify_hostname $_domain $sc_pem > /dev/null
    #        then
    #            #dbg "$_domain has a certificate."
    #            return
    #        fi
    #    fi
    #done
    
    _address=$(dig @8.8.8.8 -4 +short +answer  +time=1 $_domain | tail -n 1)

    if [ -z "$_address" ]
    then
        #dbg "$_domain can't be domain-authicated."
        echo "$_domain can't be domain-authicated." >> $SRV/$_c/rootfs/var/log/srvctl/letsencrypt.log
        return
    fi

    
    if grep -q $_address /var/srvctl/ifcfg/ipv4
    then
        _domlist="$_domlist -d $_domain"
    else
        ntc "$_domain is on $_address"
    fi
}

function get_acme_certificate { ## for container
    _c=$1 
    _dom=$_c
    
    if [ ${_c:0:5} == "mail." ]
    then
        return
    fi
    
    if [[ $_c == *.local ]] 
    then 
        return
    fi
    
    ## we enforce now here that wildcard certificated domains do not create any LE certs.
    for _d in $(ls /etc/srvctl/cert)
    do 
        if [[ $_dom == *".$_d" ]] || [ $_dom == "$_d" ]
        then
            #dbg "$_domain should have a wildcard certificate."
            return
        fi
    done
    
    ## destination is cert/pound.pem
    cert_dir=$SRV/$_c/cert
    mkdir -p $cert_dir
    ve_pem=$cert_dir/pound.pem
 
    le_dir=/etc/letsencrypt/live/$_c
    
    ## letsencrypt will set le_dir to www if it cant authenticate the bare domain
    if [ ! -d $le_dir ] && [ -d /etc/letsencrypt/live/www.$_c ]
    then
        le_dir=/etc/letsencrypt/live/www.$_c
    fi
    
    cert_pem=$le_dir/cert.pem
    fullchain_pem=$le_dir/fullchain.pem
    privkey_pem=$le_dir/privkey.pem
    
    if [ -f $ve_pem ]
    then
    
        if openssl x509 -checkend 604800 -noout -in $cert_pem
        then
            #ntc "Certificate is OK. $cert_pem"
            return
        fi
    fi
    
    if [ -f $cert_pem ] && [ ! -f $ve_pem ]
    then
        if openssl x509 -checkend 604800 -noout -in $cert_pem
        then
            ntc "Letsencrypt certificate is ok! Deploying."

            cat $cert_pem > $cert_dir/crt.pem
            cat $privkey_pem > $cert_dir/key.pem
            cat $fullchain_pem > $cert_dir/fullchain.pem
            cat /etc/letsencrypt/ca.pem > $cert_dir/ca.pem

            cat $privkey_pem > $ve_pem
            cat $fullchain_pem >> $ve_pem
            cat /etc/letsencrypt/ca.pem >> $ve_pem
            return
        else
            msg "Letsencrypt certificate has expired or will do so within a week!"
            ## renewal?
        fi
    fi
    
    ## a-b-c.domain.org notation
    _sc=$(echo $_dom | tr '.' '-')
    
    _domlist=''
    add_to_domlist $_dom 
    add_to_domlist www.$_dom 
    
    ## TODO read from settings
    #add_to_domlist en.$_dom 
    #add_to_domlist hu.$_dom
    
    if [ -z "$_domlist" ]
    then
        #dbg "$_dom has no domains for letsencrypt authentication."
        echo "$_dom has no domains for letsencrypt authentication." >> $SRV/$_c/rootfs/var/log/srvctl/letsencrypt.log
        return
    fi
    
    
    if [ "$(systemctl is-active pound.service)" != "active" ]
    then
        err "Pound is not running!"
        systemctl status pound.service
        
        exit 99
    fi
    
    if [ "$(systemctl is-active acme-server.service)" != "active" ]
    then
        err "Acme server is not running!"
        systemctl status acme-server.service
        
        exit 98
    fi
    

    ## ACTION!
    msg "letsencrypt create certificate for $_dom"
    echo "letsencrypt certonly --agree-tos --webroot --webroot-path /var/acme/ $_domlist"
    echo @$_domlist >> $LOG/letsencrypt.log
    letsencrypt certonly --agree-tos --webroot --webroot-path /var/acme/ $_domlist >> $LOG/rootfs/var/log/srvctl/letsencrypt.log 2>> $SRV/$_c/rootfs/var/log/srvctl/letsencrypt.log
    
    if [ "$?" == 0 ]
    then
        msg "Letsencrypt certonly success"
        return
    else
        err "Letsencrypt certonly failed"
        cat $SRV/$_c/rootfs/var/log/srvctl/letsencrypt.log
        echo "letsencrypt certonly failed" >> $SRV/$_c/rootfs/var/log/srvctl/letsencrypt.log
        return
    fi
    
    
    if [ ! -f $cert_pem ]
    then
        err "$cert_pem missing."
        return
    fi
    
    if [ ! -f $fullchain_pem ]
    then
        err "$fullchain_pem missing."
        return
    fi
    
    if [ ! -f $privkey_pem ]
    then
        err "$privkey_pem missing."
        return
    fi
    
    cat $cert_pem > $cert_dir/crt.pem
    cat $privkey_pem > $cert_dir/key.pem
    cat $fullchain_pem > $cert_dir/fullchain.pem
    cat /etc/letsencrypt/ca.pem > $cert_dir/ca.pem

    cat $privkey_pem > $ve_pem
    cat $fullchain_pem >> $ve_pem
    cat /etc/letsencrypt/ca.pem >> $ve_pem

    if openssl verify -CAfile $ve_pem $ve_pem >> /dev/null
    then
        msg "Certificate verified, and deployed."
    else
        err "Verify $ve_pem failed."
        rm -rf $ve_pem
    fi
}

function regenerate_letsencrypt {
        
    if [ -f /var/srvctl-host/letsencrypt ] && [ "$(cat /var/srvctl-host/letsencrypt)" == "$today" ]
    then
        return
    else
        echo $today > /var/srvctl-host/letsencrypt
        msg "Regenerate letsencrypt certificates"
        for _C in $(lxc-ls)
        do
            rm -rf $SRV/$_C/rootfs/var/log/srvctl/letsencrypt.log
            get_acme_certificate $_C
        done
    fi
}


