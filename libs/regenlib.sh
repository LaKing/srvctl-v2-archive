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
                counter=$(($(cat /var/srvctl-host/counter)+1))
                echo $counter >  /var/srvctl-host/counter
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
                 ntc "Password authentication is enabled on $_C"
                        ## make sure password authentication is disabled
                        #sed_file $SRV/$_C/rootfs/etc/ssh/sshd_config "PasswordAuthentication yes" "PasswordAuthentication no"
                        #ssh $_C "systemctl restart sshd.service"

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
                                exit
                        else
                                ip="10.10."$(to_ip $counter)
                        fi        
                fi

                if [ ! -z $ip ]
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
                                                        ntc "$_C alias: $A - is the host itself!"
                                                else
                                                        # ntc "$A is an alias of $_C"
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
        msg "processing user-list"
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

        _u=$1        
        # msg "Generating user configs for $_u"        

        ## create keypair
        if [ ! -f /home/$_u/.ssh/id_rsa.pub ]
        then
          msg "Creating keypair for user "$_u
          create_keypair $_u
        fi

        mkdir -p /root/srvctl-users/authorized_keys
        ## create user submitted authorised_keys
        if [ ! -f /home/$_u/.ssh/authorized_keys ] || $all_arg_set
        then
                ntc "Creating authorized_keys for $_u"  
                cat /root/.ssh/authorized_keys > /home/$_u/.ssh/authorized_keys
                echo '' >> /home/$_u/.ssh/authorized_keys
                if [ -f  /root/srvctl-users/authorized_keys/$_u ]
                then
                        cat /root/srvctl-users/authorized_keys/$_u >> /home/$_u/.ssh/authorized_keys
                else
                        ntc "No authorized ssh-rsa key in /root/srvctl-users/authorized_keys/$_u"
                fi                
                chown $_u:$_u /home/$_u/.ssh/authorized_keys
        fi
}


function regenerate_users_configs {

        msg "regenrateing user configs"

        for _U in $(ls /home)
        do
                generate_user_configs $_U
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
     #dbg  "Add key for $_u in $_c"
                        ## else
                        ## ntc "No public key for user "$_u
                fi

                ## Share via mount
                ## Second, create common share
                mkdir -p /home/$_u/$_c/mnt
                chown $_u:$_u /home/$_u/$_c
                chown $_u:$_u /home/$_u/$_c/mnt

                ## make sure all the hashes are up to date
                # update_password $_u

                ## take care of password hashes
                if ! [ -f "/home/$_u/$_c/.password.sha512" ]
                then
                        update_password_hash $_u

                        if [ ! -f /home/$_u/$_c/mnt/.password.sha512 ] && [ -f /home/$_u/.password ]
                        then
                                ln /home/$_u/.password.sha512 /home/$_u/$_c/mnt/.password.sha512
                        fi
                fi

                ## create directory we will bind to
                mkdir -p $SRV/$_c/rootfs/mnt/$_u

                ## everything prepared, this is for container mount point.
                add_conf $SRV/$_c/fstab "/home/$_u/$_c/mnt $SRV/$_c/rootfs/mnt/$_u none rw,bind 0 0"


}


function regenerate_users_structure {

        msg "Updateing user-structure."
        
        for _C in $(lxc-ls)
        do

                
                cat /root/.ssh/id_rsa.pub > $SRV/$_C/rootfs/root/.ssh/authorized_keys
                #echo '' >> $SRV/$_C/rootfs/root/.ssh/authorized_keys
                cat /root/.ssh/authorized_keys >> $SRV/$_C/rootfs/root/.ssh/authorized_keys 2> /dev/null
                chmod 600 $SRV/$_C/rootfs/root/.ssh/authorized_keys
         
                for _U in $(cat $SRV/$_C/settings/users)
                do        
                        generate_user_structure $_U $_C
                done

                if $all_arg_set
                then

                        nfs_unmount $_C
                        generate_exports $_C
                fi                

                for _U in $(cat $SRV/$_C/settings/users)
                do

                        nfs_mount $_U $_C
                        backup_mount $_U $_C

                done
         done

        msg "generate access keysets." 
        for U in $(ls /home)
        do
                ## users should be accessible by root with ssh
                cat /root/.ssh/authorized_keys > /home/$_U/.ssh/authorized_keys 2> /dev/null

                ## if the user submitted a public key, add it as well.
                if [ -f /root/srvctl-users/authorized_keys/$_U ]
                then
                        cat /root/srvctl-users/authorized_keys/$_U >> /home/$_U/.ssh/authorized_keys
                fi
        done

        ## TODO check why ...
        #systemctl restart firewalld.service

}
        ## constants
        named_includes=/var/named/srvctl-includes.conf
        named_live_path=/var/named/srvctl
        named_main_path=/var/srvctl-host/named-local
        named_slave_path=/var/srvctl-host/named-slave
        

function create_named_zone {

        ## argument domain ($_C or alias)
        D=$1

        named_conf=$named_main_path/$D.conf
        named_zone=$named_main_path/$D.zone
        named_slave=$named_slave_path/$D.slave
        
        named_live_zone=$named_live_path/$D.zone
        named_slave_zone=$named_live_path/$D.slave.zone
                
        mail_server="mail"

        if [ -f "$SRV/$D/settings/dns-mx-record" ] && [ ! -z "$(cat $SRV/$D/settings/dns-mx-record)" ]
        then
            mail_server="$(cat $SRV/$D/settings/dns-mx-record | xargs)."            
        fi

        #if [ ! -f $named_conf ]
        #then
                echo '## srvctl named main conf '$D > $named_conf
                echo 'zone "'$D'" {' >> $named_conf
                echo '        type master;'  >> $named_conf
                echo '        file "'$named_live_zone'";' >> $named_conf
                echo '};' >> $named_conf
        #fi

        #if [ ! -f $named_slave ]
        #then
                echo '## srvctl named slave conf '$D > $named_slave
                echo 'zone "'$D'" {' >> $named_slave
                echo '        type slave;'  >> $named_slave
                echo '        masters {'$HOSTIPv4';};'  >> $named_slave
                echo '        file "'$named_slave_zone'";' >> $named_slave
                echo '};' >> $named_slave
        #fi

        #if [ ! -f $named_zone ]
        #then
                today=$(date +%y%m%d)
                serial_file=/var/srvctl-host/named-$today
                serial=0
                
                if [ ! -f $serial_file ]
                then      
                  serial=$today'0000'
                  echo $serial > $serial_file
                else        
                  serial=$(($(cat $serial_file)+1))
                  echo $serial > $serial_file
                fi

                ## TODO add IPv6 support

set_file $named_zone '$TTL 1D
@        IN SOA        @ hostmaster.'$CDN'. (
                                        '$serial'        ; serial
                                        1D        ; refresh
                                        1H        ; retry
                                        1W        ; expire
                                        3H )        ; minimum
        IN         NS        ns1.'$CDN'.
        IN         NS        ns2.'$CDN'.
        IN         NS        ns3.'$CDN'.
*        IN         A        '$HOSTIPv4'
@        IN         A        '$HOSTIPv4'
@        IN        MX        10        '${mail_server,,}'
        AAAA        ::1'

## named zone written.                    
}

function regenerate_dns {
        
        msg "Regenerate DNS - query public information."
        for _C in $(lxc-ls)
        do
            rm -rf $SRV/$_C/dns-*
            get_dns_servers $_C
        done
        
        msg "Regenerate DNS - named/bind configs"
        
        ## dir might not exist
        mkdir -p $named_live_path
        mkdir -p $named_main_path
        mkdir -p $named_slave_path
                
        ## has to be empty for regeneration
        rm -rf $named_live_path/* 
        rm -rf $named_main_path/*
        rm -rf $named_slave_path/*
        
        ## the main include file
        named_local=/var/named/srvctl-local.conf
        
        
        ## the secondary file
        #named_slave_conf=$named_slave_path/srvctl-$(hostname).conf
        
        echo '## srvctl named includes' > $named_includes
        echo '## srvctl named primary local' > $named_local
        
        #echo '## srvctl named slaves'$(hostname) > $named_slave_conf

        for _C in $(lxc-ls)
        do
                ## skip local domains
                if [ "${_C: -6}" == ".local" ]
                then
                    continue
                fi
                
                ## skip mail-only servers
                if [ "${_C:0:5}" == "mail." ]
                then
                    continue
                fi
                
                
                ## option to skip servers
                if [ -f $SRV/$_C/settings/no-dns ]
                then
                    continue
                fi
                
                create_named_zone $_C
                echo 'include "/var/named/srvctl/'$_C'.conf";' >> $named_local
                #echo 'include "/var/named/srvctl/'$_C'.slave.conf";' >> $named_slave_conf

                if [ -f /$SRV/$_C/settings/aliases ]
                then
                        for A in $(cat /$SRV/$_C/settings/aliases)
                        do
                                #msg "$A is an alias of $_C"
                                create_named_zone $A
                                echo 'include "/var/named/srvctl/'$A'.conf";' >> $named_local
                                #echo 'include "/var/named/srvctl/'$A'.slave.conf";' >> $named_slave_conf
                        done
                fi
        done
        
        msg "Creating DNS share."
        ## delete first
        rm -rf $dns_share
                
        ## create tarball
        tar -czPf $dns_share -C $named_slave_path .


        echo 'include "'$named_local'";' >> $named_includes

        cp $named_main_path/*.zone $named_live_path
        cp $named_main_path/*.conf $named_live_path


        if [ -f /etc/srvctl/hosts ]
        then
            
            while read host
            do
            
              if [ "$(ssh -n -o ConnectTimeout=1 $host hostname 2> /dev/null)" == "$host" ]
              then
                msg "Update remote DNS connection for $host"
                
                rm -rf /var/srvctl-host/$host.dns.tar.gz
                
                wget -q --no-check-certificate https://$host/dns.tar.gz -O /var/srvctl-host/$host.dns.tar.gz
                if [ "$?" != "0" ]
                then
                    err "Failed to fetch DNS update information from https://$host/dns.tar.gz"
                    continue
                fi
                
                named_expath=/var/srvctl-host/named-$host
                
                rm -rf $named_expath/*
                mkdir -p $named_expath

                tar -xf /var/srvctl-host/$host.dns.tar.gz -C $named_expath
                
                ## expath alapján include file éas azt beincludolni
                named_exconf=/var/named/srvctl-$host.conf
                echo 'include "'$named_exconf'";' >> $named_includes
                echo '## srvctl named external slave conf includes' > $named_exconf 
                
                for ex in $(ls $named_expath)
                do
                    echo 'include "/var/named/srvctl/'$ex'";' >> $named_exconf
                done
                
                chown root:named $named_exconf
                chmod 640 $named_exconf
                
                cp $named_expath/*.slave $named_live_path
              else
                err "Could not connect to $host"
                ssh -n -o ConnectTimeout=1 $host hostname
              fi

            done < /etc/srvctl/hosts  

        fi
        
        chown root:named $named_includes
        chmod 640 $named_includes
        
        chown -R root:named $named_live_path
        chmod -R 650 $named_live_path
        
        ## all preparations done, activate!
        systemctl restart named.service
        test=$(systemctl is-active named.service)
        if ! [ "$test" == "active" ]
        then
            err "Error loading DNS settings."
            systemctl status named.service
            exit
        else
            msg "DNS server OK"
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
        
        counter=$(cat /var/srvctl-host/counter)
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
    
    
    if [ -f $SRV/$_c/fstab.local ]
    then
        cat $SRV/$_c/fstab.local >> $SRV/$_c/fstab
    fi


set_file $SRV/$_c/rootfs/etc/resolv.conf "# Generated by srvctl
search local
nameserver 10.10.0.1
"

    ## err $_C? .. $_c !
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








