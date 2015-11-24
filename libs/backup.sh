## backup 
function run_backup {
        
        _C=$1

        to=$BACKUP_PATH/$_C
        
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
            
        ntc /var/log
            7z u -uq0 $to/log.7z $SRV/$_C/rootfs/var/log
    
        ntc /var/spool/cron
            7z u -uq0 $to/cron.7z $SRV/$_C/rootfs/var/spool/cron
            
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
     if [ ! -z "$(ls $BACKUP_PATH/$_C 2> /dev/null)" ] && [ -d "/home/$_U/$_C" ]
     then 
        ## share here
        mkdir -p /home/$_U/$_C/backup
     
         test="$(mount | grep /home/$_U/$_C/backup)"
         if [ -z "$test" ]
         then
             ntc "Mount backup at /home/$_U/$_C/backup"
             
             echo "mount --bind $BACKUP_PATH/$_C /home/$_U/$_C/backup"
             mount --bind $BACKUP_PATH/$_C /home/$_U/$_C/backup
             echo "mount -o remount,ro,bind /home/$_U/$_C/backup"
             mount -o remount,ro,bind /home/$_U/$_C/backup
         fi
    fi    
}

function backup_unmount { #container

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

## rsync-backup scripts

## local backup from a local folder
function local_backup {

    backup_dirs="${@:1}"
    backup_target=$BACKUP_PATH/$(hostname)

    for i in $backup_dirs
    do
        mkdir -p $LOG/backup/$HOSTNAME
        backup_log=$LOG/backup/$HOSTNAME/log
        echo $(hostname):$i
        mkdir -p $backup_target/$(dirname $i)

        du -hs $backup_target/$i
        du -hs $i

        log "local_backup $(hostname):$i"

        if $BACKUP
        then
            if rsync --delete -av $i $backup_target/$(dirname $i) >> $backup_log
            then
                log "done $(hostname) @ $i"
            else
                log "done $(hostname) @ $i"
                echo "done $(hostname) @ $i"
            fi
        fi
        echo ''
    done
    echo ''
}

## local backup from a server
function server_backup {

    backup_host="$1"
    backup_hostname="$(ssh -n $1 hostname)"
    backup_dirs="${@:2}"
    backup_target=$BACKUP_PATH/$backup_hostname

    for i in $backup_dirs
    do
        
        mkdir -p $LOG/backup/$backup_hostname/$i
        backup_log=$LOG/backup/$backup_hostname/$i/log
        
        echo $backup_host:$i
        mkdir -p $backup_target/$i
        du -hs $backup_target/$i
        logs "backup @  $backup_host:$i"

        cmd='echo "$(du -hs '$i') $(hostname)/'$i'"'
        if ssh -n -o BatchMode=yes $backup_host "$cmd"
        then
            if $BACKUP
            then
                if rsync --delete -avze ssh $backup_host:/$i $backup_target/$(dirname $i) >> $backup_log
                then
                    log "backup done  $backup_host @ $i"
                else
                    log "ERROR $backup_host @ $i"
                    echo "ERROR $backup_host @ $i"
                fi
            fi
        else
            echo "!! Connection failed to $backup_host."
        fi
        echo ''
    done
    echo ''
}

## local backup of a host thru an ssh-tunneling proxy-server
function remote_backup {

    backup_proxy="$1"
    backup_host="$2"
    cmd="ssh -n $backup_host hostname"
    backup_hostname="$(ssh -n $backup_proxy $cmd)"
    backup_dirs="${@:3}"
    backup_target=$BACKUP_PATH/$backup_hostname

    for i in $backup_dirs
    do
        mkdir -p $LOG/backup/$backup_hostname/$i
        backup_log=$LOG/backup/$backup_hostname/$i/log
        
        echo $backup_hostname:$i 
        mkdir -p $backup_target/$i
        du -hs $backup_target/$i
        logs "backup @  $backup_host:$i"

        cmd='echo "$(du -hs '$i') $(hostname)/'$i'"'
        if ssh -o BatchMode=yes $backup_proxy "ssh -n -o BatchMode=yes $backup_host '$cmd'"
        then

            if $BACKUP
            then
                if rsync --delete -avz -e "ssh -A $backup_proxy ssh" $backup_host:/$i $backup_target/$(dirname $i) >> $backup_log
                then
                    log "done  $backup_host @ $i"
                else
                    log "ERROR $backup_host @ $i"
                    echo "ERROR $backup_host @ $i"
                fi
            fi
        else
            echo "!! Connection failed to $backup_proxy"
        fi
        echo ''
    done
    echo ''
}

function srvctl_backup {
    srvctl_host="$1"
    
    server_backup $srvctl_host /etc
    server_backup $srvctl_host /root
    server_backup $srvctl_host /var/log
    server_backup $srvctl_host /var/spool

    for c in $(ssh -n $srvctl_host 'srvctl ls')
    do
        msg $c
        if $BACKUP
        then
            ssh -n $srvctl_host "ssh -n $c 'sc backup-db'"
        fi
        server_backup $srvctl_host $SRV/$c/cert
        server_backup $srvctl_host $SRV/$c/settings
        server_backup $srvctl_host $SRV/$c/rootfs/srv        
        server_backup $srvctl_host $SRV/$c/rootfs/etc
        server_backup $srvctl_host $SRV/$c/rootfs/root
        server_backup $srvctl_host $SRV/$c/rootfs/var/www
        server_backup $srvctl_host $SRV/$c/rootfs/var/log
        server_backup $srvctl_host $SRV/$c/rootfs/var/spool
        server_backup $srvctl_host $SRV/$c/rootfs/home
    done
}




## examples:
## create a local backup

    #local_backup /etc /root /srv

## create a remote backup

    #server_backup s1.example.com /etc /root 
    #server_backup s2.example.com /etc /root 

## create a remote tunneled backup

    #remote_backup example.com 10.9.8.7 /etc /srv /mnt

## either add your own settings here, or source this file




