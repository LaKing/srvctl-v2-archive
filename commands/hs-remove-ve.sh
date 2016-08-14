#!/bin/bash

if $onHS
then ## no identation.


## reMOVE host
hint "remove VE" "Remove a container."
if [ "$CMD" == "remove" ] || [ "$CMD" == "destroy" ]
then

        argument C
        sudomize
        authorize
        
        if [ -d "$SRV/$C" ] 
        then
            
            bind_unmount $C
            nfs_unmount $C
            backup_unmount $C

            lxc-stop -k -n $ARG

            ## remove from known_hosts ... regenerate?

            RMD=$TMP/$C-$NOW
            mkdir -p $RMD
        
            if [ "$CMD" == "remove" ] 
            then
                log "Removing container to $RMD"
                rsync -a $SRV/$C $RMD        
                rm -fr $SRV/$C
            fi
            
            if [ "$CMD" == "destroy" ]
            then
                rm -fr $SRV/$C
            fi

                ## delete each users share.
                for _U in $(ls /home)
                do
                        if [ -d "/home/$_U/$C" ]
                        then
                                ## take care of password hash
                                rm -rf /home/$_U/$C/mnt/.password.sha512
                                
                                ## remove mnt folder - if empty
                                if [ -z "$(ls /home/$_U/$C/mnt 2> /dev/null)" ]
                                then
                                        rm -rf /home/$_U/$C/mnt
                                fi
                                
                                if [ -z "$(ls /home/$_U/$C/nfs 2> /dev/null)" ]
                                then
                                        rm -rf /home/$_U/$C/nfs
                                fi
                                
                                if [ -z "$(ls /home/$_U/$C/bind 2> /dev/null)" ]
                                then
                                        rm -rf /home/$_U/$C/bind
                                fi

                                ## remove user container folder
                                if [ -z "$(ls /home/$_U/$C )" ]
                                then
                                        rm -rf /home/$_U/$C
                                fi
                        fi
                done
                
                
                rm -rf /var/log/httpd/$C-access_log
                rm -rf /var/log/httpd/$C-error_log

                ## TODO regenerate everything
                regenerate_etc_hosts
                regenerate_relaydomains 
                regenerate_known_hosts
                regenerate_pound_files
                #regenerate_pound_sync
                restart_pound
                regenerate_dns
                regenerate_logfiles
                regenerate_perdition_files
        fi
            
        if [ -f /var/dyndns/$C.auth ]
        then
            rm -fr /var/dyndns/$C.auth
            rm -fr /var/dyndns/$C.ip
            rm -fr /var/dyndns/$C.lock
            rm -fr /var/dyndns/$C.updt
            regenerate_dns    
        fi
        

ok
fi ## reMOVE

man '
    This will stop the VE and remove its files to /temp - or the temporary directory defined in /etc/srvctl/config
    Containers will be extended with the date of removal. srvctl does not delete any files.
'

fi

