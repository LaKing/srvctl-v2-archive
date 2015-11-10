## backup 
function run_backup {
        
        _C=$1

        to=$backup_path/$_C
        
        mkdir -p $to
        
        set_is_running
        
        if $is_running
        then
            #ssh $_C "srvctl backup-db"
        
            if [ -f $SRV/$_C/rootfs/var/log/dnf.log ]
            then
                ssh $_C "dnf list installed" > $to/packagelist
            fi
            if [ -f $SRV/$_C/rootfs/var/log/dnf.log ]
            then
                ssh $_C "dnf list installed" > $to/packagelist
            fi        
        fi
        
        find $SRV/$_C -ls > $to/filelist
        
        if [ ! -f $to/creation-date ]
        then
            echo "Container created: $(cat $SRV/$_C/creation-date 2> /dev/null)" > $to/creation-date
            echo "Backup created: $NOW" >> $to/creation-date
        else 
            echo "Backup updated: $NOW" >> $to/creation-date
        fi
        
        
        ntc certificates
            7z u -uq0 $to/cert.7z $SRV/$_C/cert
        
        ntc /html
        if [ ! -z "$(ls $SRV/$_C/rootfs/var/www/html 2> /dev/null)" ] 
        then
            7z u -uq0 $to/html.7z $SRV/$_C/rootfs/var/www/html
        fi
        
        ntc /srv
        if [ ! -z "$(ls $SRV/$_C/rootfs/srv 2> /dev/null)" ]
        then        
            7z u -uq0 $to/srv.7z $SRV/$_C/rootfs/srv
        fi
        
        ## TODO store an incremental backup of mysql
        
        ntc /home
        if [ ! -z "$(ls $SRV/$_C/rootfs/home 2> /dev/null)" ]
        then
            7z u -uq0 $to/home.7z $SRV/$_C/rootfs/home
        fi
        
        ntc /root
            7z u -uq0 $to/root.7z $SRV/$_C/rootfs/root        
            
        ntc /etc    
            7z u -uq0 $to/etc.7z $SRV/$_C/rootfs/etc
            
        ntc /log
            7z u -uq0 $to/log.7z $SRV/$_C/rootfs/var/log

        ntc /var/lib/mysql
        if [ ! -z "$(ls $SRV/$_C/rootfs/var/lib/mysql 2> /dev/null )" ]
        then
            7z u -uq0 $to/var-lib-mysql.7z $SRV/$_C/rootfs/var/lib/mysql
        fi
        
        ntc settings
        if [ ! -z "$(ls $SRV/$_C/settings 2> /dev/null )" ]
        then
            7z u -uq0 $to/settings.7z $SRV/$_C/settings
        fi
        
        ## mount?

}

function backup_mount { # user container
    _U=$1
    _C=$2
    
     ## there is a backup?
     if [ ! -z "$(ls $backup_path/$_C 2> /dev/null)" ] && [ -d "/home/$_U/$_C" ]
     then 
        ## share here
        mkdir -p /home/$_U/$_C/backup
     
         test="$(mount | grep /home/$_U/$_C/backup)"
         if [ -z "$test" ]
         then
             ntc "Mount backup at /home/$_U/$_C/backup"
             
             echo "mount --bind $backup_path/$_C /home/$_U/$_C/backup"
             mount --bind $backup_path/$_C /home/$_U/$_C/backup
             echo "mount -o remount,ro,bind /home/$_U/$_C/backup"
             mount -o remount,ro,bind /home/$_U/$_C/backup
         fi
    fi    
}

function backup_unmount { container

    _C=$1
    
        for _U in $(ls /home)
        do
        
            test="$(mount | grep /home/$_U/$_C/backup)"
             if [ ! -z "$test" ]
             then
                 umount /home/$_U/$_C/backup
             fi
     
             rm -fr /home/$_U/$_C/backup
        done
}


