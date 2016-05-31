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
         
                if [ -f /var/srvctl-host/users/$_U/.password.sha512 ]
                then
                    cat /var/srvctl-host/users/$_U/.password.sha512 > $dest/users/$_U/.hash
                fi                               
            done 
        done
        

        chmod -R 655 /var/srvctl-ve
        chmod 644 /var/srvctl-ve/*/settings/*
        chmod 644 /var/srvctl-ve/*/users/*/.hash
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
            
        done
        
}


function regenerate_etc_hosts {
        ## and relaydomains

        msg "regenerate etc_hosts" ## fist in $TMP
        echo '# srvctl generated' > $TMP/hosts
        echo '127.0.0.1                localhost.localdomain localhost' >> $TMP/hosts
        echo '::1                localhost6.localdomain6 localhost6' >> $TMP/hosts
        echo '' >> $TMP/hosts
        echo '' > $TMP/relaydomains

        for _C in $(lxc-ls)
        do

                ip=$(cat $SRV/$_C/config.ipv4)
                

                if [ -z "$ip" ] 
                then
                        counter=$(cat $SRV/$_C/config.counter)
                        if [ -z $counter ] 
                        then        
                                err "No counter, no IPv4 for "$_C
                                exit
                        else
                                ip="10.10."$(to_ip $counter)
                                echo $ip > $SRV/$_C/config.ipv4
                        fi        
                fi

                if [ ! -z "$ip" ]
                then
 
                        echo $ip'                '$_C >>  $TMP/hosts
                        if [ ! -d $SRV/mail.$_C ] && [ "${_C:0:5}" != "mail." ]
                        then
                        echo $ip'                mail.'$_C >>  $TMP/hosts
                        fi
                        echo $_C' #' >>  $TMP/relaydomains

                                if [ -f /$SRV/$_C/settings/aliases ]
                                then
                                        for A in $(cat /$SRV/$_C/settings/aliases)
                                        do
                                                if [ "$A" == "$(hostname)" ]
                                                then
                                                        err "$_C alias: $A - is the host itself!"
                                                else
                                                        #dbg "$A is an alias of $_C"
                                                        echo $ip'                '$A >>  $TMP/hosts
                                                        
                                                        if [ ! -d $SRV/mail.$A ] && [ ! -d $SRV/mail.$_C ] && [ "${A:0:5}" != "mail." ] && [ "${_C:0:5}" != "mail." ]
                                                        then
                                                        echo $ip'                mail.'$A >>  $TMP/hosts
                                                        fi
                                                        echo $A' #' >>  $TMP/relaydomains
                                                fi
                                        done
                                fi

                        echo ''  >>  $TMP/hosts


                fi
        done ## regenerated etc_hosts

        #bak /etc/hosts
        cat $TMP/hosts > /etc/hosts

        #bak /etc/postfix/relaydomains
        cat $TMP/relaydomains > /etc/postfix/relaydomains
        postmap /etc/postfix/relaydomains

} 

function scan_host_key {

        ## argument: Container
        ntc "Scanning host key for "$1
    
        ## TODO in the next line the container name may be better if not indicated.
        echo "## srvctl host-key" > $SRV/$1/host-key
        ssh-keyscan -t rsa -H $(cat $SRV/$1/config.ipv4) >> $SRV/$1/host-key 2>/dev/null
        ssh-keyscan -t rsa -H $1 >> $SRV/$1/host-key 2>/dev/null
        echo '' >> $SRV/$1/host-key        
                                
}

function regenerate_known_hosts {

        msg "regenerate known hosts"

        echo '## srvctl generated ..' > /etc/ssh/ssh_known_hosts
        
        for _S in $srvctl_hosts
        do
            echo "## $_S" >> /etc/ssh/ssh_known_hosts
            ssh-keyscan -t rsa -H $(dig $_S +short) >> /etc/ssh/ssh_known_hosts 2>/dev/null
            ssh-keyscan -t rsa -H $_S >> /etc/ssh/ssh_known_hosts 2>/dev/null
            #2>/dev/null
            echo '' >> /etc/ssh/ssh_known_hosts
        done
        
        for _C in $(lxc-ls)
        do
        
                if [ ! -f $SRV/$_C/host-key ] || $all_arg_set
                then

                        set_is_running $_C

                        if $is_running
                        then
                                scan_host_key $_C
                        #else
                                # ntc "VE is stopped, could not scan host-key for: "$_C
                                ## host        key is needed for .ssh/known-hosts
                        fi
                       
                fi

                if [ -f $SRV/$_C/host-key ]
                then
                        echo "## $_C" >> /etc/ssh/ssh_known_hosts
                        cat $SRV/$_C/host-key >> /etc/ssh/ssh_known_hosts
                fi

        done ## regenerated  containers hosts
        #msg "Set ssh_known_hosts done."
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

function regenerate_users {
        ## First of all, make sure all users we have defined for sites, are all present.
        msg "processing user-list"
        for _C in $(lxc_ls)
        do
                mkdir -p $SRV/$_C/settings
                touch $SRV/$_C/settings/users

                for _U in $(cat $SRV/$_C/settings/users)
                do                
                        ## if the user doesent exists ... well, create it.
                        if [ ! -d "/home/$_U" ]
                        then
                            ntc "Add user $_U"
                            add_user $_U
                        fi
                        
                        if [ -z "$(su $_U -c 'cd ~ && git config --global user.email')" ]
                        then
                            su $_U -c "cd ~ && git config --global user.email $_U@$HOSTNAME"
                        fi
                        if [ -z "$(su $_U -c 'cd ~ && git config --global user.name')" ]
                        then
                            su $_U -c "cd ~ && git config --global user.name $_U"
                        fi
                        if [ -z "$(su $_U -c 'cd ~ && git config --global push.default')" ]
                        then
                            su $_U -c "cd ~ && git config --global push.default simple"
                        fi

                done
        done
}

function generate_user_configs { ## for user

        ## for each user

        local _u=$1        
        # msg "Generating user configs for user $_u"        

        ## create keypair
        if [ ! -f /home/$_u/.ssh/id_rsa.pub ] || [ ! -f /home/$_u/.ssh/id_rsa ] || [ ! -f /var/srvctl-host/users/$_u/srvctl_id_rsa.pub ] || [ ! -f /var/srvctl-host/users/$_u/srvctl_id_rsa ]
        then
          msg "Creating keypair for user "$_u
          create_keypair $_u
        fi

        mkdir -p /root/srvctl-users/authorized_keys
        
        ## root key first
        cat /root/.ssh/authorized_keys > /home/$_u/.ssh/authorized_keys
        echo '' >> /home/$_u/.ssh/authorized_keys
        
        ## srvctl-gui key
        cat /var/srvctl-host/users/$_u/srvctl_id_rsa.pub >> /home/$_u/.ssh/authorized_keys
        echo '' >> /home/$_u/.ssh/authorized_keys
        
        ## root-managed keys
        if [ -f  /root/srvctl-users/authorized_keys/$_u ]
        then
            cat /root/srvctl-users/authorized_keys/$_u >> /home/$_u/.ssh/authorized_keys
        fi
        
                        
        chown $_u:$_u /home/$_u/.ssh/authorized_keys
        
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
                generate_user_configs $_U
        done 
        
        msg "regenrate user hashes"
        for _U in $(ls /home)
        do
                update_password $_U
        done 
        
        msg "regenerate client certificates"
        for _U in $(ls /home)
        do
            create_client_certificate $_U
        done
        
}

function generate_user_structure ## for user, container
{
    _u=$1
    _c=$2

     #dbg  "Generating user structure for $_u in $C"

                ## add users host public key to container root user - for ssh access.
                if [ -f /home/$_u/.ssh/id_rsa.pub ]
                then
                        cat /home/$_u/.ssh/id_rsa.pub >> $SRV/$_c/rootfs/root/.ssh/authorized_keys
                else
                        err "No id_rsa.pub for user "$_u
                fi

                ## add users submitted public key to container root user - for ssh access.
                if [ -f /root/srvctl-users/authorized_keys/$_u ]
                then
                        cat /root/srvctl-users/authorized_keys/$_u >> $SRV/$_c/rootfs/root/.ssh/authorized_keys
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
                cat /root/.ssh/authorized_keys >> $SRV/$_C/rootfs/root/.ssh/authorized_keys 2> /dev/null
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
            dbg "bind_mount $_C"
            bind_mount $_C
            
                if $all_arg_set
                then

                        nfs_unmount $_C
                        generate_exports $SRV/$_C/rootfs
                        nfs_mount $_C
                        #backup_mount $_U $_C
                else            
                    dbg "nfs_mount $_C"
                    nfs_mount $_C
                    
                    for _U in $(cat $SRV/$_C/settings/users)
                    do
                        dbg "backup_mount $_C"
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

    __c=0
    
    for _C in $(lxc_ls)
    do
    
        if [ -f $SRV/$_C/config.counter ]
        then
            __n="$(cat $SRV/$_C/config.counter)"

            if [ "$__n" -gt "$__c" ]
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
                ## todo, .. should the counter set __c ?
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
    
        echo '## srvctl generated' > /etc/perdition/popmap.re
        echo '' >> /etc/perdition/popmap.re
    
        for _C in $(lxc-ls)
        do
            echo "(.*)@$_C: $_C" >> /etc/perdition/popmap.re
        done

        systemctl restart imap4
        systemctl restart imap4s
        systemctl restart pop3s
        
}

fi ## if onHS









