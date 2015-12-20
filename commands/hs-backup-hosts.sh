if $onHS && $isROOT
then 
## no identation.

hint "backup-hosts [?]" "Backup srvctl hosts / query backup status"
if [ "$CMD" == "backup-hosts" ]
then
        BACKUP=true
        if [ "$ARG" == "?" ]
        then
            msg "Query-only"
            BACKUP=false
        fi
        
        if [ -z "$BACKUP_PATH" ]
        then
            err "Backup path not set in configs. Using $TMP for now."
            BACKUP_PATH=$TMP
        else
            msg "Using $BACKUP_PATH"
        fi
        
        if [ -f /etc/srvctl/backup-hosts-include ]
        then
            msg processing backup-hosts-include
            source /etc/srvctl/backup-hosts-include
        fi
        
        local_backup /srv
        local_backup /etc
        local_backup /root
        local_backup /var
        
        if [ -f /etc/srvctl/hosts ]
        then
            while read host
            do
                if [ "$(ssh -n -o ConnectTimeout=1 $host hostname 2> /dev/null)" == "$host" ]
                then
                    msg "Update backup for $host"
                    srvctl_backup $host
                else
                    err "Could not connect to $host"
                fi
            done < /etc/srvctl/hosts
        else
             ntc "No hosts file. Missing /etc/srvctl/hosts from configs."
        fi
        
        msg "Done."
ok
fi ## backup
man '
    Attempt to backup all container-data, but not the container operating system.
    This will create a folder - path specified in config - and rsync files and folders.
    Optional directives may be specified in /etc/srvctl/backup-hosts-include
    - local_backup DIRs
    - server_backup HOST DIRs
    - remote_baclup PROXY HOST DIRs
'
fi

