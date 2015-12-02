#!/bin/bash

if $isROOT
then ## no identation.



hint "update-install [all]" "This will update the current OS to be a srvctl-configured containerfarm host installation."
if [ "$CMD" == "update-install" ]
then

        pm_update 

        if [ "$ARG" == "all" ]
        then
           all_arg_set=true
        fi

        if $onVE
        then
            msg "Exiting - onVE"
            ok
            exit
        fi
    
    ## privately for the host
    mkdir -p /var/srvctl-host
    ## shared for containers
    mkdir -p /var/srvctl
    ## always local
    mkdir -p /etc/srvctl
        
        ## TODO make sure networking is set and okay.
        # /etc/sysconfig/network-scripts/ifcfg-em1
        # /etc/sysconfig/network
        # systemctl stop NetworkManager.service
        # systemctl remove NetworkManager
        # systemctl enable network.service
        # systemctl start network.service
    
    ## create files in /var/srvctl/ifcfg
    import_network_configuration
    ## geoinfo created, adding timezone info
    timedatectl | grep 'Time zone' | awk '{print $3}' > /var/srvctl/timezone
        
    ## containers wont start with selinux enabled. See https://bugzilla.redhat.com/show_bug.cgi?id=1227071
    sed_file /etc/selinux/config "SELINUX=enforcing" "SELINUX=disabled"
    
    
    ## make a config file    
    mkdir -p /etc/srvctl

    if [ ! -f /etc/srvctl/config ]
    then
        
        get_password
    
        cat $install_dir/hs-install/config > /etc/srvctl/config

        msg "Created default /etc/srvctl/config for customization. Please edit, .. "
        sleep 3
        mcedit /etc/srvctl/config
        msg "The update-install process needs to start over. Exiting."
        exit 0
    else
        msg "Found config file at /etc/srvctl/config"
    fi


## Requirement checks .--
## certificate
                if [ ! -f /root/crt.pem ]
                then
                        create_certificate /root
                fi

                if [ ! -f /root/key.pem ]
                then
                        create_certificate /root
                fi
                        ca_bundle=/etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt
                        
                        if [ -f /root/ca-bundle.pem ]
                        then
                            ca_bundle=/root/ca-bundle.pem
                        fi

                        cert_status=$(openssl verify -CAfile $ca_bundle /root/crt.pem | tail -n 1 | tail -c 3)

                        if [ "$cert_status" == "OK" ]
                        then
                                msg "Cerificate is OK!"
                        else
                                err "Requirement-check, error: certificate check for /root/crt.pem"
                                #exit
                        fi

## authorized keys. own hosts should have custom values that add into the config when regenerating.
                
                if [ ! -f /root/.ssh/own_hosts ] && [ -f /root/.ssh/known_hosts ]
                then
                        cat /root/.ssh/known_hosts > /root/.ssh/own_hosts
                fi


        ## srvctl

        ## TODO change counter location to /var/srvctl/counter
        if [ -f /var/srvctl-host/counter ]
        then
         msg "Counter exists, counting at "$(cat /var/srvctl-host/counter)
        else
         log "Counter does not exist. Creating."
         echo '0' > /var/srvctl-host/counter
        fi

        ## make sure srvctl enviroment directories exists
        mkdir -p $SRV
        mkdir -p $TMP
        


        ## this will save a little space. 

        if [ ! -f /var/srvctl/locale-archive ]
        then
         log "Shared local archive does not exist. Copying from host."
         cp /usr/lib/locale/locale-archive /var/srvctl
        fi

        ## just in case
        bak /etc/hosts

        ## create ssh key for root
        if [ ! -f /root/.ssh/id_rsa.pub ]
        then
          ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N ''
          log "Created ssh keypair for root."
        fi



source $install_dir/hs-install/lxc.sh
source $install_dir/hs-install/lxc-template.sh

source $install_dir/hs-install/pound.sh

#source $install_dir/hs-install/fail2ban.sh

set_file_limits

### E-mail
source $install_dir/hs-install/opendkim.sh
source $install_dir/hs-install/saslauthd.sh
source $install_dir/hs-install/postfix.sh
source $install_dir/hs-install/perdition.sh


## DNS
source $install_dir/hs-install/named.sh


## TODO IF install dovecot, add listen = 127.0.0.1 to dovecot.conf
## and enable
  # Postfix smtp-auth ### ENABLE with srvctl!
  #unix_listener /var/spool/postfix/private/auth {
  #  mode = 0666
  #}

## Add system users, so they have a name. Ignore errr messages.

groupadd -r -g 48 apache 2> /dev/null
useradd -r -u 48 -g 48 -s /sbin/nologin -d /usr/share/httpd apache 2> /dev/null

groupadd -r -g 101 srv 2> /dev/null
useradd -r -u 101 -g 101 -s /sbin/nologin -d /tmp srv 2> /dev/null

groupadd -r -g 102 git 2> /dev/null
useradd -r -u 102 -g 102 -s /sbin/nologin -d /tmp git 2> /dev/null

groupadd -r -g 103 node 2> /dev/null
useradd -r -u 103 -g 103 -s /sbin/nologin -d /tmp node 2> /dev/null

groupadd -r -g 104 codepad 2> /dev/null
useradd -r -u 104 -g 104 -s /sbin/nologin -d /tmp codepad 2> /dev/null



## User tools
source $install_dir/hs-install/usertools.sh

## maintenance system tools
dnf -y install dnf-plugin-system-upgrade


## public ftp server
# pm vsftpd
# systemctl enable vsftpd.service
# systemctl start vsftpd.service

## public torrent seed
# pm opentracker-ipv4 opentracker-ipv6
# systemctl enable opentracker-ipv4.service
# systemctl start opentracker-ipv4.service
# pm qbittorrent

## TODO run clamscan ...


if [ -s /root/.ssh/authorized_keys  ]
then
  sed_file /etc/ssh/sshd_config "PasswordAuthentication yes" "PasswordAuthentication no"
else
  msg "Password based ssh login couldn't be disabled, as root has no authorized keys."
fi

source $install_dir/hs-install/antivirus.sh
#source $install_dir/hs-install/openvpn.sh
source $install_dir/hs-install/firewall.sh

regenerate_sudo_configs
      
    add_service named  
    add_service sshd
    add_service libvirtd  
    add_service ntpd   
    add_service pound
    add_service postfix 
    add_service saslauthd 
    add_service spamassassin
    add_service pop3s 
    add_service imap4 
    add_service imap4s
    add_service amavisd 
    add_service opendkim



msg ".. update-install process complete."


msg "update-install done. You may regenerate configs now."

ok
fi ## update-install

man '
    This command will run the srvctl installation scripts, thus inicailize the host as a container-farm.
    With the [all] option set, all srvctl-related existing configurations will be regenerated, and updated. 
    In the first step, a blank configuration fill will be written to /etc/srvctl/config
    Following files are honored - if found:
         /root/crt.pem, /root/key.pem, /root/ca-bundle.pem - certificates for the host
         /root/saslauthd - a custom binary, that fixes the incompatibility between perdition and saslauthd
    A company domain name should be set in the config file, and a logo.png and a favicon.ico should be at that domain.
    Custom files for pound will reside in /var/www/html, and they might be customized.      
'
fi ## onHS







