#!/bin/bash

if $onHS
then ## no identation.

### regenerate-related functions




function regenerate_config_files {

        ## scan for imported containers         
        for _C in $(ls $SRV)
        do            

            if ! $(is_fqdn $_C)
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
                counter=$(($(cat /etc/srvctl/counter)+1))
                echo $counter >  /etc/srvctl/counter
                echo $counter > $SRV/$_C/config.counter
            fi
            
            if [ ! -f $SRV/$_C/config.ipv4 ] || [ ! -f $SRV/$_C/config ] || $all_arg_set
            then
                    generate_lxc_config $_C
            fi
            
        done
        
        ## regenerate recognized containers
        for _C in $(lxc-ls)
        do

                if [ ! -f $SRV/$_C/config.counter ]
                then
                        err "No config.counter for $_C!"
                fi

                if [ ! -f $SRV/$_C/config.ipv4 ] || [ ! -f $SRV/$_C/config ] || $all_arg_set
                then
                        generate_lxc_config $_C
                fi

                #if [ ! -f "$SRV/$_C/settings/users" ]
                #then
                #        echo '' > $SRV/$_C/settings/users 
                #fi

                ##_ip=$(cat $SRV/$_C/config.ipv4)        
                
            ## Enforce disabled password authentication?
            if [ ! -z $(cat $SRV/$_C/rootfs/etc/ssh/sshd_config | grep "PasswordAuthentication yes") ]
            then
                 ntc "Password authentication is enabled on $C"
                        ## make sure password authentication is disabled
                        #sed_file $SRV/$C/rootfs/etc/ssh/sshd_config "PasswordAuthentication yes" "PasswordAuthentication no"
                        #ssh $C "systemctl restart sshd.service"

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
                

                if [ -z $ip ] 
                then
                        counter=$(cat $SRV/$_C/config.counter)
                        if [ -z $counter ] 
                        then        
                                err "No counter, no IPv4 for "$_C
                        else
                                ip="10.10."$(to_ip $counter)
                        fi        
                fi

                if [ ! -z $ip ]
                then
 
                        echo $ip'                '$_C >>  $TMP/hosts
                        echo $ip'                mail.'$_C >>  $TMP/hosts
                        echo $_C' #' >>  $TMP/relaydomains

                                if [ -f /$SRV/$_C/settings/aliases ]
                                then
                                        for A in $(cat /$SRV/$_C/settings/aliases)
                                        do
                                                if [ "$A" == "$(hostname)" ]
                                                then
                                                        ntc "$_C alias: $A - is the host itself!"
                                                else
                                                        # ntc "$A is an alias of $_C"
                                                        echo $ip'                '$A >>  $TMP/hosts
                                                        echo $ip'                mail.'$A >>  $TMP/hosts
                                                        echo $A' #' >>  $TMP/relaydomains
                                                fi
                                        done
                                fi

                        echo ''  >>  $TMP/hosts


                fi
        done ## regenerated etc_hosts

        bak /etc/hosts
        cat $TMP/hosts > /etc/hosts

        bak /etc/postfix/relaydomains
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
         
        for _C in $(lxc-ls)
        do
                if [ ! -f $SRV/$_C/host-key ] || $all_arg_set
                then

                        set_is_running $_C
                        if $is_running
                        then

                                scan_host_key $_C
                        else
                                 ntc "VE is stopped, could not scan host-key for: "$_C
                                ## host        key is needed for .ssh/known-hosts
                        fi
                        
                                        
                fi

                if [ -f $SRV/$_C/host-key ]
                then
                        cat $SRV/$_C/host-key >> /etc/ssh/ssh_known_hosts
                fi

        done ## regenerated  containers hosts
        msg "Set known_hosts done."
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
        msg "vierifying user-list on $(hostname)"
        for _C in $(lxc-ls)
        do
                touch $SRV/$_C/settings/users

                for _U in $(cat $SRV/$_C/settings/users)
                do                
                        ## if the user doesent exists ... well, create it.
                        if [ ! -d "/home/$_U" ]
                        then
                            ntc "Add user $_U"
                            add_user $_U
                        fi
                done
        done
}

function generate_user_configs {
        
        # echo "Generating user configs for $U"

        ## create keypair
        if [ ! -f /home/$U/.ssh/id_rsa.pub ]
        then
          msg "Creating keypair for user "$U
          create_keypair $U
        fi

        mkdir -p /root/srvctl-users/authorized_keys
        ## create user submitted authorised_keys
        if [ ! -f /home/$U/.ssh/authorized_keys ] || $all_arg_set
        then
                ntc "Creating authorized_keys for $U"  
                cat /root/.ssh/authorized_keys > /home/$U/.ssh/authorized_keys
                echo '' >> /home/$U/.ssh/authorized_keys
                if [ -f  /root/srvctl-users/authorized_keys/$U ]
                then
                        cat /root/srvctl-users/authorized_keys/$U >> /home/$U/.ssh/authorized_keys
                else
                        ntc "No authorized ssh-rsa key in /root/srvctl-users/authorized_keys/$U"
                fi                
                chown $U:$U /home/$U/.ssh/authorized_keys
        fi
}


function regenerate_users_configs {

        msg "regenrateing user configs"

        for U in $(ls /home)
        do
                generate_user_configs
        done 
}

function generate_user_structure ## for user $U, Container $C
{
     #dbg  "Generating user structure for $U in $C"

                ## add users host public key to container root user - for ssh access.
                if [ -f /home/$U/.ssh/id_rsa.pub ]
                then
                        cat /home/$U/.ssh/id_rsa.pub >> $SRV/$C/rootfs/root/.ssh/authorized_keys
                else
                        err "No id_rsa.pub for user "$U
                fi

                ## add users submitted public key to container root user - for ssh access.
                if [ -f /root/srvctl-users/authorized_keys/$U ]
                then
                        cat /root/srvctl-users/authorized_keys/$U >> $SRV/$C/rootfs/root/.ssh/authorized_keys
     #dbg  "Add key for $U in $C"
                        ## else
                        ## ntc "No public key for user "$U
                fi

                ## Share via mount
                ## Second, create common share
                mkdir -p /home/$U/$C/mnt
                chown $U:$U /home/$U/$C
                chown $U:$U /home/$U/$C/mnt

                ## make sure all the hashes are up to date
                # update_password $U

                ## take care of password hashes
                if ! [ -f "/home/$U/$C/.password.sha512" ]
                then
                        update_password_hash $U

                        if [ ! -f /home/$U/$C/mnt/.password.sha512 ] && [ -f /home/$U/.password ]
                        then
                                ln /home/$U/.password.sha512 /home/$U/$C/mnt/.password.sha512
                        fi
                fi

                ## create directory we will bind to
                mkdir -p $SRV/$C/rootfs/mnt/$U

                ## everything prepared, this is for container mount point.
                echo "/home/$U/$C/mnt $SRV/$C/rootfs/mnt/$U none rw,bind 0 0" >> $SRV/$C/fstab

                
}

                ## NOTE on port forwarding and ssh usage. This will allow direct ssh on a custom local port! 
                ## Create the tunnel
                ## ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -L 2222:nameof.container.ve:22 -N -f user@host
                ## ssh -L 2222:nameof.container.ve:22 -N -f user@host
                ## connect to the tunnel
                ## ssh -p 2222 user@localhost

                ## List Open tunnels
                ##  ps ax | grep "ssh " | grep " -L "

                ## ssh with compresion
                ## ssh -C -c blowfish

                ## kill all L tunnels
                ## kill $(ps ax | grep "ssh " | grep " -L " | cut -f 1 -d " ")

                ## another method for rsync-ing container data
                ## rsync -avz -e "ssh -A user@host ssh" root@container.ve:/srv/node-project /srv


function regenerate_users_structure {

        msg "Updateing user-structure."
        
        for C in $(lxc-ls)
        do
                
                cat /root/.ssh/id_rsa.pub > $SRV/$C/rootfs/root/.ssh/authorized_keys
                #echo '' >> $SRV/$C/rootfs/root/.ssh/authorized_keys
                cat /root/.ssh/authorized_keys >> $SRV/$C/rootfs/root/.ssh/authorized_keys 2> /dev/null
                chmod 600 $SRV/$C/rootfs/root/.ssh/authorized_keys
         
                for U in $(cat $SRV/$C/settings/users)
                do
                        generate_user_structure
                done

                if $all_arg_set
                then

                        nfs_unmount

                        generate_exports $C
                fi                

                for U in $(cat $SRV/$C/settings/users)
                do
                        nfs_mount
                        backup_mount
                done
         done

        ## generate host's-user's access keysets. 
        for U in $(ls /home)
        do
                ## users should be accessible by root with ssh
                cat /root/.ssh/authorized_keys > /home/$U/.ssh/authorized_keys 2> /dev/null

                ## if the user submitted a public key, add it as well.
                if [ -f /root/srvctl-users/authorized_keys/$U ]
                then
                        cat /root/srvctl-users/authorized_keys/$U >> /home/$U/.ssh/authorized_keys
                fi
        done

        ## TODO check why ...
        #systemctl restart firewalld.service

}


function regenerate_dns {
        
        msg "Regenerate DNS - named/bind configs"

        rm -rf /var/named/srvctl/*

        named_conf_local=$TMP/named.conf.local
         named_slave_conf_global=$TMP/named.slave.conf.global.$(hostname)

        echo '## srvctl named.conf.local' > $named_conf_local
        echo '## srvctl named.slave.conf.global.'$(hostname) > $named_slave_conf_global

        for C in $(lxc-ls)
        do
                create_named_zone $C
                echo 'include "/var/named/srvctl/'$C'.conf";' >> $named_conf_local
                echo 'include "/var/named/srvctl/'$C'.slave.conf";' >> $named_slave_conf_global

                if [ -f /$SRV/$C/settings/aliases ]
                then
                        for A in $(cat /$SRV/$C/settings/aliases)
                        do
                                #msg "$A is an alias of $C"
                                create_named_zone $A
                                echo 'include "/var/named/srvctl/'$A'.conf";' >> $named_conf_local
                                echo 'include "/var/named/srvctl/'$A'.slave.conf";' >> $named_slave_conf_global
                        
                        done
                fi

        done

        bak /etc/srvctl/named.conf.local
        bak /etc/srvctl/named.slave.conf.global.$(hostname)

        rsync -a $named_conf_local /etc/srvctl
        rsync -a $named_slave_conf_global /etc/srvctl

        ## update this variable as it was synced to its real location
        named_slave_conf_global=/etc/srvctl/named.slave.conf.global.$(hostname)

        systemctl restart named.service


        test=$(systemctl is-active named.service)

        if [ "$test" == "active" ]
        then
                msg "Creating DNS share."

                ## to make sure everything is correct we regenerate the dns share too
                ## delete first
                rm -rf $dns_share
                
                ## dir might not exist
                mkdir -p /var/named/srvctl
                
                ## create zip
                tar -czPf $dns_share $named_slave_conf_global /var/named/srvctl

        else
                err "DNS Error."
                systemctl status named.service
        fi

}

function regenerate_logfiles {

        msg "Linking log files for fail2ban."        

        rm -rf /var/log/httpd
        mkdir -p /var/log/httpd

        for _C in $(lxc-ls)
        do
                if [ -f $SRV/$_C/rootfs/var/log/httpd/access_log ]
                then
                        ln -s $SRV/$_C/rootfs/var/log/httpd/access_log /var/log/httpd/$_C-access_log
                fi
                if [ -f $SRV/$_C/rootfs/var/log/httpd/error_log ]
                then
                        ln -s $SRV/$_C/rootfs/var/log/httpd/error_log /var/log/httpd/$_C-error_log
                fi
        done

        ## TODO fix /check fail2ban
        #systemctl restart fail2ban.service
        

}

function regenerate_counter {

__c=0
        for _C in $(lxc-ls)
        do
                __n=$(cat $SRV/$_C/config.counter)

                if [ "$__n" -gt "$__c" ]
                then
                        __c=$__n
                fi
        done
        
        counter=$(cat /etc/srvctl/counter)
        if ! [ "$counter" -eq "$__c" ]
        then
                msg "Counter: $counter vs $__c"
                ## todo, .. should the counter set __c ?
        fi
        
}


## constants for generate_lxc_config
## we do some expansion on the IP address, and extract the network prefix.
if [ "$RANGEv6" != "::1" ] 
then
    IPv6_RANGE=$(sipcalc -6 $RANGEv6 2>/dev/null | fgrep Expanded | cut -d '-' -f 2 | xargs)
    IPv6_RANGE_NETBLOCK=$(echo $IPv6_RANGE | cut -d : -f 1):$(echo $IPv6_RANGE | cut -d : -f 2):$(echo $IPv6_RANGE | cut -d : -f 3):$(echo $IPv6_RANGE | cut -d : -f 4)
fi

function generate_lxc_config {

## argument container name.
_c=$1

ntc "Generating lxc configarion files for $_c"

_counter=$(cat $SRV/$_c/config.counter)

_mac=$(to_mac $_counter)
_ip4=$(to_ip $_counter)        

## four digit hex part only
_ip6=$(to_ipv6 $_counter)

if [ "$RANGEv6" != "::1" ] 
then

    __IPv6_1='lxc.network.ipv6.gateway=auto'
    __IPv6_2='lxc.network.ipv6='$IPv6_RANGE_NETBLOCK':0:1010:'$_ip6':1'
fi

## note currently working only with range 64 ip addresses.

#lxc.network.type = veth
#lxc.network.flags = up
#lxc.network.link = inet-br
#lxc.network.hwaddr = 00:00:00:aa:'$_mac'
#lxc.network.ipv4 = 192.168.'$_ip4'/8
#lxc.network.name = inet-'$_counter'

set_file $SRV/$_c/config '## Template for srvctl created fedora container #'$_counter' '$_c' '$NOW'

## system
lxc.rootfs = '$SRV'/'$_c'/rootfs
lxc.include = '$lxc_usr_path'/share/lxc/config/fedora.common.conf
lxc.utsname = '$_c'
lxc.autodev = 1

## extra mountpoints
lxc.mount = '$SRV'/'$_c'/fstab

## networking IPv4
lxc.network.type = veth
lxc.network.flags = up
lxc.network.link = srv-net
lxc.network.hwaddr = 00:00:10:10:'$_mac'
lxc.network.ipv4 = 10.10.'$_ip4'/8
lxc.network.name = srv-'$_counter'
lxc.network.ipv4.gateway = auto
'

## IPv6
## four digit hex part only
_ip6=$(to_ipv6 $_counter)

if [ "$RANGEv6" != "::1" ] 
then
    echo '## networking IPv6' >> $SRV/$_c/config
    echo 'lxc.network.ipv6.gateway = auto' >> $SRV/$_c/config
    echo 'lxc.network.ipv6='$IPv6_RANGE_NETBLOCK':0:1010:'$_ip6':1' >> $SRV/$_c/config
fi



## this is there since srvctl 1.x
echo "/var/srvctl $SRV/$_c/rootfs/var/srvctl none ro,bind 0 0" > $SRV/$_c/fstab
## in srvctl 2.x we add the folowwing
echo "$install_dir $SRV/$_c/rootfs/$install_dir none ro,bind 0 0" >> $SRV/$_c/fstab


set_file $SRV/$_c/rootfs/etc/resolv.conf "# Generated by srvctl
search local
nameserver 10.10.0.1
"

## err $C? .. $_c !
echo "10.10."$_ip4 > $SRV/$_c/config.ipv4

}

function set_file_limits {

    ## You can increase the amount of open files and thus the amount of client connections by using "ulimit -n ". 
    ## For example, to allow pound to accept 5,000 connections and forward 5,000 connection to back end servers (10,000 total) use "ulimit -n 10000".
    ulimit -n 100000

    ## Hint from Tamás Papp to fix Error: Too many open files
    sysctl fs.inotify.max_user_watches=81920 >> /dev/null
    sysctl fs.inotify.max_user_instances=1024 >> /dev/null
}

function create_named_zone {

        ## argument domain ($C or alias)
        D=$1

        mkdir -p /var/named/srvctl
        chown -R named:named /var/named/srvctl

        named_conf=/var/named/srvctl/$D.conf
        named_slave_conf=/var/named/srvctl/$D.slave.conf
        named_zone=/var/named/srvctl/$D.zone
        
        mail_server="mail"

        if [ -f "$SRV/$C/settings/dns-mx-record" ] && [ ! -z "$(cat $SRV/$C/settings/dns-mx-record)" ]
        then
            ## TODO validate entry.
            mail_server="$(cat $SRV/$C/settings/dns-mx-record | xargs)."            
        fi

        if [ ! -f $named_conf ]
        then
## TODO convert to single string and command, this is ugly.
                echo '## srvctl named.conf '$D > $named_conf
                echo 'zone "'$D'" {' >> $named_conf
                echo '        type master;'  >> $named_conf
                echo '        file "'$named_zone'";' >> $named_conf
                echo '};' >> $named_conf
        fi

        if [ ! -f $named_slave_conf ]
        then
                echo '## srvctl named.slave.conf '$D > $named_slave_conf
                echo 'zone "'$D'" {' >> $named_slave_conf
                echo '        type slave;'  >> $named_slave_conf
                echo '        masters {'$HOSTIPv4';};'  >> $named_slave_conf
                echo '        file "'$named_zone'";' >> $named_slave_conf
                echo '};' >> $named_slave_conf
        fi

        if [ ! -f $named_zone ]
        then
                

                serial_file=/var/named/serial-counter.txt

                if [ ! -f $serial_file ]
                then
                  serial='1'        
                  echo $serial > $serial_file
                else        
                  serial=$(($(cat $serial_file)+1))
                  echo $serial >  $serial_file
                fi

                set_file $named_zone '$TTL 1D
@        IN SOA        @ hostmaster.'$CDN'. (
                                        '$serial'        ; serial
                                        1D        ; refresh
                                        1H        ; retry
                                        1W        ; expire
                                        3H )        ; minimum
        IN         NS        ns1.'$CDN'.
        IN         NS        ns2.'$CDN'.
*        IN         A        '$HOSTIPv4'
@        IN         A        '$HOSTIPv4'
@        IN        MX        10        '${mail_server,,}'
        AAAA        ::1'

## TODO add IPv6 support

        fi

        chown named:named $named_conf
        chown named:named $named_slave_conf
        chown named:named $named_zone

        ## TODO create a nice file structure and re-enable this.
        #if [ ! -L $SRV/$C/$D.named.conf ]
        #then
        #   ln -s $named_conf $SRV/$C/$D.named.conf
        #fi

        #if [ ! -L $SRV/$C/$D.named.zone ]
        #then
        #   ln -s $named_zone $SRV/$C/$D.named.zone
        #fi
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
}


function wait_for_ve_connection {

        ## wait for the container to get up check via ssh connect
        __llimit=100
        __n=0

        echo -n '..'

        while [  $__n -lt $__llimit ] 
        do
                sleep 1
                res=$(ssh $1 exit 2> /dev/null)

                if [ ! "$?" -gt 0 ]
                then
                        __n=$__llimit
                else
                        echo -n '.'
                fi

                 let __n=__n+1 

        done


        echo -n " connected "
}


fi ## if onHS




