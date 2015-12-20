#!/bin/bash

if $onHS
then ## no identation.

hint "backup [VE]" "Backup VE data, or all containers locally."
if [ "$CMD" == "backup" ]
then
        sudomize
       
        
        if [ -z "$BACKUP_PATH" ]
        then
            err "Backup path not set in configs. Using $TMP for now."
            BACKUP_PATH=$TMP
        fi
        
        if [ ! -z "$ARG" ]
        then
            argument C
            authorize
            run_backup $C
            msg "$C - backup complete."
        else
            for C in $(lxc_ls)
            do
                msg $C
                run_backup $C
                msg "$C - backup complete."
            done
        fi
        
        msg "Done."
ok
fi ## backup
man '
    Attempt to backup all user-data, but not the container operating system.
    This will create a folder - path specified in config - and create 7zip archives.
    Archives should be accessible for all authorized users.
'


## restore host
hint "restore VE" "Restore VE based on backup data"
if [ "$CMD" == "restore" ]
then

        argument C
        sudomize
        authorize

        nfs_unmount $C
        
        if [ -z "$BACKUP_PATH" ]
        then
            err "Backup path not set in configs. Using $TMP for now."
            BACKUP_PATH=$TMP
        fi

        from=$BACKUP_PATH/$C
        
        if [ ! -d $from ]
        then
            err "Archive not found."
            exit 110
        fi
        
        set_is_running
        if $is_running
        then
            err "There is a container running as $C - exiting"
            exit 111
        fi
        
        if [ -d $SRV/$C ]
        then
            err "There is a container $C - exiting"
            ## TODO - remove the container?
            exit 112
        fi
        
        ## Create the container
        CMD="add"
        source $install_dir/commands/hs-add-ve.sh
        
         
        ## check packages
            
            if [ -f $from/packagelist ]
            then
                
                msg "Processing packagelist"
                
                echo ''
                echo '#!/bin/bash' > $SRV/$C/rootfs/root/restore-packagelist.sh
                echo -n 'dnf -y install' > $SRV/$C/rootfs/root/restore-packagelist.sh
                
                
                fr=$from/packagelist
                lp=$TMP/$C-packagelist
                ## create local pacgakelist
                if [ -f $SRV/$C/rootfs/var/log/yum.log ]
                then
                    ssh $C "yum list installed" > $lp
                fi
                if [ -f $SRV/$C/rootfs/var/log/dnf.log ]
                then
                    ssh $C "dnf list installed" > $lp
                fi
                
                ## compare packagelist
                while read in;
                do 
                    if [ "${in:0:13}" == "Last metadata" ] || [ "${in:0:18}" == "Installed Packages" ] || [ "${in:0:7}" == "@System" ]
                    then
                        continue
                    fi
                    
                    ## in package
                    p=${in%%.*}
                    found=false
                    
                    ## seach im local package list
                    while read im;
                    do 
                        if [ "${im:0:13}" == "Last metadata" ] || [ "${im:0:18}" == "Installed Packages" ] || [ "${im:0:7}" == "@System" ]
                        then
                            continue
                        fi
                        q=${im%%.*}
                    
                        if [ "$p" == "$q" ]
                        then
                            found=true
                        fi    
                    
                    ## local package list
                    done < $lp
                    
                    if ! $found
                    then
                        ntc $p
                        echo -n " $p" >> $SRV/$C/rootfs/root/restore-packagelist.sh
                    fi
                    
                ## from packagelist
                done < $fr
                
            fi
            
        ssh $C "bash /root/restore-packagelist.sh"

        
        ## stop the container
        #ssh $C "shutdown -P now"
        #lxc-stop -k -n $C
        #ntc "Stopped for the restore process ..."
        
        if [ -f $from/settings.7z ]
        then
            msg "settings"
            rm -rf /$SRV/$C/rootfs/settings/*
            7z x -o/$SRV/$C $from/settings.7z -aoa
        fi
        
        if [ -f $from/cert.7z ]
        then
            msg "certificates"
            rm -rf /$SRV/$C/cert
            7z x -o/$SRV/$C $from/cert.7z -aoa
        fi
        
        if [ -f $from/html.7z ]
        then            
            msg "/var/www/html"
            rm -rf /$SRV/$C/rootfs/var/www/html/*
            7z x -o/$SRV/$C/rootfs/var/www $from/html.7z -aoa 
            chown -R apache:apache $SRV/$C/rootfs/var/www/html
        fi
        
        if [ -f $from/srv.7z ]
        then
            msg "/srv"
            rm -rf /$SRV/$C/rootfs/srv/*
            7z x -o/$SRV/$C/rootfs $from/srv.7z -aoa 
        fi
        
        if [ -f $from/home.7z ]
        then
            msg "/home"
            rm -rf /$SRV/$C/rootfs/home/*
            7z x -o/$SRV/$C/rootfs $from/home.7z -aoa
            ## add users to the system, set permissions 
            ssh $C 'for u in $(ls /home); do srvctl add-user $u; done'
        fi
        
        if [ -f $from/root.7z ]
        then
            msg "/root"
            rm -rf $SRV/$C/rootfs/root/.ssh/*
            7z x -o/$SRV/$C/rootfs $from/root.7z -aoa 
        fi
        
        if [ -f $from/var-lib-mysql.7z ]
        then
            msg "/var/lib/mysql"
            mkdir -p $SRV/$C/rootfs/var/lib
            7z x -o/$SRV/$C/rootfs/var/lib $from/var-lib-mysql.7z -aoa 
        fi
        
        if [ -f $from/etc.7z ]
        then
            msg "/etc to /root/etc"
            7z x -o/$SRV/$C/rootfs/root $from/etc.7z -aoa 
            
            ## checkpoint need units
            _cp=$SRV/$C/rootfs/root/etc/systemd/system/multi-user.target.wants
            if [ -f $_cp/codepad.service ] || [ -f $_cp/node-project.service ] || [ -f $_cp/logio.service ] 
            then
                source $install_dir/ve-install/unitfiles.sh
            fi
            
            ssh $C 'for s in $(ls /etc/srvctl/system); systemctl enable $u && systemctl start $u; done'
        fi
        
        if [ -f $from/var.7z ]
        then
            msg "/var to /root/var"
            7z x -o/$SRV/$C/rootfs/root $from/var.7z -aoa 
        fi
        
       
        creation_date="$(cat $from/creation-date)"
        if [ ! -z "$creation_date" ]
        then
            echo $creation_date >> $SRV/$C/creation-date
        fi

        ## if the container is not disabled, turn it back on
        #if [ ! -f "$SRV/$C/settings/disabled" ]
        #then
        #    ## START the container
        #    set_file_limits
        #    
        #    lxc-start -o $SRV/$C/lxc.log -n $C -d
        #    say_info "STARTED"        
        #    get_info
        #    wait_for_ve_online $C
        #                
        #fi
        
ok
fi
man '
    Attempt to restore all user-data, and create a new container operating system.
'

fi



