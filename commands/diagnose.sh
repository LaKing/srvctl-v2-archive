#!/bin/bash

#if $isROOT
#then

hint "scan" "Run scan or phpscan and clamscan to diagnose infections even while the container is offline."
if [ "$CMD" == "scan" ] || [ "$CMD" == "phpscan" ]
then
        sudomize
        source $install_dir/libs/phpscan.sh
        mkdir -p $LOG/phpscan
        
        for C in $(lxc_ls)
        do
            msg "phpscan $C"
            phpscan $SRV/$C/rootfs/var/www/html $LOG/phpscan/$C.log
        done
ok
fi

if [ "$CMD" == "scan" ] || [ "$CMD" == "clamscan" ]
then
        sudomize
        
        msg "Running freshclam"
        freshclam
        for C in $(lxc_ls)
        do 
            msg "CLAMAV-SCAN $C"
        
            karantene_path="$SRV/$C/rootfs/root/clamav-quarantine"
            mkdir -p $karantene_path
            for u in $(ls $SRV/$C/rootfs/home)
            do
                ntc $u@$C
                clamscan -r --move=$karantene_path /$SRV/$C/rootfs/home/$u/Maildir
            done
        done

ok
fi
man '
    Set of troubleshooting commands.
    Detect malicious PHP files with phpscan, files with a score above 1000 are really suspicious!
    Scan emails for viruses with clamscan, and put them innto a quarantine folder.
'

hint "diagnose" "Run a set of diagnostic commands."
if [ "$CMD" == "diagnose" ]
then        
        uname -a

        ## maintain these list of variables for debugging!
        msg "srvctl variables and settings."
        echo "NAME: $NAME"
        echo "ARCH: $ARCH"
        echo "VERSION_ID: $VERSION_ID"
        echo "install_bin: $install_bin"
        echo "install_dir: $install_dir"
        echo "install_ver: $install_ver"
        echo "C: $C"
        echo "onVE: $onVE"
        echo "onHS: $onHS"
        echo "USER: $USER / $(whoami)"
        echo "HOST: $C / $(hostname)"
        echo "HOSTIPv4: $HOSTIPv4"
        echo "SC_USER: $SC_USER"
        echo "isUSER: $isUSER"
        echo "isROOT: $isROOT"
        echo "isSUDO: $isSUDO"
        echo "LXC_SERVER: $LXC_SERVER"
        echo "CWD: $CWD"
        echo "CMD: $CMD"
        echo "ARG: $ARG"
        echo "OPA: $OPA"
        echo "ARGS: $ARGS"
        echo "OPAS: $OPAS"
        echo "OPAS3: $OPAS3"
        echo "LXC_INSTALL: $LXC_INSTALL"
        echo "LXC_VERSION: $LXC_VERSION"
        echo "LOG: $LOG"
        echo "TMP: $TMP"
        echo "SRV: $SRV"
        echo "MDA: $MDA"
        echo "MDF: $MDF"
        echo "CMP: $CMP"
        echo "CDN: $CDN"

        #echo "HOSTIPv6: $HOSTIPv6"
        #echo "RANGEv6: $RANGEv6"
        #echo "PREFIXv6: $PREFIXv6"

        echo "BACKUP_PATH: $BACKUP_PATH"

        echo "debug: $debug"
        #echo ": $"
        echo ""


        msg "Checking for services"
        
        for service in $(ls /etc/srvctl/system)
        do
            if [ $(systemctl is-active $service) == "active" ]
            then
                msg $service $(systemctl is-active $service) $(systemctl is-enabled $service)
            else
                err $service $(systemctl is-active $service) $(systemctl is-enabled $service)
                systemctl status $service
            fi
        done


        
        if $isROOT && [ "$(type -a netstat)" == "netstat is /usr/bin/netstat" ]
        then
            msg "NETWORK PORTS and PROTOCOLLS"
            netstat -tulpn
        
            msg "POP3"
            netstat -np | grep ":995"
            msg "IMAP4S"
            netstat -np | grep ":993"
            msg "IMAP for SMTPS auth"
            netstat -np | grep ":143"
            msg "SMTPS"
            netstat -np | grep ":465"
            msg "SMTP"
            netstat -np | grep ":25"
            msg "SSH"
            netstat -np | grep ":22"
            msg "FTP"
            netstat -np | grep ":21"
            msg "HTTP"
            netstat -np | grep ":80"
            netstat -np | grep ":443"
        fi
        echo ''
        

        msg "Host network addresses"
        cat /var/srvctl/ifcfg/ipv* 
        echo ''
        
        
    msg "Uptime: $(uptime)"
    msg "CONNECTED SHELL USERS"
    w
        
        
  if $onHS && $isROOT
    then    
        msg "Containers"
        lxc-ls --fancy
    
    
        zone=$(firewall-cmd --get-default-zone)
        services=" $(firewall-cmd --zone=$zone --list-services) "

        msg "Firewall $(firewall-cmd --state) - default zone: $zone"
        echo $services
        echo ''

        echo Interfaces:
        interfaces=$(firewall-cmd --list-interfaces)
        for i in $interfaces
        do
            echo $i - $(firewall-cmd --get-zone-of-interface=$i)
            echo ''
        done
    

    
    msg 'Query spamhouse.org'    
    while read IP
    do
        get_pure_ip $IP
        if [ ! -z "$(curl http://www.spamhaus.org/query/ip/$ip 2> /dev/null | grep "$ip is listed")" ]
        then
            err "CHECK $ip AT spamhouse.org -  http://www.spamhaus.org/query/ip/$ip"
        fi
    done < /var/srvctl/ifcfg/ipv4
        
        
    for _c in $(lxc_ls)
    do
    echo $_c
        if [ ! -z "$(curl http://www.spamhaus.org/query/domain/$_c 2> /dev/null | grep "$_c is listed")" ]
        then
            err "CHECK $_c AT spamhouse.org -  http://www.spamhaus.org/query/domain/$_c"
        fi
    done   
    
    msg "Container error-messages" 

    for C in $(lxc_ls)
    do      
        if [ -f $SRV/$C/dns.log ]
        then
            echo ''
            while read line
            do
                err "$line"
            done < $SRV/$C/dns.log
        fi
        
        if [ -f $SRV/$C/rootfs/var/log/srvctl/letsencrypt.log ]
        then
            echo ''
            while read line
            do
                ntc "$line"
            done < $SRV/$C/rootfs/var/log/srvctl/letsencrypt.log
        fi

    done
    
    msg "Certificates"
    
    for _d in $(ls /etc/srvctl/cert)
    do
       pound_pem=/etc/srvctl/cert/$_d/pound.pem
       check_pound_pem
    done
 
    for _c in $(lxc_ls)
    do
       pound_pem=$SRV/$_c/cert/pound.pem
       check_pound_pem
    done
   
    
    
  fi
ok
fi
man '
    Set of troubleshooting commands. 
    Display status messages of services, and list important network port statuses.
'

#fi ## isROOT






