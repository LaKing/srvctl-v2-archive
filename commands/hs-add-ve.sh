if $onHS
then ## no identation.

## add new host
hint "add-fedora VE [CMS]" "Add new LXC OS-container. Optionally specify DNS"
hint "add-codepad VE" "Add new LXC OS-container running codepad."
hint "add-ubuntu VE" "Add new LXC ubuntu based OS container."
hint "add-apache VE" "Add new LXC application container running apache with a readonly filesystem."

if [ "$CMD" == "add" ] || [ "$CMD" == "add-fedora" ] || [ "$CMD" == "add-apache" ] || [ "$CMD" == "add-codepad" ] || [ "$CMD" == "add-ubuntu" ]
then

    ##  TODO add srvctl services

        ## authorize
        sudomize

        argument C 
        local isDEV=false
        local isMX=false
        
        local ctype="fedora"
        
        if [ "$CMD" == "add-apache" ]
        then
            ctype="apache"
        fi
        
        if [ "$CMD" == "add-ubuntu" ]
        then
            ctype="ubuntu"
        fi
        
        if [ "$CMD" == "add-codepad" ]
        then
            ctype="codepad"
        fi
        
        ## TODO verify if a domain alias already exists

        ## if thi sis a dev site, use the domain without the dev. prefix
        if [ ${C:0:4} == "dev." ]
        then
                C=${C:4}
                isDEV=true
                msg "$C will be a dev-enabled site."      
        fi

        ## if this is a mail server, its something special
        if [ ${C:0:5} == "mail." ]
        then
                isMX=true
                msg "$C will be a mailserver." 
        fi

        ## check for human mistake
        if [ -d $SRV/$C ]
        then
          err "$SRV/$C already exists! Exiting"
          exit 11
        fi
        
        for _S in $SRVCTL_HOSTS
        do
            for _c in $(ssh $$_S srvctl ls)
            do
                if [ "$_c" == "$C" ]
                then
                    err "$C already on $$_S"
                    exit 111
                fi
            done
        done
        
        
    if [ "${C: -6}" == ".devel" ] || [ "${C: -6}" == "-devel" ] || [ "${C: -6}" == ".local" ] || [ "${C: -6}" == "-local" ]
    then
        msg "Local container."
    else
        
        if ! $(is_fqdn $C)
        then
            C="$C.$SDN"
            msg "$C will be set as hostname"
        fi
        
        if ! $(is_fqdn $C)
        then
          err "$C failed the domain regexp check. Exiting."
          exit 10
        fi
        
    fi

        if [ -z "$(ip addr show srv-net 2> /dev/null | grep UP)" ]
        then
            err "srv-net is not present. ... run 'srvctl update-install' then reboot?"
            exit 12
        fi
      
        if ! [ -d /var/srvctl-rootfs/$ctype/root ]
        then
            err "$ctype has no rootfs directory."
            exit 13
        fi
      
        regenerate_counter 

        ## increase the counter
        counter=$(($(cat /var/srvctl-host/counter)+1))
        echo $counter >  /var/srvctl-host/counter

        log "Create $ctype container #$counter as $C for $SRVCTL_USER"
        
        ## instead of using the lxc-templates, we brew our own beer 
     
        mkdir -p $SRV/$C/settings
        echo $SC_USER > $SRV/$C/settings/users
        echo $ctype > $SRV/$C/ctype
        echo $NOW > $SRV/$C/creation-date
        
        rootfs=$SRV/$C/rootfs
        
        ## Create rootfs
        if [ $ctype == fedora ] || [ $ctype == ubuntu ] || [ $ctype == codepad ]
        then
            cp -R -p /var/srvctl-rootfs/$ctype $rootfs
         
            if [ "$?" == "0" ] #&& [ -f $SRV/$C/rootfs/etc/hostname ]
            then
              log "Container $C rootfs created."
            else
              err "Container rootfs not created!"
              exit 31
            fi
            
            mkdir -p $SRV/$C/rootfs/var/log/srvctl

            ## set hostname
            echo $C > $rootfs/etc/hostname

            setup_rootfs_ssh        
        fi
        
        if [ $ctype == apache ]
        then
            mnt_rorootfs
            
            mkdir -p $SRV/$C/rootfs/var/www/html
            chown -R apache:apache $SRV/$C/rootfs/var/www/html
            
            mkdir -p $SRV/$C/rootfs/var/log/httpd
            mkdir -p $SRV/$C/rootfs/etc
            
            #cp -R /var/srvctl-rorootfs/apache/etc $SRV/$C/rootfs
            cp -R /var/srvctl-rorootfs/apache/root $SRV/$C/rootfs
            cp -R /var/srvctl-rorootfs/apache/run $SRV/$C/rootfs
        fi
        
        if [ $ctype == codepad ]
        then
            date +%s | sha256sum | base64 | head -c 64 > $SRV/$C/rootfs/etc/codepad/SESSIONKEY.txt
            date +%s | sha256sum | base64 | head -c 64 > $SRV/$C/rootfs/etc/codepad/APIKEY.txt
            ln -s /var/srvctl-ve/$C/users $SRV/$C/rootfs/var/codepad/users
            
            set_file $SRV/$C/rootfs/etc/codepad/settings.json '/* ep_codepad-devel settings*/
{
  "ep_codepad": { 
    "theme": "Cobalt",
    "project_path": "/srv/codepad-project",
    "log_path": "/var/codepad/project.log",
    "push_action": "/bin/bash /srv/codepad-project/push.sh",
    "play_url": "https://'$(echo $C | tr '.' '-')'.play.'$CDN'"
  },
  "title": "codepad",
  "favicon": "favicon.ico",
  "ip": "0.0.0.0",
  "port" : 9001,
  "dbType" : "mysql",
  "dbSettings" : {
    "user"    : "root",
    "host"    : "localhost",
    "password": "",
    "database": "codepad"
  },
  "defaultPadText" : "// codepad",
  "requireSession" : false,
  "editOnly" : false,
  "minify" : true,
  "maxAge" : 21600, 
  "abiword" : null,
  "requireAuthentication": true,
  "requireAuthorization": false,
  "trustProxy": false,
  "disableIPlogging": true,  
  "socketTransportProtocols" : ["xhr-polling", "jsonp-polling", "htmlfile"],
  "loglevel": "INFO",
  "logconfig" :
    { "appenders": [
        { "type": "console"}
      ]
    },
}
'


cd $SRV/$C/rootfs/var/git
git init --bare -q
git clone $SRV/$C/rootfs/var/git $SRV/$C/rootfs/srv/codepad-project -q &> /dev/null

set_file $SRV/$C/rootfs/srv/codepad-project/.git/config '[core]
        repositoryformatversion = 0
        filemode = true
        bare = false
        logallrefupdates = true
[remote "origin"]
        url = /var/git
        fetch = +refs/heads/*:refs/remotes/origin/*
[branch "master"]
        remote = origin
        merge = refs/heads/master
'

set_file $SRV/$C/rootfs/var/codepad/.gitconfig '[user]
        email = codepad@'$C'
        name = codepad
[push]
        default = simple
'

rsync -a $install_dir/ve-install/codepad-project $SRV/$C/rootfs/srv

$(cd $SRV/$C/rootfs/srv/codepad-project && npm install >> /dev/null)

cat $SRV/$C/rootfs/etc/pki/tls/certs/localhost.crt > $SRV/$C/rootfs/var/codepad/localhost.crt
cat $SRV/$C/rootfs/etc/pki/tls/private/localhost.key > $SRV/$C/rootfs/var/codepad/localhost.key


chmod 744 -R $SRV/$C/rootfs/etc/codepad
chown -R codepad:codepad $SRV/$C/rootfs/var/codepad
chown -R codepad:codepad $SRV/$C/rootfs/srv/codepad-project

        fi

        ## mark as dev site
        #if $isDEV
        #then
        #        echo "true" > $SRV/$C/settings/pound-enable-dev
        #fi

        echo $counter > $SRV/$C/config.counter

        generate_lxc_config $C

        IPv4="10.$HOSTNET."$(to_ip $counter)
        

        regenerate_etc_hosts



## USERs

        generate_user_structure $SC_USER $C
        
        ## static-server
        mkdir -p /var/static-server/$C
            
            if [ -d /home/$SC_USER/$C ]
            then
                if [ ! -e /home/$SC_USER/$C/static-server ]
                then
                    ln -sf /var/static-server/$C /home/$SC_USER/$C/static-server
                fi
                chown -R $SC_USER:$SC_USER /var/static-server/$C
            fi
            
        local _config=/var/srvctl-host/ssh_config/$HOSTNAME 
            echo "Host $C" >> $_config 
            echo "User root" >> $_config
            echo "" >> $_config    
        
        #if $isSUDO
        #then
        #    msg "Add user $SC_USER" 
        #    echo "$SC_USER" >> $SRV/$C/settings/users
        #    U=$SC_USER
        #    
        #    add_user $U
        #    generate_user_configs $U
        #    generate_user_structure $U $C
        #fi

        ## add users from argument
        #for U in $OPAS3
        #do
        #    msg "Add users $U"                
        #    echo "$U" >> $SRV/$C/settings/users
        #    add_user $U
        #    generate_user_configs $U
        #    generate_user_structure $U $C
        #done        
        
        mkdir -p $BACKUP_PATH/$C
        
        ## srvctl 2.x installation dir
        mkdir -p /var/srvctl-ve/$C
        setup_srvctl_ve_dirs
        
        ## shares
        regenerate_var_ve
     
    if [ $ctype == fedora ]
    then
   
        
## Postfix
## Sendmail
        msg "Setting up the Postfix mailing system."
        ## set containers sendmail que directory in order to allow apache to use php's mail function. (Didnt find a better way yet.) 
        ## TODO check!
        ## Seems to be obsolete. No such file or directory
        # chmod 773 $rootfs/var/spool/clientmqueue

        ## Container should have the same aliases as the host. (Important here is to disable info@domain) 
        ## TODO remove, as its outdated
        #rsync -a /etc/aliases $rootfs/etc
        #rsync -a /etc/aliases.db $rootfs/etc
        make_aliases_db $rootfs
        write_ve_postfix_main $C

        

        echo "@$C root" > $rootfs/etc/postfix/catchall
        postmap $rootfs/etc/postfix/catchall

        ln -s '/usr/lib/systemd/system/postfix.service' $rootfs'/etc/systemd/system/multi-user.target.wants/postfix.service'

        regenerate_opendkim
        
        regenerate_perdition_files
    
    fi
        
## Apache
        
        ## use this patch for better logging of IP addresses

        setup_index_html $C
        
        if [ "$C" == "default-host.local" ]
        then            
            setup_index_html $HOSTNAME
        else        
            setup_index_html $C
        fi 
        
## DNS
        get_dns_servers $C
        regenerate_dns
        
## Pound
        msg "Pound configuration"        
        
        ## create selfsigned certificate
        cert_path=/var/srvctl-host/selfsigned-certificates/$C
        create_selfsigned_domain_certificate $C
        
        if [ $ctype == fedora ]
        then
            ## add a new, unique selfsigned certificate to container - for https reverse proxying
            cat $ssl_key > $rootfs/etc/pki/tls/private/localhost.key
            cat $ssl_crt > $rootfs/etc/pki/tls/certs/localhost.crt
        fi


        if [ $ctype == ubuntu ]
        then
            ## add a new, unique selfsigned certificate to container - for https reverse proxying ... snakeoil????
            cat $ssl_key > $rootfs/etc/ssl/private/localhost.key
            cat $ssl_crt > $rootfs/etc/ssl/certs/localhost.pem
        fi

        ## create letsencrypt certificate
        get_acme_certificate $C
        ## TODO - import that o containers for IPv6?

        if [ "$C" == "default-host.local" ]
        then
            echo $(hostname) > $SRV/$C/settings/pound-host        
        fi 

        regenerate_pound_files
        regenerate_pound_sync
        restart_pound



## Node / npm
        ## npm root -g => /usr/lib/node_modules
        #echo 'export NODE_PATH="/usr/lib/node_modules"' > /etc/profile.d/npm.sh

        bind_mount $C


#### START #### 
   
    if [ $ctype == fedora ] || [ $ctype == ubuntu ] || [ $ctype == codepad ]
    then
 

        log "Starting container $C - $IPv4 $U" 

        lxc_start $C
        echo ''
        
        if $lxc_start_success
        then
        
            ## if this is a dev. site install codepad
            if $isDEV
            then
                msg "Setup codepad"
                ssh $C "srvctl setup-codepad"
            fi
        
            msg "$C ready."
        fi
    fi
    
    
    if [ $ctype == apache ]
    then
        ln -s $SRV/$C/$ctype.service /etc/systemd/system/multi-user.target.wants/$C.$ctype.service
        systemctl daemon-reload
        systemctl start $C.$ctype.service
        msg "apache application-container ready."
    fi
    

   
    regenerate_relaydomains 
    regenerate_known_hosts


ok
fi ## srvctl add

fi

man '
    This will add a new LXC OS container, also called virtual enviroment or VE - to a srvctl host. Each container is unique, and runs a complete OS.
    The name of the VE has to be a domain name, and might be a .local domain or a subdomain. Developer domains can be prefixed with dev. 
    An optional username can be given to define the owner of the VE. Multiple users can have access to the VE, defined in the containers users file.
    Each container will be configured with SSH keypairs, all authorized users can have root-access to a VE from the user account of the srvctl host.
    Logged in users can access files of the containers with ssh - usually in a two step hop, or directly with NFS folders mounted to their home/VE directories.
    The srvctl-client script can be used to sync, backup, upload files. Proper SSH port forwarding allows SFTP access directly from remote user computers.
    OS Containers will be configured as web and mail servers. The srvctl command will be available on every VE, and can be used to configure further.
    Local containers might be called *.local *-local or *.devel *-devel.
    Prefixes make sense, mail. or dev. will create MX or development servers.
    
'

