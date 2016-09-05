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
        create_selfsigned_domain_certificate $CDN
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

save_file /etc/ssh/ssh_config.bak '#        $OpenBSD: ssh_config,v 1.30 2016/02/20 23:06:23 sobrado Exp $

# This is the ssh client system-wide configuration file.  See
# ssh_config(5) for more information.  This file provides defaults for
# users, and the values can be changed in per-user configuration files
# or on the command line.

# Configuration data is parsed as follows:
#  1. command line options
#  2. user-specific file
#  3. system-wide file
# Any configuration value is only changed the first time it is set.
# Thus, host-specific definitions should be at the beginning of the
# configuration file, and defaults at the end.

# Site-wide defaults for some commonly used options.  For a comprehensive
# list of available options, their meanings and defaults, please see the
# ssh_config(5) man page.

# Host *
#   ForwardAgent no
#   ForwardX11 no
#   RhostsRSAAuthentication no
#   RSAAuthentication yes
#   PasswordAuthentication yes
#   HostbasedAuthentication no
#   GSSAPIAuthentication no
#   GSSAPIDelegateCredentials no
#   GSSAPIKeyExchange no
#   GSSAPITrustDNS no
#   BatchMode no
#   CheckHostIP yes
#   AddressFamily any
#   ConnectTimeout 0
#   StrictHostKeyChecking ask
#   IdentityFile ~/.ssh/identity
#   IdentityFile ~/.ssh/id_rsa
#   IdentityFile ~/.ssh/id_dsa
#   IdentityFile ~/.ssh/id_ecdsa
#   IdentityFile ~/.ssh/id_ed25519
#   Port 22
#   Protocol 2
#   Cipher 3des
#   Ciphers aes128-ctr,aes192-ctr,aes256-ctr,arcfour256,arcfour128,aes128-cbc,3des-cbc
#   MACs hmac-md5,hmac-sha1,umac-64@openssh.com,hmac-ripemd160
#   EscapeChar ~
#   Tunnel no
#   TunnelDevice any:any
#   PermitLocalCommand no
#   VisualHostKey no
#   ProxyCommand ssh -q -W %h:%p gateway.example.com
#   RekeyLimit 1G 1h
#
# Uncomment this if you want to use .local domain
# Host *.local
#   CheckHostIP no

Host *
        GSSAPIAuthentication yes
# If this option is set to yes then remote X11 clients will have full access
# to the original X11 display. As virtually no X11 client supports the untrusted
# mode correctly we set this to yes.
        ForwardX11Trusted yes
# Send locale-related environment variables
        SendEnv LANG LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES
        SendEnv LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT
        SendEnv LC_IDENTIFICATION LC_ALL LANGUAGE
        SendEnv XMODIFIERS
'

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

## So ...
## ubuntu adds users 100 and up.
## fedora adds dynamic system users from 999 downwards
## great ... 101..104 should be changed to 501..504
## okay?

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

## acording to new users struct
groupadd -r -g 505 srvctl-gui 2> /dev/null
useradd -r -u 505 -g 505 -s /sbin/nologin -d /tmp srvctl-gui 2> /dev/null

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
source $install_dir/hs-install/openvpn.sh
regenerate_sudo_configs

## srvctl-gui
if [ "$ROOTCA_HOST" == "$HOSTNAME" ]
then

## service-file
set_file /lib/systemd/system/srvctl-gui.service '## srvctl generated
[Unit]
Description=srvctl-gui server.
After=syslog.target network.target

[Service]
Type=simple
ExecStart=/bin/node '$install_dir'/hs-apps/srvctl-gui.js
User=root
Group=root

[Install]
WantedBy=multi-user.target
'


    mkdir -p /var/srvctl-gui
    chown -R srvctl-gui:srvctl-gui /var/srvctl-gui
    chmod 700 /var/srvctl-gui
    
    
    if [ ! -f /var/srvctl-gui/hosts ]
    then
        hostname > /var/srvctl-gui/hosts
        ntc "You may can add additional srvctl-hosts to srvctl-gui in /var/srvctl-gui/hosts"
    else 
        msg "Current srvctl-gui hosts are:"
        cat /var/srvctl-gui/hosts
        msg "Additional hosts can be added to /var/srvctl-gui/hosts"
    fi

    add_service srvctl-gui

fi
      
set_file /lib/systemd/system/mozilla-autoconfig-server.service '## srvctl generated
[Unit]
Description=Mozilla thunderbird autoconfig server.
After=syslog.target network.target

[Service]
Type=simple
ExecStart=/bin/node '$install_dir'/hs-apps/mozilla-autoconfig-server.js
User=node
Group=node

[Install]
WantedBy=multi-user.target
'

set_file /lib/systemd/system/static-server.service '## srvctl generated
[Unit]
Description=HTTP static-server as emergency fallback.
After=syslog.target network.target

[Service]
Type=simple
ExecStart=/bin/node '$install_dir'/hs-apps/static-server.js
User=node
Group=node

[Install]
WantedBy=multi-user.target
'


systemctl daemon-reload
     
      
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
    add_service mozilla-autoconfig-server
    add_service static-server
    
mnt_rorootfs

regenerate_var_ve

source $install_dir/hs-install/mkrootfs.sh

if [ ! -z "$BOOT" ]
then
    msg "Boot of $BOOT requested"
    GRUBBOOT="$(grep ^menuentry /boot/grub2/grub.cfg | cut -d "'" -f2 | grep $BOOT)"
    grub2-set-default "$GRUBBOOT"
    grub2-editenv list
fi




