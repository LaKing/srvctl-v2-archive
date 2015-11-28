## constants
named_includes=/var/named/srvctl-includes.conf
named_live_path=/var/named/srvctl
named_main_path=/var/srvctl-host/named-local
named_slave_path=/var/srvctl-host/named-slave
        
## function-wide
today=$(date +%y%m%d)

function create_named_zone {

    ## argument domain ($_C or alias)
    D=$1

    named_conf=$named_main_path/$D.conf
    named_zone=$named_main_path/$D.zone
    named_slave=$named_slave_path/$D.slave
        
    named_live_zone=$named_live_path/$D.zone
    named_slave_zone=$named_live_path/$D.slave.zone
                
    mail_server="mail"
    spf_string="v=spf1 ip:$HOSTIPv4 a mx -all"
    dkim_selector="default"
        
        
    if [ -f "$SRV/$D/settings/dns-custom-zone" ] && [ ! -z "$(cat $SRV/$D/settings/dns-custom-zone)" ]
    then
        cat $SRV/$D/settings/dns-custom-zone >> $named_zone
        return
    fi
        
    if [ -f "$SRV/$D/settings/use-google-apps-mail" ] 
    then
        spf_string="v=spf1 ip:$HOSTIPv4 a mx include:_spf.google.com ~all"
    fi
        
    if [ -f "$SRV/$D/settings/dns-mx-record" ] && [ ! -z "$(cat $SRV/$D/settings/dns-mx-record)" ]
    then
        mail_server="$(cat $SRV/$D/settings/dns-mx-record | xargs)."            
    fi
        
    if [ -f "$SRV/$D/settings/dns-txt-spf" ] && [ ! -z "$(cat $SRV/$D/settings/dns-txt-spf)" ]
    then
        spf_string="$(cat $SRV/$D/settings/dns-txt-spf | xargs)."            
    fi
        
    echo '## srvctl named main conf '$D > $named_conf
    echo 'zone "'$D'" {' >> $named_conf
    echo '        type master;'  >> $named_conf
    echo '        file "'$named_live_zone'";' >> $named_conf
    echo '};' >> $named_conf

    echo '## srvctl named slave conf '$D > $named_slave
    echo 'zone "'$D'" {' >> $named_slave
    echo '        type slave;'  >> $named_slave
    echo '        masters {'$HOSTIPv4';};'  >> $named_slave
    echo '        file "'$named_slave_zone'";' >> $named_slave
    echo '};' >> $named_slave


        
    serial_file=/var/srvctl-host/named-$today
    serial=0
                
    if [ ! -f $serial_file ]
    then      
        serial=$today'0000'
        echo $serial > $serial_file
    else        
        serial=$(($(cat $serial_file)+1))
        echo $serial > $serial_file
    fi

        ## TODO add IPv6 support
        ## Create Basic Zonefile
        
set_file $named_zone '$TTL 1D
@        IN SOA        @ hostmaster.'$CDN'. (
                                        '$serial'        ; serial
                                        1D        ; refresh
                                        1H        ; retry
                                        1W        ; expire
                                        3H )        ; minimum
        IN         NS        ns1.'$CDN'.
        IN         NS        ns2.'$CDN'.
        IN         NS        ns3.'$CDN'.
*        IN         A        '$HOSTIPv4'
@        IN         A        '$HOSTIPv4'
'

    if [ -f "$SRV/$D/settings/use-google-apps-mail" ] 
    then

        ## Use google apps mailservers
        echo '
; nameservers for google apps
@    IN    MX    1    ASPMX.L.GOOGLE.COM
@    IN    MX    5    ALT1.ASPMX.L.GOOGLE.COM
@    IN    MX    5    ALT2.ASPMX.L.GOOGLE.COM
@    IN    MX    10    ALT3.ASPMX.L.GOOGLE.COM
@    IN    MX    10    ALT4.ASPMX.L.GOOGLE.COM
' >> $named_zone
        
        ## Use the dkim string if found
        if [ -f "$SRV/$D/settings/use-google-apps-dkim" ] 
        then    
            echo 'google._domainkey    IN    TXT    ( "'$(cat $SRV/$D/settings/use-google-apps-dkim)'" ) ; -- custom DKIM'
        fi
    else
    
        ## use custom / standard mail
        echo '@        IN        MX        10        '${mail_server,,} >> $named_zone
    fi

    ## add SPF
    echo '@    IN    TXT    "'$spf_string'"' >> $named_zone

    ## Add DKIM
    for i in $SRV/$D/opendkim/*.txt
    do
        selector="$(basename $i)"
        selector="${selector:0:-4}"
        cat $SRV/$D/opendkim/$selector.txt >> $named_zone
    done
    
    if [ -d $SRV/mail.$D/opendkim ] 
    then 
        ## we have a seperate mailserver
        for i in $SRV/mail.$D/opendkim/*.txt
        do
            selector="$(basename $i)"
            selector="${selector:0:-4}"
            cat $SRV/mail.$D/opendkim/$selector.txt >> $named_zone
        done
    fi
    
    if [ -f "$SRV/$D/settings/dns-custom-records" ] && [ ! -z "$(cat $SRV/$D/settings/dns-custom-records)" ]
    then
        cat $SRV/$D/settings/dns-custom-records >> $named_zone
    fi
    


## TODO IPv6
#'        AAAA        ::1'

## named zone written.                    

}

function regenerate_dns_publicinfo {
        
    if [ -f /var/srvctl-host/dns-pubinfo ] && [ "$(cat /var/srvctl-host/dns-pubinfo)" == "$today" ]
    then
        return
    else
        echo $today > /var/srvctl-host/dns-pubinfo
        
        ## TODO this is enough once a day
        msg "Regenerate DNS - query public information."
        for _C in $(lxc-ls)
        do
            rm -rf $SRV/$_C/dns-*
            get_dns_servers $_C
        done
    fi
}

function regenerate_dns {
    
        msg "Regenerate DNS - named/bind configs"
        
        ## dir might not exist
        mkdir -p $named_live_path
        mkdir -p $named_main_path
        mkdir -p $named_slave_path
                
        ## has to be empty for regeneration
        rm -rf $named_live_path/* 
        rm -rf $named_main_path/*
        rm -rf $named_slave_path/*
        
        ## the main include file
        named_local=/var/named/srvctl-local.conf
        
        
        ## the secondary file
        #named_slave_conf=$named_slave_path/srvctl-$(hostname).conf
        
        echo '## srvctl named includes' > $named_includes
        echo '## srvctl named primary local' > $named_local
        
        #echo '## srvctl named slaves'$(hostname) > $named_slave_conf

        for _C in $(lxc-ls)
        do
                ## skip local domains
                if [ "${_C: -6}" == ".local" ]
                then
                    continue
                fi
                
                ## skip mail-only servers
                if [ "${_C:0:5}" == "mail." ]
                then
                    continue
                fi
                
                
                ## option to skip servers
                if [ -f $SRV/$_C/settings/no-dns ]
                then
                    continue
                fi
                
                create_named_zone $_C
                echo 'include "/var/named/srvctl/'$_C'.conf";' >> $named_local
                #echo 'include "/var/named/srvctl/'$_C'.slave.conf";' >> $named_slave_conf

                if [ -f /$SRV/$_C/settings/aliases ]
                then
                        for A in $(cat /$SRV/$_C/settings/aliases)
                        do
                                #msg "$A is an alias of $_C"
                                create_named_zone $A
                                echo 'include "/var/named/srvctl/'$A'.conf";' >> $named_local
                                #echo 'include "/var/named/srvctl/'$A'.slave.conf";' >> $named_slave_conf
                        done
                fi
        done
        
        msg "Creating DNS share."
        ## delete first
        rm -rf $dns_share
                
        ## create tarball
        tar -czPf $dns_share -C $named_slave_path .


        echo 'include "'$named_local'";' >> $named_includes

        cp $named_main_path/*.zone $named_live_path
        cp $named_main_path/*.conf $named_live_path


        if [ -f /etc/srvctl/hosts ]
        then
            
            while read host
            do
            
              if [ "$(ssh -n -o ConnectTimeout=1 $host hostname 2> /dev/null)" == "$host" ]
              then
                msg "Update remote DNS connection for $host"
                
                rm -rf /var/srvctl-host/$host.dns.tar.gz
                
                wget -q --no-check-certificate https://$host/dns.tar.gz -O /var/srvctl-host/$host.dns.tar.gz
                if [ "$?" != "0" ]
                then
                    err "Failed to fetch DNS update information from https://$host/dns.tar.gz"
                    continue
                fi
                
                named_expath=/var/srvctl-host/named-$host
                
                rm -rf $named_expath/*
                mkdir -p $named_expath

                tar -xf /var/srvctl-host/$host.dns.tar.gz -C $named_expath
                
                ## expath alapján include file éas azt beincludolni
                named_exconf=/var/named/srvctl-$host.conf
                echo 'include "'$named_exconf'";' >> $named_includes
                echo '## srvctl named external slave conf includes' > $named_exconf 
                
                for ex in $(ls $named_expath)
                do
                    echo 'include "/var/named/srvctl/'$ex'";' >> $named_exconf
                done
                
                chown root:named $named_exconf
                chmod 640 $named_exconf
                
                cp $named_expath/*.slave $named_live_path
              else
                err "Could not connect to $host"
                ssh -n -o ConnectTimeout=1 $host hostname
              fi

            done < /etc/srvctl/hosts  

        fi
        
        chown root:named $named_includes
        chmod 640 $named_includes
        
        chown -R root:named $named_live_path
        chmod -R 640 $named_live_path
        chmod 650 $named_live_path
        
        ## all preparations done, activate!
        systemctl restart named.service
        test=$(systemctl is-active named.service)
        if ! [ "$test" == "active" ]
        then
            err "Error loading DNS settings."
            systemctl status named.service
            exit
        else
            msg "DNS server OK"
        fi
        
}

function get_dns_authority { ## for domain name $_c
    dns_authority=''
    ## we will buffer the dns authority
    
    if [ ! -f $SRV/$_c/dns-authority ] || $all_arg_set
    then
        _query=''
        _query="$(dig @8.8.8.8 +noall +authority  +time=1 NS $_c | cut -f1 )"
    
        if [ -z "$_query" ]
        then
            dns_authority=$_c
        else
            dns_authority="${_query%?}"
        fi
        
        ## result
        echo "$dns_authority" > $SRV/$_c/dns-authority

    fi

    ## return
    dns_authority="$(cat $SRV/$_c/dns-authority)"
}

function get_dns_provider { ## for domain name $_c
    
    dns_provider=''
    if [ ! -f $SRV/$_c/dns-provider ] || $all_arg_set
    then

        ## we will buffer the dns authority
        if [ ! -f $SRV/$_c/dns-servers ] || $all_arg_set
        then
            dig @8.8.8.8 +short +answer +time=1 NS $dns_authority > $SRV/$_c/dns-servers
        fi
    
        if [ -z "$(cat $SRV/$_c/dns-servers)" ]
        then
            err "Domain $_c has no name servers. ($dns_authority?)"
        fi 
    
    
        dns_provider=''
        while read dns_server
        do 
            _query="$(dig @8.8.8.8 +noall +authority +time=1 NS $dns_server | cut -f1 )"
            if [ -z "$dns_provider" ]
            then
                dns_provider="${_query%?}"
            else
                if [ "$dns_provider" != "${_query%?}" ]
                then
                    echo "$_c has multiple DNS authorities! ($dns_provider. $_query)" > $SRV/$_c/err.log
                fi
            fi
        done < $SRV/$_c/dns-servers
    
        echo $dns_provider > $SRV/$_c/dns-provider
    else 
        dns_provider="$(cat $SRV/$_c/dns-provider)"
    fi
}

function get_dns_servers { ## argument domain
    
    _c=$1
    dns_provider=''
    
    ## dont apply for local containers, aliases, and mailservers
    if [[ $_c != *.local ]] && [ -d $SRV/$_c ] && [ "${_c:0:5}" != mail ] 
    then
        get_dns_authority
        
        if [[ "$dns_authority" != *.* ]]
        then
            rm -rf $SRV/$_c/dns-authority
            get_dns_authority
            echo "$_c has no DNS authority. ($dns_authority?) $(cat $SRV/$_c/dns-provider 2> /dev/null)" > $SRV/$_c/err.log
        else
            get_dns_provider
        fi
    fi
}


