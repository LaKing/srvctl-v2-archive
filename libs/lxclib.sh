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

    ntc "Generating lxc config files for $_c"

    _ctype=fedora
    if [ -f $SRV/$_c/ctype ]
    then
        _ctype=$(cat $SRV/$_c/ctype)
    else 
        echo fedora > $SRV/$_c/ctype
    fi

    _counter=$(cat $SRV/$_c/config.counter)

    _mac=$(to_mac $_counter)
    _ip4=$(to_ip $_counter)      
    
    echo "10.10."$_ip4 > $SRV/$_c/config.ipv4  

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
    
    ## IPv6
    ## four digit hex part only
    #_ip6=$(to_ipv6 $_counter)

    #if [ "$RANGEv6" != "::1" ] 
    #then
    #    echo '## networking IPv6' >> $SRV/$_c/config
    #    echo 'lxc.network.ipv6.gateway = auto' >> $SRV/$_c/config
    #    echo 'lxc.network.ipv6='$IPv6_RANGE_NETBLOCK':0:1010:'$_ip6':1' >> $SRV/$_c/config
    #fi


    if [ $_ctype == fedora ] || [ $_ctype == ubuntu ]
    then
    
    _rootfs_path=$SRV/$_c/rootfs
    

set_file $SRV/$_c/config '## Template for srvctl created fedora container #'$_counter' '$_c' '$NOW'

## system
lxc.rootfs = '$_rootfs_path'
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
    ## share some common files across containers and host
    echo "/var/srvctl $_rootfs_path/var/srvctl none ro,bind 0 0" > $SRV/$_c/fstab
    ## share srvctl
    echo "$install_dir $_rootfs_path/$install_dir none ro,bind 0 0" >> $SRV/$_c/fstab
    
        if [ -f $SRV/$_c/fstab.local ]
        then
            ## for custom mounts
            cat $SRV/$_c/fstab.local >> $SRV/$_c/fstab
        fi
    
    fi
    
    
    if [ $_ctype == apache ]
    then    
        _rootfs_path=/var/srvctl-rorootfs/$_ctype

set_file $SRV/$_c/$_ctype.config '## Template for srvctl created '$_ctype' container #'$_counter' '$_c' '$NOW'

## system
lxc.rootfs = '$_rootfs_path'
lxc.utsname = '$_c'

## extra mountpoints
lxc.mount = '$SRV/$_c/$_ctype'.fstab

## networking IPv4
lxc.network.type = veth
lxc.network.flags = up
lxc.network.link = srv-net
lxc.network.hwaddr = 00:00:10:10:'$_mac'
lxc.network.ipv4 = 10.10.'$_ip4'/8
lxc.network.name = srv-'$_counter'
lxc.network.ipv4.gateway = auto
'
        
        if [ $_ctype == apache ]
        then
            echo "# /var/srvctl $_rootfs_path/var/srvctl none ro,bind 0 0" > $SRV/$_c/$_ctype.fstab
            echo "# $install_dir $_rootfs_path/$install_dir none ro,bind 0 0" >> $SRV/$_c/$_ctype.fstab
        
            #echo "$SRV/$_c/rootfs/ $_rootfs_path none ro,bind 0 0" > $SRV/$_c/$_ctype.fstab
            echo "$SRV/$_c/rootfs/root root none rw,bind 0 0" >> $SRV/$_c/$_ctype.fstab
            echo "$SRV/$_c/rootfs/var/www/html var/www/html  none ro,bind 0 0" >> $SRV/$_c/$_ctype.fstab
            echo "$SRV/$_c/rootfs/var/log var/log none rw,bind 0 0" >> $SRV/$_c/$_ctype.fstab
            echo "$SRV/$_c/rootfs/run run none rw,bind 0 0" >> $SRV/$_c/$_ctype.fstab
            
            set_file $SRV/$_c/$_ctype.service '[Unit]
Description=The Apache HTTP Server application container for '$_c'
After=network.target remote-fs.target nss-lookup.target

[Service]
ExecStart=/usr/bin/lxc-execute -f /srv/'$_c'/apache.config -n '$_c' -- /usr/sbin/httpd -DFOREGROUND
PrivateTmp=true

[Install]
WantedBy=multi-user.target
'
            mkdir -p /etc/srvctl/apps
            if [ ! -f /etc/srvctl/apps/$_c.$_ctype.service ]
            then
                ln -s $SRV/$_c/$_ctype.service /etc/srvctl/apps/$_c.$_ctype.service
            fi
        fi
    
    fi
}


function lxc_ls {
    ## special lxc-ls that honors the call via sudo
    for _lsi in $(lxc-ls)
    do
            if [ ! -f $SRV/$_lsi/config ]
            then
                continue
            fi
    
            if $isSUDO
            then
                _skp=true
                for _uti in $(cat $SRV/$_lsi/settings/users)
                do
                    if [ "$_uti" == "$SC_USER" ]
                    then
                        _skp=false
                        break
                    fi
                done
                
                if $_skp
                then
                    continue
                fi
            fi
            
            echo $_lsi
            
      done
}

function lxc_start { ## container

    lxc_start_success=false

    local _c=$1
    echo "srvctl lxc_start $_c $NOW" > $SRV/$_c/lxc.log
    #echo "lxc-start -o $SRV/$_c/lxc.log -n $_c -d"
    if lxc-start -o $SRV/$_c/lxc.log -n $_c -d
    then 

        bind_mount $_c
        lxc_start_success=true
        say_info "STARTED" 
        say_name $_c
        wait_for_ve_online $_c

        scan_host_key $_c

        regenerate_known_hosts

        wait_for_ve_connection $_c

        set_is_running $_c
        if $is_running
        then
                for _u in $(cat $SRV/$_c/settings/users)
                do
                        msg "Mounting shares"
                        nfs_mount $_c
                        backup_mount $_u $_c

                done
        else
            err "$_c is stopped."
        fi
    else
        err $_c failed to start.
        cat $SRV/$_c/lxc.log
    fi
    
}



