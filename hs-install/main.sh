    rm -fr $TMP/*

    source $install_dir/hs-install/srvctl.sh
        
    ## make a config file 
    if [ ! -f /etc/srvctl/config ]
    then
        
        ## always local
        mkdir -p /etc/srvctl
    
        get_password
    
        cat $install_dir/hs-install/config > /etc/srvctl/config

        msg "Created default /etc/srvctl/config for customization. Please review and make changes according this containerfarm host."
        sleep 3
        pmc mc
        mcedit /etc/srvctl/config
        msg "The update-install process needs to start over. Exiting."
        exit 0
    else
        msg "Found config file at /etc/srvctl/config"
        grep "^[^#;]" /etc/srvctl/config
    fi

    if [ -z "$CDN" ] || [ "$CDN" == "Unknown" ]
    then
        err "Company domain name not set!"
        exit 44
    fi
    
    if ! $(is_fqdn $CDN)
    then
        err "Company domain name invalid!"
        exit 45
    fi
    
    
    msg "Creating directories."
    
    ## privately for the host
    mkdir -p /var/srvctl-host
    chmod -R 600 /var/srvctl-host
    ## shared for containers
    mkdir -p /var/srvctl
    
    ## make sure srvctl enviroment directories exists
    mkdir -p $SRV
    mkdir -p $TMP
     
    mkdir -p /etc/srvctl/cert
    chmod 600 /etc/srvctl/cert
    
    ## create files in /var/srvctl/ifcfg
    import_network_configuration
    
    local _timezone="$(timedatectl | grep 'Time zone' | awk '{print $3}')"
    msg "Set timezone $_timezone"
    ## geoinfo created, adding timezone info
    echo $_timezone > /var/srvctl/timezone
        
    ## containers wont start with selinux enabled. See https://bugzilla.redhat.com/show_bug.cgi?id=1227071
    sed_file /etc/selinux/config "SELINUX=enforcing" "SELINUX=disabled"
    
## Requirement checks .--
## certificate
        cert_path=/etc/srvctl/cert/$CDN
        create_certificate $CDN
        ## verify against the hostname?

        ## this will save a little space. 

        if [ ! -f /var/srvctl/locale-archive ]
        then
         log "Shared local archive does not exist. Copying from host."
         cp /usr/lib/locale/locale-archive /var/srvctl
        fi

        ## just in case
        bak /etc/hosts

        ## create ssh key for root
        if [ ! -f /root/.ssh/id_rsa.pub ] || [ ! -f /root/.ssh/id_rsa ]
        then
          ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N ''
          log "Created ssh keypair for root."
        fi



source $install_dir/hs-install/lxc.sh
#source $install_dir/hs-install/lxc-template.sh

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

groupadd -r -g 27 mysql 2> /dev/null
useradd -r -u 27 -g 27 -s /sbin/nologin -d /var/lib/mysql mysql 2> /dev/null

git config --global user.email "root@$CDN"
git config --global user.name root
git config --global push.default simple

## User tools
source $install_dir/hs-install/usertools.sh

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

## make a server for authentication
install_nodejs_latest

source $install_dir/hs-install/letsencrypt.sh

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
    add_service acme-server
    
mnt_rorootfs

regenerate_var_ve

source $install_dir/hs-install/mkrootfs.sh

## dyndns stuff
mkdir -p /var/srvctl-host/dyndns
cat /etc/srvctl/cert/$CDN/$CDN.key /var/srvctl-host/dyndns/key.pem
cat /etc/srvctl/cert/$CDN/$CDN.crt /var/srvctl-host/dyndns/crt.pem
chown -R 600 /var/srvctl-host/dyndns


set_file /lib/systemd/system/dyndns-server.service '## srvctl generated
[Unit]
Description=Dyndns server.
After=syslog.target network.target

[Service]
Type=simple
ExecStart=/bin/node '$install_dir'/hs-apps/dyndns-server.js
User=node
Group=node

[Install]
WantedBy=multi-user.target
'

systemctl daemon-reload
add_service dyndns-server


