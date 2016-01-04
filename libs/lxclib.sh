function lxc_ls {
    ## special lxc-ls that honors the call via sudo
    for _lsi in $(lxc-ls)
    do
            if [ ! -d $SRV/$_lsi/rootfs ]
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
    echo "srvctl lxc_start $NOW" > $SRV/$_c/lxc.log
    #echo "lxc-start -o $SRV/$_c/lxc.log -n $_c -d"
    if lxc-start -o $SRV/$_c/lxc.log -n $_c -d
    then    
        lxc_start_success=true
        say_info "STARTED" 
        say_name $C
        wait_for_ve_online $C
        scan_host_key $C
        regenerate_known_hosts
        wait_for_ve_connection $C
        
        
                for _u in $(cat $SRV/$_c/settings/users)
                do

                        nfs_mount $_u $_c
                        backup_mount $_u $_c

                done
       
    else
        err $_c failed to start.
        cat $SRV/$C/lxc.log
    fi
    
}



