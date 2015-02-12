#!/bin/bash

if $onHS
then ## no identation.

## exec-all 'something' (or with "")ssh  
hint "exec-all 'CMD [..]'" "Execute a command on all running containers."
if [ "$CMD" == "exec-all" ]
then


argument comm

 for C in $(lxc-ls)
 do
        set_is_running

        if $is_running
        then
            #ssh $C $comm - but we take all - max 8 - arguments
            ssh $C "$2 $3 $4 $5 $6 $7 $8 $9"
        fi

        get_ip
        get_pound_state
        get_state
        get_info

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

 for C in $(lxc-ls)
 do
        set_is_running

        if $is_running
        then
        ssh $C "srvctl backup-db"
        fi

        get_ip
        get_pound_state
        get_state
        get_info

        echo ''        

 done

ok
fi
man '
    This command will run srvctl backup-db on all running containers.
    It will create backups of all MariaDB databases in the VE, sql format.
'

fi
