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
        
        for _S in $SRVCTL_HOSTS
        do
                if [ "$(ssh -n -o ConnectTimeout=1 $_S hostname 2> /dev/null)" == "$_S" ]
                then
                    msg "Update backup for $_S"
                    srvctl_backup $_S
                else
                    err "Could not connect to $_S"
                fi
        
        done
        
        msg "Done."
ok
fi ## backup
man '
    Attempt to backup all container-data, but not the container operating system.
    This will create a folder - path specified in config - and rsync files and folders.
    Optional directives may be specified in /etc/srvctl/backup-hosts-include
    - local_backup DIRs
    - server_backup HOST DIRs
    - remote_backup PROXY HOST DIRs
'
fi


