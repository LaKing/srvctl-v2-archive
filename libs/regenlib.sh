#!/bin/bash

if $onHS
then ## no identation.

### regenerate-related functions
function regenerate_var_ve {
        
        msg "Regenerate VE shares"
        
        mkdir -p /var/srvctl-ve
        
        for _C in $(lxc_ls)
        do
            dest=/var/srvctl-ve/$_C
            mkdir -p $dest
            
            ## if container is accessed with IPv6 this migh come handy ...
            #rm -rf $dest/cert/*
            #cp -ru $SRV/$_C/cert $dest
            
            rm -rf $dest/settings/*
            cp -ru $SRV/$_C/settings $dest
            
            rm -rf $dest/users/*
            
            local _root_username="root@$HOSTNAME"
            
            if [ -f /root/.username ] 
            then
                _root_username="$(cat /root/.username)"  
            fi           
            
            if [ -f /root/.password.sha512 ] 
            then
                mkdir -p $dest/users/$_root_username
                cat /root/.password.sha512 > $dest/users/$_root_username/.hash
            fi

            for _U in $(cat $SRV/$_C/settings/users)
            do
                mkdir -p $dest/users/$_U 
         
                if [ -f /var/srvctl-users/$_U/.password.sha512 ]
                then
                    cat /var/srvctl-users/$_U/.password.sha512 > $dest/users/$_U/.hash
                fi                               
            done 
        done
        

        chmod -R 655 /var/srvctl-ve
        chmod 644 /var/srvctl-ve/*/settings/* 2>/dev/null
        chmod 644 /var/srvctl-ve/*/users/*/.hash 2>/dev/null
}


function regenerate_config_files {

        ## scan for imported containers         
        for _C in $(ls $SRV)
        do            
            if [ $_C == "lost+found" ]
            then
              continue
            fi
            
            if [ -f "$SRV/$_C" ]
            then
              continue
            fi
            
            if  [ ! -f $SRV/$_C/rootfs/etc/hostname ]
            then
              continue
            else
              echo $_C > $SRV/$_C/rootfs/etc/hostname
            fi
           
            
            if [ ! -f $SRV/$_C/config.counter ]
            then
                ## increase the counter
                counter=$(($(cat /var/srvctl-host/counter)+1))
                echo $counter >  /var/srvctl-host/counter
                echo $counter > $SRV/$_C/config.counter
            fi
            
            if [ ! -f $SRV/$_C/config.ipv4 ] || [ ! -f $SRV/$_C/config ] || $all_arg_set
            then
                    generate_lxc_config $_C
                    
            fi
            
            if $all_arg_set
            then
                ## TODO resolv conf from host? or special one?
                cat /etc/resolv.conf > $SRV/$_C/rootfs/etc/resolv.conf
                write_ve_postfix_main $_C
            fi
            
        done
        
}

function regenerate_etc_hosts {

        mkdir -p /var/srvctl-host/etchosts
        local _eh=/var/srvctl-host/etchosts/$HOSTNAME

        local _dig=''
        local ip=''
        msg "regenerate etc_hosts" ## first in var

        echo "## $HOSTNAME ##" > $_eh
        echo "10.$HOSTNET.0.1    ${HOSTNAME%%.*}" >> $_eh


        for _C in $(lxc-ls)
        do

                ip=$(cat $SRV/$_C/config.ipv4)
                

                if [ -z "$ip" ] 
                then
                        counter=$(cat $SRV/$_C/config.counter)
                        if [ -z "$counter" ] 
                        then        
                                err "No counter, no IPv4 for "$_C
                                exit
                        else
                                ip="10.$HOSTNET."$(to_ip $counter)
                                echo $ip > $SRV/$_C/config.ipv4
                                ntc "$_C set to $ip"
                        fi        
                fi

                if [ ! -z "$ip" ]
                then
 
                        echo $ip'                '$_C >>  $_eh
                        
                        if [ ! -d $SRV/mail.$_C ] && [ "${_C:0:5}" != "mail." ]
                        then
                            echo $ip'                mail.'$_C >>  $_eh
                        fi

                        if [ -f $SRV/$_C/settings/aliases ]
                        then
                            for A in $(cat $SRV/$_C/settings/aliases)
                            do
                                if [ "$A" == "$(hostname)" ]
                                then
                                    err "$_C alias: $A - is the host itself!"
                                else
                                    #dbg "$A is an alias of $_C"
                                    echo $ip'                '$A >>  $_eh
                                                        
                                    if [ ! -d $SRV/mail.$A ] && [ ! -d $SRV/mail.$_C ] && [ "${A:0:5}" != "mail." ] && [ "${_C:0:5}" != "mail." ]
                                    then
                                        echo $ip'                mail.'$A >>  $_eh
                                    fi
                                fi
                            done
                        fi

                        echo ''  >>  $_eh
                fi
        done 
        
        ## regenerated local etc_hosts, now check the remote ones and put them together

        _eh=/var/srvctl-host/etchosts/srvctl-hosts
        
        
        IP="$(cat /var/srvctl/ifcfg/ipv4)"
        
        echo "## srvctl-hosts ##" > $_eh
        echo "${IP%/*}    $HOSTNAME" >> $_eh
        echo "" >> $_eh
        
        echo "${IP%/*}" > /var/srvctl/ifcfg/$HOSTNAME
        
        local _dig=''
        
        if [ -f /var/srvctl/ifcfg/$HOSTNAME ]
        then
            _dig=$(cat /var/srvctl/ifcfg/$HOSTNAME)
        else
            _dig="$(dig $HOSTNAME +short +time=1)"
            echo $_dig > /var/srvctl/ifcfg/$HOSTNAME
        fi
        
        ## a but redundant configuration check
        # if [ "$_dig" != "$(cat /var/srvctl/ifcfg/$HOSTNAME)" ]
        # then
        #        err "CRITICAL ERROR - DNS $_dig != CONFIG $(cat /var/srvctl/ifcfg/$HOSTNAME)"
        # fi
            
        for _S in $SRVCTL_HOSTS
        do
                    
            if [ -f /var/srvctl/ifcfg/$_S ]
            then
                _dig=$(cat /var/srvctl/ifcfg/$_S)
            else
                _dig="$(dig $_S +short  +time=1)"
                echo $_dig > /var/srvctl/ifcfg/$_S
            fi
        
            if [ "$(ssh -n -o ConnectTimeout=1 $_S hostname 2> /dev/null)" == "$_S" ]
            then
                
                msg "get hosts on $_S"

                if ! [ -z "$_dig" ]
                then
                    echo "$_dig    $_S" >> $_eh
                fi

                ssh -n -o ConnectTimeout=1 $_S "cat /var/srvctl-host/etchosts/$_S" > /var/srvctl-host/etchosts/$_S

            else 
                err "Connection to $_S failed!"
            fi
  
        done
        
        echo "" >> $_eh
        
        echo "# srvctl generated" > /etc/hosts
        echo "127.0.0.1                localhost.localdomain localhost" >> /etc/hosts
        echo "::1                localhost6.localdomain6 localhost6" >> /etc/hosts
        
        cat /var/srvctl-host/etchosts/* >> /etc/hosts
        cat /var/srvctl-host/etchosts/* >> /var/srvctl/hosts

} 

function regenerate_relaydomains {


        mkdir -p /var/srvctl-host/relaydomains
        local _rd=/var/srvctl-host/relaydomains/$HOSTNAME

        msg "regenerate etc_hosts" ## first in var

        echo '' > $_rd

        for _C in $(lxc-ls)
        do

                ip=$(cat $SRV/$_C/config.ipv4)
                
                if [ -z "$ip" ] 
                then
                        counter=$(cat $SRV/$_C/config.counter)
                        if [ -z "$counter" ] 
                        then        
                                err "No counter, no IPv4 for "$_C
                                exit
                        else
                                ip="10.$HOSTNET."$(to_ip $counter)
                                echo $ip > $SRV/$_C/config.ipv4
                                ntc "$_C set to $ip"
                        fi        
                fi

                if [ ! -z "$ip" ]
                then 
                        echo $_C' #' >>  $_rd
                        if [ -f /$SRV/$_C/settings/aliases ]
                        then
                            for A in $(cat /$SRV/$_C/settings/aliases)
                            do
                                if [ "$A" == "$(hostname)" ]
                                then
                                    err "$_C alias: $A - is the host itself!"
                                else
                                    echo $A' #' >>  $_rd
                                fi
                            done
                        fi
                fi
        done 
        
        ## regenerated local relaydomains, now check the remote ones and put them together
                
        IP="$(cat /var/srvctl/ifcfg/ipv4)"

        for _S in $SRVCTL_HOSTS
        do
            if [ "$(ssh -n -o ConnectTimeout=1 $_S hostname 2> /dev/null)" == "$_S" ]
            then
                msg "get relaydomains on $_S"

                ssh -n -o ConnectTimeout=1 $_S "cat /var/srvctl-host/relaydomains/$_S" > /var/srvctl-host/relaydomains/$_S

            else 
                err "Connection to $_S failed!"
            fi
            
        done
        
        echo '' > /etc/postfix/relaydomains
        cat /var/srvctl-host/relaydomains/* > /etc/postfix/relaydomains
        postmap /etc/postfix/relaydomains

} 


function scan_host_key {
    
    local _C=$1
    local _ip=$(cat $SRV/$_C/config.ipv4)
    local _res_ip=''
    local _res_ve=''
    
    if [ ! -f $SRV/$_C/host-key ] || $all_arg_set
    then
        set_is_running $_C

        if $is_running && [ "$(getent hosts $_C | cut -d' ' -f1)" == "$_ip" ]
        then 
            msg "Scanning host key of "$_C
            _res_ip="$(ssh-keyscan -t rsa -H $_ip 2>/dev/null)" 
            _res_ve="$(ssh-keyscan -t rsa -H $_C 2>/dev/null)"    
            if [ ! -z "$_res_ip" ] && [ ! -z "$_res_ve" ]         
            then
                echo "## srvctl scanned host-key $NOW IP $_ip VE $_C" > $SRV/$_C/host-key
                echo "$_res_ip" >> $SRV/$_C/host-key 
                echo "$_res_ve" >> $SRV/$_C/host-key 
            else
                err "ssh-keyscan returned with no result."
            fi
        else
            err "Could not scan host-key for: "$_C                   
        fi              
    fi                             
}

function regenerate_known_hosts {

        msg "regenerate known hosts"
        mkdir -p /var/srvctl-host/known_hosts
        
        local known_hosts=/var/srvctl-host/known_hosts/localhost

        echo '## srvctl generated ..' > $known_hosts
        ## local first
        ssh-keyscan -t rsa -H 127.0.0.1 >> $known_hosts 2>/dev/null
        ssh-keyscan -t rsa -H localhost >> $known_hosts 2>/dev/null
        ssh-keyscan -t rsa -H localhost.localdomain >> $known_hosts 2>/dev/null
        ssh-keyscan -t rsa -H ::1 >> $known_hosts 2>/dev/null
        ssh-keyscan -t rsa -H localhost6 >> $known_hosts 2>/dev/null
        ssh-keyscan -t rsa -H localhost6.localdomain6 >> $known_hosts 2>/dev/null
        
        known_hosts=/var/srvctl-host/known_hosts/$HOSTNAME
        echo '## srvctl generated ..' > $known_hosts
        
        ssh-keyscan -t rsa -H $HOSTNAME >> $known_hosts 2>/dev/null
        ssh-keyscan -t rsa -H ${HOSTNAME%%.*} >> $known_hosts 2>/dev/null
        ssh-keyscan -t rsa -H 10.$HOSTNET.0.1 >> $known_hosts 2>/dev/null
        
        ## should be created on update-install
        if [ -f /var/srvctl/ifcfg/$HOSTNAME ]
        then
             ssh-keyscan -t rsa -H $(cat /var/srvctl/ifcfg/$HOSTNAME) >> $known_hosts 2>/dev/null
        fi
        
        echo '## srvctl containers' >> $known_hosts
        
        #for _S in $SRVCTL_HOSTS
        #do
        #    _known_hosts=/var/srvctl-host/known_hosts/$_S
        #    echo "## $_S $(cat /var/srvctl/ifcfg/$_S) ${_S%%.*}" > $known_hosts
        #    ssh-keyscan -t rsa -H $(cat /var/srvctl/ifcfg/$_S) >> $known_hosts 2>/dev/null
        #    ssh-keyscan -t rsa -H $_S >> $known_hosts 2>/dev/null
        #    ssh-keyscan -t rsa -H ${_S%%.*} >> $known_hosts 2>/dev/null
        #    #2>/dev/null
        #    echo '' >> $known_hosts
        #done
        #
        #local _known_hosts=/var/srvctl-host/known_hosts/$HOSTNAME
        
        for _C in $(lxc-ls)
        do
            scan_host_key $_C

            if [ -f $SRV/$_C/host-key ]
            then
                echo "## $_C" >> $known_hosts
                cat $SRV/$_C/host-key >> $known_hosts
            fi

        done ## regenerated  containers hosts
        #msg "Set ssh_known_hosts done."
        
        for _S in $SRVCTL_HOSTS
        do
            if [ "$(ssh -n -o ConnectTimeout=1 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $_S '[ -f /var/srvctl-host/known_hosts/$HOSTNAME ] && hostname || echo err' 2> /dev/null)" == "$_S" ]
            then
                msg "get $_S known_hosts"
                ssh -n -o ConnectTimeout=1 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $_S "cat /var/srvctl-host/known_hosts/$_S" > /var/srvctl-host/known_hosts/$_S
            else
                err "Could not fetch known_hosts of $_S"  
            fi
        done
        
        cat /var/srvctl-host/known_hosts/* > /etc/ssh/ssh_known_hosts
        cat /var/srvctl-host/known_hosts/* > /var/srvctl/ssh_known_hosts
}




function regenerate_root_configs {

#echo "Checking root's .ssh configs"

### User checks
        ## for root
        if [ ! -f /root/.ssh/id_rsa.pub ]
        then
          err "ERROR - NO KEYPAIR FOR ROOT!"
        fi

        if [ ! -f /root/.ssh/authorized_keys ]
        then
          msg "WARNING - NO authorized_keys FOR ROOT!"
          #echo '' >> /root/.ssh/authorized_keys
        fi

}

function regenerate_users_sync {
    ## this is one way. $ROOTCA_HOST broadcasting data to all hosts ...
    ## but regenerate is doing it back and forth ...
    if [ "$ROOTCA_HOST" == $HOSTNAME ]
    then
        for _S in $SRVCTL_HOSTS
        do    
            if [ "$(ssh -n -o ConnectTimeout=1 $_S hostname 2> /dev/null)" == "$_S" ]
            then
                msg "Update users on $_S"
                rsync -ae ssh /var/srvctl-users $_S:/var
            else
                err "Connection for users_sync failed to $_S"
            fi
        done
    else
        if [ "$(ssh -n -o ConnectTimeout=1 $ROOTCA_HOST hostname 2> /dev/null)" == "$ROOTCA_HOST" ]
        then
            msg "Update users from $ROOTCA_HOST"
            rsync -ae ssh $ROOTCA_HOST:/var/srvctl-users /var
        else
            err "Connection for users_sync failed from $ROOTCA_HOST"
        fi
    fi
}


function regenerate_users {
        ## First of all, make sure all users we have defined for sites, are all present.
        msg "processing user-list"
        
        echo '' > /var/srvctl-host/local-users
        
        for _C in $(lxc_ls)
        do
                mkdir -p $SRV/$_C/settings
                touch $SRV/$_C/settings/users

                for _U in $(cat $SRV/$_C/settings/users)
                do                
                        ## if the user doesent exists ... well, create it.
                        if [ ! -d /home/$U ]
                        then
                            add_user $_U
                        fi
                done
        done

}

function generate_user_configs { ## for each user

        ## for each user

        local _u=$1        
        local _keys=/var/srvctl-users/$_u/authorized_keys       

        ## create keypair
        #if [ ! -f /home/$_u/.ssh/id_rsa.pub ] || [ ! -f /home/$_u/.ssh/id_rsa ]
        #then
          create_user_keypair $_u
        #fi
        
        if [ "$ROOTCA_HOST" == $HOSTNAME ]
        then
            #if [ ! -f /var/srvctl-users/$_u/srvctl_id_rsa.pub ] || [ ! -f /var/srvctl-users/$_u/srvctl_id_rsa ]
            #then
                create_srvctl_keypair $_u
            #fi  
            
            mkdir -p /root/srvctl-users/authorized_keys
            ## srvctl-user key
            cat /var/srvctl-users/$_u/user_id_rsa.pub > $_keys
            echo '' >> $_keys
        
            ## srvctl-gui key
            cat /var/srvctl-users/$_u/srvctl_id_rsa.pub >> $_keys
            echo '' >> $_keys
        
            ## root-managed keys
            if [ -f  /root/srvctl-users/authorized_keys/$_u ]
            then
                cat /root/srvctl-users/authorized_keys/$_u >> $_keys
                echo '' >> $_keys
            fi
        fi
        
        if [ -f $_keys ]
        then
            cat /root/.ssh/authorized_keys > /home/$_u/.ssh/authorized_keys
            cat $_keys >> /home/$_u/.ssh/authorized_keys
            chown $_u:$_u /home/$_u/.ssh/authorized_keys
        fi
        
        ## so we use bind mounts now, and want allow users to access files in their bind-mounted container dirs....
        usermod -a -G srv $_u
        usermod -a -G apache $_u
        usermod -a -G node $_u
        usermod -a -G git $_u
        usermod -a -G codepad $_u
        
}


function regenerate_users_configs {

## for simplicity, we assume all users have a home

        msg "regenrate user configs"
        for _U in $(ls /home)
        do
            if [ -d "/home/$_U" ]
            then
            generate_user_configs $_U
            else
                err "$_U is not a directory? in /home?"
            fi
        done 
        
        msg "regenrate user hashes"
        for _U in $(ls /home)
        do  
            if [ -d "/home/$_U" ]
            then
                update_password $_U
            fi
        done 
        

        
        msg "regenerate openvpn authorisations"
        mkdir -p /var/openvpn
        rm -fr /var/openvpn/*
        for _U in $(ls /home)
        do
            if [ -d "/home/$_U" ]
            then
                echo '## srvctl' > /var/openvpn/$_U
                make_openvpn_client_conf $_U
            fi
        done
        
    if [ "$ROOTCA_HOST" == "$HOSTNAME" ]
    then 

        msg "regenerate client certificates"
        for _U in $(ls /home)
        do
            if [ -d "/home/$_U" ]
            then
                create_ca_certificate client usernet $_U
            fi
        done
        
        msg "Update settings for srvctl-gui"
        
        rsync -a /var/srvctl-users /var/srvctl-gui
        
        chown -R srvctl-gui:srvctl-gui /var/srvctl-gui
        chmod 700 /var/srvctl-gui
        
        systemctl restart srvctl-gui
        
    fi
        
}

function generate_user_structure ## for user, container
{
    local _u=$1
    local _c=$2

     #dbg  "Generating user structure for $_u in $_c"

                ## add users srvctl-gui public key to container root user - for gui ssh access.
                if [ -f /var/srvctl-users/$_u/authorized_keys ]
                then
                        cat /var/srvctl-users/$_u/authorized_keys >> $SRV/$_c/rootfs/root/.ssh/authorized_keys
                fi

                ## Share via mount
                ## Second, create common share
                mkdir -p /home/$_u/$_c/mnt
                chown $_u:$_u /home/$_u/$_c
                chown $_u:$_u /home/$_u/$_c/mnt

                ## create directory we will bind to
                mkdir -p $SRV/$_c/rootfs/mnt/$_u

                ## everything prepared, this is for container mount point.
                add_conf $SRV/$_c/fstab "/home/$_u/$_c/mnt $SRV/$_c/rootfs/mnt/$_u none rw,bind 0 0"


}


function regenerate_users_structure {

        ## for each container

        msg "regenerate users structure"
        
        for _C in $(lxc_ls)
        do
            if [ ! -d $SRV/$_C/rootfs/root/.ssh ]
            then
                continue
            fi

                
                cat /root/.ssh/id_rsa.pub > $SRV/$_C/rootfs/root/.ssh/authorized_keys
                #echo '' >> $SRV/$_C/rootfs/root/.ssh/authorized_keys
                cat /root/.ssh/authorized_keys >> $SRV/$_C/rootfs/root/.ssh/authorized_keys
                chmod 600 $SRV/$_C/rootfs/root/.ssh/authorized_keys
         
                for _U in $(cat $SRV/$_C/settings/users)
                do        
                        generate_user_structure $_U $_C
                done
        
        done
   
    ## temporary only on all arg
    if $all_arg_set
    then
                   
        msg "Generate user access." 
        for _C in $(lxc-ls)
        do
            #dbg "bind_mount $_C"
            bind_mount $_C
            
                if $all_arg_set
                then

                        nfs_unmount $_C
                        generate_exports $SRV/$_C/rootfs
                        nfs_mount $_C
                        #backup_mount $_U $_C
                else            
                    #dbg "nfs_mount $_C"
                    nfs_mount $_C
                    
                    for _U in $(cat $SRV/$_C/settings/users)
                    do
                        #dbg "backup_mount $_C"
                        backup_mount $_U $_C
                    done
                fi
         done
    
    
    fi
}


function regenerate_logfiles {    

        rm -rf /var/log/srvctl/httpd
        mkdir -p /var/log/srvctl/httpd

        for _C in $(lxc_ls)
        do
                if [ -f $SRV/$_C/rootfs/var/log/httpd/access_log ]
                then
                        ln -s $SRV/$_C/rootfs/var/log/httpd/access_log /var/log/srvctl/httpd/$_C-access_log
                fi
                if [ -f $SRV/$_C/rootfs/var/log/httpd/error_log ]
                then
                        ln -s $SRV/$_C/rootfs/var/log/httpd/error_log /var/log/srvctl/httpd/$_C-error_log
                fi
        done

        ## TODO fix /check fail2ban
        #systemctl restart fail2ban.service
        

}

function regenerate_counter {

    local __c=0
    
    for _C in $(lxc_ls)
    do
    
        if [ -f $SRV/$_C/config.counter ]
        then
            __n="$(cat $SRV/$_C/config.counter)"

            if (("$__n" >= "$__c"))
            then
                __c=$__n
            fi
        fi
        
    done
        
    __c=$(($__c+1))
        
    if [ -f /var/srvctl-host/counter ]
    then
        counter=$(cat /var/srvctl-host/counter)
        if ! [ "$counter" -eq "$__c" ]
        then
                msg "Counter: $counter vs $__c"
                echo $__c > /var/srvctl-host/counter
        fi
    fi    
}


function set_file_limits {

    ## You can increase the amount of open files and thus the amount of client connections by using "ulimit -n ". 
    ## For example, to allow pound to accept 5,000 connections and forward 5,000 connection to back end servers (10,000 total) use "ulimit -n 10000".
    ulimit -n 100000

    ## Hint from Tamás Papp to fix Error: Too many open files
    sysctl fs.inotify.max_user_watches=81920 >> /dev/null
    sysctl fs.inotify.max_user_instances=1024 >> /dev/null
}



function wait_for_ve_online {

        ## wait for the container to get up check via keyscan
        __llimit=100        
        __n=0

        echo -n '..'

        while [  $__n -lt $__llimit ] 
        do
                sleep 1
                res=$(ssh-keyscan -t rsa -H $1 2> /dev/null)

                if [ "${res:0:3}" == '|1|' ]
                then
                        __n=$__llimit 
                else
                        echo -n '.'
                fi

                 let __n=__n+1 

        done

        echo -n " online "
        echo ''
}


function wait_for_ve_connection { #on container
        msg "Connection-check"
        ## wait for the container to get up check via ssh connect
        local __llimit=100
        local __n=0

        echo -n '..'
        local res=''

        while [  $__n -lt $__llimit ] 
        do
                set_is_running
                
                if ! $is_running
                then
                    return
                fi

                sleep 1
                res=$(lxc-attach -n $1 -- /bin/echo OK 2> /dev/null)
                
                if [ ! "$?" -gt 0 ]
                then
                        __n=$__llimit
                else
                        echo -n '.'
                fi

                 let __n=__n+1 

        done


        echo -n " $res "
        echo ''
}

function regenerate_perdition_files {
    
        msg "regenerate perdition popmap"
        local popmap=/var/srvctl-host/popmap/$HOSTNAME
        
        mkdir -p /var/srvctl-host/popmap
        
        echo '## $HOSTNAME $NOW' > $popmap
        echo '' >> $popmap
    
        for _C in $(lxc-ls)
        do
            echo "(.*)@$_C: $_C" >> $popmap
        done
        
        echo '' >> $popmap
        
        for _S in $SRVCTL_HOSTS
        do   
            msg "get $_S popmap" 
            query="$(ssh -n -o ConnectTimeout=1 $_S '[ -f /var/srvctl-host/popmap/$HOSTNAME ] && cat /var/srvctl-host/popmap/$HOSTNAME || echo ""' 2> /dev/null)"
            popmap=/var/srvctl-host/popmap/$_S
            
            if [ ! -z "$query" ]
            then
                echo "$query" > $popmap
            else 
                err "get $_S popmap query failed. $query"
            fi
        done
        
        
        cat /var/srvctl-host/popmap/* > /etc/perdition/popmap.re

        systemctl restart imap4
        systemctl restart imap4s
        systemctl restart pop3s
        
}

fi ## if onHS













