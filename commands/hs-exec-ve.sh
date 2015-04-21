#!/bin/bash

if $onHS
then ## no identation.

## exec-all 'something' (or with "")ssh  
hint "exec-all 'CMD [..]'" "Execute a command on all running containers."
if [ "$CMD" == "exec-all" ]
then

    if [ -z "$2" ]
    then
        err "No command specified to execute on containers."
        exit
    fi

    sudomize 
    
        for C in $(lxc_ls)
        do                 
            set_is_running
    
            get_ip
            get_pound_state
            get_state
            get_info
            echo ''        
            if $is_running
            then
                ## execute everything after the "exec-all" part of the argument
                ssh root@$C "${ARGS:9}"
                if [ ! "$?" == "0" ]
                then
                    err "Command returned an error."
                fi
            fi
            echo ''
    
        done
        
    ok
    
fi

man '
    It is possible to iterate trough all running containers, and run a command.
    The command will be executed via ssh, as root, starting in the /root folder.
    Enclose the command into a string to use certain operators, like &&
'

## exec-all backup-db
hint "exec-all-backup-db" "Execute a db backup on all running containers."
if [ "$CMD" == "exec-all-backup-db" ]
then

    sudomize
    
    for C in $(lxc_ls)
    do     
        set_is_running
        get_ip
        get_pound_state
        get_state
        get_info
    
        if $is_running
        then
            ssh $C "srvctl backup-db"
        fi
        echo ''        
    done


ok
fi
man '
    This command will run srvctl backup-db on all running containers.
    It will create backups of all MariaDB databases in the VE, sql format.
'

fi
