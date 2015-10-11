## backup 
function run_backup {

        to=$backup_path/$C
        
        mkdir -p $to
        
        set_is_running
        
        if $is_running
        then
            #ssh $C "srvctl backup-db"
        
            if [ -f $SRV/$C/rootfs/var/log/yum.log ]
            then
                ssh $C "yum list installed" > $to/packagelist
            fi
            if [ -f $SRV/$C/rootfs/var/log/dnf.log ]
            then
                ssh $C "dnf list installed" > $to/packagelist
            fi        
        fi
        
        find $SRV/$C -ls > $to/filelist
        
        if [ ! -f $to/creation-date ]
        then
            echo "Container created: $(cat $SRV/$C/creation-date 2> /dev/null)" > $to/creation-date
            echo "Backup created: $NOW" >> $to/creation-date
        else 
            echo "Backup updated: $NOW" >> $to/creation-date
        fi
        
        
        ntc certificates
            7z u -uq0 $to/cert.7z $SRV/$C/cert
        
        ntc /html
        if [ ! -z "$(ls $SRV/$C/rootfs/var/www/html 2> /dev/null)" ] 
        then
            7z u -uq0 $to/html.7z $SRV/$C/rootfs/var/www/html
        fi
        
        ntc /srv
        if [ ! -z "$(ls $SRV/$C/rootfs/srv 2> /dev/null)" ]
        then        
            7z u -uq0 $to/srv.7z $SRV/$C/rootfs/srv
        fi
        
        ## TODO store an incremental backup of mysql
        
        ntc /home
        if [ ! -z "$(ls $SRV/$C/rootfs/home 2> /dev/null)" ]
        then
            7z u -uq0 $to/home.7z $SRV/$C/rootfs/home
        fi
        
        ntc /root
            7z u -uq0 $to/root.7z $SRV/$C/rootfs/root        
            
        ntc /etc    
            7z u -uq0 $to/etc.7z $SRV/$C/rootfs/etc
            
        ntc /log
            7z u -uq0 $to/log.7z $SRV/$C/rootfs/var/log

        ntc /var/lib/mysql
        if [ ! -z "$(ls $SRV/$C/rootfs/var/lib/mysql 2> /dev/null )" ]
        then
            7z u -uq0 $to/var-lib-mysql.7z $SRV/$C/rootfs/var/lib/mysql
        fi
        
        ntc settings
        if [ ! -z "$(ls $SRV/$C/settings 2> /dev/null )" ]
        then
            7z u -uq0 $to/settings.7z $SRV/$C/settings
        fi
        
        ## mount?

}

function backup_mount {
     ## container C
     ## user U
    
     ## there is a backup?
     if [ ! -z "$(ls $backup_path/$C 2> /dev/null)" ] && [ -d "/home/$U/$C" ]
     then 
        ## share here
        mkdir -p /home/$U/$C/backup
     
         test="$(mount | grep /home/$U/$C/backup)"
         if [ -z "$test" ]
         then
             ntc "Mount backup at /home/$U/$C/backup"
             
             echo "mount --bind $backup_path/$C /home/$U/$C/backup"
             mount --bind $backup_path/$C /home/$U/$C/backup
             echo "mount -o remount,ro,bind /home/$U/$C/backup"
             mount -o remount,ro,bind /home/$U/$C/backup
         fi
    fi    
}

function backup_unmount {
     ## container C
     ## user U
     test="$(mount | grep /home/$U/$C/backup)"
     if [ ! -z "$test" ]
     then
         umount /home/$U/$C/backup
     fi
     
     rm -fr /home/$U/$C/backup
         
}


