#!/bin/bash

if $onHS
then ## no identation.

## exec-all 'something' (or with "")ssh  
hint "exec-all 'CMD [..]'" "Execute a command on all running containers."
if [ "$CMD" == "exec-all" ]
then

    if [ -z "$ARG" ]
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

## exec-all backup-db
hint "top" "Show table of processes on all running containers."
if [ "$CMD" == "top" ]
then

    sudomize
    
    tmp_file=$TMP/root-top
    if ! [ -z "$SC_SUDO_USER" ]
    then
        tmp_file=$TMP/$SC_SUDO_USER-top
    fi
        
    echo "" > $tmp_file
    
    
    for C in $(lxc_ls)
    do     
        set_is_running    
        if $is_running
        then
            echo $C
            echo "--- $C ---" >> $tmp_file
            ssh -t $C "top -b -n 1" >> $tmp_file
        fi
               
    done
    
 cat $tmp_file

ok
fi
man '
    This command will run top with one run on all running containers.
    top may help to identify hanging or resource intensive processes.
'


fi
