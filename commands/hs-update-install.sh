#!/bin/bash

if $onHS
then ## no identation.

## just to make sure, LXC is installed for real - TODO check this
#if [ -z "$(lxc-info --version 2> /dev/null)" ] && ! [ "$CMD" == "update-install" ]
#then        
#        err "   LXC NOT INSTALLED!"
#        msg "        run 'srvctl update-install' to configure this system as container-host."
#ok
#fi


hint "update-install [all]" "This will update the srvctl host installation."
if [ "$CMD" == "update-install" ]
then

        if [ "$2" == "all" ]
        then
           all_arg_set=true
        fi

        ### srvctl

        ## TODO create a srvctl file in /bin and ..
        # ln /bin/srvctl /var/srvctl

        if [ ! $0 == "/bin/srvctl" ]
        then
                msg "srvctl should be located at /bin/srvctl"
        fi

        ## TODO yum -y update ?

        ## TODO make sure networking is set and okay.
        # /etc/sysconfig/network-scripts/ifcfg-em1
        # /etc/sysconfig/network
        # systemctl stop NetworkManager.service
        # systemctl remove NetworkManager
        # systemctl enable network.service
        # systemctl start network.service

        mkdir -p /etc/srvctl

        if [ ! -f /etc/srvctl/config ]
        then
        
        get_password

set_file /etc/srvctl/config "## srvctl config 
## Use string if value contains spaces.

## use the latst version, options are 'yum' 'git' 'zip' 'src' 
LXC_INSTALL='yum'
## eventually specify the version - mandatory for zip, optional for yum
#LXC_VERSION=1.1.0

## logfile
#LOG=/var/log/srvctl.log

## temporal backup and work directory
#TMP=/temp

## The main /srv folder mount point - SSD recommended
#SRV=/srv

## Used for certificate generation - do not leave it empty in config file.
ssl_password=ssl_pass_$password

## Company codename - use your own
#CMP=Unknown

## Company domain name - use your own
#CDN=$(hostname)

## CC as Certificate creation
#CCC=HU
#CCST=Hungary
#CCL=Budapest

## IPv4 Address of the host
#HOSTIPv4=127.0.0.1

## IPv6 address of the host
#HOSTIPv6=::1

## IPv6 address range base
#RANGEv6=::1
#PREFIXv6=64

## File to share this system's VE domains to ns servers - http share recommended
#dns_share=/root/dns.tar.gz

#### the following options are exported to containers, when they get created..

## for php.ini in containers
#php_timezone=Europe/Budapest


"
        msg "Generated default /etc/srvctl/config for customization. Please edit, and restart the update-install process. Exiting."
        exit

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

                if [ -f /root/ca-bundle.pem ]
                then
                        no_ca_bundle_hashmark=''
                        cert_status=$(openssl verify -CAfile /root/ca-bundle.pem /root/crt.pem | tail -n 1 | tail -c 3)

                        if [ ! "$cert_status" == "OK" ]
                        then
                                err "Requirement-check, error: certificate check failed with /root/ca-bundle.pem /root/crt.pem - Exiting"
                                exit

                        fi
                else
                        msg "No ca-bundle.pem found."
                        no_ca_bundle_hashmark='# '
                        cert_status=$(openssl verify /root/crt.pem | tail -n 1 | tail -c 3)

                        if [ ! "$cert_status" == "OK" ]
                        then
                                err "Requirement-check, error: certificate check failed. /root/crt.pem - Exiting"
                                exit

                        fi
                fi
## authorized keys. own hosts should have custom values that add into the config when regenerating.
                
                if [ ! -f /root/.ssh/own_hosts ] && [ -f /root/.ssh/known_hosts ]
                then
                        cat /root/.ssh/known_hosts > /root/.ssh/own_hosts
                fi

## saslauthd

        if [ ! -f /root/saslauthd ]
        then
                msg "No custom saslauthd file detected. Attemt to download a compiled 64bit executable from d250.hu."
                wget -O /root/saslauthd http://d250.hu/scripts/bin/saslauthd
        fi

        if [ ! -f /root/saslauthd ]
        then
                err "Due to incompatibility of saslauthd <= 2.1.26 and perdition, a custom version of saslauthd is required, that has to be located at /root/saslauthd. Exiting."
                exit
        fi

## TODO saslauthd may hang, research / or implementation fix is needed.

## @update-install
if [ -z "$(lxc-info --version 2> /dev/null)" ] || $all_arg_set
then
        log "Installing LXC!"
        msg $CDN

        if [ "$LXC_INSTALL" == "git" ] || [ "$LXC_INSTALL" == "src" ] || [ "$LXC_INSTALL" == "tar" ]
        then
                ## packages needed for compilation and for running
                log "Install Development Tools"
                yum -y groupinstall "Development Tools"
                yum -y install automake
                yum -y install graphviz
                yum -y install libcap-devel


                cd /root

                if [ "$LXC_INSTALL" == "git" ]
                then
                        log "Install LXC via git"
                          git clone git://github.com/lxc/lxc
                fi

                if [ "$LXC_INSTALL" == "src" ]
                then
                        log "Installing using existing /root/lxc source."
                fi

                if [ "$LXC_INSTALL" == "tar" ]
                then

                        if [ $LXC_VERSION == '' ]
                        then
                                err 'LXC_VERSION not specified! CAN NOT use a release! exiting.'
                                exit 10
                        fi

                        if $all_arg_set
                        then
                                rm -rf lxc
                        fi



                        ## use a version-release
                        if [ ! -f "/root/lxc-$LXC_VERSION.tar.gz" ] 
                        then 
                                msg "Downloading LXC $LXC_VERSION"
                                wget -O /root/lxc-$LXC_VERSION.tar.gz https://linuxcontainers.org/downloads/lxc/lxc-$LXC_VERSION.tar.gz
                        fi
                        
                        if [ ! -d "/root/lxc" ]
                        then
                                tar -zxvf /root/lxc-$LXC_VERSION.tar.gz
                                mv /root/lxc-$LXC_VERSION /root/lxc
                        fi
                                    
                                ## This seems to be absolete
                                ## wget -O /root/lxc-$LXC_VERSION.zip https://github.com/lxc/lxc/archive/lxc-$LXC_VERSION.zip
                                ##unzip /root/lxc-$LXC_VERSION.zip                    
                        
                        
                fi
         
                cd /root/lxc

                if [ ! -f /root/lxc/autogen.sh ]
                then
                        err "LXC-building: autogen.sh not found!"
                        exit 11
                fi

                log "LXC-building: autogen"
                ./autogen.sh

                if [ ! -f /root/lxc/configure ]
                then
                        err "LXC-building: configure not found!"
                        exit 12
                fi

                log "LXC-building: configure"
                ./configure

                log "LXC-building: make"
                make

                log "LXC-building: install"
                make install
    
        else
                ## this is the default method
                log "yum install lxc $LXC_VERSION"

                if [ ! "$LXC_VERSION" == '' ]
                then
                        yum -y install lxc-$LXC_VERSION
                        yum -y install lxc-extra-$LXC_VERSION
                        yum -y install lxc-templates-$LXC_VERSION
                else
                        yum -y install lxc
                        yum -y install lxc-extra
                        yum -y install lxc-templates
                fi                 
        fi


        add_conf /root/.bash_profile "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib"

        log "Configure libvirt network"

## Networking with libvirt
        yum -y install libvirt-daemon-driver-network libvirt-daemon-config-network libvirt-daemon-config-nwfilter

        ## DHCP is only for manually created containers. srvctl containers should use static ip addresses.
        
        set_file /etc/libvirt/qemu/networks/default.xml '<network>
  <name>default</name>
  <uuid>00000000-0000-aaaa-aaaa-aaaaaaaaaaaa</uuid>
  <bridge name="inet-br"/>
  <mac address="00:00:00:AA:AA:AA"/>
  <forward/>
  <ip address="192.168.0.1" netmask="255.255.0.0">
    <dhcp>
      <range start="192.168.0.2" end="192.168.0.254"/>
    </dhcp>
  </ip>
</network>
'

set_file /etc/libvirt/qemu/networks/primary.xml '<network>
  <name>primary</name>
  <uuid>00000000-0000-2010-0010-000000000001</uuid>
  <bridge name="srv-net"/>
  <mac address="00:00:10:10:00:01"/>
  <forward/>
  <ip address="10.10.0.1" netmask="255.255.0.0"></ip>
</network>
'

## TODO, .. consider to set a new bridge for ipv6

        ln -s /etc/libvirt/qemu/networks/primary.xml /etc/libvirt/qemu/networks/autostart/primary.xml 2> /dev/null

        systemctl enable libvirtd.service
        systemctl start  libvirtd.service
        systemctl status libvirtd.service

        #### RESTART REQUIRED HERE, if libvirt networks got modified.
        if ! $all_arg_set
        then
                log "LXC Installed. Please reboot, and run this command again to continiue. Exiting."
                exit
        fi

else
msg "LXC is OK! "$(lxc-info --version)
fi ## Install LXC

## @update-install

        ## srvctl

        ## TODO change counter location to /var/srvctl/counter
        if [ -f /etc/srvctl/counter ]
        then
         msg "Counter exists, counting at "$(cat /etc/srvctl/counter)
        else
         log "Counter does not exist. Creating."
         echo '0' > /etc/srvctl/counter
        fi

        ## make sure srvctl enviroment directories exists
        mkdir -p $SRV
        mkdir -p $TMP
        #mkdir -p /var/srvctl/share
        ## TODO FIX HERE
        mkdir -p /var/srvctl
        mkdir -p /etc/srvctl

        ## this will save a little space. 
        ## TODO: I'm not a distro engineer, but I think there is space for optimalisation. Move locale-archive to shar efolder

        if [ ! -f /var/srvctl/locale-archive ]
        then
         log "Shared local archive does not exist. Copying from host."
         cp /usr/lib/locale/locale-archive /var/srvctl
        fi


        ## default path for containers - source install
        if [ -f "/usr/local/etc/lxc/default.conf" ]
        then        
                set_file "/usr/local/etc/lxc/lxc.conf" "lxc.lxcpath=$SRV" 
        fi        
        ## package install
        if [ -f "/etc/lxc/default.conf" ]
        then                        
                set_file "/etc/lxc/lxc.conf" "lxc.lxcpath=$SRV" 
        fi

        ## just in case
        bak /etc/hosts

        ## create ssh key for root
        if [ ! -f /root/.ssh/id_rsa.pub ]
        then
          ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N ''
          log "Created ssh keypair for root."
        fi



        ## We do some customisations in our template
        ## template path is different depending on installation, yum or some src

        

        ## yum-based install
        fedora_template="$lxc_usr_path/share/lxc/templates/lxc-fedora"
        srvctl_template="$lxc_usr_path/share/lxc/templates/lxc-fedora-srv"


## @update-install
if [ ! -f $srvctl_template ] || $all_arg_set
then
        log "Create Custom template: $srvctl_template"

        set_file $srvctl_template '#!/bin/bash

        ## You may want to add your own sillyables, or faorite characters and customy security measures.
        declare -a pwarra=("B" "C" "D" "F" "G" "H" "J" "K" "L" "M" "N" "P" "R" "S" "T" "V" "Z")
        pwla=${#pwarra[@]}

        declare -a pwarrb=("a" "e" "i" "o" "u")
        pwlb=${#pwarrb[@]}        

        declare -a pwarrc=("" "." ":" "@" ".." "::" "@@")
        pwlc=${#pwarrc[@]}

        p=''
        p=$p${pwarra[$(( RANDOM % $pwla ))]}
        p=$p${pwarrb[$(( RANDOM % $pwlb ))]}
        p=$p${pwarra[$(( RANDOM % $pwla ))]}
        p=$p${pwarrb[$(( RANDOM % $pwlb ))]}
        # p=$p${pwarrc[$(( RANDOM % $pwlc ))]}
        p=$p${pwarra[$(( RANDOM % $pwla ))]}
        p=$p${pwarrb[$(( RANDOM % $pwlb ))]}
        p=$p${pwarra[$(( RANDOM % $pwla ))]}
        p=$p${pwarrb[$(( RANDOM % $pwlb ))]}

        root_password=$p

'
        chmod 755 $srvctl_template

        cat $fedora_template >> $srvctl_template
        ## cosmetical TODO remove second #!/bin/bash

        ## disable the root password redefining force
        sed_file $srvctl_template 'chroot $rootfs_path passwd -e root' 'echo "" ## srvctl-disabled: chroot $rootfs_path passwd -e root'
        sed_file $srvctl_template 'Container rootfs and config have been created.' 'Container rootfs and config have been created."'
        ## and do not display the dialog for that subject
        sed_file $srvctl_template 'Edit the config file to check/enable networking setup.' 'exit 0'

        ## Add additional default packages 
        sed_file $srvctl_template '    PKG_LIST="yum initscripts passwd rsyslog vim-minimal openssh-server openssh-clients dhclient chkconfig rootfiles policycoreutils fedora-release"' '    PKG_LIST="yum initscripts passwd rsyslog vim-minimal openssh-server openssh-clients dhclient chkconfig rootfiles policycoreutils fedora-release fedora-repos mc httpd mod_ssl openssl postfix mailx sendmail unzip clucene-core make  rsync nfs-utils"'

        ## fedora-repos added for fixing: https://bugzilla.redhat.com/show_bug.cgi?id=1176634

        ## wordpress mariadb mariadb-server postfix mailx sendmail dovecot .. 

        ## TODO Dovecot fails with
        ##  warning: %post(dovecot-1:2.2.13-1.fc20.x86_64) scriptlet failed, exit status 1
        ## Non-fatal POSTIN scriptlet failure in rpm package 1:dovecot-2.2.13-1.fc20.x86_64
        ## therefore it should be installed once the container started.

        ## httpd needs to be installed here, other wise it failes with cpio set_file_cap error.

        ## After modifocation of the last line, in a live filesystem, /usr/local/var/cache/lxc/fedora needs to be purged.
        log "Clearing yum cache for container creation."

        ## paths are different for src or yum install
        rm -rf /usr/local/var/cache/lxc/fedora
        rm -rf /var/cache/lxc/fedora

fi ## if fedora_template does not exists.

## @update-install



## TODO / ISSUE : dovecot can not be added, as it freezes the install process


        ##log "Install Pound Reverse Proxy for HTTP" 



if [ ! -f /etc/pound.cfg ] || $all_arg_set
then
        ## Pound is a reverse Proxy for http
        yum -y install Pound

        set_file /etc/pound.cfg '## srvctl pound.cfg
User "pound"
Group "pound"
Control "/var/lib/pound/pound.cfg"

## Default loglevel is 1
LogFacility local0
LogLevel    2

Alive 1

ListenHTTP

    Address 0.0.0.0
    Port    80

    Err414 "/var/www/html/414.html"
    Err500 "/var/www/html/500.html"
    Err501 "/var/www/html/501.html"
    Err503 "/var/www/html/503.html"

    Include "/var/pound/http-includes.cfg"

End
ListenHTTPS

    Address 0.0.0.0
    Port    443

    Err414 "/var/www/html/414.html"
    Err500 "/var/www/html/500.html"
    Err501 "/var/www/html/501.html"
    Err503 "/var/www/html/503.html"

    ## The certificate from root.
    Cert "/etc/pound/pound.pem"

    Include "/var/pound/https-includes.cfg"

End

## Include the default host here, as a fallback.
# Include "/srv/default-host/pound"
'
        ## certificate chainfile
        mkdir -p /etc/pound
        

        cat /root/crt.pem > /etc/pound/crt.pem
        cat /root/key.pem > /etc/pound/key.pem
        cat /root/ca-bundle.pem > /etc/pound/ca-bundle.pem 2> /dev/null

        cat /root/crt.pem > /etc/pound/pound.pem
        echo '' >> /etc/pound/pound.pem
        cat /root/key.pem >> /etc/pound/pound.pem
        echo '' >> /etc/pound/pound.pem
        cat /root/ca-bundle.pem >> /etc/pound/pound.pem 2> /dev/null


        mkdir -p /var/pound
        mkdir -p /var/www/html

        #  echo $MSG >> /etc/srvctl/pound-include-ca.cfg
        #  echo 'CAlist "/etc/srvctl/ca-bundle.pem"' >> /etc/srvctl/pound-include-ca.cfg
        ## TODO check for /etc/pki maybe?

        ## The pound-served custom error documents

set_file /var/www/html/414.html '<head></head><body bgcolor="#333"><div id="header" style="background-color:#151515;"><img src="http://'$CDN'/logo.png" alt="'"$CMP"'" style="display: block; margin-left: auto; margin-right: auto; vertical-align: middle"></div><p align="center"><font color="#aaa" style="margin-left: auto; margin-right: auto" size="6px" face="Arial">
<b>Error 414</b> @ '$(hostname)'<br />
Request URI is too long.
</font><p></body>'

set_file /var/www/html/500.html '<head></head><body bgcolor="#333"><div id="header" style="background-color:#151515;"><img src="http://'$CDN'/logo.png" alt="'"$CMP"'" style="display: block; margin-left: auto; margin-right: auto; vertical-align: middle"></div><p align="center"><font color="#aaa" style="margin-left: auto; margin-right: auto" size="6px" face="Arial">
<b>Error 500</b> @ '$(hostname)'<br />
An internal server error occurred. Please try again later.
</font><p></body>'

set_file /var/www/html/501.html '<head></head><body bgcolor="#333"><div id="header" style="background-color:#151515;"><img src="http://'$CDN'/logo.png" alt="'"$CMP"'" style="display: block; margin-left: auto; margin-right: auto; vertical-align: middle"></div><p align="center"><font color="#aaa" style="margin-left: auto; margin-right: auto" size="6px" face="Arial">
<b>Error 501</b> @ '$(hostname)'<br />
Request URI is too long.
</font><p></body>'

set_file /var/www/html/503.html '<head></head><body bgcolor="#333"><div id="header" style="background-color:#151515;"><img src="http://'$CDN'/logo.png" alt="'"$CMP"'" style="display: block; margin-left: auto; margin-right: auto; vertical-align: middle"></div><p align="center"><font color="#aaa" style="margin-left: auto; margin-right: auto" size="6px" face="Arial">
<b>Error 503</b> @ '$(hostname)'<br />
The service is not available. Please try again later.
</font><p></body>'


        if [ ! -f /var/www/html/favicon.ico ]
        then
           msg "Downloading favicon.ico from $CDN"
           wget -O /var/www/html/favicon.ico http://$CDN/favicon.ico
        fi

        if [ ! -f /var/www/html/logo.png ]
        then
           msg "Downloading logo.png from $CDN" 
           wget -O /var/www/html/logo.png http://$CDN/logo.png
        fi

        if [ ! -f /var/www/html/favicon.ico ]
        then
           err "No favicon.ico from could be located."
        fi

        if [ ! -f /var/www/html/logo.png ]
        then
           err "No logo.png from could be located."
        fi

## Pound logging. By default pound is logging to systemd-journald.
## To work with logs, use rsyslog to export to /var/log/pound

        yum -y install rsyslog

        add_conf /etc/rsyslog.conf 'local0.*                         -/var/log/pound'

        systemctl restart rsyslog.service


        systemctl stop pound.service
        systemctl enable pound.service
        systemctl start pound.service
        systemctl status pound.service


fi ## install pound


if [ ! -d /etc/fail2ban ]
then
        yum -y install fail2ban

        cf=/etc/fail2ban/fail2ban.d/firewallcmd-ipset.conf
        wget -O $cf https://raw.githubusercontent.com/fail2ban/fail2ban/master/config/action.d/firewallcmd-ipset.conf

        cf=/etc/fail2ban/fail2ban.d/firewallcmd-new.conf
        wget -O $cf https://raw.githubusercontent.com/fail2ban/fail2ban/master/config/action.d/firewallcmd-new.conf


set_file /etc/fail2ban/jail.d/apache.conf '## srvctl
[apache-auth]
enabled = true
action = firewallcmd-ipset
port     = http,https
logpath  = %(apache_error_log)s


[apache-badbots]
enabled = true
action = firewallcmd-ipset
port     = http,https
logpath  = %(apache_access_log)s
bantime  = 172800
maxretry = 1


[apache-noscript]
enabled = true
action = firewallcmd-ipset
port     = http,https
logpath  = %(apache_error_log)s
maxretry = 6


[apache-overflows]
enabled = true
action = firewallcmd-ipset
port     = http,https
logpath  = %(apache_error_log)s
maxretry = 2


[apache-nohome]
enabled = true
action = firewallcmd-ipset
port     = http,https
logpath  = %(apache_error_log)s
maxretry = 2


[apache-botsearch]
enabled = true
action = firewallcmd-ipset
port     = http,https
logpath  = %(apache_error_log)s
maxretry = 2


[apache-modsecurity]
enabled = true
action = firewallcmd-ipset
port     = http,https
logpath  = %(apache_error_log)s
maxretry = 2

[php-url-fopen]
enabled = true
action = firewallcmd-ipset
port    = http,https
logpath = %(apache_access_log)s
'

set_file /etc/fail2ban/jail.d/perdition.conf '## srvctl
[perdition]
enabled = true
action = firewallcmd-ipset
port    = 995,143,993
'

set_file /etc/fail2ban/jail.d/postfix.conf '## srvctl 
[postfix]
enabled = true
action = firewallcmd-ipset
port    = 25,465,587

#logpath = %(sshd_log)s

[postfix-sasl]
enabled = true
action = firewallcmd-ipset
port     = 25,465,587,995,143,995
'

set_file /etc/fail2ban/jail.d/ssh.conf '[sshd]
enabled = true
action = firewallcmd-ipset
port    = ssh
'

set_file /etc/fail2ban/jail.local '[INCLUDES]

before = paths-fedora.conf

[DEFAULT]

ignoreip = 127.0.0.1/8 10.10.0.1/16
ignorecommand =
bantime  = 600
findtime  = 600
maxretry = 5
usedns = warn
logencoding = auto
enabled = false
filter = %(__name__)s
destemail = root@localhost
sender = root@localhost
mta = sendmail
protocol = tcp
chain = INPUT
port = 0:65535
banaction = iptables-multiport

action_ = %(banaction)s[name=%(__name__)s, port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]

action_mw = %(banaction)s[name=%(__name__)s, port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]
            %(mta)s-whois[name=%(__name__)s, dest="%(destemail)s", protocol="%(protocol)s", chain="%(chain)s"]

action_mwl = %(banaction)s[name=%(__name__)s, port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]
             %(mta)s-whois-lines[name=%(__name__)s, dest="%(destemail)s", logpath=%(logpath)s, chain="%(chain)s"]


action_xarf = %(banaction)s[name=%(__name__)s, port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]
             xarf-login-attack[service=%(__name__)s, sender="%(sender)s", logpath=%(logpath)s, port="%(port)s"]

action_blocklist_de  = blocklist_de[email="%(sender)s", service=%(filter)s, apikey="%(blocklist_de_apikey)s"]
action_badips = badips.py[category="%(name)s", banaction="%(banaction)s"]
action = %(action_)s

## Jails in jail.d folder.
'

fi ## install fail2ban

## TODO: fail2ban seems to be resource hungry. :/

        ## Dev-note .. I was worried that unencrypted http between the host and a container can be sniffed from another container.
        ## My attempts to do so, did not work, therefore I kept this concept of the containers sitting together on srv-net with static IP's


## @update-install
set_file_limits

### E-mail
## Postfix
if [ ! -f /etc/postfix/main.cf ] || $all_arg_set
then
        log "Installing the Postfix mail subsystem."

        yum -y install postfix

        pc=/etc/postfix/main.cf

        sed_file $pc 'inet_interfaces = localhost' '#inet_interfaces # localhost'


        if grep -q  '## srvctl postfix configuration directives' $pc; then
         log "Skipping Postfix configuration, as it seems to be configured."
        else
                bak $pc

                ## append to the default conf
                echo '
## srvctl postfix configuration directives
## RECIEVING

## Listen on ..
inet_interfaces = all

## use /etc/hosts instead of dns-query
lmtp_host_lookup = native
smtp_host_lookup = native
## in addition, this might be enabled too.
# smtp_dns_support_level = disabled

## dont forget to postmap /etc/postfix/relaydomains
relay_domains = $mydomain, hash:/etc/postfix/relaydomains

## SENDING
## SMTPS
'$no_ca_bundle_hashmark'smtpd_tls_CAfile =    /etc/postfix/ca-bundle.pem
smtpd_tls_cert_file = /etc/postfix/crt.pem
smtpd_tls_key_file =  /etc/postfix/key.pem
smtpd_tls_security_level = may
smtpd_use_tls = yes

## We use cyrus for PAM authentication of local users
smtpd_sasl_type = cyrus

## We could use dovecot too.
#smtpd_sasl_type = dovecot
#smtpd_sasl_path = private/auth

smtpd_sasl_auth_enable = yes
smtpd_sasl_authenticated_header = yes
smtpd_recipient_restrictions = permit_mynetworks, permit_sasl_authenticated
##, check_recipient_access, reject_unauth_destination
smtpd_sasl_local_domain = '$CDN'

## Max 25MB mail size
message_size_limit=26214400 
' >> $pc
        fi ## add postfix directives

        echo '# srvctl postfix relaydomains' >> /etc/postfix/relaydomains


set_file /etc/postfix/master.cf '
# Postfix master process configuration file. (minimized) 
# ==========================================================================
# service type  private unpriv  chroot  wakeup  maxproc command + args
#               (yes)   (yes)   (yes)   (never) (100)
# ==========================================================================
smtp      inet  n       -       n       -       -       smtpd
smtps     inet  n       -       n       -       -       smtpd
  -o syslog_name=postfix/smtps
  -o smtpd_tls_wrappermode=yes
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_reject_unlisted_recipient=no
  -o smtpd_recipient_restrictions=permit_sasl_authenticated,reject
pickup    unix  n       -       n       60      1       pickup
cleanup   unix  n       -       n       -       0       cleanup
qmgr      unix  n       -       n       300     1       qmgr
tlsmgr    unix  -       -       n       1000?   1       tlsmgr
rewrite   unix  -       -       n       -       -       trivial-rewrite
bounce    unix  -       -       n       -       0       bounce
defer     unix  -       -       n       -       0       bounce
trace     unix  -       -       n       -       0       bounce
verify    unix  -       -       n       -       1       verify
flush     unix  n       -       n       1000?   0       flush
proxymap  unix  -       -       n       -       -       proxymap
proxywrite unix -       -       n       -       1       proxymap
smtp      unix  -       -       n       -       -       smtp
relay     unix  -       -       n       -       -       smtp
showq     unix  n       -       n       -       -       showq
error     unix  -       -       n       -       -       error
retry     unix  -       -       n       -       -       error
discard   unix  -       -       n       -       -       discard
local     unix  -       n       n       -       -       local
virtual   unix  -       n       n       -       -       virtual
lmtp      unix  -       -       n       -       -       lmtp
anvil     unix  -       -       n       -       1       anvil
scache    unix  -       -       n       -       1       scache
'

        cat /root/ca-bundle.pem > /etc/postfix/ca-bundle.pem 2> /dev/null
        cat /root/crt.pem > /etc/postfix/crt.pem
        cat /root/key.pem > /etc/postfix/key.pem

        postmap /etc/postfix/relaydomains
        systemctl enable postfix.service
        systemctl start postfix.service


fi ## postfix
## @update-install


if [ ! -f /etc/aliases.db ] || $all_arg_set
then

log "Set /etc/aliases.db"

## We will mainly use these files to copy over to clients. Main thing is: info should not be aliased.
set_file /etc/aliases '
#
#  Aliases in this file will NOT be expanded in the header from
#  Mail, but WILL be visible over networks or from /bin/mail.
#
#        >>>>>>>>>>        The program "newaliases" must be run after
#        >> NOTE >>        this file is updated for any changes to
#        >>>>>>>>>>        show through to sendmail.
#

# Basic system aliases -- these MUST be present.
mailer-daemon:        postmaster
postmaster:        root

# General redirections for pseudo accounts.
bin:                root
daemon:                root
adm:                root
lp:                root
sync:                root
shutdown:        root
halt:                root
mail:                root
news:                root
uucp:                root
operator:        root
games:                root
gopher:                root
ftp:                root
nobody:                root
radiusd:        root
nut:                root
dbus:                root
vcsa:                root
canna:                root
wnn:                root
rpm:                root
nscd:                root
pcap:                root
apache:                root
webalizer:        root
dovecot:        root
fax:                root
quagga:                root
radvd:                root
pvm:                root
amandabackup:        root
privoxy:        root
ident:                root
named:                root
xfs:                root
gdm:                root
mailnull:        root
postgres:        root
sshd:                root
smmsp:                root
postfix:        root
netdump:        root
ldap:                root
squid:                root
ntp:                root
mysql:                root
desktop:        root
rpcuser:        root
rpc:                root
nfsnobody:        root

ingres:                root
system:                root
toor:                root
manager:        root
dumper:                root
abuse:                root

newsadm:        root #news
newsadmin:        root #news
usenet:                root #news
ftpadm:                root #ftp
ftpadmin:        root #ftp
ftp-adm:        root #ftp
ftp-admin:        root #ftp
www:                webmaster
webmaster:        root
noc:                root
security:        root
hostmaster:        root
#info:                postmaster
#marketing:        postmaster
#sales:                postmaster
#support:        postmaster


# trap decode to catch security attacks
decode:                root

# Person who should get roots mail
#root:                marc
'

## TODO alternatives set postfix as default MTA - or newaliases wont work.
newaliases



fi ## set aliases.db



## To create proper SMTPD Auth proxy method http://www.postfix.org/SASL_README.html
## saslauthd can verify the SMTP client credentials by using them to log into an IMAP server. 
## If the login succeeds, SASL authentication also succeeds. saslauthd contacts an IMAP server when started like this: saslauthd -d -a rimap -O test.d250.hu
## the remote server - in the container - needs to have dovecot (or an IMAP server) with users to authenticate.

## saslauthd and perdition - incompability problem as of 2014.06.25 
## 
## saslauthd with rimap to perdition ...
## The response after LOGIN is not being processed correctly.
## Perdition sends the CAPABILITY before the OK, thus saslauthd returns 
## [reason=[ALERT] Unexpected response from remote authentication server] 
## .. and fails to authenticate.
##
## A workaround is to patch saslauthd.
## We can consider CAPABILITY equal to OK [CAPABILITY ...], as in case of bad password / bad username / bad host, the remote server rejects the credentials.
## That means, if the response is not a NO, and there is a response, we can assume its an OK.
##
## cyrus-sasl-2.1.26/saslauthd/auth_rimap.c last lines:
## replace: return strdup(RESP_UNEXPECTED);
## with: return strdup("OK remote authentication successful"); 
## .. compile, install.
##
## Some more dev-hints.
##
## The LOGIN command is supported on both, saslauthd and perdition, plaintext only on saslauthd.
## Here is a note how to enable plaintext in dovecot:
## disable_plaintext_auth = no  >>> /etc/dovecot 10-auth.conf 
## ssl = no >>> 10-ssl.conf 
## testing the running saslauthd: testsaslauthd -u tx -p xxxxxx
##
## Get base64 encoded login code for user x pass xxxxxx
## echo -en "\0x\0xxxxxx" | base64
## AHgAeHh4eHh4
##
##
## Send e-mail
## echo "this is the body" | mail -s "this is the subject" "to@address"
##
## Other test commands:
##
#### plaintext IMAP connaction test
## telnet test.d250.hu 143
## a AUTHENTICATE PLAIN
## + base64_code
##
#### IMAP4S connection test
## openssl s_client -crlf -connect test.d250.hu:993
## a LOGIN user passwd
##
#### SASL commands
## saslauthd -a rimap -O localhost
## saslauthd -d -a rimap -O localhost
## testsaslauthd -u username -p password
## testsaslauthd -u x -p xxxxxx
## testsaslauthd -u x@test.d250.hu -p xxxxxx
##
#### SMTPS connection test 
## openssl s_client -connect test.d250.hu:465
## EHLO d250.hu
## AUTH PLAIN
## base64_code
##
## exit from telnet Ctrl-AltGr-G quit
##
## TODO: this information is submitted to the cyrus sasl devel mailing list. keep an eye on it.
## for now we will aply a customization in the next step.

## to verify openssl SNI use the following command:
## openssl s_client -servername container.ve -connect localhost:443

## IMAP4S proxy
if [ ! -f /etc/perdition/perdition.conf ] || $all_arg_set
then

        log "Install perdition, with custom service files: imap4.service, imap4s.service, pop3s.service"

        yum -y install perdition
        ##   + vanessa_logger vanessa_socket

        ## perdition is run as template.service by default.
        ## we use our own unit files and service names.

        set_file /etc/perdition/perdition.conf '#### srvctl tuned perdition.conf
## Logging settings

# Turn on verbose debuging.
#debug
#quiet

# Log all comminication recieved from end-users or real servers or sent from perdition.
# Note: debug must be in effect for this option to take effect.

connection_logging

log_facility mail

## Basic settings

## NOTE: possibly listen only on the external-facing interface, and local-dovecot only on 127.0.0.1
bind_address 0.0.0.0 

domain_delimiter @


#### IMPORTANT .. the symbolic link .so.0 does not work. Full path is needed to real file.
map_library /usr/lib64/libperditiondb_posix_regex.so.0.0.0
map_library_opt /etc/perdition/popmap.re

no_lookup

ok_line "Reverse-proxy IMAP4S service lookup OK!"

## If no matches found in popmap.re
outgoing_server localhost

strip_domain remote_login

## For the default dovecot config, no ssl verification is needed
ssl_no_cert_verify
ssl_no_cn_verify

ssl_no_cn_verify

## SSL files
ssl_cert_file /etc/perdition/crt.pem
ssl_key_file /etc/perdition/key.pem

'"$no_ca_bundle_hashmark"'ssl_ca_chain_file /etc/perdition/ca-bundle.pem

'

        set_file /etc/perdition/popmap.re '#### srvctl tuned popmap.re

# (.*)@'$(hostname)': localhost

## you may add email domains here that should be located at localhost.

(.*)@(.*): $2
'

## srvctl custom unit files to make it work with different pid files.

mkdir -p /var/run/perdition

set_file /usr/lib/systemd/system/imap4.service '[Unit]
Description=Perdition IMAP4 reverse proxy
After=syslog.target network.target

[Service]
Type=forking
PIDFile=/var/run/perdition/perdition-imap4.pid
EnvironmentFile=-/etc/sysconfig/perdition
ExecStart=/usr/sbin/perdition.imap4 --pid_file /var/run/perdition/perdition-imap4.pid --protocol IMAP4 --ssl_mode tls_outgoing --bind_address 127.0.0.1

[Install]
WantedBy=multi-user.target
'

set_file /usr/lib/systemd/system/imap4s.service '[Unit]
Description=Perdition IMAP4S reverse proxy
After=syslog.target network.target

[Service]
Type=forking
PIDFile=/var/run/perdition/perdition-imap4s.pid
EnvironmentFile=-/etc/sysconfig/perdition
ExecStart=/usr/sbin/perdition.imap4s --pid_file /var/run/perdition/perdition-imap4s.pid --protocol IMAP4S

[Install]
WantedBy=multi-user.target
'

set_file /usr/lib/systemd/system/pop3s.service '[Unit]
Description=Perdition POP3S reverse proxy
After=syslog.target network.target

[Service]
Type=forking
PIDFile=/var/run/perdition/perdition-pop3s.pid
EnvironmentFile=-/etc/sysconfig/perdition
ExecStart=/usr/sbin/perdition.pop3s --pid_file /var/run/perdition/perdition-pop3s.pid --protocol POP3S

[Install]
WantedBy=multi-user.target
'

set_file /etc/sasl2/smtpd.conf 'pwcheck_method: saslauthd
mech_list: LOGIN'


        cat /root/ca-bundle.pem > /etc/perdition/ca-bundle.pem
        cat /root/crt.pem > /etc/perdition/crt.pem
        cat /root/key.pem > /etc/perdition/key.pem

        ## saslauthd
        if ! diff /root/saslauthd /usr/sbin/saslauthd >/dev/null ; then
                 rm -fr /usr/sbin/saslauthd
                cp /root/saslauthd /usr/sbin/saslauthd
                chmod 755 /usr/sbin/saslauthd
                saslauthd -v
        fi

        bak /etc/sysconfig/saslauthd

        set_file /etc/sysconfig/saslauthd '# Directory in which to place saslauthds listening socket, pid file, and so
# on.  This directory must already exist.
SOCKETDIR=/run/saslauthd

# Mechanism to use when checking passwords.  Run "saslauthd -v" to get a list
# of which mechanism your installation was compiled with the ablity to use.
MECH=rimap

# Additional flags to pass to saslauthd on the command line.  See saslauthd(8)
# for the list of accepted flags.
FLAGS="-O localhost -r"'

        systemctl daemon-reload

        systemctl stop imap4.service
        systemctl enable imap4.service
        systemctl start imap4.service
        systemctl status imap4.service

        systemctl stop imap4s.service
        systemctl enable imap4s.service
        systemctl start imap4s.service
        systemctl status imap4s.service

        systemctl stop pop3s.service
        systemctl enable pop3s.service
        systemctl start pop3s.service
        systemctl status pop3s.service

        systemctl stop saslauthd.service
        systemctl enable saslauthd.service
        systemctl start saslauthd.service
        systemctl status saslauthd.service

fi ## install perdition
## @update-install

## configure DNS server
## no recursion to prevent DNS amplifiaction attacks
if [ ! -f /etc/named.conf ] || $all_arg_set
then
        log "Installing BIND (named) DNS server."

        yum -y install bind bind-utils

        set_file /etc/named.conf '// srvctl generated named.conf

acl "trusted" {
     10.10.0.0/16;
     localhost;
     localnets;
 };

options {
    listen-on port 53 { any; };
    listen-on-v6 port 53 { any; };
    directory         "/var/named";
    dump-file         "/var/named/data/cache_dump.db";
    statistics-file "/var/named/data/named_stats.txt";
    memstatistics-file "/var/named/data/named_mem_stats.txt";
    allow-query     { any; };
    allow-recursion { trusted; };
    allow-query-cache { trusted; };
    recursion yes;
    dnssec-enable yes;
    dnssec-validation yes;
    dnssec-lookaside auto;
    bindkeys-file "/etc/named.iscdlv.key";
    managed-keys-directory "/var/named/dynamic";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "." IN {
    type hint;
    file "named.ca";
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";

include "/etc/srvctl/named.conf.local";
'

set_file /etc/srvctl/named.conf.local '## srvctl generated 
'

        rsync -a /usr/share/doc/bind/sample/etc/named.rfc1912.zones /etc
        rsync -a /usr/share/doc/bind/sample/var/named /var
        mkdir -p /var/named/dynamic

        chown -R named:named /var/named

fi ## install named
## @update-install

## TODO: firewall-config. open ports permanently

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

if [ ! -f /etc/freshclam.conf ] || $all_arg_set
then
        log "Installing Userspace tools."

        msg "Clamav antivirus"
        yum -y install clamav clamav-update
        sed_file /etc/freshclam.conf "Example" "### Exampl."
        sed_file /etc/freshclam.conf "#DNSDatabaseInfo current.cvd.clamav.net" "DNSDatabaseInfo current.cvd.clamav.net"

        msg "Tigervnc server"
        yum -y install tigervnc-server

        msg "Version managers"
        yum -y install mercurial
        yum -y install git

fi


## public ftp server
# yum -y install vsftpd
# systemctl enable vsftpd.service
# systemctl start vsftpd.service

## public torrent seed
# yum -y install opentracker-ipv4 opentracker-ipv6
# systemctl enable opentracker-ipv4.service
# systemctl start opentracker-ipv4.service
# yum -y install qbittorrent

## TODO run clamscan ...




scd=/root/srvctl-devel
if [ ! -d $scd ] 
then
        log "Creating srvctl-shortcuts in $scd"
        ## some quick links for root
        ## this has no real imporance so it can be any directory for your convinience
        mkdir -p $scd

        ln -s $SRV $scd/$SRV
        ln -s /etc/hosts $scd/hosts        
        ln -s /etc/pound.cfg $scd/pound.cfg

        #ln -s /usr/local/etc/lxc/lxc.conf $scd/lxc.conf
        #ln -s /usr/local/share/lxc/templates/lxc-fedora-srv $scd/lxc-fedora-srv
        #ln -s /usr/local/var/cache/lxc/fedora $scd/cache-lxc-fedora 
fi


if [ -s /root/.ssh/authorized_keys  ]
then
  sed_file /etc/ssh/sshd_config "PasswordAuthentication yes" "PasswordAuthentication no"
else
  msg "Password based ssh login couldnt be disabled, no authorized keys."
fi

## @update-install
## installation / configuration should be done.
log "Running updates"

freshclam
yum -y update

## TODO, configure firewalld

ok
fi ## update-install

fi ## onHS

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
