#!/bin/bash

if $onHS
then ## no identation.


## add new host
hint "add VE [USERNAME]" "Add new LXC container."
if [ "$CMD" == "add" ] && $onHS
then

        argument C 
        isDEV=false

        ## TODO verify if a domain alias already exists

        ## if thi sis a dev site, use the domain without the dev. prefix
        if [ ${C:0:4} == "dev." ]
        then
                C=${C:4}
                isDEV=true      
        fi

        ## check for human mistake
        if [ -d $SRV/$C ]; then
          err "$SRV/$C already exists! Exiting"
          exit 11
        fi

        if ! $(is_fqdn $C)
        then
          err "$C failed the domain regexp check. Exiting."
          exit 10
        fi

        ## authorize
        sudomize

        ## increase the counter
        counter=$(($(cat /etc/srvctl/counter)+1))
        echo $counter >  /etc/srvctl/counter

        log "Create container. #$counter"
        ## templates are usually in /usr/local/share/lxc/templates, lxc-fedora-srv has to be installed!
        lxc-create -n $C -t fedora-srv
        
        if [ "$?" == "0" ] && [ -f $SRV/$C/rootfs/etc/hostname ]
        then
              log "Container created."
        else
              err "Container not created!"
              exit
        fi
        
        echo $NOW > $SRV/$C/creation-date

        ## mark as dev site
        if $isDEV
        then
                echo "true" > $SRV/$C/pound-enable-dev
        fi

        #mkdir -p $SRV/$C 
        echo $counter > $SRV/$C/config.counter

        generate_lxc_config $C

        IPv4="10.10."$(to_ip $counter)
        rootfs=$SRV/$C/rootfs

        ## make root's key access
        mkdir -m 600 $rootfs/root/.ssh
        cat /root/.ssh/id_rsa.pub > $rootfs/root/.ssh/authorized_keys
        cat /root/.ssh/authorized_keys >> $rootfs/root/.ssh/authorized_keys
        chmod 600 $rootfs/root/.ssh/authorized_keys
        
        ## disable password authentication on ssh
        sed_file $rootfs/etc/ssh/sshd_config "PasswordAuthentication yes" "PasswordAuthentication no"
        


        ## Add IP to hosts file
        regenerate_etc_hosts

        ## set (fix) hostname
        echo $C > $rootfs/etc/hostname

        ## Container should be in the same timezone as the host.
        rsync -a /etc/localtime $rootfs/etc

        ## make the installation smaller        
        rm $rootfs/usr/lib/locale/locale-archive
        mkdir -p $rootfs/var/srvctl
        mkdir -p $rootfs/etc/srvctl

        ## srvctl 2.x installation dir
        mkdir -p $rootfs/$install_dir

set_file $rootfs/etc/srvctl/config '## srvctl generated
## MYSQL / MARIADB conf file that stores the mysql root password - in containers
MDF="'$MDF'"

## for php.ini in containers
php_timezone="'$php_timezone'"

## IPv4 Address ## TODO: dig command not available on a minimal-container, get it with: $(dig +time=1 +short $(hostname))
HOSTIPv4="'$HOSTIPv4'"
'

        ln -s /var/srvctl/locale-archive $rootfs/usr/lib/locale/locale-archive 
        
        rm -rf $rootfs/var/cache/yum/*

        ## add symlink to the srvctl application.
        ## outdated with 2.x, this was it for 1.x ln -s /var/srvctl/srvctl $rootfs/bin/srvctl
        ln -sf $install_dir/srvctl.sh $rootfs//bin/srvctl
        ln -sf $install_dir/srvctl.sh $rootfs//bin/sc

        ## As of June 2014, systemd-journald is running amok in the containers. To prevent 100% CPU usage, it has to be disabled.
        ## To undo, you may run: rm $rootfs/etc/systemd/system/systemd-journald.service
        ## Or, in the containers mask / unmask journald.service - reboot container to apply.
        ln -s '/dev/null' "$rootfs/etc/systemd/system/systemd-journald.service"

## Sendmail

        ## set containers sendmail que directory in order to allow apache to use php's mail function. (Didnt find a better way yet.) 
        chmod 773 $rootfs/var/spool/clientmqueue

## Postfix

        ## Container should have the same aliases as the host. (Important here is to disable info@domain) TODO remove, as its outdated
        #rsync -a /etc/aliases $rootfs/etc
        #rsync -a /etc/aliases.db $rootfs/etc
        make_aliases_db $rootfs

        echo '

# srvctl configuration
## Listen on ..
inet_interfaces = all

## If required Catch all mail defined in ..
# virtual_alias_maps = hash:/etc/postfix/catchall

## And send it to ..
home_mailbox = Maildir/

## Max 25MB mail size
message_size_limit=26214400

## set localhost.localdomain in mydestination to enable local mail delivery
mydestination = $myhostname, mail.$myhostname, localhost, localhost.localdomain

## also, add aliases there
        ' >> $rootfs/etc/postfix/main.cf

        echo "@$C root" > $rootfs/etc/postfix/catchall
        postmap $rootfs/etc/postfix/catchall

        ## TODO remove this as it is part of regenerate_etc_hosts
        #echo "$C #"  >> /etc/postfix/relaydomains
        #postmap /etc/postfix/relaydomains
        

        ln -s '/usr/lib/systemd/system/postfix.service' $rootfs'/etc/systemd/system/multi-user.target.wants/postfix.service'


## NFS
        generate_exports $C        

        ## enable nfs
        ln -s '/usr/lib/systemd/system/nfs.service' $rootfs'/etc/systemd/system/multi-user.target.wants/nfs.service'

## Apache

        ## enable the webserver
        ln -s '/usr/lib/systemd/system/httpd.service' $rootfs'/etc/systemd/system/multi-user.target.wants/httpd.service'

        ## use this patch for better logging of IP addresses
        set_file $SRV/$C/rootfs/etc/httpd/conf.d/pound.conf '## srvctl
        <IfModule log_config_module>

            ### Custom log redefinition
            ## - with extra host header
            # LogFormat "%{X-Forwarded-For}i %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" %h %D \"%{Host}i\"" combined
            ## - As close as possible
            LogFormat "%{X-Forwarded-For}i %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined

        </IfModule>

        Listen 8080
        Listen 8443 
'

        ## set default index page 
        index=$rootfs/var/www/html/index.html
        echo '<head></head><body bgcolor="#333"><div id="header" style="background-color:#151515;">
        <img src="logo.png" alt="'"$CMP"'" style="display: block; margin-left: auto; margin-right: auto; vertical-align: middle"></div>
        <p align="center"><font color="#aaa" style="margin-left: auto; margin-right: auto" size="6px" face="Arial">' > $index
        echo '<b>'$C'</b> @ '$(hostname) >> $index
        echo '</font><p></body>' >> $index

        cp /var/www/html/logo.png $rootfs/var/www/html
        cp /var/www/html/favicon.ico $rootfs/var/www/html

        ## system users ## TODO double check if this is really happens
        chown -R apache:apache  $rootfs/var/www/html
        chown -R srv:srv  $rootfs/srv

        ## we regenerate re-link all log files. like in regenerate_logfiles
        mkdir -p /var/log/httpd
        ln -s $rootfs/var/log/httpd/access_log /var/log/httpd/$C-access_log
        ln -s $rootfs/var/log/httpd/error_log /var/log/httpd/$C-error_log

## Pound
        ## create self-signed certificate
        create_certificate
        ## add to container - for https reverse proxying
        cat $ssl_key > $rootfs/etc/pki/tls/private/localhost.key
        cat $ssl_crt > $rootfs/etc/pki/tls/certs/localhost.crt

        regenerate_pound_files
        

## DNS

        named_slave_conf_global=/etc/srvctl/named.slave.conf.global.$(hostname)

        create_named_zone $C
        echo 'include "/var/named/srvctl/'$C'.conf";' >> /etc/srvctl/named.conf.local
        echo 'include "/var/named/srvctl/'$C'.slave.conf";' >> $named_slave_conf_global

        rm $dns_share
        tar -czPf $dns_share $named_slave_conf_global /var/named/srvctl

        systemctl restart named.service

        ## what user?
        U=$3
        if [ ! -z "$SC_SUDO_USER" ]
        then
            U=$SC_SUDO_USER
        fi
                
        echo "$U" > $SRV/$C/users

        if [ ! -z "$U" ]
        then
                add_user $U
                generate_user_configs
                generate_user_structure
        fi

##         #### START #### 

        log "Starting container $C - $IPv4 $U"        

        lxc-start -o $SRV/$C/lxc.log -n $C -d 


        ## wait for the container to get up 
        ## was based on $IPv4

        wait_for_ve_online $C

        scan_host_key $C
        regenerate_known_hosts

        wait_for_ve_connection $C

        msg "Post installation, ..."

## add system users 

        ssh $C "groupadd -r -g 101 srv"
        ssh $C "useradd -r -u 101 -g 101 -s /sbin/nologin -d /srv srv"

        ssh $C "groupadd -r -g 102 git"
        ssh $C "useradd -r -u 102 -g 102 -s /sbin/nologin -d /var/git git"

        ssh $C "groupadd -r -g 103 node"
        ssh $C "useradd -r -u 103 -g 103 -s /sbin/nologin -d /srv node"

        ssh $C "groupadd -r -g 104 codepad"
        ssh $C "useradd -r -u 104 -g 104 -s /sbin/nologin -d /srv/etherpad-lite codepad"

## Dovecot - due to an error in yum, it has to be installed in the container after it has started.
## Fedora 20 and fedora 21 as well.
## TODO bugcheck - does dovecot hang on postinit script?
 
        ssh $C "newaliases"
        ssh $C "yum -y install dovecot"
        ssh $C "systemctl enable dovecot.service"
        ssh $C "systemctl start dovecot.service"

        
        ## if this is a dev. site install codepad
        if $isDEV
        then
                msg "Setup codepad"
                ssh $C "srvctl setup-codepad"
        fi


        if [ ! -z "$U" ]
        then
                nfs_mount

        fi

        msg "$C ready."

ok
fi ## srvctl add

fi

man '
    This will add a new LXC container, also called virtual enviroment or VE - to a srvctl host. Each container is unique, and runs a complete OS.
    The name of the VE has to be a domain name, and might be a .local domain or a subdomain. Developer domains can be prefixed with dev. 
    An optional username can be given to define the owner of the VE. Multiple users can have access to the VE, defined in the containers users file.
    Each container will be configured with SSH keypairs, all authorized users can have root-access to a VE from the user account of the srvctl host.
    Logged in users can access files of the containers with ssh - usually in a two step hop, or directly with NFS folders mounted to their home/VE directories.
    The srvctl-client script can be used to sync, backup, upload files. Proper SSH port forwarding allows SFTP access directly from remote user computers.
    Containers will be configured as web and mail servers. The srvctl command will be available on every VE, and can be used to configure further.
    
'
